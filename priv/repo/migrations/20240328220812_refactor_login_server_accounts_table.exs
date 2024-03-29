defmodule ProjectZek.Repo.Migrations.RefactorLoginServerAccountsTable do
  use Ecto.Migration

  def change do
   create table(:login_server_accounts) do
    add :user_id, references(:users, on_delete: :delete_all), null: false
    add :username, :string, size: 30
    add :password, :string, size: 50
    add :last_password_change_at, :utc_datetime
    add :last_login_ip, :string, size: 15
    add :last_login_at, :utc_datetime
    timestamps()
  end
  end
end
