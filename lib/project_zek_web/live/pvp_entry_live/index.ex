defmodule ProjectZekWeb.PvpEntryLive.Index do
  use ProjectZekWeb, :live_view

  alias ProjectZek.Characters
  alias ProjectZek.Characters.PvpEntry

  @impl true
  def mount(_params, _session, socket) do
    {:ok, stream(socket, :character_pvp_entries, Characters.list_character_pvp_entries())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Pvp entry")
    |> assign(:pvp_entry, Characters.get_pvp_entry!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Pvp entry")
    |> assign(:pvp_entry, %PvpEntry{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Character pvp entries")
    |> assign(:pvp_entry, nil)
  end

  @impl true
  def handle_info({ProjectZekWeb.PvpEntryLive.FormComponent, {:saved, pvp_entry}}, socket) do
    {:noreply, stream_insert(socket, :character_pvp_entries, pvp_entry)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    pvp_entry = Characters.get_pvp_entry!(id)
    {:ok, _} = Characters.delete_pvp_entry(pvp_entry)

    {:noreply, stream_delete(socket, :character_pvp_entries, pvp_entry)}
  end
end
