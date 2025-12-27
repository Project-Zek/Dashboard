defmodule ProjectZekWeb.AuthController do
  use ProjectZekWeb, :controller

  alias ProjectZek.Accounts

  # GET /auth/discord
  # Ueberauth handles the redirect; we just keep a placeholder.
  def request(conn, _params) do
    # If this function runs, just inform the user.
    conn
    |> put_flash(:info, "Redirecting to Discord for authentication...")
    |> redirect(to: ~p"/users/settings")
  end

  # GET /auth/discord/callback
  def callback(%{assigns: %{ueberauth_auth: auth, current_user: current_user}} = conn, _params) do
    discord_user_id = to_string(auth.uid)
    discord_username = auth.info[:name] || auth.info[:nickname]
    discord_avatar = auth.info[:image]

    case Accounts.link_discord(current_user, %{
           discord_user_id: discord_user_id,
           discord_username: discord_username,
           discord_avatar: discord_avatar
         }) do
      {:ok, _user} ->
        # Try to sync Discord roles (best-effort)
        _ = Task.start(fn ->
          try do
            ProjectZek.Discord.sync_user_roles(Accounts.get_user!(current_user.id))
          rescue
            _ -> :ok
          end
        end)

        conn
        |> put_flash(:info, "Discord account linked successfully.")
        |> redirect(to: ~p"/users/settings")

      {:error, %Ecto.Changeset{} = changeset} ->
        error = changeset_error_message(changeset)
        conn
        |> put_flash(:error, error || "Could not link Discord account.")
        |> redirect(to: ~p"/users/settings")

      {:error, :discord_id_taken} ->
        conn
        |> put_flash(:error, "That Discord account is already linked to another user.")
        |> redirect(to: ~p"/users/settings")

      {:error, :already_linked} ->
        conn
        |> put_flash(:error, "Your account is already linked to a different Discord user.")
        |> redirect(to: ~p"/users/settings")

      {:error, :invalid_discord_user_id} ->
        conn
        |> put_flash(:error, "Invalid Discord user information received.")
        |> redirect(to: ~p"/users/settings")
    end
  end

  def callback(%{assigns: %{ueberauth_failure: failure}} = conn, _params) do
    reason = failure.reason && failure.reason.message
    conn
    |> put_flash(:error, reason || "Discord authentication failed.")
    |> redirect(to: ~p"/users/settings")
  end

  # POST /auth/discord/unlink
  def unlink(%{assigns: %{current_user: current_user}} = conn, _params) do
    case Accounts.unlink_discord(current_user) do
      {:ok, _user} ->
        conn
        |> put_flash(:info, "Discord account unlinked.")
        |> redirect(to: ~p"/users/settings")

      {:error, _} ->
        conn
        |> put_flash(:error, "Could not unlink Discord account.")
        |> redirect(to: ~p"/users/settings")
    end
  end

  defp changeset_error_message(%Ecto.Changeset{errors: errors}) when is_list(errors) do
    errors
    |> Keyword.get(:discord_user_id)
    |> case do
      {msg, _opts} -> to_string(msg)
      _ -> nil
    end
  end

  defp changeset_error_message(_), do: nil
end
