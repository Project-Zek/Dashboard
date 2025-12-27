defmodule ProjectZekWeb.AccountLive.Index do
  use ProjectZekWeb, :live_view

  require Logger

  alias ProjectZek.LoginServer
  # alias ProjectZek.LoginServer.LsAccount

  @impl true
  def render(assigns) do
    ~H"""
    <div class="bg-gray-900">
      <div class="mx-auto max-w-7xl">
        <div class="bg-gray-800 py-10">
          <div class="px-4 sm:px-6 lg:px-8">
            <div class="sm:flex sm:items-center justify-between">
              <div class="sm:flex-auto">
                <h1 class="text-base font-semibold text-white">Server Accounts</h1>
              </div>
              <div class="mt-4 sm:mt-0">
                <%= cond do %>
                  <% @has_account? -> %>
                    <span class="text-gray-400 text-sm">You already have a server account.</span>
                  <% @discord_required? and not @discord_linked? -> %>
                    <div class="flex items-center gap-3">
                      <span class="text-gray-300 text-sm">Link your Discord to create a server account.</span>
                      <a href={~p"/auth/discord"} class="rounded-lg bg-indigo-600 hover:bg-indigo-500 py-2 px-3 text-sm font-semibold text-white">Link Discord</a>
                    </div>
                  <% true -> %>
                    <.link patch={~p"/loginserver/accounts/new"} phx-click={JS.push_focus()}>
                      <.button class="bg-indigo-600 hover:bg-indigo-500">New Account</.button>
                    </.link>
                <% end %>
              </div>
            </div>
            <div class="mt-8 flow-root">
              <div class="-mx-4 -my-2 overflow-x-auto sm:-mx-6 lg:-mx-8">
                <div class="inline-block min-w-full py-2 align-middle sm:px-6 lg:px-8">
                  <table class="min-w-full divide-y divide-gray-300">
                    <thead>
                      <tr>
                        <th scope="col" class="py-3.5 pl-4 pr-3 text-left text-sm font-semibold text-white sm:pl-0">Username</th>
                        <th scope="col" class="px-3 py-3.5 text-left text-sm font-semibold text-white">Status</th>
                        <th scope="col" class="px-3 py-3.5 text-left text-sm font-semibold text-white">Last login date</th>
                        <th scope="col" class="px-3 py-3.5 text-left text-sm font-semibold text-white">Last ip address</th>
                        <th scope="col" class="px-3 py-3.5 text-left text-sm font-semibold text-white">Actions</th>
                      </tr>
                    </thead>
                    <tbody id="accounts" phx-update={match?(%Phoenix.LiveView.LiveStream{}, @streams.accounts) && "stream"} class="divide-y divide-gray-800">
                      <%= for {dom_id, account} <- @streams.accounts do %>
                        <tr id={dom_id}>
                          <td class="whitespace-nowrap py-4 pl-4 pr-3 text-sm font-medium text-white sm:pl-0"><%= account.account_name %></td>
                          <td class="whitespace-nowrap px-3 py-4 text-sm text-gray-300">
                            <%= if @banned_map[account.login_server_id] do %>
                              <span class="inline-flex items-center rounded-full bg-rose-600/20 px-2 py-0.5 text-xs font-medium text-rose-400 ring-1 ring-inset ring-rose-600/30">Banned</span>
                            <% else %>
                              <span class="inline-flex items-center rounded-full bg-emerald-600/20 px-2 py-0.5 text-xs font-medium text-emerald-400 ring-1 ring-inset ring-emerald-600/30">Active</span>
                            <% end %>
                          </td>
                          <td class="whitespace-nowrap px-3 py-4 text-sm text-gray-300"><%= account.last_login_date %></td>
                          <td class="whitespace-nowrap px-3 py-4 text-sm text-gray-300"><%= account.last_ip_address %></td>
                          <td class="whitespace-nowrap px-3 py-4 text-sm text-gray-300">
                            <div class="flex gap-3">
                              <.link patch={~p"/loginserver/accounts/#{account.login_server_id}/edit"} class="text-indigo-400 hover:underline">Change Password</.link>
                            </div>
                          </td>
                        </tr>
                      <% end %>
                    </tbody>
                  </table>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
    <div class="bg-gray-900 mt-8">
      <div class="mx-auto max-w-7xl">
        <div class="bg-gray-800 py-10">
          <div class="px-4 sm:px-6 lg:px-8">
            <div class="sm:flex sm:items-center justify-between">
              <div class="sm:flex-auto">
                <h2 class="text-base font-semibold text-white">Your Characters</h2>
              </div>
            </div>
            <div class="mt-8 flow-root">
              <div class="-mx-4 -my-2 overflow-x-auto sm:-mx-6 lg:-mx-8">
                <div class="inline-block min-w-full py-2 align-middle sm:px-6 lg:px-8">
                  <table class="min-w-full divide-y divide-gray-300">
                    <thead>
                      <tr>
                        <th class="py-3.5 pl-4 pr-3 text-left text-sm font-semibold text-white sm:pl-0">Name</th>
                        <th class="px-3 py-3.5 text-left text-sm font-semibold text-white">Race</th>
                        <th class="px-3 py-3.5 text-left text-sm font-semibold text-white">Level</th>
                        <th class="px-3 py-3.5 text-left text-sm font-semibold text-white">Kills</th>
                        <th class="px-3 py-3.5 text-left text-sm font-semibold text-white">Deaths</th>
                        <th class="px-3 py-3.5 text-left text-sm font-semibold text-white">Current Points</th>
                        <th class="px-3 py-3.5 text-left text-sm font-semibold text-white">Career Points</th>
                      </tr>
                    </thead>
                    <tbody class="divide-y divide-gray-800">
                      <%= for c <- @characters do %>
                        <tr>
                          <td class="whitespace-nowrap py-4 pl-4 pr-3 text-sm font-medium text-white sm:pl-0">
                            <.link navigate={~p"/kills?#{[player: c.name]}"} class="text-indigo-400 hover:underline">
                              <%= c.name %>
                            </.link>
                          </td>
                          <td class="whitespace-nowrap px-3 py-4 text-sm text-gray-300"><%= ProjectZek.Characters.Meta.race_name(c.race) %></td>
                          <td class="whitespace-nowrap px-3 py-4 text-sm text-gray-300"><%= c.level %></td>
                          <td class="whitespace-nowrap px-3 py-4 text-sm text-gray-300"><%= (c.pvp_stat && c.pvp_stat.pvp_kills) || 0 %></td>
                          <td class="whitespace-nowrap px-3 py-4 text-sm text-gray-300"><%= (c.pvp_stat && c.pvp_stat.pvp_deaths) || 0 %></td>
                          <td class="whitespace-nowrap px-3 py-4 text-sm text-gray-300"><%= (c.pvp_stat && c.pvp_stat.pvp_current_points) || 0 %></td>
                          <td class="whitespace-nowrap px-3 py-4 text-sm text-gray-300"><%= (c.pvp_stat && c.pvp_stat.pvp_career_points) || 0 %></td>
                        </tr>
                      <% end %>
                    </tbody>
                  </table>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
    <.modal :if={@live_action in [:new, :edit]} id="account-modal" show on_cancel={JS.patch(~p"/loginserver/accounts")}>
      <.live_component
        module={ProjectZekWeb.AccountLive.FormComponent}
          id={@account.login_server_id || :new}
          title={@page_title}
          action={@live_action}
          account={@account}
          current_user={@current_user}
          request_ip={@request_ip}
          patch={~p"/loginserver/accounts"}
        />
      </.modal>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    headers = Phoenix.LiveView.get_connect_info(socket, :x_headers) || %{}

    ip =
      cond do
        is_map(headers) ->
          headers["x-forwarded-for"] || headers["x-real-ip"]

        is_list(headers) ->
          # Could be a list of {key, val} or just header names.
          Enum.find_value(headers, fn item ->
            case item do
              {k, v} ->
                key = String.downcase(to_string(k))
                if key in ["x-forwarded-for", "x-real-ip"], do: v, else: nil

              bin when is_binary(bin) ->
                # Header names without values -> ignore
                nil

              _ -> nil
            end
          end)

        true ->
          nil
      end

    ip =
      ip
      |> case do
        nil -> nil
        v -> v |> to_string() |> String.split(",") |> List.first() |> String.trim()
      end

    # Configure stream DOM ids to use login_server_id instead of default :id
    socket = stream_configure(socket, :accounts, dom_id: &"ls-#{&1.login_server_id}")

    ls_accounts = LoginServer.list_ls_accounts_by_user(socket.assigns.current_user)
    banned_map = Map.new(ls_accounts, fn ls -> {ls.login_server_id, LoginServer.ls_account_banned?(ls)} end)
    chars = LoginServer.list_user_characters(socket.assigns.current_user)
    discord_required? = LoginServer.require_discord_for_ls?()
    discord_linked? = not is_nil(socket.assigns.current_user.discord_user_id) and socket.assigns.current_user.discord_user_id != ""

    {:ok,
     socket
     |> assign(:request_ip, ip)
     |> assign(:has_account?, length(ls_accounts) > 0)
     |> assign(:discord_required?, discord_required?)
     |> assign(:discord_linked?, discord_linked?)
     |> assign(:banned_map, banned_map)
     |> assign(:characters, chars)
     |> stream(:accounts, ls_accounts)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    ls = ProjectZek.Repo.get!(ProjectZek.LoginServer.LsAccount, String.to_integer(id))
    owned = Enum.any?(LoginServer.list_ls_accounts_by_user(socket.assigns.current_user), &(&1.login_server_id == ls.login_server_id))
    if owned do
      socket
      |> assign(:page_title, "Edit Account")
      |> assign(:account, ls)
    else
      socket
      |> put_flash(:error, "Not authorized to edit this account")
      |> push_navigate(to: ~p"/loginserver/accounts")
    end
  end

  defp apply_action(socket, :new, _params) do
    if LoginServer.require_discord_for_ls?() and (is_nil(socket.assigns.current_user.discord_user_id) or socket.assigns.current_user.discord_user_id == "") do
      socket
      |> put_flash(:error, "You must link a Discord account before creating a server account.")
      |> push_navigate(to: ~p"/users/settings")
    else
      socket
      |> assign(:page_title, "New Login Server Account")
      |> assign(:account, %ProjectZek.LoginServer.LsAccount{})
    end
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Accounts")
    |> assign(:account, nil)
  end

  @impl true
  def handle_info({ProjectZekWeb.AccountLive.FormComponent, {:saved, ls}}, socket) do
    {:noreply, stream_insert(socket, :accounts, ls)}
  end

  # Unlink removed from UI; no event handlers needed here.
end
