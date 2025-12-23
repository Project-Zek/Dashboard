defmodule ProjectZek.Repo.Migrations.CreateUserLsAccountsAndDropLocalLs do
  use Ecto.Migration

  def up do
    create table(:user_ls_accounts, primary_key: false) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :login_server_id, :"int unsigned", null: false
    end

    create unique_index(:user_ls_accounts, [:user_id])
    create unique_index(:user_ls_accounts, [:login_server_id])

    # Optional backfill from old login_server_accounts by matching username to LS AccountName
    if table_exists?(:login_server_accounts) do
      execute "INSERT IGNORE INTO user_ls_accounts (user_id, login_server_id) \
               SELECT a.user_id, l.LoginServerID \
               FROM login_server_accounts a \
               JOIN tblLoginServerAccounts l ON l.AccountName = a.username",
              "DELETE FROM user_ls_accounts"
    end

    drop_if_exists table(:login_server_accounts)
  end

  def down do
    create table(:login_server_accounts) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :username, :string, null: false
      add :password, :string, null: false
      add :last_password_change_at, :utc_datetime
      add :last_login_ip, :string
      add :last_login_at, :utc_datetime
      timestamps()
    end

    drop table(:user_ls_accounts)
  end

  defp table_exists?(name) do
    repo().query!("SELECT 1 FROM information_schema.tables WHERE table_schema = DATABASE() AND table_name = ? LIMIT 1", [to_string(name)]).num_rows > 0
  end
end

