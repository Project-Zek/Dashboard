defmodule ProjectZek.Uploaders.PvpScreenshot do
  use Waffle.Definition
  use Waffle.Ecto.Definition

  @versions [:original, :thumb]
  @extension_whitelist ~w(.jpg .jpeg .png)
  @max_bytes 5_000_000

  def validate({file, _}) do
    name = file.file_name || Path.basename(file.path)
    ext_ok = name |> Path.extname() |> String.downcase() |> then(&Enum.member?(@extension_whitelist, &1))
    size_ok =
      case File.stat(file.path) do
        {:ok, %File.Stat{size: size}} -> size <= @max_bytes
        _ -> false
      end

    ext_ok and size_ok
  end

  def storage_dir(_version, {_file, scope}) do
    id = Map.get(scope, :id) || "new"
    Path.join(["priv/static/uploads", "pvp_entries", to_string(id)])
  end

  def filename(:original, {_file, _scope}), do: "screenshot"
  def filename(_version, {_file, _scope}), do: "screenshot"

  # Generate a small thumbnail for gallery views
  def transform(:thumb, _), do: {:convert, "-strip -thumbnail 640x360^ -gravity center -extent 640x360", :jpg}
end
