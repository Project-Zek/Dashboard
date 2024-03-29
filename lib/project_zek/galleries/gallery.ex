defmodule ProjectZek.Galleries.Gallery do
  use Ecto.Schema
  import Ecto.Changeset

  schema "galleries" do
    field :name, :string
    field :character_data_id, :integer
    field :screenshot_image, :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(gallery, attrs) do
    gallery
    |> cast(attrs, [:name, :character_data_id, :screenshot_image])
    |> validate_required([:name, :character_data_id, :screenshot_image])
  end
end
