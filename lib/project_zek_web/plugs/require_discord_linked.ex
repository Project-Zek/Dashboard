defmodule ProjectZekWeb.RequireDiscordLinked do
  import Plug.Conn
  import Phoenix.Controller
  use ProjectZekWeb, :verified_routes

  def init(opts), do: opts

  def call(conn, _opts) do
    case conn.assigns[:current_user] do
      %{discord_user_id: id} when not is_nil(id) and id != "" ->
        conn

      _ ->
        conn
        |> put_flash(:error, "You must link a Discord account before using this feature.")
        |> redirect(to: ~p"/users/settings")
        |> halt()
    end
  end
end

