defmodule ProjectZek.Guilds.Guild do
  use Ecto.Schema
  import Ecto.Changeset

  schema "guilds" do
    field :name, :string
    field :pvp_points, :integer, default: 0
    field :url, :string

    belongs_to :guild_leader, ProjectZek.Characters.Character, foreign_key: :leader, references: :id
  end

  @doc false
  def changeset(guild, attrs) do
    guild
    |> cast(attrs, [
      :name,
      :pvp_points,
      :url
    ])
    |> validate_required([
      :name,
      :pvp_points,
      :url
    ])
    |> validate_length(:name, max: 32)
    |> validate_length(:url, max: 512)
    |> validate_number(:pvp_points, greater_than_or_equal_to: 0)
    |> unique_constraint(:name)
  end
end