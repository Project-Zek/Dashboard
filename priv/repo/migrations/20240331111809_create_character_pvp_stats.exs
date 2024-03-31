defmodule ProjectZek.Repo.Migrations.CreateCharacterPvpStats do
  use Ecto.Migration

  def change do
    create_table(:character_pvp_stats) do
      add references(:character_data, on_delete: :delete_all)
      add :pvp_kills, :integer, null: false, default: 0
      add :pvp_deaths, :integer, null: false, default: 0
      add :pvp_points_available, :integer, null: false, default: 0
      add :pvp_total_points, :integer, null: false, default: 0
      add :pvp_current_kill_streak, :integer, null: false, default: 0
      add :pvp_best_kill_streak, :integer, null: false, default: 0
      add :pvp_current_death_streak, :integer, null: false, default: 0
      add :pvp_worst_death_streak, :integer, null: false, default: 0
      add :pvp_infamy, :integer, null: false, default: 0
      add :pvp_vitality, :integer, null: false, default: 0
    end
  end
end
