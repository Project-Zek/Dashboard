defmodule ProjectZekWeb.UserSettingsLive do
  use ProjectZekWeb, :live_view

  alias ProjectZek.Accounts

  def render(assigns) do
    ~H"""
    <.header class="text-center">
      Account Settings
      <:subtitle>Manage your account email address and password settings</:subtitle>
    </.header>

    <div class="space-y-12 divide-y">
      <div>
        <.simple_form
          for={@email_form}
          id="email_form"
          phx-submit="update_email"
          phx-change="validate_email"
        >
          <.input field={@email_form[:email]} type="email" label="Email" required />
          <.input
            field={@email_form[:current_password]}
            name="current_password"
            id="current_password_for_email"
            type="password"
            label="Current password"
            value={@email_form_current_password}
            required
          />
          <:actions>
            <.button phx-disable-with="Changing...">Change Email</.button>
          </:actions>
        </.simple_form>
      </div>
      <div>
        <.simple_form
          for={@password_form}
          id="password_form"
          action={~p"/users/log_in?_action=password_updated"}
          method="post"
          phx-change="validate_password"
          phx-submit="update_password"
          phx-trigger-action={@trigger_submit}
        >
          <.input
            field={@password_form[:email]}
            type="hidden"
            id="hidden_user_email"
            value={@current_email}
          />
          <.input field={@password_form[:password]} type="password" label="New password" required />
          <.input
            field={@password_form[:password_confirmation]}
            type="password"
            label="Confirm new password"
          />
          <.input
            field={@password_form[:current_password]}
            name="current_password"
            type="password"
            label="Current password"
            id="current_password_for_password"
            value={@current_password}
            required
          />
          <:actions>
            <.button phx-disable-with="Changing...">Change Password</.button>
          </:actions>
        </.simple_form>
      </div>
      <div>
        <div class="mt-8 p-4 rounded-lg border border-indigo-700 bg-indigo-900/20">
          <h2 class="text-indigo-300 font-semibold mb-2">Discord</h2>
          <%= if @current_user.discord_user_id do %>
            <div class="flex items-center gap-3 mb-4">
              <%= if @current_user.discord_avatar do %>
                <img src={@current_user.discord_avatar} alt="Discord avatar" class="h-8 w-8 rounded-full" />
              <% end %>
              <p class="text-sm text-gray-200">
                Linked to Discord:
                <strong><%= @current_user.discord_username || @current_user.discord_user_id %></strong>
              </p>
            </div>
            <form action={~p"/auth/discord/unlink"} method="post">
              <input type="hidden" name="_csrf_token" value={Phoenix.Controller.get_csrf_token()} />
              <.button class="bg-rose-600 hover:bg-rose-500">Unlink Discord</.button>
            </form>
          <% else %>
            <p class="text-sm text-gray-300 mb-4">Link your Discord account to access Discord-gated features.</p>
            <a href={~p"/auth/discord"} class="inline-flex items-center rounded-lg bg-indigo-600 hover:bg-indigo-500 py-2 px-3 text-sm font-semibold text-white">Link Discord</a>
          <% end %>
        </div>
      </div>
      <div>
        <div class="mt-8 p-4 rounded-lg border border-rose-700 bg-rose-900/20">
          <h2 class="text-rose-400 font-semibold mb-2">Delete My Account</h2>
          <p class="text-sm text-gray-300 mb-4">This will permanently delete your web account and unlink it from your login server account. Your LS account and characters remain unaffected. This action cannot be undone.</p>
          <div>
            <button phx-click="delete_account" data-confirm="Are you sure? This cannot be undone." class="rounded-lg bg-rose-600 hover:bg-rose-500 py-2 px-3 text-sm font-semibold text-white">Delete my account</button>
          </div>
        </div>
      </div>
    </div>
    """
  end

  def mount(%{"token" => token}, _session, socket) do
    socket =
      case Accounts.update_user_email(socket.assigns.current_user, token) do
        :ok ->
          put_flash(socket, :info, "Email changed successfully.")

        :error ->
          put_flash(socket, :error, "Email change link is invalid or it has expired.")
      end

    {:ok, push_navigate(socket, to: ~p"/users/settings")}
  end

  def mount(_params, _session, socket) do
    user = socket.assigns.current_user
    email_changeset = Accounts.change_user_email(user)
    password_changeset = Accounts.change_user_password(user)

    socket =
      socket
      |> assign(:current_password, nil)
      |> assign(:email_form_current_password, nil)
      |> assign(:current_email, user.email)
      |> assign(:email_form, to_form(email_changeset))
      |> assign(:password_form, to_form(password_changeset))
      |> assign(:trigger_submit, false)

    {:ok, socket}
  end

  def handle_event("validate_email", params, socket) do
    %{"current_password" => password, "user" => user_params} = params

    email_form =
      socket.assigns.current_user
      |> Accounts.change_user_email(user_params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, email_form: email_form, email_form_current_password: password)}
  end

  def handle_event("update_email", params, socket) do
    %{"current_password" => password, "user" => user_params} = params
    user = socket.assigns.current_user

    case Accounts.apply_user_email(user, password, user_params) do
      {:ok, applied_user} ->
        Accounts.deliver_user_update_email_instructions(
          applied_user,
          user.email,
          &url(~p"/users/settings/confirm_email/#{&1}")
        )

        info = "A link to confirm your email change has been sent to the new address."
        {:noreply, socket |> put_flash(:info, info) |> assign(email_form_current_password: nil)}

      {:error, changeset} ->
        {:noreply, assign(socket, :email_form, to_form(Map.put(changeset, :action, :insert)))}
    end
  end

  def handle_event("validate_password", params, socket) do
    %{"current_password" => password, "user" => user_params} = params

    password_form =
      socket.assigns.current_user
      |> Accounts.change_user_password(user_params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, password_form: password_form, current_password: password)}
  end

  def handle_event("update_password", params, socket) do
    %{"current_password" => password, "user" => user_params} = params
    user = socket.assigns.current_user

    case Accounts.update_user_password(user, password, user_params) do
      {:ok, user} ->
        password_form =
          user
          |> Accounts.change_user_password(user_params)
          |> to_form()

        {:noreply, assign(socket, trigger_submit: true, password_form: password_form)}

      {:error, changeset} ->
        {:noreply, assign(socket, password_form: to_form(changeset))}
    end
  end

  def handle_event("delete_account", _params, socket) do
    user = socket.assigns.current_user

    # Block if any login server account is banned
    if ProjectZek.LoginServer.user_has_banned_account?(user) do
      {:noreply, put_flash(socket, :error, "Your login server account is banned. Contact a superadmin to remove it before deleting.")}
    else
      case ProjectZek.Accounts.delete_user_and_related(user) do
        {:ok, _} ->
          {:noreply,
           socket
           |> put_flash(:info, "Your account has been deleted.")
           |> Phoenix.LiveView.redirect(to: ~p"/")}

        {:error, :banned} ->
          {:noreply, put_flash(socket, :error, "Your login server account is banned. Contact a superadmin.")}

        {:error, _} ->
          {:noreply, put_flash(socket, :error, "Failed to delete your account. Please try again.")}
      end
    end
  end
end
