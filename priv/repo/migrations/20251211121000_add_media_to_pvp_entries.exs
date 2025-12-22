defmodule ProjectZek.Repo.Migrations.AddMediaToPvpEntries do
  use Ecto.Migration

  def change do
    alter table(:character_pvp_entries) do
      add :screenshot, :string
      add :video_url, :string
    end
  end
end

