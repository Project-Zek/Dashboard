defmodule ProjectZek.Characters.PvpEntry do
  use Ecto.Schema
  import Ecto.Changeset

  schema "character_pvp_entries" do
    field :killer_id, :integer
    field :killer_name, :string
    field :killer_level, :integer
    field :victim_id, :integer
    field :victim_name, :integer
    field :victim_level, :integer
    field :zone_id, :integer
    field :points, :integer
    field :timestamp, :utc_datetime
    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(pvp_entry, attrs) do
    pvp_entry
    |> cast(attrs, [:killer_id, :killer_name, :killer_level, :victim_id, :victim_name, :victim_level, :zone_id, :points, :timestamp])
    |> validate_required([:killer_id, :killer_name, :killer_level, :victim_id, :victim_name, :victim_level, :zone_id, :points, :timestamp])
  end
end
