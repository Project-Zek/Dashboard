defmodule ProjectZek.Repo.Migrations.AddScreenshotImageToGalleries do
  use Ecto.Migration

  def change do
    alter table(:galleries) do
      add(:screenshot_image, :string)
   end
  end
end
