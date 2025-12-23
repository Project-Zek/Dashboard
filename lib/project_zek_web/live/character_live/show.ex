defmodule ProjectZekWeb.CharacterLive.Show do
  use ProjectZekWeb, :live_view

  alias ProjectZek.{Repo, LoginServer}
  alias ProjectZek.Characters.Character
  alias ProjectZek.World.Account, as: WorldAccount

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    character = Repo.get!(Character, id)

    # Authorize: character.account_id must belong to one of user's world accounts
    if authorized?(socket.assigns.current_user, character.account_id) do
      character = Repo.preload(character, [:kills, :deaths])
      {:ok, assign(socket, :character, character)}
    else
      {:ok,
       socket
       |> put_flash(:error, "Not authorized")
       |> push_navigate(to: ~p"/")}
    end
  end

  defp authorized?(nil, _account_id), do: false
  defp authorized?(user, account_id) do
    usernames = LoginServer.list_ls_accounts_by_user(%ProjectZek.Accounts.User{id: user.id}) |> Enum.map(& &1.account_name)
    import Ecto.Query
    world_ids =
      from(a in WorldAccount, where: a.name in ^usernames, select: a.id)
      |> Repo.all()

    account_id in world_ids
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="bg-gray-900 min-h-screen">
      <div class="mx-auto max-w-3xl py-8 px-4">
        <h1 class="text-white text-xl font-semibold"><%= @character.name %></h1>
        <p class="text-gray-300">Kills: <%= length(@character.kills) %> · Deaths: <%= length(@character.deaths) %></p>
      </div>
    </div>
    """
  end
end
