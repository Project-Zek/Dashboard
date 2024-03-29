defmodule ProjectZekWeb.PvpEntryLiveTest do
  use ProjectZekWeb.ConnCase

  import Phoenix.LiveViewTest
  import ProjectZek.CharactersFixtures

  @create_attrs %{timestamp: "2024-03-28T14:20:00Z", killer_id: 42, killer_level: 42, victim_id: 42, victim_level: 42, zone_id: 42, points: 42}
  @update_attrs %{timestamp: "2024-03-29T14:20:00Z", killer_id: 43, killer_level: 43, victim_id: 43, victim_level: 43, zone_id: 43, points: 43}
  @invalid_attrs %{timestamp: nil, killer_id: nil, killer_level: nil, victim_id: nil, victim_level: nil, zone_id: nil, points: nil}

  defp create_pvp_entry(_) do
    pvp_entry = pvp_entry_fixture()
    %{pvp_entry: pvp_entry}
  end

  describe "Index" do
    setup [:create_pvp_entry]

    test "lists all character_pvp_entries", %{conn: conn} do
      {:ok, _index_live, html} = live(conn, ~p"/character_pvp_entries")

      assert html =~ "Listing Character pvp entries"
    end

    test "saves new pvp_entry", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/character_pvp_entries")

      assert index_live |> element("a", "New Pvp entry") |> render_click() =~
               "New Pvp entry"

      assert_patch(index_live, ~p"/character_pvp_entries/new")

      assert index_live
             |> form("#pvp_entry-form", pvp_entry: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#pvp_entry-form", pvp_entry: @create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/character_pvp_entries")

      html = render(index_live)
      assert html =~ "Pvp entry created successfully"
    end

    test "updates pvp_entry in listing", %{conn: conn, pvp_entry: pvp_entry} do
      {:ok, index_live, _html} = live(conn, ~p"/character_pvp_entries")

      assert index_live |> element("#character_pvp_entries-#{pvp_entry.id} a", "Edit") |> render_click() =~
               "Edit Pvp entry"

      assert_patch(index_live, ~p"/character_pvp_entries/#{pvp_entry}/edit")

      assert index_live
             |> form("#pvp_entry-form", pvp_entry: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#pvp_entry-form", pvp_entry: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/character_pvp_entries")

      html = render(index_live)
      assert html =~ "Pvp entry updated successfully"
    end

    test "deletes pvp_entry in listing", %{conn: conn, pvp_entry: pvp_entry} do
      {:ok, index_live, _html} = live(conn, ~p"/character_pvp_entries")

      assert index_live |> element("#character_pvp_entries-#{pvp_entry.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#character_pvp_entries-#{pvp_entry.id}")
    end
  end

  describe "Show" do
    setup [:create_pvp_entry]

    test "displays pvp_entry", %{conn: conn, pvp_entry: pvp_entry} do
      {:ok, _show_live, html} = live(conn, ~p"/character_pvp_entries/#{pvp_entry}")

      assert html =~ "Show Pvp entry"
    end

    test "updates pvp_entry within modal", %{conn: conn, pvp_entry: pvp_entry} do
      {:ok, show_live, _html} = live(conn, ~p"/character_pvp_entries/#{pvp_entry}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Pvp entry"

      assert_patch(show_live, ~p"/character_pvp_entries/#{pvp_entry}/show/edit")

      assert show_live
             |> form("#pvp_entry-form", pvp_entry: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#pvp_entry-form", pvp_entry: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/character_pvp_entries/#{pvp_entry}")

      html = render(show_live)
      assert html =~ "Pvp entry updated successfully"
    end
  end
end
