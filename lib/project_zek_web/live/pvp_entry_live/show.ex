defmodule ProjectZekWeb.PvpEntryLive.Show do
  use ProjectZekWeb, :live_view

  alias ProjectZek.Characters

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:pvp_entry, Characters.get_pvp_entry!(id))}
  end

  defp page_title(:show), do: "Show Pvp entry"
  defp page_title(:edit), do: "Edit Pvp entry"
end
