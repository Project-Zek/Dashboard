defmodule ProjectZek.GalleriesTest do
  use ProjectZek.DataCase

  alias ProjectZek.Galleries

  describe "galleries" do
    alias ProjectZek.Galleries.Gallery

    import ProjectZek.GalleriesFixtures

    @invalid_attrs %{name: nil, character_data_id: nil}

    test "list_galleries/0 returns all galleries" do
      gallery = gallery_fixture()
      assert Galleries.list_galleries() == [gallery]
    end

    test "get_gallery!/1 returns the gallery with given id" do
      gallery = gallery_fixture()
      assert Galleries.get_gallery!(gallery.id) == gallery
    end

    test "create_gallery/1 with valid data creates a gallery" do
      valid_attrs = %{name: "some name", character_data_id: 42}

      assert {:ok, %Gallery{} = gallery} = Galleries.create_gallery(valid_attrs)
      assert gallery.name == "some name"
      assert gallery.character_data_id == 42
    end

    test "create_gallery/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Galleries.create_gallery(@invalid_attrs)
    end

    test "update_gallery/2 with valid data updates the gallery" do
      gallery = gallery_fixture()
      update_attrs = %{name: "some updated name", character_data_id: 43}

      assert {:ok, %Gallery{} = gallery} = Galleries.update_gallery(gallery, update_attrs)
      assert gallery.name == "some updated name"
      assert gallery.character_data_id == 43
    end

    test "update_gallery/2 with invalid data returns error changeset" do
      gallery = gallery_fixture()
      assert {:error, %Ecto.Changeset{}} = Galleries.update_gallery(gallery, @invalid_attrs)
      assert gallery == Galleries.get_gallery!(gallery.id)
    end

    test "delete_gallery/1 deletes the gallery" do
      gallery = gallery_fixture()
      assert {:ok, %Gallery{}} = Galleries.delete_gallery(gallery)
      assert_raise Ecto.NoResultsError, fn -> Galleries.get_gallery!(gallery.id) end
    end

    test "change_gallery/1 returns a gallery changeset" do
      gallery = gallery_fixture()
      assert %Ecto.Changeset{} = Galleries.change_gallery(gallery)
    end
  end
end
