defmodule ProjectZek.CharactersTest do
  use ProjectZek.DataCase

  alias ProjectZek.Characters

  describe "character_pvp_entries" do
    alias ProjectZek.Characters.PvpEntry

    import ProjectZek.CharactersFixtures

    @invalid_attrs %{timestamp: nil, killer_id: nil, killer_level: nil, victim_id: nil, victim_level: nil, zone_id: nil, points: nil}

    test "list_character_pvp_entries/0 returns all character_pvp_entries" do
      pvp_entry = pvp_entry_fixture()
      assert Characters.list_character_pvp_entries() == [pvp_entry]
    end

    test "get_pvp_entry!/1 returns the pvp_entry with given id" do
      pvp_entry = pvp_entry_fixture()
      assert Characters.get_pvp_entry!(pvp_entry.id) == pvp_entry
    end

    test "create_pvp_entry/1 with valid data creates a pvp_entry" do
      valid_attrs = %{timestamp: ~U[2024-03-28 14:20:00Z], killer_id: 42, killer_level: 42, victim_id: 42, victim_level: 42, zone_id: 42, points: 42}

      assert {:ok, %PvpEntry{} = pvp_entry} = Characters.create_pvp_entry(valid_attrs)
      assert pvp_entry.timestamp == ~U[2024-03-28 14:20:00Z]
      assert pvp_entry.killer_id == 42
      assert pvp_entry.killer_level == 42
      assert pvp_entry.victim_id == 42
      assert pvp_entry.victim_level == 42
      assert pvp_entry.zone_id == 42
      assert pvp_entry.points == 42
    end

    test "create_pvp_entry/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Characters.create_pvp_entry(@invalid_attrs)
    end

    test "update_pvp_entry/2 with valid data updates the pvp_entry" do
      pvp_entry = pvp_entry_fixture()
      update_attrs = %{timestamp: ~U[2024-03-29 14:20:00Z], killer_id: 43, killer_level: 43, victim_id: 43, victim_level: 43, zone_id: 43, points: 43}

      assert {:ok, %PvpEntry{} = pvp_entry} = Characters.update_pvp_entry(pvp_entry, update_attrs)
      assert pvp_entry.timestamp == ~U[2024-03-29 14:20:00Z]
      assert pvp_entry.killer_id == 43
      assert pvp_entry.killer_level == 43
      assert pvp_entry.victim_id == 43
      assert pvp_entry.victim_level == 43
      assert pvp_entry.zone_id == 43
      assert pvp_entry.points == 43
    end

    test "update_pvp_entry/2 with invalid data returns error changeset" do
      pvp_entry = pvp_entry_fixture()
      assert {:error, %Ecto.Changeset{}} = Characters.update_pvp_entry(pvp_entry, @invalid_attrs)
      assert pvp_entry == Characters.get_pvp_entry!(pvp_entry.id)
    end

    test "delete_pvp_entry/1 deletes the pvp_entry" do
      pvp_entry = pvp_entry_fixture()
      assert {:ok, %PvpEntry{}} = Characters.delete_pvp_entry(pvp_entry)
      assert_raise Ecto.NoResultsError, fn -> Characters.get_pvp_entry!(pvp_entry.id) end
    end

    test "change_pvp_entry/1 returns a pvp_entry changeset" do
      pvp_entry = pvp_entry_fixture()
      assert %Ecto.Changeset{} = Characters.change_pvp_entry(pvp_entry)
    end
  end
end
