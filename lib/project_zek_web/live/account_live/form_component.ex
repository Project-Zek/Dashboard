defmodule ProjectZekWeb.AccountLive.FormComponent do
  use ProjectZekWeb, :live_component

  require Logger

  alias ProjectZek.LoginServer

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
        <:subtitle>This is the credentials you will use to login with the client</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="account-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
        autocomplete="off"
      >
        <.input field={@form[:username]} type="text" label="Username" required autocomplete="username" />
        <.input
          field={@form[:password]}
          type="password"
          label="Password"
          required
          autocomplete="new-password"
          value={@password_val}
        />
        <.input
          field={@form[:password_confirmation]}
          type="password"
          label="Password confirmation"
          required
          autocomplete="new-password"
          value={@password_confirmation_val}
        />
        <:actions>
          <.button phx-disable-with="Saving...">Save Account</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{account: account} = assigns, socket) do
    changeset = LoginServer.change_account(account)

    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:password_val, fn -> if assigns[:action] == :new, do: "", else: nil end)
     |> assign_new(:password_confirmation_val, fn -> if assigns[:action] == :new, do: "", else: nil end)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"account" => account_params}, socket) do
    changeset =
      socket.assigns.account
      |> LoginServer.change_account(Map.put(account_params, "user_id", socket.assigns.current_user.id))
      |> Map.put(:action, :validate)

    password_val = Map.get(account_params, "password", socket.assigns.password_val)
    confirm_val = Map.get(account_params, "password_confirmation", socket.assigns.password_confirmation_val)

    {:noreply,
     socket
     |> assign(password_val: password_val, password_confirmation_val: confirm_val)
     |> assign_form(changeset)}
  end

  def handle_event("save", %{"account" => account_params}, socket) do
    save_account(socket, socket.assigns.action, account_params)
  end

  defp save_account(socket, :edit, account_params) do
    case LoginServer.update_account(socket.assigns.account, account_params) do
      {:ok, account} ->
        notify_parent({:saved, account})

        {:noreply,
         socket
         |> put_flash(:info, "Account updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_account(socket, :new, account_params) do
    user_id = socket.assigns.current_user.id

    account_params_with_user_id =
      account_params
      |> Map.put("user_id", user_id)
      |> Map.put_new("email", socket.assigns.current_user.email)
      |> Map.put_new("ip", socket.assigns.request_ip)

    case LoginServer.create_account(account_params_with_user_id) do
      {:ok, account} ->
        notify_parent({:saved, account})

        {:noreply,
         socket
         |> put_flash(:info, "Account created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
