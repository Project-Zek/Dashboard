defmodule ProjectZekWeb.AccountLive.Show do
  use ProjectZekWeb, :live_view

  alias ProjectZek.LoginServer

  @impl true
  def render(assigns) do
    ~H"""
    <.header>
      Account <%= @account.id %>
      <:subtitle>This is a account record from your database.</:subtitle>
      <:actions>
        <.link patch={~p"/loginserver/accounts/#{@account.id}/edit"} phx-click={JS.push_focus()}>
          <.button>Edit account</.button>
        </.link>
      </:actions>
    </.header>

    <.list>
      <:item title="Login server"><%= @account.login_server_id %></:item>
      <:item title="Account name"><%= @account.account_name %></:item>
      <:item title="Account password"><%= @account.account_password %></:item>
      <:item title="Account create date"><%= @account.account_create_date %></:item>
      <:item title="Account email"><%= @account.account_email %></:item>
      <:item title="Last login date"><%= @account.last_login_date %></:item>
      <:item title="Last ip address"><%= @account.last_ip_address %></:item>
      <:item title="Created by"><%= @account.created_by %></:item>
      <:item title="Client unlock"><%= @account.client_unlock %></:item>
      <:item title="Creation ip"><%= @account.creation_ip %></:item>
      <:item title="Forum name"><%= @account.forum_name %></:item>
      <:item title="Max accts"><%= @account.max_accts %></:item>
      <:item title="Num ip bypass"><%= @account.num_ip_bypass %></:item>
      <:item title="Lastpass change"><%= @account.lastpass_change %></:item>
    </.list>

    <.back navigate={~p"/loginserver/accounts"}>Back to accounts</.back>

    <.modal :if={@live_action == :edit} id="account-modal" show on_cancel={JS.patch(~p"/loginserver/accounts/#{@account.id}")}>
      <.live_component
        module={ProjectZekWeb.AccountLive.FormComponent}
        id={@account.id}
        title={@page_title}
        action={@live_action}
        account={@account}
        patch={~p"/loginserver/accounts/#{@account.id}"}
      />
    </.modal>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    account = LoginServer.get_account!(id)
    if account.user_id == socket.assigns.current_user.id or ProjectZek.LoginServer.superadmin?(socket.assigns.current_user) do
      {:noreply,
       socket
       |> assign(:page_title, page_title(socket.assigns.live_action))
       |> assign(:account, account)}
    else
      {:noreply,
       socket
       |> put_flash(:error, "Not authorized")
       |> push_navigate(to: ~p"/loginserver/accounts")}
    end
  end

  defp page_title(:show), do: "Show Account"
  defp page_title(:edit), do: "Edit Account"
end
