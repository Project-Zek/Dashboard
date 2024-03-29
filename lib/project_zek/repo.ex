defmodule ProjectZek.Repo do
  use Ecto.Repo,
    otp_app: :project_zek,
    adapter: Ecto.Adapters.MyXQL
end
