defmodule ProjectZekWeb.TeamLive.Index do
  use ProjectZekWeb, :live_view

  alias ProjectZek.Teams

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, teams: Teams.list_team_pvp_stats())}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="bg-gray-900">
      <div class="mx-auto max-w-7xl">
        <div class="bg-gray-800 py-10">
          <div class="px-4 sm:px-6 lg:px-8">
            <div class="sm:flex sm:items-center">
              <div class="sm:flex-auto">
                <h1 class="text-base font-semibold text-white">Teams PvP</h1>
                <p class="mt-2 text-sm text-gray-300">Aggregated by deity-based teams.</p>
              </div>
            </div>
            <div class="mt-8 flow-root">
              <div class="-mx-4 -my-2 overflow-x-auto sm:-mx-6 lg:-mx-8">
                <div class="inline-block min-w-full py-2 align-middle sm:px-6 lg:px-8">
                  <table class="min-w-full divide-y divide-gray-300">
                    <thead>
                      <tr>
                        <th scope="col" class="py-3.5 pl-4 pr-3 text-left text-sm font-semibold text-white sm:pl-0">Team</th>
                        <th scope="col" class="px-3 py-3.5 text-left text-sm font-semibold text-white">Players</th>
                        <th scope="col" class="px-3 py-3.5 text-left text-sm font-semibold text-white">Kills</th>
                        <th scope="col" class="px-3 py-3.5 text-left text-sm font-semibold text-white">Deaths</th>
                        <th scope="col" class="px-3 py-3.5 text-left text-sm font-semibold text-white">Current Pts</th>
                        <th scope="col" class="px-3 py-3.5 text-left text-sm font-semibold text-white">Career Pts</th>
                      </tr>
                    </thead>
                    <tbody class="divide-y divide-gray-800">
                      <%= for row <- @teams do %>
                        <tr>
                          <td class="whitespace-nowrap py-4 pl-4 pr-3 text-sm font-medium text-white sm:pl-0"><%= row.team_name %></td>
                          <td class="whitespace-nowrap px-3 py-4 text-sm text-gray-300"><%= row.player_count %></td>
                          <td class="whitespace-nowrap px-3 py-4 text-sm text-gray-300"><%= row.pvp_kills %></td>
                          <td class="whitespace-nowrap px-3 py-4 text-sm text-gray-300"><%= row.pvp_deaths %></td>
                          <td class="whitespace-nowrap px-3 py-4 text-sm text-gray-300"><%= row.pvp_current_points %></td>
                          <td class="whitespace-nowrap px-3 py-4 text-sm text-gray-300"><%= row.pvp_career_points %></td>
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

