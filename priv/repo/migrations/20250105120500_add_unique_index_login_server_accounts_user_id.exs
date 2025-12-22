defmodule ProjectZek.Repo.Migrations.AddUniqueIndexLoginServerAccountsUserId do
  use Ecto.Migration

  def up do
    execute("""
    DELETE l1
    FROM login_server_accounts l1
    JOIN login_server_accounts l2
      ON l1.user_id = l2.user_id
     AND (
          l1.inserted_at < l2.inserted_at OR
          (l1.inserted_at = l2.inserted_at AND l1.id < l2.id)
         )
    """)

    create unique_index(:login_server_accounts, [:user_id])
  end

  def down do
    drop_if_exists index(:login_server_accounts, [:user_id])
  end
end
