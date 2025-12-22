defmodule ProjectZekWeb.AccountAdminLive.Index do
  use ProjectZekWeb, :live_view

  alias ProjectZek.LoginServer
  alias Flop

  @impl true
  def mount(_params, _session, socket) do
    user = socket.assigns.current_user
    if LoginServer.superadmin?(user) do
      flop = %{order_by: [:inserted_at], order_directions: [:desc], page_size: 25, page: 1}
      {:ok, fetch(socket, flop, %{"q" => nil, "status" => nil})}
    else
      {:ok,
       socket
       |> put_flash(:error, "Not authorized")
       |> redirect(to: ~p"/")}
    end
  end

  @impl true
  def handle_event("sort", %{"field" => field}, socket) do
    field = String.to_existing_atom(field)
    {order_by, order_directions} =
      case socket.assigns.flop.order_by do
        [^field] ->
          case socket.assigns.flop.order_directions do
            [:asc] -> {[field], [:desc]}
            _ -> {[field], [:asc]}
          end
        _ -> {[field], [:asc]}
      end

    flop = %{socket.assigns.flop | order_by: order_by, order_directions: order_directions}
    {:noreply, fetch(socket, flop, %{"q" => socket.assigns.q, "status" => socket.assigns.status})}
  end

  @impl true
  def handle_event("search", %{"q" => q}, socket) do
    {:noreply, fetch(socket, socket.assigns.flop, %{"q" => q, "status" => socket.assigns.status})}
  end

  @impl true
  def handle_event("filter_status", %{"status" => status}, socket) do
    {:noreply, fetch(socket, socket.assigns.flop, %{"q" => socket.assigns.q, "status" => status})}
  end

  @impl true
  def handle_event("page_prev", _params, socket) do
    page = max((socket.assigns.flop[:page] || 1) - 1, 1)
    flop = %{socket.assigns.flop | page: page}
    {:noreply, fetch(socket, flop, %{"q" => socket.assigns.q, "status" => socket.assigns.status})}
  end

  @impl true
  def handle_event("page_next", _params, socket) do
    page = (socket.assigns.flop[:page] || 1) + 1
    flop = %{socket.assigns.flop | page: page}
    {:noreply, fetch(socket, flop, %{"q" => socket.assigns.q, "status" => socket.assigns.status})}
  end

  @impl true
  def handle_event("set_page_size", %{"page_size" => size}, socket) do
    page_size =
      case Integer.parse(to_string(size)) do
        {i, _} when i > 0 -> i
        _ -> socket.assigns.flop[:page_size] || 25
      end

    flop = %{socket.assigns.flop | page_size: page_size, page: 1}
    {:noreply, fetch(socket, flop, %{"q" => socket.assigns.q, "status" => socket.assigns.status})}
  end

  defp fetch(socket, flop, params) do
    {:ok, {accounts, meta}} = LoginServer.list_accounts_admin(flop, params)
    banned_map = Map.new(accounts, fn a -> {a.id, LoginServer.account_banned?(a)} end)
    ban_info = Map.new(accounts, fn a -> {a.id, LoginServer.ban_info(a)} end)

    assign(socket,
      accounts: accounts,
      banned_map: banned_map,
      ban_info: ban_info,
      meta: meta,
      flop: flop,
      q: Map.get(params, "q"),
      status: Map.get(params, "status")
    )
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="bg-gray-900">
      <div class="mx-auto max-w-7xl">
        <div class="bg-gray-800 py-10">
          <div class="px-4 sm:px-6 lg:px-8">
            <div class="sm:flex sm:items-center justify-between">
              <div class="sm:flex-auto">
                <h1 class="text-base font-semibold text-white">All Login Server Accounts</h1>
              </div>
              <div class="flex gap-3">
                <form phx-change="search">
                  <input type="text" name="q" value={@q} placeholder="Search username or email..." class="px-2 py-1 rounded bg-gray-700 text-white" />
                </form>
                <form phx-change="filter_status">
                  <select name="status" class="px-2 py-1 rounded bg-gray-700 text-white">
                    <option value="" selected={@status in [nil, ""]}>All</option>
                    <option value="active" selected={@status == "active"}>Active</option>
                    <option value="banned" selected={@status == "banned"}>Banned</option>
                    <option value="suspended" selected={@status == "suspended"}>Suspended</option>
                  </select>
                </form>
                <form phx-change="set_page_size">
                  <select name="page_size" class="px-2 py-1 rounded bg-gray-700 text-white">
                    <option value="10" selected={@flop.page_size == 10}>10</option>
                    <option value="25" selected={@flop.page_size in [nil, 25]}>25</option>
                    <option value="50" selected={@flop.page_size == 50}>50</option>
                    <option value="100" selected={@flop.page_size == 100}>100</option>
                  </select>
                </form>
              </div>
            </div>
            <div class="mt-8 flow-root">
              <div class="-mx-4 -my-2 overflow-x-auto sm:-mx-6 lg:-mx-8">
                <div class="inline-block min-w-full py-2 align-middle sm:px-6 lg:px-8">
                  <table class="min-w-full divide-y divide-gray-300">
                    <thead>
                      <tr>
                        <th class="py-3.5 pl-4 pr-3 text-left text-sm font-semibold text-white sm:pl-0"><a href="#" phx-click="sort" phx-value-field="username">Username</a></th>
                        <th class="px-3 py-3.5 text-left text-sm font-semibold text-white">Owner</th>
                        <th class="px-3 py-3.5 text-left text-sm font-semibold text-white">Status</th>
                        <th class="px-3 py-3.5 text-left text-sm font-semibold text-white">Reason</th>
                        <th class="px-3 py-3.5 text-left text-sm font-semibold text-white"><a href="#" phx-click="sort" phx-value-field="last_login_at">Last login</a></th>
                        <th class="px-3 py-3.5 text-left text-sm font-semibold text-white">Last IP</th>
                        <th class="px-3 py-3.5 text-left text-sm font-semibold text-white"><a href="#" phx-click="sort" phx-value-field="inserted_at">Created</a></th>
                      </tr>
                    </thead>
                    <tbody class="divide-y divide-gray-800">
                      <%= for account <- @accounts do %>
                        <tr>
                          <td class="whitespace-nowrap py-4 pl-4 pr-3 text-sm font-medium text-white sm:pl-0"><%= account.username %></td>
                          <td class="whitespace-nowrap px-3 py-4 text-sm text-gray-300"><%= account.user && account.user.email %></td>
                          <td class="whitespace-nowrap px-3 py-4 text-sm text-gray-300">
                            <%= if @banned_map[account.id] do %>
                              <span class="inline-flex items-center rounded-full bg-rose-600/20 px-2 py-0.5 text-xs font-medium text-rose-400 ring-1 ring-inset ring-rose-600/30">Banned</span>
                            <% else %>
                              <span class="inline-flex items-center rounded-full bg-emerald-600/20 px-2 py-0.5 text-xs font-medium text-emerald-400 ring-1 ring-inset ring-emerald-600/30">Active</span>
                            <% end %>
                          </td>
                          <td class="whitespace-nowrap px-3 py-4 text-sm text-gray-300">
                            <%= case @ban_info[account.id] do %>
                              <% {:ok, {:banned, reason}} -> %>
                                <%= reason || "(no reason provided)" %>
                              <% {:ok, {:suspended, until, reason}} -> %>
                                Suspended until <%= until %><%= if reason, do: ": #{reason}" %>
                              <% _ -> %>
                                —
                            <% end %>
                          </td>
                          <td class="whitespace-nowrap px-3 py-4 text-sm text-gray-300"><%= account.last_login_at %></td>
                          <td class="whitespace-nowrap px-3 py-4 text-sm text-gray-300"><%= account.last_login_ip %></td>
                          <td class="whitespace-nowrap px-3 py-4 text-sm text-gray-300"><%= account.inserted_at %></td>
                        </tr>
                      <% end %>
                    </tbody>
                  </table>
                  <div class="mt-4 flex items-center justify-between text-sm text-gray-300">
                    <div>
                      <% page = @flop.page || 1 %>
                      <% page_size = @flop.page_size || 25 %>
                      <% total_pages = if @meta && @meta.total_count && page_size, do: div(@meta.total_count + page_size - 1, page_size), else: nil %>
                      <span>
                        Page <%= page %><%= if total_pages, do: " of #{total_pages}" %>
                      </span>
                    </div>
                    <div class="flex gap-2">
                      <% prev_disabled = (@flop.page || 1) <= 1 %>
                      <% next_disabled =
                        if @meta && @meta.total_count && (@flop.page_size || 25) do
                          total_pages = div(@meta.total_count + (@flop.page_size || 25) - 1, (@flop.page_size || 25))
                          (@flop.page || 1) >= max(total_pages, 1)
                        else
                          length(@accounts) < (@flop.page_size || 25)
                        end %>
                      <button phx-click="page_prev" disabled={prev_disabled} class={"px-3 py-1 rounded border border-gray-600 " <> if(prev_disabled, do: "text-gray-500", else: "text-white hover:bg-gray-700")}>Prev</button>
                      <button phx-click="page_next" disabled={next_disabled} class={"px-3 py-1 rounded border border-gray-600 " <> if(next_disabled, do: "text-gray-500", else: "text-white hover:bg-gray-700")}>Next</button>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
