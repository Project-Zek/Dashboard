defmodule ProjectZek.Repo.Migrations.CreateGalleries do
  use Ecto.Migration

  def change do
    create table(:galleries) do
      add :name, :string
      add :character_data_id, :"BIGINT UNSIGNED"

      timestamps(type: :utc_datetime)
    end
  end
end
