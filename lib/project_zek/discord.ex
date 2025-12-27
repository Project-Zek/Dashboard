defmodule ProjectZek.Discord do
  @moduledoc """
  Discord role sync utilities using the Bot API.

  Assumptions:
  - The user has already joined your Discord guild.
  - Bot has Manage Roles permission and sits above team roles.
  - Only the `identify` OAuth scope is used for linking; role changes use the bot token.
  """

  require Logger
  alias ProjectZek.LoginServer
  alias ProjectZek.Teams

  @discord_api "https://discord.com/api/v10"

  def config do
    Application.get_env(:project_zek, :discord, [])
  end

  def enabled? do
    cfg = config()
    is_binary(cfg[:bot_token]) and is_binary(cfg[:guild_id])
  end

  @doc """
  Computes the team role IDs that should be present for this user based on their characters.
  Returns a MapSet of role IDs (strings). Unknown teams are ignored.
  """
  def desired_team_role_ids_for_user(user) do
    roles =
      LoginServer.list_user_characters(user)
      |> Enum.map(&Teams.team_id_from_deity(&1.deity))
      |> Enum.uniq()
      |> Enum.flat_map(&role_ids_for_team/1)
      |> Enum.reject(&is_nil/1)

    MapSet.new(roles)
  end

  defp role_ids_for_team(1), do: [config()[:role_evil_id]]
  defp role_ids_for_team(2), do: [config()[:role_good_id]]
  defp role_ids_for_team(3), do: [config()[:role_neutral_id]]
  defp role_ids_for_team(_), do: []

  @doc """
  Syncs the user's guild roles to match the computed team roles.
  - Adds missing team roles
  - Removes extra team roles (among Evil/Good/Neutral)
  Requires bot token and guild ID.
  """
  def sync_user_roles(%{discord_user_id: nil}), do: {:error, :no_discord}
  def sync_user_roles(%{discord_user_id: ""}), do: {:error, :no_discord}
  def sync_user_roles(user) do
    unless enabled?() do
      Logger.debug("Discord role sync skipped: missing bot_token or guild_id")
      {:error, :disabled}
    else
      with {:ok, member} <- get_guild_member(user.discord_user_id),
           desired <- desired_team_role_ids_for_user(user),
           current <- MapSet.new(member["roles"] || []),
           team_role_set <- MapSet.new([config()[:role_evil_id], config()[:role_good_id], config()[:role_neutral_id]]) |> MapSet.delete(nil),
           # Only manage team roles; ignore other roles
           current_team_roles <- MapSet.intersection(current, team_role_set),
           to_add <- MapSet.difference(desired, current_team_roles),
           to_remove <- MapSet.difference(current_team_roles, desired),
           :ok <- add_roles(user.discord_user_id, to_add),
           :ok <- remove_roles(user.discord_user_id, to_remove) do
        {:ok, %{added: Enum.to_list(to_add), removed: Enum.to_list(to_remove)}}
      else
        {:error, :not_in_guild} = e -> e
        {:error, _} = e -> e
        _ -> {:error, :unknown}
      end
    end
  end

  defp add_roles(_user_id, roles) when roles in [nil, [], %MapSet{}] do
    :ok
  end
  defp add_roles(user_id, %MapSet{} = roles), do: add_roles(user_id, MapSet.to_list(roles))
  defp add_roles(user_id, roles) when is_list(roles) do
    Enum.reduce_while(roles, :ok, fn role_id, _acc ->
      case role_id do
        nil -> {:cont, :ok}
        id ->
          case put("/guilds/#{config()[:guild_id]}/members/#{user_id}/roles/#{id}") do
            {:ok, _} -> {:cont, :ok}
            {:error, reason} -> {:halt, {:error, reason}}
          end
      end
    end)
  end

  defp remove_roles(_user_id, roles) when roles in [nil, [], %MapSet{}] do
    :ok
  end
  defp remove_roles(user_id, %MapSet{} = roles), do: remove_roles(user_id, MapSet.to_list(roles))
  defp remove_roles(user_id, roles) when is_list(roles) do
    Enum.reduce_while(roles, :ok, fn role_id, _acc ->
      case role_id do
        nil -> {:cont, :ok}
        id ->
          case delete("/guilds/#{config()[:guild_id]}/members/#{user_id}/roles/#{id}") do
            {:ok, _} -> {:cont, :ok}
            {:error, reason} -> {:halt, {:error, reason}}
          end
      end
    end)
  end

  defp get_guild_member(user_id) do
    case get("/guilds/#{config()[:guild_id]}/members/#{user_id}") do
      {:ok, %{status: 200, body: body}} -> {:ok, body}
      {:ok, %{status: 404}} -> {:error, :not_in_guild}
      {:ok, resp} -> {:error, {:unexpected_status, resp.status}}
      {:error, reason} -> {:error, reason}
    end
  end

  # Minimal HTTP helpers using Finch
  defp headers do
    [
      {"Authorization", "Bot #{config()[:bot_token]}"},
      {"Content-Type", "application/json"}
    ]
  end

  defp get(path) do
    req = Finch.build(:get, @discord_api <> path, headers())
    send_req(req)
  end

  defp put(path) do
    req = Finch.build(:put, @discord_api <> path, headers())
    send_req(req)
  end

  defp delete(path) do
    req = Finch.build(:delete, @discord_api <> path, headers())
    send_req(req)
  end

  defp send_req(req) do
    case Finch.request(req, ProjectZek.Finch) do
      {:ok, %Finch.Response{status: status, body: body}} ->
        parsed = parse_json(body)
        {:ok, %{status: status, body: parsed}}
      {:error, reason} -> {:error, reason}
    end
  end

  defp parse_json(nil), do: nil
  defp parse_json("") , do: nil
  defp parse_json(body) do
    case Jason.decode(body) do
      {:ok, data} -> data
      _ -> body
    end
  end
end

