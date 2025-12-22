defmodule ProjectZekWeb.HomeLive.Index do
  use ProjectZekWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="bg-gray-900 text-white">
      <div class="w-full">
        <div
          class="w-full h-32 sm:h-40 md:h-48 lg:h-56 bg-center bg-cover bg-no-repeat"
          style={"background-image: url('#{~p"/images/project_zek_banner.png"}');"}
        >
        </div>
      </div>
      <div class="p-6">
      <h1 class="text-3xl font-bold mb-4">Welcome to Project Zek!</h1>
      <p class="mb-6">
        Project Zek is an emulated EverQuest server inspired by the intense and thrilling PvP experiences of the original Sullon Zek server. Our goal is to recreate the competitive spirit of EverQuest's unique PvP environment while adding modern quality-of-life features, gameplay tracking, and competitive systems.
      </p>

      <h2 class="text-2xl font-semibold mb-2">Server Highlights:</h2>
      <ul class="list-disc list-inside mb-6">
        <li>Sullon Zek Rule Set: This is a team-based PvP server with three factions: Good, Neutral, and Evil.</li>
        <li>No PvP Level Restrictions: Engage in combat with anyone, regardless of level.</li>
        <li>No Grief Play Restrictions: Play how you want, but remember, the challenge is real.</li>
        <li>Points-Based PvP System: Earn points for defeating players from opposing factions and spend them on rewards.</li>
      </ul>

      <h2 class="text-2xl font-semibold mb-2">PvP Rules:</h2>
      <ul class="list-disc list-inside mb-6">
        <li>Factions Matter: Choose your faction wisely. Your allies are your strength, and your enemies are everywhere.</li>
        <li>No Safe Zones: The entire world is your battleground. Always be prepared.</li>
        <li>Corpse Looting: PvP kills allow limited looting of coin, but equipment stays safe.</li>
        <li>No PvP Penalties for Dying: While you’ll lose points if you die, you won’t lose experience.</li>
        <li>Point Scaling: Points earned depend on your opponent’s level and recent PvP activity. Targeting active, high-value players is rewarding.</li>
      </ul>

      <h2 class="text-2xl font-semibold mb-2">PvP Point System:</h2>
      <ul class="list-disc list-inside mb-6">
        <li>Earn Points: Gain PvP points for defeating players from opposing factions. Bonus points are awarded for killing high-ranking players or those with high PvP streaks.</li>
        <li>Lose Points: Lose a fraction of your points when you are defeated in PvP.</li>
        <li>Spend points: Use points to trigger quakes to spawn mobs or purchase summon corpse points.</li>
        <li>Leaderboard: Compete for glory by climbing the server-wide PvP leaderboard.</li>
      </ul>

      <h2 class="text-2xl font-semibold mb-2">Additional Features:</h2>
      <ul class="list-disc list-inside">
        <li>Dynamic Events: Participate in faction-based PvP events to earn massive rewards.</li>
        <li>Faction Balancing: Automated systems to ensure no single faction dominates the server.</li>
        <li>Guild Support: Form guilds to coordinate with faction members and dominate the battlefield.</li>
      </ul>
      </div>
    </div>
    """
  end
end
