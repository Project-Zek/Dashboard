defmodule ProjectZek.World.BannedIp do
  use Ecto.Schema
  @derive {Flop.Schema, filterable: [:ip_address, :notes], sortable: [:ip_address]}

  @primary_key {:ip_address, :string, []}
  schema "banned_ips" do
    field :notes, :string
  end
end
