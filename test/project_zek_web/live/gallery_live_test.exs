defmodule ProjectZekWeb.GalleryLiveTest do
  use ProjectZekWeb.ConnCase

  import Phoenix.LiveViewTest
  import ProjectZek.GalleriesFixtures

  @create_attrs %{name: "some name", character_data_id: 42}
  @update_attrs %{name: "some updated name", character_data_id: 43}
  @invalid_attrs %{name: nil, character_data_id: nil}

  defp create_gallery(_) do
    gallery = gallery_fixture()
    %{gallery: gallery}
  end

  describe "Index" do
    setup [:create_gallery]

    test "lists all galleries", %{conn: conn, gallery: gallery} do
      {:ok, _index_live, html} = live(conn, ~p"/galleries")

      assert html =~ "Listing Galleries"
      assert html =~ gallery.name
    end

    test "saves new gallery", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/galleries")

      assert index_live |> element("a", "New Gallery") |> render_click() =~
               "New Gallery"

      assert_patch(index_live, ~p"/galleries/new")

      assert index_live
             |> form("#gallery-form", gallery: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#gallery-form", gallery: @create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/galleries")

      html = render(index_live)
      assert html =~ "Gallery created successfully"
      assert html =~ "some name"
    end

    test "updates gallery in listing", %{conn: conn, gallery: gallery} do
      {:ok, index_live, _html} = live(conn, ~p"/galleries")

      assert index_live |> element("#galleries-#{gallery.id} a", "Edit") |> render_click() =~
               "Edit Gallery"

      assert_patch(index_live, ~p"/galleries/#{gallery}/edit")

      assert index_live
             |> form("#gallery-form", gallery: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#gallery-form", gallery: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/galleries")

      html = render(index_live)
      assert html =~ "Gallery updated successfully"
      assert html =~ "some updated name"
    end

    test "deletes gallery in listing", %{conn: conn, gallery: gallery} do
      {:ok, index_live, _html} = live(conn, ~p"/galleries")

      assert index_live |> element("#galleries-#{gallery.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#galleries-#{gallery.id}")
    end
  end

  describe "Show" do
    setup [:create_gallery]

    test "displays gallery", %{conn: conn, gallery: gallery} do
      {:ok, _show_live, html} = live(conn, ~p"/galleries/#{gallery}")

      assert html =~ "Show Gallery"
      assert html =~ gallery.name
    end

    test "updates gallery within modal", %{conn: conn, gallery: gallery} do
      {:ok, show_live, _html} = live(conn, ~p"/galleries/#{gallery}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Gallery"

      assert_patch(show_live, ~p"/galleries/#{gallery}/show/edit")

      assert show_live
             |> form("#gallery-form", gallery: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#gallery-form", gallery: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/galleries/#{gallery}")

      html = render(show_live)
      assert html =~ "Gallery updated successfully"
      assert html =~ "some updated name"
    end
  end
end
