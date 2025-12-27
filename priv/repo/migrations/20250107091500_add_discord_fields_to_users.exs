defmodule ProjectZek.Repo.Migrations.AddDiscordFieldsToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :discord_user_id, :string
      add :discord_username, :string
      add :discord_avatar, :string
      add :discord_linked_at, :utc_datetime
    end

    create unique_index(:users, [:discord_user_id])
  end
end

