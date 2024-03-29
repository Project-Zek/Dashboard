defmodule ProjectZek.LoginServerTest do
  use ProjectZek.DataCase

  alias ProjectZek.LoginServer

  describe "accounts" do
    alias ProjectZek.LoginServer.Account

    import ProjectZek.LoginServerFixtures

    @invalid_attrs %{login_server_id: nil, account_name: nil, account_password: nil, account_create_date: nil, account_email: nil, last_login_date: nil, last_ip_address: nil, created_by: nil, client_unlock: nil, creation_ip: nil, forum_name: nil, max_accts: nil, num_ip_bypass: nil, lastpass_change: nil}

    test "list_accounts/0 returns all accounts" do
      account = account_fixture()
      assert LoginServer.list_accounts() == [account]
    end

    test "get_account!/1 returns the account with given id" do
      account = account_fixture()
      assert LoginServer.get_account!(account.id) == account
    end

    test "create_account/1 with valid data creates a account" do
      valid_attrs = %{login_server_id: 42, account_name: "some account_name", account_password: "some account_password", account_create_date: ~N[2024-03-26 22:24:00.000000], account_email: "some account_email", last_login_date: ~N[2024-03-26 22:24:00.000000], last_ip_address: "some last_ip_address", created_by: 42, client_unlock: 42, creation_ip: "some creation_ip", forum_name: "some forum_name", max_accts: 42, num_ip_bypass: 42, lastpass_change: 42}

      assert {:ok, %Account{} = account} = LoginServer.create_account(valid_attrs)
      assert account.login_server_id == 42
      assert account.account_name == "some account_name"
      assert account.account_password == "some account_password"
      assert account.account_create_date == ~N[2024-03-26 22:24:00.000000]
      assert account.account_email == "some account_email"
      assert account.last_login_date == ~N[2024-03-26 22:24:00.000000]
      assert account.last_ip_address == "some last_ip_address"
      assert account.created_by == 42
      assert account.client_unlock == 42
      assert account.creation_ip == "some creation_ip"
      assert account.forum_name == "some forum_name"
      assert account.max_accts == 42
      assert account.num_ip_bypass == 42
      assert account.lastpass_change == 42
    end

    test "create_account/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = LoginServer.create_account(@invalid_attrs)
    end

    test "update_account/2 with valid data updates the account" do
      account = account_fixture()
      update_attrs = %{login_server_id: 43, account_name: "some updated account_name", account_password: "some updated account_password", account_create_date: ~N[2024-03-27 22:24:00.000000], account_email: "some updated account_email", last_login_date: ~N[2024-03-27 22:24:00.000000], last_ip_address: "some updated last_ip_address", created_by: 43, client_unlock: 43, creation_ip: "some updated creation_ip", forum_name: "some updated forum_name", max_accts: 43, num_ip_bypass: 43, lastpass_change: 43}

      assert {:ok, %Account{} = account} = LoginServer.update_account(account, update_attrs)
      assert account.login_server_id == 43
      assert account.account_name == "some updated account_name"
      assert account.account_password == "some updated account_password"
      assert account.account_create_date == ~N[2024-03-27 22:24:00.000000]
      assert account.account_email == "some updated account_email"
      assert account.last_login_date == ~N[2024-03-27 22:24:00.000000]
      assert account.last_ip_address == "some updated last_ip_address"
      assert account.created_by == 43
      assert account.client_unlock == 43
      assert account.creation_ip == "some updated creation_ip"
      assert account.forum_name == "some updated forum_name"
      assert account.max_accts == 43
      assert account.num_ip_bypass == 43
      assert account.lastpass_change == 43
    end

    test "update_account/2 with invalid data returns error changeset" do
      account = account_fixture()
      assert {:error, %Ecto.Changeset{}} = LoginServer.update_account(account, @invalid_attrs)
      assert account == LoginServer.get_account!(account.id)
    end

    test "delete_account/1 deletes the account" do
      account = account_fixture()
      assert {:ok, %Account{}} = LoginServer.delete_account(account)
      assert_raise Ecto.NoResultsError, fn -> LoginServer.get_account!(account.id) end
    end

    test "change_account/1 returns a account changeset" do
      account = account_fixture()
      assert %Ecto.Changeset{} = LoginServer.change_account(account)
    end
  end
end
