defmodule ProjectZek.Teams do
  @moduledoc """
  Aggregates PvP statistics by deity-based teams (Evil/Good/Neutral).

  Team mapping (by `character_data.deity`):
  - 1: Evil -> 201,203,211,206
  - 2: Good -> 215,204,208,210,212
  - 3: Neutral -> 216,207,214,209,213,205,202
  - 0: Unknown (others)
  """

  import Ecto.Query, warn: false
  alias ProjectZek.Repo
  alias ProjectZek.Characters.{PvpStat, Character}

  @evil [201, 203, 211, 206]
  @good [215, 204, 208, 210, 212]
  @neutral [216, 207, 214, 209, 213, 205, 202]

  @spec list_team_pvp_stats() :: [map()]
  def list_team_pvp_stats do
    query =
      from s in PvpStat,
        join: c in Character,
        as: :c,
        on: s.character_data_id == c.id,
        where: c.is_deleted == 0 and c.deity != 0,
        group_by:
          fragment(
            "CASE WHEN ? IN (?) THEN 1 WHEN ? IN (?) THEN 2 WHEN ? IN (?) THEN 3 ELSE 0 END",
            c.deity,
            ^@evil,
            c.deity,
            ^@good,
            c.deity,
            ^@neutral
          ),
        select: %{
          team_id:
            fragment(
              "CASE WHEN ? IN (?) THEN 1 WHEN ? IN (?) THEN 2 WHEN ? IN (?) THEN 3 ELSE 0 END",
              c.deity,
              ^@evil,
              c.deity,
              ^@good,
              c.deity,
              ^@neutral
            ),
          player_count: count(s.id),
          pvp_kills: coalesce(sum(s.pvp_kills), 0),
          pvp_deaths: coalesce(sum(s.pvp_deaths), 0),
          pvp_current_points: coalesce(sum(s.pvp_current_points), 0),
          pvp_career_points: coalesce(sum(s.pvp_career_points), 0)
        }

    Repo.all(query)
    |> Enum.map(&add_team_name/1)
    |> Enum.sort_by(& &1.pvp_career_points, :desc)
  end

  defp add_team_name(%{team_id: id} = row) do
    Map.put(row, :team_name, team_name(id))
  end

  def team_name(1), do: "Evil"
  def team_name(2), do: "Good"
  def team_name(3), do: "Neutral"
  def team_name(_), do: "Unknown"

  def evil, do: @evil
  def good, do: @good
  def neutral, do: @neutral

  def team_id_from_deity(nil), do: 0
  def team_id_from_deity(deity) when deity in @evil, do: 1
  def team_id_from_deity(deity) when deity in @good, do: 2
  def team_id_from_deity(deity) when deity in @neutral, do: 3
  def team_id_from_deity(_), do: 0

  # public wrapper already defined above
end
