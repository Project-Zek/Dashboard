defmodule ProjectZek.Characters.PvpStat do
  use Ecto.Schema
  import Ecto.Changeset
  @derive {Flop.Schema,
           filterable: [:pvp_kills, :pvp_deaths, :pvp_current_points, :pvp_career_points],
           sortable: [:pvp_kills, :pvp_deaths, :pvp_current_points, :pvp_career_points],
           default_limit: 25,
           max_limit: 100,
           default_order: %{
             order_by: [:pvp_career_points],
             order_directions: [:desc]
           }}

  schema "character_pvp_stats" do
    field :pvp_kills, :integer, default: 0
    field :pvp_deaths, :integer, default: 0
    field :pvp_current_points, :integer, default: 0
    field :pvp_career_points, :integer, default: 0
    field :pvp_current_kill_streak, :integer, default: 0
    field :pvp_best_kill_streak, :integer, default: 0
    field :pvp_current_death_streak, :integer, default: 0
    field :pvp_worst_death_streak, :integer, default: 0
    field :pvp_infamy, :integer, default: 0
    field :pvp_vitality, :integer, default: 0

    belongs_to :character_data, ProjectZek.Characters.Character
  end

  @doc false
  def changeset(pvp_stat, attrs) do
    pvp_stat
    |> cast(attrs, [
      :character_data_id,
      :pvp_kills,
      :pvp_deaths,
      :pvp_current_points,
      :pvp_career_points,
      :pvp_current_kill_streak,
      :pvp_best_kill_streak,
      :pvp_current_death_streak,
      :pvp_worst_death_streak,
      :pvp_infamy,
      :pvp_vitality
    ])
    |> validate_required([
      :character_data_id,
      :pvp_kills,
      :pvp_deaths,
      :pvp_current_points,
      :pvp_career_points,
      :pvp_current_kill_streak,
      :pvp_best_kill_streak,
      :pvp_current_death_streak,
      :pvp_worst_death_streak,
      :pvp_infamy,
      :pvp_vitality
    ])
    |> validate_number(:character_data_id, greater_than_or_equal_to: 0)
    |> validate_number(:pvp_kills, greater_than_or_equal_to: 0)
    |> validate_number(:pvp_deaths, greater_than_or_equal_to: 0)
    |> validate_number(:pvp_current_points, greater_than_or_equal_to: 0)
    |> validate_number(:pvp_career_points, greater_than_or_equal_to: 0)
    |> validate_number(:pvp_current_kill_streak, greater_than_or_equal_to: 0)
    |> validate_number(:pvp_best_kill_streak, greater_than_or_equal_to: 0)
    |> validate_number(:pvp_current_death_streak, greater_than_or_equal_to: 0)
    |> validate_number(:pvp_worst_death_streak, greater_than_or_equal_to: 0)
    |> validate_number(:pvp_infamy, greater_than_or_equal_to: 0)
    |> validate_number(:pvp_vitality, greater_than_or_equal_to: 0)
  end
end
