defmodule ProjectZekWeb.GuildLive.Index do
  use ProjectZekWeb, :live_view

  alias ProjectZek.Guilds

  @impl true
  def mount(_params, _session, socket) do
    {:ok, fetch(socket, %{"q" => nil, "team" => nil})}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, fetch(socket, params)}
  end

  defp fetch(socket, params) do
    records =
      Guilds.list_guilds_with_stats(%{
        q: Map.get(params, "q"),
        team: Map.get(params, "team")
      })

    assign(socket,
      records: records,
      q: Map.get(params, "q"),
      team: Map.get(params, "team")
    )
  end

  @impl true
  def handle_event("search", %{"q" => q}, socket) do
    {:noreply, fetch(socket, %{"q" => q, "team" => socket.assigns.team})}
  end

  @impl true
  def handle_event("filter_team", %{"team" => team}, socket) do
    {:noreply, fetch(socket, %{"q" => socket.assigns.q, "team" => team})}
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
                <h1 class="text-base font-semibold text-white">Guilds</h1>
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
                        <th scope="col" class="px-3 py-3.5 text-left text-sm font-semibold text-white">Leader</th>
                        <th scope="col" class="px-3 py-3.5 text-left text-sm font-semibold text-white">Team</th>
                        <th scope="col" class="px-3 py-3.5 text-left text-sm font-semibold text-white">Kills</th>
                        <th scope="col" class="px-3 py-3.5 text-left text-sm font-semibold text-white">% of All</th>
                        <th scope="col" class="px-3 py-3.5 text-left text-sm font-semibold text-white">% of Team</th>
                      </tr>
                    </thead>
                    <tbody class="divide-y divide-gray-800">
                      <%= for row <- @records do %>
                        <tr>
                          <td class="whitespace-nowrap py-4 pl-4 pr-3 text-sm font-medium text-white sm:pl-0">
                            <.link navigate={~p"/kills?#{[guild_id: row.guild.id, sort: "latest"]}"} class="text-indigo-400 hover:underline">
                              <%= row.guild.name %>
                            </.link>
                          </td>
                          <td class="whitespace-nowrap px-3 py-4 text-sm text-gray-300"><%= row.guild.guild_leader && row.guild.guild_leader.name %></td>
                          <td class="whitespace-nowrap px-3 py-4 text-sm text-gray-300"><%= row.team_name %></td>
                          <td class="whitespace-nowrap px-3 py-4 text-sm text-gray-300"><%= row.kills %></td>
                          <td class="whitespace-nowrap px-3 py-4 text-sm text-gray-300"><%= row.kills_pct_all %>%</td>
                          <td class="whitespace-nowrap px-3 py-4 text-sm text-gray-300"><%= row.kills_pct_team %>%</td>
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
