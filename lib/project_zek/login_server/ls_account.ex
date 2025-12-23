defmodule ProjectZek.LoginServer.LsAccount do
  use Ecto.Schema
  import Ecto.Changeset
  @derive {Flop.Schema, filterable: [:account_name], sortable: [:account_name, :last_login_date]}
  @derive {Phoenix.Param, key: :login_server_id}

  @primary_key false
  schema "tblLoginServerAccounts" do
    field :login_server_id, :integer, primary_key: true, source: :LoginServerID
    field :account_name, :string, source: :AccountName
    field :account_password, :string, source: :AccountPassword
    field :account_email, :string, source: :AccountEmail
    field :last_login_date, :naive_datetime, source: :LastLoginDate
    field :last_ip_address, :string, source: :LastIPAddress
    field :creation_ip, :string, source: :creationIP
    field :forum_name, :string, source: :ForumName
    field :client_unlock, :integer, source: :client_unlock
    field :created_by, :integer, source: :created_by
    field :max_accts, :integer, source: :max_accts

    # Through mapping to the web user via user_ls_accounts
    has_one :user_ls, ProjectZek.LoginServer.UserLsAccount,
      foreign_key: :login_server_id,
      references: :login_server_id

    has_one :user, through: [:user_ls, :user]
  end

  def changeset(ls_account, attrs) do
    ls_account
    |> cast(attrs, [
      :account_name,
      :account_password,
      :account_email,
      :last_login_date,
      :last_ip_address,
      :creation_ip,
      :forum_name,
      :client_unlock,
      :created_by,
      :max_accts
    ])
    |> validate_required([:account_name, :account_password, :last_login_date, :last_ip_address, :creation_ip])
  end
end
