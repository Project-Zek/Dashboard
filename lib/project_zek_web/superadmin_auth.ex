defmodule ProjectZekWeb.SuperadminAuth do
  import Phoenix.LiveView
  import Phoenix.Component
  use ProjectZekWeb, :verified_routes

  def on_mount(:ensure_superadmin, _params, _session, socket) do
    user = socket.assigns[:current_user]

    if user && ProjectZek.LoginServer.superadmin?(user) do
      {:cont, socket}
    else
      {:halt,
       socket
       |> put_flash(:error, "Not authorized")
       |> redirect(to: ~p"/")}
    end
  end
end

