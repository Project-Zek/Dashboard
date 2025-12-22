defmodule ProjectZek.Characters.Meta do
  @moduledoc false

  # Common playable races. Falls back to the numeric id for unknown values.
  @race_names %{
    1 => "Human",
    2 => "Barbarian",
    3 => "Erudite",
    4 => "Wood Elf",
    5 => "High Elf",
    6 => "Dark Elf",
    7 => "Half Elf",
    8 => "Dwarf",
    9 => "Troll",
    10 => "Ogre",
    11 => "Halfling",
    12 => "Gnome",
    26 => "Froglok",
    128 => "Iksar",
    130 => "Vah Shir"
  }

  @class_names %{
    1 => "Warrior",
    2 => "Cleric",
    3 => "Paladin",
    4 => "Ranger",
    5 => "Shadow Knight",
    6 => "Druid",
    7 => "Monk",
    8 => "Bard",
    9 => "Rogue",
    10 => "Shaman",
    11 => "Necromancer",
    12 => "Wizard",
    13 => "Magician",
    14 => "Enchanter",
    15 => "Beastlord"
  }

  def race_name(nil), do: "?"
  def race_name(id) when is_integer(id), do: Map.get(@race_names, id, Integer.to_string(id))
  def race_name(id) when is_binary(id) do
    case Integer.parse(id) do
      {i, _} -> race_name(i)
      _ -> id
    end
  end

  def class_name(nil), do: "?"
  def class_name(id) when is_integer(id), do: Map.get(@class_names, id, Integer.to_string(id))
  def class_name(id) when is_binary(id) do
    case Integer.parse(id) do
      {i, _} -> class_name(i)
      _ -> id
    end
  end
end

