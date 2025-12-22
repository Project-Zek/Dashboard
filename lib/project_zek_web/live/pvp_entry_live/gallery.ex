defmodule ProjectZekWeb.PvpEntryLive.Gallery do
  use ProjectZekWeb, :live_view

  import Ecto.Query
  alias ProjectZek.{Repo}
  alias ProjectZek.Characters.{PvpEntry, Character}
  alias ProjectZek.Guilds.Guild
  alias ProjectZek.Uploaders.PvpScreenshot

  @evil [201, 203, 211, 206]
  @good [215, 204, 208, 210, 212]
  @neutral [216, 207, 214, 209, 213, 205, 202]

  @impl true
  def mount(params, _session, socket) do
    sort_by = parse_sort(Map.get(params, "sort", "latest"))
    filters = %{
      player: Map.get(params, "player"),
      victim: Map.get(params, "victim"),
      from: Map.get(params, "from"),
      to: Map.get(params, "to"),
      guild_id: Map.get(params, "guild_id"),
      team: Map.get(params, "team")
    }
    entries = list_entries(sort_by, filters)
    guilds = Repo.all(from g in Guild, order_by: g.name, select: {g.name, g.id})
    {:ok, assign(socket, entries: entries, sort_by: sort_by, guilds: guilds) |> assign(filters)}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    sort_by = parse_sort(Map.get(params, "sort", "latest"))
    filters = %{
      player: Map.get(params, "player"),
      victim: Map.get(params, "victim"),
      from: Map.get(params, "from"),
      to: Map.get(params, "to"),
      guild_id: Map.get(params, "guild_id"),
      team: Map.get(params, "team")
    }
    {:noreply, socket |> assign(filters) |> assign(entries: list_entries(sort_by, filters), sort_by: sort_by)}
  end

  defp parse_sort("latest"), do: :latest
  defp parse_sort("team"), do: :team
  defp parse_sort("player"), do: :player
  defp parse_sort(_), do: :latest

  defp list_entries(:latest, filters) do
    base_query(filters)
    |> order_by([e, _c], desc: e.timestamp)
    |> Repo.all()
    |> decorate()
  end

  defp list_entries(:player, filters) do
    base_query(filters)
    |> order_by([e, _c], asc: e.killer_name)
    |> Repo.all()
    |> decorate()
  end

  defp list_entries(:team, filters) do
    base_query(filters)
    |> order_by([_e, c], asc: fragment("CASE WHEN ? IN (?) THEN 1 WHEN ? IN (?) THEN 2 WHEN ? IN (?) THEN 3 ELSE 0 END", c.deity, ^@evil, c.deity, ^@good, c.deity, ^@neutral))
    |> Repo.all()
    |> decorate()
  end

  defp base_query(filters \\ %{}) do
    q =
      from e in PvpEntry,
        join: c in Character,
        on: c.id == e.killer_id,
        where: not is_nil(e.screenshot),
        select: {e, c}

    q =
      case Map.get(filters, :player) do
        nil -> q
        "" -> q
        name -> where(q, [e, _c], like(e.killer_name, ^"%#{name}%"))
      end

    q =
      case Map.get(filters, :victim) do
        nil -> q
        "" -> q
        name -> where(q, [e, _c], like(e.victim_name, ^"%#{name}%"))
      end

    q =
      case Map.get(filters, :team) do
        "evil" -> where(q, [_e, c], c.deity in ^@evil)
        "good" -> where(q, [_e, c], c.deity in ^@good)
        "neutral" -> where(q, [_e, c], c.deity in ^@neutral)
        _ -> q
      end

    q =
      case parse_guild_id(Map.get(filters, :guild_id)) do
        nil -> q
        gid -> where(q, [e, _c], fragment("EXISTS (SELECT 1 FROM guild_members gm WHERE gm.guild_id = ? AND gm.char_id = ?)", ^gid, e.killer_id))
      end

    with_from = parse_date(Map.get(filters, :from), ~T[00:00:00])
    with_to = parse_date(Map.get(filters, :to), ~T[23:59:59])

    q =
      case with_from do
        nil -> q
        from_ts -> where(q, [e, _c], e.timestamp >= ^from_ts)
      end

    q =
      case with_to do
        nil -> q
        to_ts -> where(q, [e, _c], e.timestamp <= ^to_ts)
      end

    q
  end

  defp parse_guild_id(nil), do: nil
  defp parse_guild_id(""), do: nil
  defp parse_guild_id(val) when is_binary(val) do
    case Integer.parse(val) do
      {i, _} -> i
      _ -> nil
    end
  end
  defp parse_guild_id(i) when is_integer(i), do: i

  defp parse_date(nil, _time), do: nil
  defp parse_date("", _time), do: nil
  defp parse_date(iso_date, time) when is_binary(iso_date) do
    case Date.from_iso8601(iso_date) do
      {:ok, date} ->
        case NaiveDateTime.new(date, time) do
          {:ok, ndt} ->
            case DateTime.from_naive(ndt, "Etc/UTC") do
              {:ok, dt} -> DateTime.to_unix(dt)
              _ -> nil
            end
          _ -> nil
        end
      _ -> nil
    end
  end

  defp decorate(rows) do
    Enum.map(rows, fn {e, c} ->
      %{
        id: e.id,
        killer_name: e.killer_name,
        victim_name: e.victim_name,
        timestamp: e.timestamp,
        timestamp_fmt: format_ts(e.timestamp),
        screenshot_url: PvpScreenshot.url({e.screenshot, e}, :thumb),
        team_name: team_name(c.deity)
      }
    end)
  end

  defp team_name(deity) when deity in @evil, do: "Evil"
  defp team_name(deity) when deity in @good, do: "Good"
  defp team_name(deity) when deity in @neutral, do: "Neutral"
  defp team_name(_), do: "Unknown"

  @impl true
  def render(assigns) do
    ~H"""
    <div class="bg-gray-900 min-h-screen">
      <div class="mx-auto max-w-7xl py-8 px-4">
        <div class="mb-2">
          <h1 class="text-white text-lg font-semibold">PvP Gallery</h1>
        </div>
        <div class="mb-6 flex flex-wrap items-center gap-2 text-sm">
          <form phx-change="sort_change">
            <select name="sort" class="px-2 py-1 rounded bg-gray-700 text-white">
              <option value="latest" selected={@sort_by == :latest}>Sort: Latest</option>
              <option value="player" selected={@sort_by == :player}>Sort: Player</option>
            </select>
          </form>
          <form phx-change="filter_team">
            <select name="team" class="px-2 py-1 rounded bg-gray-700 text-white">
              <option value="" selected={@team in [nil, ""]}>Team: All</option>
              <option value="evil" selected={@team == "evil"}>Team: Evil</option>
              <option value="good" selected={@team == "good"}>Team: Good</option>
              <option value="neutral" selected={@team == "neutral"}>Team: Neutral</option>
            </select>
          </form>
          <form phx-change="filter_guild">
            <select name="guild_id" class="px-2 py-1 rounded bg-gray-700 text-white">
              <option value="" selected={@guild_id in [nil, ""]}>Guild: All</option>
              <%= for {name, id} <- @guilds do %>
                <option value={id} selected={to_string(id) == to_string(@guild_id)}><%= name %></option>
              <% end %>
            </select>
          </form>
          <form phx-change="search_player">
            <input type="text" name="player" value={@player} placeholder="Player..." class="px-2 py-1 rounded bg-gray-700 text-white" />
          </form>
          <form phx-change="search_victim">
            <input type="text" name="victim" value={@victim} placeholder="Victim..." class="px-2 py-1 rounded bg-gray-700 text-white" />
          </form>
          <form phx-change="filter_date" class="flex items-center gap-2">
            <input type="date" name="from" value={@from} class="px-2 py-1 rounded bg-gray-700 text-white" />
            <span class="text-gray-400">to</span>
            <input type="date" name="to" value={@to} class="px-2 py-1 rounded bg-gray-700 text-white" />
          </form>
          <.link patch={~p"/kills?#{[sort: Atom.to_string(@sort_by)]}"} class="rounded bg-gray-700 px-2 py-1 text-white hover:bg-gray-600">
            Clear filters
          </.link>
        </div>

        <div class="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-6">
          <%= for item <- @entries do %>
            <div class="bg-gray-800 rounded shadow overflow-hidden">
              <img src={item.screenshot_url} alt="PvP screenshot" class="w-full h-40 object-cover" />
              <div class="p-3 text-sm text-gray-200">
                <div class="flex justify-between">
                  <span class="font-medium"><%= item.killer_name %></span>
                  <span class="text-xs text-gray-400"><%= item.team_name %></span>
                </div>
                <div class="text-gray-300">killed <%= item.victim_name %></div>
                <div class="text-xs text-gray-400"><%= item.timestamp_fmt %></div>
              </div>
            </div>
          <% end %>
        </div>
      </div>
    </div>
    """
  end

  defp format_ts(nil), do: ""
  defp format_ts(ts) when is_integer(ts) do
    case DateTime.from_unix(ts) do
      {:ok, dt} -> Calendar.strftime(dt, "%Y-%m-%d %H:%M UTC")
      _ -> to_string(ts)
    end
  end

  defp format_ts(%NaiveDateTime{} = ndt) do
    case DateTime.from_naive(ndt, "Etc/UTC") do
      {:ok, dt} -> Calendar.strftime(dt, "%Y-%m-%d %H:%M UTC")
      _ -> to_string(ndt)
    end
  end

  defp format_ts(%DateTime{} = dt), do: Calendar.strftime(dt, "%Y-%m-%d %H:%M UTC")

  @impl true
  def handle_event("search_player", %{"player" => player}, socket) do
    {:noreply, push_patch(socket, to: ~p"/kills?#{[sort: Atom.to_string(socket.assigns.sort_by), player: player, victim: socket.assigns.victim, from: socket.assigns.from, to: socket.assigns.to, guild_id: socket.assigns.guild_id, team: socket.assigns.team]}")}
  end

  @impl true
  def handle_event("search_victim", %{"victim" => victim}, socket) do
    {:noreply, push_patch(socket, to: ~p"/kills?#{[sort: Atom.to_string(socket.assigns.sort_by), player: socket.assigns.player, victim: victim, from: socket.assigns.from, to: socket.assigns.to, guild_id: socket.assigns.guild_id, team: socket.assigns.team]}")}
  end

  @impl true
  def handle_event("filter_date", %{"from" => from, "to" => to}, socket) do
    {:noreply, push_patch(socket, to: ~p"/kills?#{[sort: Atom.to_string(socket.assigns.sort_by), player: socket.assigns.player, victim: socket.assigns.victim, from: from, to: to, guild_id: socket.assigns.guild_id, team: socket.assigns.team]}")}
  end

  @impl true
  def handle_event("filter_guild", %{"guild_id" => gid}, socket) do
    gid = if gid in [nil, ""], do: nil, else: gid
    {:noreply,
     push_patch(socket,
       to:
         ~p"/kills?#{[
           sort: Atom.to_string(socket.assigns.sort_by),
           player: socket.assigns.player,
           victim: socket.assigns.victim,
           from: socket.assigns.from,
           to: socket.assigns.to,
           guild_id: gid,
           team: socket.assigns.team
          ]}"
     )}
  end

  @impl true
  def handle_event("filter_team", %{"team" => team}, socket) do
    team = if team in [nil, ""], do: nil, else: team
    {:noreply,
     push_patch(socket,
       to:
         ~p"/kills?#{[
           sort: Atom.to_string(socket.assigns.sort_by),
           player: socket.assigns.player,
           victim: socket.assigns.victim,
           from: socket.assigns.from,
           to: socket.assigns.to,
           guild_id: socket.assigns.guild_id,
           team: team
         ]}"
     )}
  end

  @impl true
  def handle_event("sort_change", %{"sort" => sort}, socket) do
    sort = sort in ["latest", "player"] && sort || "latest"
    {:noreply,
     push_patch(socket,
       to:
         ~p"/kills?#{[
           sort: sort,
           player: socket.assigns.player,
           victim: socket.assigns.victim,
           from: socket.assigns.from,
           to: socket.assigns.to,
           guild_id: socket.assigns.guild_id,
           team: socket.assigns.team
         ]}"
     )}
  end
end
