defmodule ProjectZekWeb.PvpStatLive.Index do
  use ProjectZekWeb, :live_view

  import Ecto.Query
  alias Flop
  # alias ProjectZek.Repo
  alias ProjectZek.Characters.{PvpStat, Character}

  @evil [201, 203, 211, 206]
  @good [215, 204, 208, 210, 212]
  @neutral [216, 207, 214, 209, 213, 205, 202]

  @impl true
  def mount(_params, _session, socket) do
    flop = %{
      order_by: [:pvp_career_points],
      order_directions: [:desc],
      page_size: 25,
      page: 1
    }

    {:ok, fetch(socket, flop, %{"q" => nil, "team" => nil})}
  end

  @impl true
  def handle_params(params, _url, socket) do
    flop =
      %{
        order_by: parse_list(params["order_by"], [:pvp_career_points]),
        order_directions: parse_list(params["order_directions"], [:desc]),
        page_size: parse_int(params["page_size"], 25),
        page: parse_int(params["page"], 1)
      }

    {:noreply, fetch(socket, flop, params)}
  end

  defp parse_list(nil, default), do: default
  defp parse_list(val, _default) when is_list(val), do: Enum.map(val, &String.to_existing_atom/1)
  defp parse_list(val, _default) when is_binary(val), do: [String.to_existing_atom(val)]

  defp parse_int(nil, default), do: default
  defp parse_int(val, default) do
    case Integer.parse(to_string(val)) do
      {i, _} -> i
      _ -> default
    end
  end

  defp fetch(socket, flop, params) do
    q = Map.get(params, "q")
    team = Map.get(params, "team")

    base =
      from s in PvpStat,
        join: c in Character,
        on: s.character_data_id == c.id,
        preload: [character_data: c]

    base =
      case q do
        nil -> base
        "" -> base
        term -> where(base, [s, c], like(c.name, ^"%#{term}%"))
      end

    base =
      case team do
        "evil" -> where(base, [s, c], c.deity in ^@evil)
        "good" -> where(base, [s, c], c.deity in ^@good)
        "neutral" -> where(base, [s, c], c.deity in ^@neutral)
        _ -> base
      end

    {:ok, {stats, meta}} = Flop.validate_and_run(base, flop, for: PvpStat)

    assign(socket,
      pvp_stats: stats,
      meta: meta,
      flop: flop,
      q: q,
      team: team
    )
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
    {:noreply, fetch(socket, flop, %{"q" => socket.assigns.q, "team" => socket.assigns.team})}
  end

  @impl true
  def handle_event("search", %{"q" => q}, socket) do
    {:noreply, fetch(socket, socket.assigns.flop, %{"q" => q, "team" => socket.assigns.team})}
  end

  @impl true
  def handle_event("filter_team", %{"team" => team}, socket) do
    {:noreply, fetch(socket, socket.assigns.flop, %{"q" => socket.assigns.q, "team" => team})}
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
                <h1 class="text-base font-semibold text-white">Leaderboard</h1>
                <p class="mt-1 text-sm text-gray-300">Only characters with PvP activity appear here.</p>
              </div>
              <div class="flex gap-3">
                <form phx-change="search">
                  <input type="text" name="q" value={@q} placeholder="Search name..." class="px-2 py-1 rounded bg-gray-700 text-white" />
                </form>
                <form phx-change="filter_team">
                  <select name="team" class="px-2 py-1 rounded bg-gray-700 text-white">
                    <option value="" selected={@team in [nil, ""]}>All Teams</option>
                    <option value="evil" selected={@team == "evil"}>Evil</option>
                    <option value="good" selected={@team == "good"}>Good</option>
                    <option value="neutral" selected={@team == "neutral"}>Neutral</option>
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
                        <th scope="col" class="py-3.5 pl-4 pr-3 text-left text-sm font-semibold text-white sm:pl-0">Name</th>
                        <th scope="col" class="px-3 py-3.5 text-left text-sm font-semibold text-white"><a href="#" phx-click="sort" phx-value-field="pvp_kills">Kills</a></th>
                        <th scope="col" class="px-3 py-3.5 text-left text-sm font-semibold text-white"><a href="#" phx-click="sort" phx-value-field="pvp_deaths">Deaths</a></th>
                        <th scope="col" class="px-3 py-3.5 text-left text-sm font-semibold text-white"><a href="#" phx-click="sort" phx-value-field="pvp_current_points">Current Points</a></th>
                        <th scope="col" class="px-3 py-3.5 text-left text-sm font-semibold text-white"><a href="#" phx-click="sort" phx-value-field="pvp_career_points">Career Points</a></th>
                      </tr>
                    </thead>
                    <tbody class="divide-y divide-gray-800">
                      <%= for stat <- @pvp_stats do %>
                        <tr>
                          <td class="whitespace-nowrap py-4 pl-4 pr-3 text-sm font-medium text-white sm:pl-0">
                            <.link navigate={~p"/kills?#{[player: stat.character_data && stat.character_data.name]}"} class="text-indigo-400 hover:underline">
                              <%= stat.character_data && stat.character_data.name %>
                            </.link>
                          </td>
                          <td class="whitespace-nowrap px-3 py-4 text-sm text-gray-300"><%= stat.pvp_kills %></td>
                          <td class="whitespace-nowrap px-3 py-4 text-sm text-gray-300"><%= stat.pvp_deaths %></td>
                          <td class="whitespace-nowrap px-3 py-4 text-sm text-gray-300"><%= stat.pvp_current_points %></td>
                          <td class="whitespace-nowrap px-3 py-4 text-sm text-gray-300"><%= stat.pvp_career_points %></td>
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
    """
  end
end
