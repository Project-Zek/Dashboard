defmodule ProjectZek.Repo.Migrations.CreateCharacterPvpEntries do
  use Ecto.Migration

  def change do
    create table(:character_pvp_entries) do
      add :killer_id, :integer
      add :killer_name, :string
      add :killer_level, :integer
      add :victim_id, :integer
      add :victim_name, :string
      add :victim_level, :integer
      add :zone_id, :integer
      add :points, :integer
      add :timestamp, :utc_datetime

      timestamps(type: :utc_datetime)
    end
  end
end
