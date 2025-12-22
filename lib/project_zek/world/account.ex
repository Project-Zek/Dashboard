defmodule ProjectZek.World.Account do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :integer, autogenerate: false}
  schema "account" do
    field :name, :string
    field :lsaccount_id, :integer
    field :status, :integer
    field :revoked, :integer
    field :active, :integer
    field :suspendeduntil, ProjectZek.EctoTypes.ZeroNaiveDatetime
    field :ban_reason, :string
    field :suspend_reason, :string
  end

  def changeset(account, attrs) do
    account
    |> cast(attrs, [:name, :lsaccount_id])
    |> validate_required([:name])
  end
end
