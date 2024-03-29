defmodule ProjectZek.LoginServerFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `ProjectZek.LoginServer` context.
  """

  @doc """
  Generate a account.
  """
  def account_fixture(attrs \\ %{}) do
    {:ok, account} =
      attrs
      |> Enum.into(%{
        account_create_date: ~N[2024-03-26 22:24:00.000000],
        account_email: "some account_email",
        account_name: "some account_name",
        account_password: "some account_password",
        client_unlock: 42,
        created_by: 42,
        creation_ip: "some creation_ip",
        forum_name: "some forum_name",
        last_ip_address: "some last_ip_address",
        last_login_date: ~N[2024-03-26 22:24:00.000000],
        lastpass_change: 42,
        login_server_id: 42,
        max_accts: 42,
        num_ip_bypass: 42
      })
      |> ProjectZek.LoginServer.create_account()

    account
  end
end
