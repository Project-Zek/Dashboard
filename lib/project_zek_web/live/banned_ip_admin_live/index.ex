defmodule ProjectZekWeb.BannedIpAdminLive.Index do
  use ProjectZekWeb, :live_view

  import Ecto.Changeset
  import Ecto.Query
  alias ProjectZek.World.BannedIp
  alias ProjectZek.Repo
  alias Flop

  @impl true
  def mount(_params, _session, socket) do
    flop = %{order_by: [:ip_address], order_directions: [:asc], page_size: 25, page: 1}
    {:ok, fetch(socket, flop, %{"q" => nil})}
  end

  defp fetch(socket, flop, params) do
    q = Map.get(params, "q")

    base = from b in BannedIp

    base =
      case q do
        nil -> base
        "" -> base
        term -> from b in base, where: ilike(b.ip_address, ^"%#{term}%") or ilike(b.notes, ^"%#{term}%")
      end

    {:ok, {ips, meta}} = Flop.validate_and_run(base, flop, for: BannedIp)

    assign(socket,
      ips: ips,
      meta: meta,
      flop: flop,
      q: q,
      form: to_form(%{"ip_address" => "", "notes" => ""})
    )
  end

  @impl true
  def handle_event("add", %{"ip_address" => ip, "notes" => notes}, socket) do
    ip = String.trim(to_string(ip))
    changeset = cast(%BannedIp{}, %{ip_address: ip, notes: notes}, [:ip_address, :notes])
    case Repo.insert(changeset, on_conflict: :nothing) do
      {:ok, _} ->
        {:noreply, fetch(socket, socket.assigns.flop, %{"q" => socket.assigns.q})}
      {:error, cs} ->
        {:noreply, put_flash(socket, :error, "Invalid IP: #{inspect(cs.errors)}")}
    end
  end

  @impl true
  def handle_event("delete", %{"ip" => ip}, socket) do
    if rec = Repo.get(BannedIp, ip) do
      {:ok, _} = Repo.delete(rec)
    end
    {:noreply, fetch(socket, socket.assigns.flop, %{"q" => socket.assigns.q})}
  end

  @impl true
  def handle_event("search", %{"q" => q}, socket) do
    {:noreply, fetch(socket, socket.assigns.flop, %{"q" => q})}
  end

  @impl true
  def handle_event("page_prev", _params, socket) do
    page = max((socket.assigns.flop[:page] || 1) - 1, 1)
    flop = %{socket.assigns.flop | page: page}
    {:noreply, fetch(socket, flop, %{"q" => socket.assigns.q})}
  end

  @impl true
  def handle_event("page_next", _params, socket) do
    page = (socket.assigns.flop[:page] || 1) + 1
    flop = %{socket.assigns.flop | page: page}
    {:noreply, fetch(socket, flop, %{"q" => socket.assigns.q})}
  end

  @impl true
  def handle_event("set_page_size", %{"page_size" => size}, socket) do
    page_size =
      case Integer.parse(to_string(size)) do
        {i, _} when i > 0 -> i
        _ -> socket.assigns.flop[:page_size] || 25
      end

    flop = %{socket.assigns.flop | page_size: page_size, page: 1}
    {:noreply, fetch(socket, flop, %{"q" => socket.assigns.q})}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="bg-gray-900">
      <div class="mx-auto max-w-4xl">
        <div class="bg-gray-800 py-10">
          <div class="px-4 sm:px-6 lg:px-8">
            <h1 class="text-base font-semibold text-white mb-6">Banned IPs</h1>

            <form phx-change="search" class="mb-6">
              <input type="text" name="q" value={@q} placeholder="Search IP or notes..." class="mt-1 w-full rounded-lg border border-gray-600 bg-gray-700 text-white px-3 py-2" />
            </form>

            <form phx-submit="add" class="mb-6 grid grid-cols-1 md:grid-cols-3 gap-3 items-end">
              <div>
                <label class="block text-sm font-medium text-gray-200">IP Address</label>
                <input name="ip_address" type="text" placeholder="e.g. 203.0.113.42" class="mt-1 w-full rounded-lg border border-gray-600 bg-gray-700 text-white px-3 py-2" />
              </div>
              <div class="md:col-span-2">
                <label class="block text-sm font-medium text-gray-200">Notes</label>
                <input name="notes" type="text" placeholder="Reason or context" class="mt-1 w-full rounded-lg border border-gray-600 bg-gray-700 text-white px-3 py-2" />
              </div>
              <div>
                <button class="rounded-lg bg-rose-600 hover:bg-rose-500 px-3 py-2 text-sm font-semibold text-white">Add</button>
              </div>
            </form>

            <table class="min-w-full divide-y divide-gray-700">
              <thead>
                <tr>
                  <th class="text-left text-sm font-semibold text-white py-2">IP Address</th>
                  <th class="text-left text-sm font-semibold text-white py-2">Notes</th>
                  <th class="text-left text-sm font-semibold text-white py-2">Actions</th>
                </tr>
              </thead>
              <tbody class="divide-y divide-gray-800">
                <%= for ip <- @ips do %>
                  <tr>
                    <td class="text-gray-200 py-2"><%= ip.ip_address %></td>
                    <td class="text-gray-400 py-2"><%= ip.notes %></td>
                    <td class="py-2">
                      <button phx-click="delete" phx-value-ip={ip.ip_address} data-confirm="Remove this IP?" class="text-rose-400 hover:underline">Remove</button>
                    </td>
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
              <div class="flex items-center gap-3">
                <form phx-change="set_page_size">
                  <select name="page_size" class="px-2 py-1 rounded bg-gray-700 text-white">
                    <option value="10" selected={@flop.page_size == 10}>10</option>
                    <option value="25" selected={@flop.page_size in [nil, 25]}>25</option>
                    <option value="50" selected={@flop.page_size == 50}>50</option>
                    <option value="100" selected={@flop.page_size == 100}>100</option>
                  </select>
                </form>
                <% prev_disabled = (@flop.page || 1) <= 1 %>
                <% next_disabled =
                  if @meta && @meta.total_count && (@flop.page_size || 25) do
                    total_pages = div(@meta.total_count + (@flop.page_size || 25) - 1, (@flop.page_size || 25))
                    (@flop.page || 1) >= max(total_pages, 1)
                  else
                    length(@ips) < (@flop.page_size || 25)
                  end %>
                <button phx-click="page_prev" disabled={prev_disabled} class={"px-3 py-1 rounded border border-gray-600 " <> if(prev_disabled, do: "text-gray-500", else: "text-white hover:bg-gray-700")}>Prev</button>
                <button phx-click="page_next" disabled={next_disabled} class={"px-3 py-1 rounded border border-gray-600 " <> if(next_disabled, do: "text-gray-500", else: "text-white hover:bg-gray-700")}>Next</button>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
