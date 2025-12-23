defmodule ProjectZekWeb.AccountLive.Show do
  use ProjectZekWeb, :live_view

  alias ProjectZek.LoginServer
  alias ProjectZek.LoginServer.LsAccount

  @impl true
  def render(assigns) do
    ~H"""
    <.header>
      Account <%= @account.login_server_id %>
      <:subtitle>Login server account details.</:subtitle>
      <:actions>
        <.link patch={~p"/loginserver/accounts/#{@account.login_server_id}/edit"} phx-click={JS.push_focus()}>
          <.button>Edit account</.button>
        </.link>
      </:actions>
    </.header>

    <.list>
      <:item title="Account name"><%= @account.account_name %></:item>
      <:item title="Account email"><%= @account.account_email %></:item>
      <:item title="Last login date"><%= @account.last_login_date %></:item>
      <:item title="Last ip address"><%= @account.last_ip_address %></:item>
      <:item title="Creation IP"><%= @account.creation_ip %></:item>
      <:item title="Forum name"><%= @account.forum_name %></:item>
      <:item title="Client unlock"><%= @account.client_unlock %></:item>
      <:item title="Created by"><%= @account.created_by %></:item>
      <:item title="Max accts"><%= @account.max_accts %></:item>
    </.list>

    <.back navigate={~p"/loginserver/accounts"}>Back to accounts</.back>

    <.modal :if={@live_action == :edit} id="account-modal" show on_cancel={JS.patch(~p"/loginserver/accounts/#{@account.login_server_id}")}>
      <.live_component
        module={ProjectZekWeb.AccountLive.FormComponent}
        id={@account.login_server_id}
        title={@page_title}
        action={@live_action}
        account={@account}
        patch={~p"/loginserver/accounts/#{@account.login_server_id}"}
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
    ls = ProjectZek.Repo.get!(LsAccount, String.to_integer(id))
    owned = Enum.any?(LoginServer.list_ls_accounts_by_user(socket.assigns.current_user), &(&1.login_server_id == ls.login_server_id))
    if owned or ProjectZek.LoginServer.superadmin?(socket.assigns.current_user) do
      {:noreply,
       socket
       |> assign(:page_title, page_title(socket.assigns.live_action))
       |> assign(:account, ls)}
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
