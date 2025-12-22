   defmodule ProjectZek.Guilds do
     @moduledoc """
     The Guilds context.
     
     This module handles all operations related to guilds, including creation, retrieval,
     updating, and deletion of guild records.
     """

     import Ecto.Query, warn: false
     alias ProjectZek.Repo
     alias ProjectZek.Guilds.Guild
     alias ProjectZek.Characters.{Character, PvpStat}
     alias ProjectZek.Teams

     @doc """
     Lists all guilds.
     """
     def list_guilds do
       Guild
       |> order_by(desc: :pvp_points)
       |> Repo.all()
       |> Repo.preload(:guild_leader)
end

     @doc """
     Returns guilds and derived stats (kills, % of all, % of team), with optional filters.
     Options:
       - :q => search name (ilike)
       - :team => "evil" | "good" | "neutral" (by leader deity)
     """
     def list_guilds_with_stats(opts \\ %{}) do
       total_kills =
         from(s in PvpStat, select: coalesce(sum(s.pvp_kills), 0))
         |> Repo.one()

       team_totals = team_kill_totals()

       base = from g in Guild

       base =
         case Map.get(opts, :q) do
           nil -> base
           "" -> base
           term -> where(base, [g], ilike(g.name, ^"%#{term}%"))
         end

       base =
         case Map.get(opts, :team) do
           "evil" -> join(base, :left, [g], c in Character, on: c.id == g.leader) |> where([_g, c], c.deity in ^Teams.evil())
           "good" -> join(base, :left, [g], c in Character, on: c.id == g.leader) |> where([_g, c], c.deity in ^Teams.good())
           "neutral" -> join(base, :left, [g], c in Character, on: c.id == g.leader) |> where([_g, c], c.deity in ^Teams.neutral())
           _ -> base
         end

       guilds =
         base
         |> order_by(desc: :pvp_points)
         |> Repo.all()
         |> Repo.preload(:guild_leader)

       kills_by_guild = kills_per_guild(Enum.map(guilds, & &1.id))

       Enum.map(guilds, fn g ->
         kills = Map.get(kills_by_guild, g.id, 0)
         team_id = Teams.team_id_from_deity(g.guild_leader && g.guild_leader.deity)
         team_total = Map.get(team_totals, team_id, 0)
         %{
           guild: g,
           kills: kills,
           kills_pct_all: percent(kills, total_kills),
           kills_pct_team: percent(kills, team_total),
           team_name: Teams.team_name(team_id)
         }
       end)
     end

     defp percent(_n, 0), do: 0.0
     defp percent(n, d) when is_integer(n) and is_integer(d), do: Float.round(n * 100.0 / d, 2)
     defp percent(%Decimal{} = n, %Decimal{} = d) do
       if Decimal.equal?(d, 0) do
         0.0
       else
         n
         |> Decimal.mult(Decimal.new(100))
         |> Decimal.div(d)
         |> Decimal.to_float()
         |> Float.round(2)
       end
     end
     defp percent(n, d) do
       case {Decimal.cast(n), Decimal.cast(d)} do
         {{:ok, dn}, {:ok, dd}} -> percent(dn, dd)
         _ ->
           nf = if is_number(n), do: n * 1.0, else: 0.0
           df = if is_number(d), do: d * 1.0, else: 0.0
           if df == 0.0, do: 0.0, else: Float.round(nf * 100.0 / df, 2)
       end
     end

     defp team_kill_totals do
       evil = Teams.evil()
       good = Teams.good()
       neutral = Teams.neutral()

       from(s in PvpStat,
         join: c in Character,
         on: s.character_data_id == c.id,
         group_by:
           fragment(
             "CASE WHEN ? IN (?) THEN 1 WHEN ? IN (?) THEN 2 WHEN ? IN (?) THEN 3 ELSE 0 END",
             c.deity, ^evil, c.deity, ^good, c.deity, ^neutral
           ),
         select: {
           fragment(
             "CASE WHEN ? IN (?) THEN 1 WHEN ? IN (?) THEN 2 WHEN ? IN (?) THEN 3 ELSE 0 END",
             c.deity, ^evil, c.deity, ^good, c.deity, ^neutral
           ),
           coalesce(sum(s.pvp_kills), 0)
         }
       )
       |> Repo.all()
       |> Map.new()
     end

     defp kills_per_guild(guild_ids) when guild_ids == [], do: %{}
     defp kills_per_guild(guild_ids) do
       gm = "guild_members"

       from(g in Guild,
         where: g.id in ^guild_ids,
         left_join: m in ^gm,
         on: field(m, :guild_id) == g.id,
         left_join: c in Character,
         on: field(m, :char_id) == c.id,
         left_join: s in PvpStat,
         on: s.character_data_id == c.id,
         group_by: g.id,
         select: {g.id, coalesce(sum(s.pvp_kills), 0)}
       )
       |> Repo.all()
       |> Map.new()
     end

     @doc """
     Gets a single guild by ID.
     
     Raises `Ecto.NoResultsError` if the guild does not exist.
     """
     def get_guild!(id), do: Repo.get!(Guild, id)

     @doc """
     Creates a guild with the given attributes.
     """
     def create_guild(attrs \\ %{}) do
       %Guild{}
       |> Guild.changeset(attrs)
       |> Repo.insert()
     end

     @doc """
     Updates a guild with the given attributes.
     """
     def update_guild(%Guild{} = guild, attrs) do
       guild
       |> Guild.changeset(attrs)
       |> Repo.update()
     end

     @doc """
     Deletes a guild.
     """
     def delete_guild(%Guild{} = guild) do
       Repo.delete(guild)
     end

     @doc """
     Returns an `%Ecto.Changeset{}` for tracking guild changes.
     """
     def change_guild(%Guild{} = guild) do
       Guild.changeset(guild, %{})
     end
   end
