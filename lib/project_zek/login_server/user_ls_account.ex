defmodule ProjectZek.LoginServer.UserLsAccount do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  schema "user_ls_accounts" do
    belongs_to :user, ProjectZek.Accounts.User
    field :login_server_id, :integer
  end

  def changeset(mapping, attrs) do
    mapping
    |> cast(attrs, [:user_id, :login_server_id])
    |> validate_required([:user_id, :login_server_id])
    |> unique_constraint(:user_id)
    |> unique_constraint(:login_server_id)
  end
end

