defmodule ProjectZek.LoginServer.Account do
  use Ecto.Schema
  import Ecto.Changeset

  schema "login_server_accounts" do
    belongs_to :user, ProjectZek.Accounts.User
    field :username, :string
    field :password, :string
    field :last_password_change_at, :utc_datetime
    field :last_login_ip, :string
    field :last_login_at, :utc_datetime
    timestamps()
  end

  @spec changeset(
          {map(), map()}
          | %{
              :__struct__ => atom() | %{:__changeset__ => map(), optional(any()) => any()},
              optional(atom()) => any()
            },
          :invalid | %{optional(:__struct__) => none(), optional(atom() | binary()) => any()}
        ) :: Ecto.Changeset.t()
  @doc false
  def changeset(account, attrs) do
    account
    |> cast(attrs, [:user_id, :username, :password])
    |> validate_required([:user_id, :username, :password])
  end

  @doc false
  def registration_changeset(account, attrs, opts \\ []) do
    account
    |> cast(attrs, [:user_id, :username, :password])
    |> validate_required([:user_id])
    |> validate_username(opts)
    |> validate_password(opts)
    |> validate_confirmation(:password, message: "does not match password")
  end

  defp validate_username(changeset, opts) do
    changeset
    |> validate_required([:username])
    |> validate_length(:username, min: 5, max: 30)
  end

  @doc false
  defp validate_password(changeset, opts) do
    changeset
    |> validate_required([:password])
    |> validate_length(:password, min: 8, max: 50)
    |> validate_format(:password, ~r/[a-z]/, message: "at least one lower case character")
    |> validate_format(:password, ~r/[A-Z]/, message: "at least one upper case character")
    |> validate_format(:password, ~r/[!?@#$%^&*_0-9]/, message: "at least one digit or punctuation character")
    |> hash_password(opts)
  end

  defp hash_password(changeset, opts) do
    password = get_change(changeset, :password)

    changeset
    |> put_change(:password, ProjectZek.LoginServer.HashUtils.sha1(password))
  end
end
