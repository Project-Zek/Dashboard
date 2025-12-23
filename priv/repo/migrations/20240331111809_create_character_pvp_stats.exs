defmodule ProjectZek.Repo.Migrations.CreateCharacterPvpStats do
  use Ecto.Migration

  def change do
    create table(:character_pvp_stats) do
      # Match world schema: character_data.id is INT UNSIGNED, so FK must be INT UNSIGNED
      add :character_data_id, references(:character_data, type: :"int unsigned", on_delete: :delete_all)
      add :pvp_kills, :integer, null: false, default: 0
      add :pvp_deaths, :integer, null: false, default: 0
      add :pvp_current_points, :integer, null: false, default: 0
      add :pvp_career_points, :integer, null: false, default: 0
      add :pvp_current_kill_streak, :integer, null: false, default: 0
      add :pvp_best_kill_streak, :integer, null: false, default: 0
      add :pvp_current_death_streak, :integer, null: false, default: 0
      add :pvp_worst_death_streak, :integer, null: false, default: 0
      add :pvp_infamy, :integer, null: false, default: 0
      add :pvp_vitality, :integer, null: false, default: 0
    end

    create index(:character_pvp_stats, [:character_data_id])
  end
end
