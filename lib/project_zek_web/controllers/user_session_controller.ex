defmodule ProjectZekWeb.UserSessionController do
  use ProjectZekWeb, :controller

  alias ProjectZek.Accounts
  alias ProjectZekWeb.UserAuth

  def create(conn, %{"_action" => "registered"} = params) do
    create(conn, params, "Account created successfully!")
  end

  def create(conn, %{"_action" => "password_updated"} = params) do
    conn
    |> put_session(:user_return_to, ~p"/users/settings")
    |> create(params, "Password updated successfully!")
  end

  def create(conn, params) do
    create(conn, params, "Welcome back!")
  end

  defp create(conn, %{"user" => user_params}, info) do
    %{"email" => email, "password" => password} = user_params

    # Block by banned IP first
    ip = get_forwarded_ip(conn)
    if banned_ip?(ip) do
      conn
      |> put_flash(:error, "Your IP is banned from web access.")
      |> put_flash(:email, String.slice(email, 0, 160))
      |> redirect(to: ~p"/users/log_in")
    else
      # Check credentials without dropping banned users to provide reason
      user_by_email = Accounts.get_user_by_email(email)
      if user_by_email && ProjectZek.Accounts.User.valid_password?(user_by_email, password) do
        case ProjectZek.LoginServer.ban_info_for_user(user_by_email) do
          {:ok, {:banned, reason}} ->
            msg = "Your account is banned" <> if(reason && reason != "", do: ": #{reason}", else: ".")
            conn
            |> put_flash(:error, msg)
            |> put_flash(:email, String.slice(email, 0, 160))
            |> redirect(to: ~p"/users/log_in")

          {:ok, {:suspended, until, reason}} ->
            msg = "Your account is suspended until #{until}" <> if(reason && reason != "", do: ": #{reason}", else: ".")
            conn
            |> put_flash(:error, msg)
            |> put_flash(:email, String.slice(email, 0, 160))
            |> redirect(to: ~p"/users/log_in")

          _ ->
            # Proceed with normal login flow (user not banned/suspended)
            conn
            |> put_flash(:info, info)
            |> UserAuth.log_in_user(user_by_email, user_params)
        end
      else
        # In order to prevent user enumeration attacks, don't disclose whether the email is registered.
        conn
        |> put_flash(:error, "Invalid email or password")
        |> put_flash(:email, String.slice(email, 0, 160))
        |> redirect(to: ~p"/users/log_in")
      end
    end
  end

  defp get_forwarded_ip(conn) do
    xf = List.first(get_req_header(conn, "x-forwarded-for"))
    xr = List.first(get_req_header(conn, "x-real-ip"))
    ip = xf || xr ||
      case Tuple.to_list(conn.remote_ip) do
        [_, _, _, _] = quad -> Enum.join(quad, ".")
        _ -> nil
      end

    case ip do
      nil -> nil
      v -> v |> String.split(",") |> List.first() |> String.trim()
    end
  end

  defp banned_ip?(nil), do: false
  defp banned_ip?(ip) do
    import Ecto.Query
    alias ProjectZek.World.BannedIp
    case ProjectZek.Repo.one(from b in BannedIp, where: b.ip_address == ^ip, select: 1) do
      1 -> true
      _ -> false
    end
  end

  def delete(conn, _params) do
    conn
    |> put_flash(:info, "Logged out successfully.")
    |> UserAuth.log_out_user()
  end
end
