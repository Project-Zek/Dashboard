defmodule ProjectZekWeb.AccountLive.FormComponent do
  use ProjectZekWeb, :live_component

  require Logger

  alias ProjectZek.LoginServer
  alias Ecto.Changeset

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
        <%= if @action == :new do %>
          <.input field={@form[:username]} type="text" label="Username" required autocomplete="username" label_class="text-gray-800" />
        <% else %>
          <div class="text-sm">
            <label class="block text-sm font-semibold leading-6 text-gray-800">Username</label>
            <div class="mt-2 text-gray-900"><%= @account.account_name %></div>
          </div>
        <% end %>
        <.input
          field={@form[:password]}
          type="password"
          label="Password"
          required
          autocomplete="new-password"
          value={@password_val}
          label_class="text-gray-800"
        />
        <.input
          field={@form[:password_confirmation]}
          type="password"
          label="Password confirmation"
          required
          autocomplete="new-password"
          value={@password_confirmation_val}
          label_class="text-gray-800"
        />
        <:actions>
          <.button phx-disable-with="Saving...">Save Account</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{account: _account} = assigns, socket) do
    changeset =
      if assigns[:action] == :new do
        new_changeset(%{})
      else
        password_changeset(%{})
      end

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
      case socket.assigns.action do
        :new -> new_changeset(account_params) |> Map.put(:action, :validate)
        :edit -> password_changeset(account_params) |> Map.put(:action, :validate)
      end

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
    case LoginServer.update_ls_password(socket.assigns.account, Map.get(account_params, "password")) do
      {:ok, _} ->
        notify_parent({:saved, socket.assigns.account})

        {:noreply,
         socket
         |> put_flash(:info, "Account updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, _reason} ->
        {:noreply, put_flash(socket, :error, "Failed to update password. Please try again.")}
    end
  end

  defp save_account(socket, :new, account_params) do
    attrs =
      account_params
      |> Map.put_new("email", socket.assigns.current_user.email)
      |> Map.put_new("ip", socket.assigns.request_ip)

    case LoginServer.create_ls_account_and_link(socket.assigns.current_user, attrs) do
      {:ok, ls} ->
        notify_parent({:saved, ls})

        {:noreply,
         socket
         |> put_flash(:info, "Account created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, :already_linked} ->
        cs =
          new_changeset(account_params)
          |> Ecto.Changeset.add_error(:username, "you already have a linked account")
          |> Map.put(:action, :validate)
        {:noreply, assign_form(socket, cs)}

      {:error, :username_taken} ->
        cs =
          new_changeset(account_params)
          |> Ecto.Changeset.add_error(:username, "is already taken")
          |> Map.put(:action, :validate)
        {:noreply, assign_form(socket, cs)}

      {:error, _reason} ->
        cs =
          new_changeset(account_params)
          |> Ecto.Changeset.add_error(:username, "failed to create account, please try again")
          |> Map.put(:action, :validate)
        {:noreply, assign_form(socket, cs)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    # Schema-less changeset requires an explicit :as to generate form names
    assign(socket, :form, to_form(changeset, as: :account))
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})

  defp new_changeset(attrs) do
    {%{}, %{username: :string, password: :string, password_confirmation: :string}}
    |> Changeset.cast(attrs, [:username, :password, :password_confirmation])
    |> Changeset.validate_required([:username, :password, :password_confirmation])
    |> Changeset.validate_length(:username, min: 3, max: 30)
    |> Changeset.validate_length(:password, min: 8, max: 50)
    |> Changeset.validate_confirmation(:password, message: "does not match password")
  end

  defp password_changeset(attrs) do
    {%{}, %{password: :string, password_confirmation: :string}}
    |> Changeset.cast(attrs, [:password, :password_confirmation])
    |> Changeset.validate_required([:password, :password_confirmation])
    |> Changeset.validate_length(:password, min: 8, max: 50)
    |> Changeset.validate_confirmation(:password, message: "does not match password")
  end
end
