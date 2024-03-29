defmodule ProjectZek.CharactersFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `ProjectZek.Characters` context.
  """

  @doc """
  Generate a pvp_entry.
  """
  def pvp_entry_fixture(attrs \\ %{}) do
    {:ok, pvp_entry} =
      attrs
      |> Enum.into(%{
        killer_id: 42,
        killer_level: 42,
        points: 42,
        timestamp: ~U[2024-03-28 14:20:00Z],
        victim_id: 42,
        victim_level: 42,
        zone_id: 42
      })
      |> ProjectZek.Characters.create_pvp_entry()

    pvp_entry
  end
end
