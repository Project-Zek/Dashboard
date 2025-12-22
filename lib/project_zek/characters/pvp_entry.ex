defmodule ProjectZek.Characters.PvpEntry do
  use Ecto.Schema
  import Ecto.Changeset
  use Waffle.Ecto.Schema
  alias ProjectZek.Uploaders.PvpScreenshot

  schema "character_pvp_entries" do
    field :killer_id, :integer
    field :killer_name, :string
    field :killer_level, :integer
    field :victim_id, :integer
    field :victim_name, :string
    field :victim_level, :integer
    field :points, :integer
    field :timestamp, :integer

    field :screenshot, PvpScreenshot.Type
    field :video_url, :string
  end

  @doc false
  def changeset(pvp_entry, attrs) do
    pvp_entry
    |> cast(attrs, [:killer_id, :killer_name, :killer_level, :victim_id, :victim_name, :victim_level, :points, :timestamp, :video_url])
    |> cast_attachments(attrs, [:screenshot])
    |> validate_required([:killer_id, :killer_name, :killer_level, :victim_id, :victim_name, :victim_level, :points, :timestamp])
    |> validate_change(:video_url, &validate_youtube_url/2)
  end

  defp validate_youtube_url(:video_url, nil), do: []
  defp validate_youtube_url(:video_url, ""), do: []
  defp validate_youtube_url(:video_url, url) when is_binary(url) do
    case URI.parse(url) do
      %URI{scheme: scheme, host: host} when scheme in ["http", "https"] and host in ["youtube.com", "www.youtube.com", "youtu.be"] ->
        []
      _ ->
        [video_url: "must be a YouTube URL"]
    end
  end
end
