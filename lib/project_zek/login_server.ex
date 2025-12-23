defmodule ProjectZek.LoginServer do
  @moduledoc """
  The LoginServer context.
  """

  import Ecto.Query, warn: false
  alias ProjectZek.Repo

  alias ProjectZek.LoginServer.Account
  alias ProjectZek.LoginServer.LsAccount
  alias ProjectZek.World.Account, as: WorldAccount
  alias Ecto.Multi

  @doc """
  Returns the list of accounts.

  ## Examples

      iex> list_accounts()
      [%Account{}, ...]

  """
  def list_accounts do
    Repo.all(Account)
  end

  @doc """
  Admin listing with Flop search/filter/sort for login server accounts.

  Supported params:
    - :q / "q": search term across username and owner email
    - :status / "status": one of "all" | "active" | "banned" | "suspended"
  """
  def list_accounts_admin(flop, params \\ %{}) do
    q = Map.get(params, :q) || Map.get(params, "q")
    status = Map.get(params, :status) || Map.get(params, "status")

    now = NaiveDateTime.utc_now()

    base =
      from a in Account,
        left_join: u in assoc(a, :user),
        left_join: l in LsAccount,
        on: l.account_name == a.username,
        left_join: w in WorldAccount,
        on:
          (not is_nil(l.login_server_id) and l.login_server_id > 0 and w.lsaccount_id == l.login_server_id) or
            fragment("LOWER(?) = LOWER(?)", w.name, l.account_name),
        preload: [user: u]

    base =
      case q do
        nil -> base
        "" -> base
        term ->
          from [a, u, l, w] in base,
            where: ilike(a.username, ^"%#{term}%") or ilike(u.email, ^"%#{term}%")
      end

    base =
      case status do
        "banned" -> from [a, u, l, w] in base, where: not is_nil(w.status) and w.status < 0
        "suspended" -> from [a, u, l, w] in base, where: not is_nil(w.suspendeduntil) and w.suspendeduntil > ^now
        "active" ->
          from [a, u, l, w] in base,
            where:
              is_nil(w.id) or
                ((is_nil(w.status) or w.status >= 0) and (is_nil(w.suspendeduntil) or w.suspendeduntil <= ^now))
        _ -> base
      end

    Flop.validate_and_run(base, flop, for: Account)
  end

  @doc """
  Returns the list of accounts by user_id.

  ## Examples

      iex> list_accounts_by_user_id(1)
      [%Account{}, ...]

  """
  def list_accounts_by_user_id(user_id) do
    Repo.all(from(a in Account, where: a.user_id == ^user_id))
  end

  @doc """
  Gets a single account.

  Raises `Ecto.NoResultsError` if the Account does not exist.

  ## Examples

      iex> get_account!(123)
      %Account{}

      iex> get_account!(456)
      ** (Ecto.NoResultsError)

  """
  def get_account!(id), do: Repo.get!(Account, id)

  @doc """
  Creates a account.

  ## Examples

      iex> create_account(%{field: value})
      {:ok, %Account{}}

      iex> create_account(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_account(attrs \\ %{}) do
    ip = Map.get(attrs, "ip") || "127.0.0.1"
    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

    Multi.new()
    |> Multi.run(:enforce_user_limit, fn repo, _changes ->
      user_id = Map.get(attrs, "user_id") || Map.get(attrs, :user_id)
      count = repo.aggregate(from(a in Account, where: a.user_id == ^user_id), :count)
      if count == 0 do
        {:ok, :ok}
      else
        changeset = Account.registration_changeset(%Account{}, attrs, hash_password: false)
        {:error, Ecto.Changeset.add_error(changeset, :username, "you already have a login server account")}
      end
    end)
    |> Multi.run(:ensure_unique_username, fn _repo, _changes ->
      username = Map.get(attrs, "username")
      case Repo.get_by(WorldAccount, name: username) do
        nil -> {:ok, :available}
        _ ->
          changeset = Account.registration_changeset(%Account{}, attrs, hash_password: false)
          {:error, Ecto.Changeset.add_error(changeset, :username, "has already been taken")}
      end
    end)
    |> Multi.insert(:account,
      Account.registration_changeset(
        %Account{},
        attrs
        |> Map.put("last_login_ip", ip)
        |> Map.put("last_login_at", now)
      )
    )
    |> Multi.run(:ls_account, fn repo, %{account: account} ->
      # Insert into LS table using DB-side SHA() and NOW() to match server behavior
      # Use plaintext password from attrs specifically for the LS insert
      plain_password = Map.get(attrs, "password") || Map.get(attrs, :password)
      email = Map.get(attrs, "email") || "local_creation"

      sql = "INSERT INTO `tblLoginServerAccounts` (AccountName, AccountPassword, AccountEmail, LastLoginDate, LastIPAddress, creationIP, ForumName) VALUES (?, SHA(?), ?, NOW(), ?, ?, 'Guest')"

      case repo.query(sql, [account.username, plain_password, email, ip, ip]) do
        {:ok, _} ->
          # Fetch the row we just inserted so downstream can use login_server_id
          case repo.get_by(LsAccount, account_name: account.username) do
            nil -> {:error, :ls_insert_failed}
            ls -> {:ok, ls}
          end
        {:error, reason} -> {:error, reason}
      end
    end)
    |> Multi.run(:world_account, fn repo, %{ls_account: ls_account} ->
      # Create or ensure a world account exists matching the LS account name
      # and link it to the LS account id for downstream auth/ownership checks.
      world_attrs = %{name: ls_account.account_name, lsaccount_id: ls_account.login_server_id}
      %WorldAccount{}
      |> WorldAccount.changeset(world_attrs)
      |> repo.insert()
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{account: account}} -> {:ok, account}
      {:error, :account, changeset, _} -> {:error, changeset}
      {:error, _step, reason, _} -> {:error, reason}
    end
  end

  @doc """
  Updates a account.

  ## Examples

      iex> update_account(account, %{field: new_value})
      {:ok, %Account{}}

      iex> update_account(account, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_account(%Account{} = account, attrs) do
    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
    plain_password = Map.get(attrs, "password") || Map.get(attrs, :password)

    Multi.new()
    # Hash and validate only the password, do not allow username changes
    |> Multi.update(:account,
      Account.password_changeset(account, attrs)
      |> Ecto.Changeset.put_change(:last_password_change_at, now)
    )
    |> Multi.run(:ls_account, fn repo, %{account: updated} ->
      case repo.get_by(LsAccount, account_name: updated.username) do
        nil -> {:ok, :skip}
        _ls ->
          # Update LS password using DB-side SHA(), but only if a new password was provided
          if is_binary(plain_password) and byte_size(String.trim(plain_password)) > 0 do
            sql = "UPDATE `tblLoginServerAccounts` SET AccountPassword = SHA(?) WHERE AccountName = ?"
            repo.query(sql, [plain_password, updated.username])
          else
            {:ok, :no_password_change}
          end
      end
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{account: updated}} -> {:ok, updated}
      {:error, :account, changeset, _} -> {:error, changeset}
      {:error, _step, reason, _} -> {:error, reason}
    end
  end

  @doc """
  Deletes a account.

  ## Examples

      iex> delete_account(account)
      {:ok, %Account{}}

      iex> delete_account(account)
      {:error, %Ecto.Changeset{}}

  """
  def delete_account(%Account{} = account) do
    Repo.delete(account)
  end

  @doc """
  Deeply deletes a login server account and all linked world data.

  Rules:
    - Only the owner may delete, unless `opts[:force]` is true and caller is superadmin.
    - If world account is banned, deny unless `:force`.
  """
  def delete_account_deep(%Account{} = account, current_user, opts \\ []) do
    force? = Keyword.get(opts, :force, superadmin?(current_user))

    cond do
      account.user_id != current_user.id and not force? ->
        {:error, :unauthorized}

      true ->
        do_delete_account_deep(account, force?)
    end
  end

  def superadmin?(user) do
    admins = Application.get_env(:project_zek, :superadmins, [])
    is_binary(user.email) and Enum.member?(admins, String.downcase(user.email))
  end

  defp do_delete_account_deep(%Account{} = account, force?) do
    Repo.transaction(fn ->
      # Find LS account and world account
      ls = Repo.get_by(LsAccount, account_name: account.username)
      world = resolve_world_account(account.username, ls)

      if world do
        # Check banned state
        banned? = (world.revoked && world.revoked != 0) || (world.status && world.status < 0) || (world.active == 0)
        if banned? and not force?, do: Repo.rollback(:banned)

        # Collect character ids and names
        {:ok, %{rows: char_ids_rows}} = Repo.query("SELECT id FROM character_data WHERE account_id = ?", [world.id])
        char_ids = Enum.map(char_ids_rows, fn [id] -> id end)

        {:ok, %{rows: names_rows}} = Repo.query("SELECT name FROM character_data WHERE account_id = ?", [world.id])
        char_names = Enum.map(names_rows, fn [n] -> n end)

        if length(char_ids) > 0 do
          ids_in = Enum.map_join(char_ids, ",", &to_string/1)

          # Delete dependent rows keyed by character id
          for table <- [
                 "character_alternate_abilities",
                 "character_bind",
                 "character_buffs",
                 "character_currency",
                 "character_inspect_messages",
                 "character_inventory",
                 "character_keyring",
                 "character_languages",
                 "character_memmed_spells",
                 "character_pet_buffs",
                 "character_pet_info",
                 "character_pet_inventory",
                 "character_skills",
                 "character_spells",
                 "character_timers",
                 "character_zone_flags"
               ] do
            Repo.query!("DELETE FROM `#{table}` WHERE id IN (#{ids_in})")
          end

          # Corpses and corpse items
          {:ok, %{rows: corpse_rows}} = Repo.query("SELECT id FROM character_corpses WHERE charid IN (#{ids_in})")
          corpse_ids = Enum.map(corpse_rows, fn [id] -> id end)
          if length(corpse_ids) > 0 do
            cids_in = Enum.map_join(corpse_ids, ",", &to_string/1)
            Repo.query!("DELETE FROM character_corpse_items WHERE corpse_id IN (#{cids_in})")
            Repo.query!("DELETE FROM character_corpses WHERE charid IN (#{ids_in})")
            Repo.query!("DELETE FROM character_corpses_backup WHERE charid IN (#{ids_in})")
          end

          # PvP data (entries and stats)
          Repo.query!("DELETE FROM character_pvp_entries WHERE killer_id IN (#{ids_in}) OR victim_id IN (#{ids_in})")
          Repo.query!("DELETE FROM character_pvp_stats WHERE character_data_id IN (#{ids_in})")

          # Finally delete characters
          Repo.query!("DELETE FROM character_data WHERE account_id = ?", [world.id])
        end

        # Account-related aux tables
        Repo.query!("DELETE FROM account_flags WHERE account_id = ?", [world.id])
        Repo.query!("DELETE FROM account_ip WHERE account_id = ?", [world.id])
        Repo.query!("DELETE FROM account_rewards WHERE account_id = ?", [world.id])

        # World account
        Repo.query!("DELETE FROM account WHERE id = ?", [world.id])
      end

      # LoginServer accounts
      if ls, do: Repo.delete!(ls)
      Repo.delete!(account)

      :ok
    end)
    |> case do
      {:ok, :ok} -> {:ok, :deleted}
      {:error, :banned} -> {:error, :banned}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking account changes.

  ## Examples

      iex> change_account(account)
      %Ecto.Changeset{data: %Account{}}

  """
  def change_account(%Account{} = account, attrs \\ %{}) do
    # Use registration validations (including password confirmation) without hashing
    Account.registration_changeset(account, attrs, hash_password: false)
  end

  @doc """
  Returns true if any of the user's login server accounts are banned at the world level.
  """
  def user_has_banned_account?(%ProjectZek.Accounts.User{id: user_id}) do
    list_accounts_by_user_id(user_id)
    |> Enum.any?(fn a ->
      account_banned?(a)
    end)
  end

  @doc """
  Returns true if the given login server account appears banned in the world DB.
  """
  def account_banned?(%Account{username: username}) do
    ls = Repo.get_by(LsAccount, account_name: username)
    world = resolve_world_account(username, ls)

    case world do
      nil -> false
      w ->
        suspended? =
          case w.suspendeduntil do
            nil -> false
            %NaiveDateTime{} = ndt -> NaiveDateTime.compare(ndt, NaiveDateTime.utc_now()) == :gt
            _ -> false
          end

        status_banned? = is_integer(w.status) and w.status < 0

        status_banned? or suspended?
    end
  end

  @doc """
  Returns detailed ban info for a login server account.
  {:ok, :none} | {:ok, {:suspended, until, reason}} | {:ok, {:banned, reason}}
  """
  def ban_info(%Account{username: username}) do
    ls = Repo.get_by(LsAccount, account_name: username)
    world = resolve_world_account(username, ls)

    case world do
      nil -> {:ok, :none}
      w ->
        now = NaiveDateTime.utc_now()
        suspended? = case w.suspendeduntil do
          %NaiveDateTime{} = ndt -> NaiveDateTime.compare(ndt, now) == :gt
          _ -> false
        end

        cond do
          is_integer(w.status) and w.status < 0 -> {:ok, {:banned, w.ban_reason}}
          suspended? -> {:ok, {:suspended, w.suspendeduntil, w.suspend_reason}}
          true -> {:ok, :none}
        end
    end
  end

  @doc """
  Returns detailed ban info for a web user by mapping to their LS account.
  """
  def ban_info_for_user(%ProjectZek.Accounts.User{id: user_id}) do
    case list_accounts_by_user_id(user_id) do
      [acc | _] -> ban_info(acc)
      _ -> {:ok, :none}
    end
  end

  @doc """
  Lists all characters that belong to any world account linked to the given web user.
  Preloads PvP stats for display.
  """
  def list_user_characters(%ProjectZek.Accounts.User{id: user_id}) do
    import Ecto.Query
    alias ProjectZek.Characters.Character

    accounts = list_accounts_by_user_id(user_id)

    world_ids =
      accounts
      |> Enum.map(fn a ->
        ls = Repo.get_by(LsAccount, account_name: a.username)
        case resolve_world_account(a.username, ls) do
          nil -> nil
          w -> w.id
        end
      end)
      |> Enum.reject(&is_nil/1)
      |> Enum.uniq()

    if world_ids == [] do
      []
    else
      Repo.all(from c in Character, where: c.account_id in ^world_ids, preload: [:pvp_stat])
    end
  end

  # -- Mapping helpers -----------------------------------------------------
  defp resolve_world_account(username, ls) do
    cond do
      match?(%LsAccount{}, ls) and is_integer(ls.login_server_id) and ls.login_server_id > 0 ->
        Repo.get_by(WorldAccount, lsaccount_id: ls.login_server_id) ||
          Repo.one(from w in WorldAccount, where: fragment("LOWER(?) = LOWER(?)", w.name, ^ls.account_name), limit: 1)

      true ->
        Repo.one(from w in WorldAccount, where: fragment("LOWER(?) = LOWER(?)", w.name, ^to_string(username)), limit: 1)
    end
  end
end
