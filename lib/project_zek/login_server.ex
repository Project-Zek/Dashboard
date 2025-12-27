defmodule ProjectZek.LoginServer do

  import Ecto.Query, warn: false
  alias ProjectZek.Repo

  alias ProjectZek.LoginServer.LsAccount
  alias ProjectZek.LoginServer.UserLsAccount
  alias ProjectZek.World.Account, as: WorldAccount
  # alias Ecto.Multi

  # New LS-centric helpers (non-breaking; used by new UI)
  def list_ls_accounts_by_user(%ProjectZek.Accounts.User{id: user_id}) do
    import Ecto.Query
    Repo.all(
      from ula in UserLsAccount,
        where: ula.user_id == ^user_id,
        join: ls in LsAccount,
        on: ls.login_server_id == ula.login_server_id,
        select: ls
    )
  end

  def require_discord_for_ls? do
    Application.get_env(:project_zek, :require_discord_for_ls, false)
  end

  def create_ls_account_and_link(%ProjectZek.Accounts.User{} = user, %{"username" => username, "password" => password} = attrs) do
    if require_discord_for_ls?() and (is_nil(user.discord_user_id) or user.discord_user_id == "") do
      {:error, :discord_required}
    else
    ip = Map.get(attrs, "ip") || "127.0.0.1"
    email = Map.get(attrs, "email") || user.email || "local_creation"
    salt = Application.get_env(:project_zek, :login_salt, "")

    Repo.transaction(fn ->
      # Clean up any stale user->LS mappings where the LS row no longer exists
      from(m in UserLsAccount,
        left_join: ls in LsAccount,
        on: ls.login_server_id == m.login_server_id,
        where: m.user_id == ^user.id and is_nil(ls.login_server_id)
      )
      |> Repo.delete_all()

      # Check constraints up-front for accurate error messages
      has_link? = Repo.exists?(from m in UserLsAccount, where: m.user_id == ^user.id)

      username_taken? =
        Repo.exists?(
          from l in LsAccount,
            where: fragment("LOWER(?) = LOWER(?)", l.account_name, ^username)
        )

      cond do
        has_link? -> Repo.rollback(:already_linked)
        username_taken? -> Repo.rollback(:username_taken)
        true -> :ok
      end

      # Create LS row using salted SHA and NOW()
      sql = "INSERT INTO `tblLoginServerAccounts` (AccountName, AccountPassword, AccountEmail, LastLoginDate, LastIPAddress, creationIP, ForumName) VALUES (?, SHA(CONCAT(?, ?)), ?, NOW(), ?, ?, 'Guest')"
      case Repo.query(sql, [username, password, salt, email, ip, ip]) do
        {:ok, _} -> :ok
        {:error, reason} -> Repo.rollback(reason)
      end

      ls = Repo.get_by!(LsAccount, account_name: username)
      mapping = UserLsAccount.changeset(%UserLsAccount{}, %{user_id: user.id, login_server_id: ls.login_server_id})
      {:ok, _} = Repo.insert(mapping)
      ls
    end)
    end
  end

  # Linking existing LS accounts is intentionally not supported.

  def update_ls_password(%LsAccount{} = ls, password) when is_binary(password) do
    salt = Application.get_env(:project_zek, :login_salt, "")
    Repo.query("UPDATE `tblLoginServerAccounts` SET AccountPassword = SHA(CONCAT(?, ?)) WHERE LoginServerID = ?", [password, salt, ls.login_server_id])
  end

  def unlink_ls_account(%ProjectZek.Accounts.User{id: user_id}, login_server_id) do
    import Ecto.Query
    Repo.delete_all(from m in UserLsAccount, where: m.user_id == ^user_id and m.login_server_id == ^login_server_id)
  end

  def delete_ls_account(login_server_id) when is_integer(login_server_id) do
    # Delete mapping(s) first, then LS row
    import Ecto.Query
    Repo.transaction(fn ->
      Repo.delete_all(from m in UserLsAccount, where: m.login_server_id == ^login_server_id)
      Repo.query!("DELETE FROM `tblLoginServerAccounts` WHERE LoginServerID = ?", [login_server_id])
    end)
  end

  def ls_account_banned?(%LsAccount{} = ls) do
    world = resolve_world_account(ls.account_name, ls)
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

  def list_accounts_admin(flop, params \\ %{}) do
    import Ecto.Query
    q = Map.get(params, :q) || Map.get(params, "q")
    status = Map.get(params, :status) || Map.get(params, "status")

    now = NaiveDateTime.utc_now()

    base =
      from l in LsAccount,
        left_join: uls in UserLsAccount,
        on: uls.login_server_id == l.login_server_id,
        left_join: u in ProjectZek.Accounts.User,
        on: u.id == uls.user_id,
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
          from [l, uls, u, w] in base,
            where: ilike(l.account_name, ^"%#{term}%") or ilike(u.email, ^"%#{term}%")
      end

    base =
      case status do
        "banned" -> from [l, uls, u, w] in base, where: not is_nil(w.status) and w.status < 0
        "suspended" -> from [l, uls, u, w] in base, where: not is_nil(w.suspendeduntil) and w.suspendeduntil > ^now
        "active" ->
          from [l, uls, u, w] in base,
            where:
              is_nil(w.id) or
                ((is_nil(w.status) or w.status >= 0) and (is_nil(w.suspendeduntil) or w.suspendeduntil <= ^now))
        _ -> base
      end

    Flop.validate_and_run(base, flop, for: LsAccount)
  end


  def superadmin?(user) do
    admins = Application.get_env(:project_zek, :superadmins, [])
    is_binary(user.email) and Enum.member?(admins, String.downcase(user.email))
  end

  def user_has_banned_account?(%ProjectZek.Accounts.User{id: user_id}) do
    list_ls_accounts_by_user(%ProjectZek.Accounts.User{id: user_id})
    |> Enum.any?(fn ls -> ls_account_banned?(ls) end)
  end

  def ban_info_for_user(%ProjectZek.Accounts.User{id: user_id}) do
    ls_list = list_ls_accounts_by_user(%ProjectZek.Accounts.User{id: user_id})
    case ls_list do
      [%LsAccount{} = ls | _] -> ban_info(ls)
      _ -> {:ok, :none}
    end
  end

  def ban_info(%LsAccount{} = ls) do
    world = resolve_world_account(ls.account_name, ls)
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

  def list_user_characters(%ProjectZek.Accounts.User{id: user_id}) do
    import Ecto.Query
    alias ProjectZek.Characters.Character

    ls_accounts = list_ls_accounts_by_user(%ProjectZek.Accounts.User{id: user_id})

    world_ids =
      ls_accounts
      |> Enum.map(fn ls ->
        case resolve_world_account(ls.account_name, ls) do
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
