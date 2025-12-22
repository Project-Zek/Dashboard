defmodule ProjectZek.Repo.Migrations.AddUniqueIndexLoginServerAccountsUsername do
  use Ecto.Migration

  def change do
    create unique_index(:login_server_accounts, [:username])
  end
end

