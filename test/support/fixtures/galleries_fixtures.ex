defmodule ProjectZek.GalleriesFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `ProjectZek.Galleries` context.
  """

  @doc """
  Generate a gallery.
  """
  def gallery_fixture(attrs \\ %{}) do
    {:ok, gallery} =
      attrs
      |> Enum.into(%{
        character_data_id: 42,
        name: "some name"
      })
      |> ProjectZek.Galleries.create_gallery()

    gallery
  end
end
