defmodule ProjectZekWeb.AccountLiveTest do
  use ProjectZekWeb.ConnCase

  import Phoenix.LiveViewTest
  import ProjectZek.LoginServerFixtures

  @create_attrs %{login_server_id: 42, account_name: "some account_name", account_password: "some account_password", account_create_date: "2024-03-26T22:24:00.000000", account_email: "some account_email", last_login_date: "2024-03-26T22:24:00.000000", last_ip_address: "some last_ip_address", created_by: 42, client_unlock: 42, creation_ip: "some creation_ip", forum_name: "some forum_name", max_accts: 42, num_ip_bypass: 42, lastpass_change: 42}
  @update_attrs %{login_server_id: 43, account_name: "some updated account_name", account_password: "some updated account_password", account_create_date: "2024-03-27T22:24:00.000000", account_email: "some updated account_email", last_login_date: "2024-03-27T22:24:00.000000", last_ip_address: "some updated last_ip_address", created_by: 43, client_unlock: 43, creation_ip: "some updated creation_ip", forum_name: "some updated forum_name", max_accts: 43, num_ip_bypass: 43, lastpass_change: 43}
  @invalid_attrs %{login_server_id: nil, account_name: nil, account_password: nil, account_create_date: nil, account_email: nil, last_login_date: nil, last_ip_address: nil, created_by: nil, client_unlock: nil, creation_ip: nil, forum_name: nil, max_accts: nil, num_ip_bypass: nil, lastpass_change: nil}

  defp create_account(_) do
    account = account_fixture()
    %{account: account}
  end

  describe "Index" do
    setup [:create_account]

    test "lists all accounts", %{conn: conn, account: account} do
      {:ok, _index_live, html} = live(conn, ~p"/accounts")

      assert html =~ "Listing Accounts"
      assert html =~ account.account_name
    end

    test "saves new account", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/accounts")

      assert index_live |> element("a", "New Account") |> render_click() =~
               "New Account"

      assert_patch(index_live, ~p"/accounts/new")

      assert index_live
             |> form("#account-form", account: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#account-form", account: @create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/accounts")

      html = render(index_live)
      assert html =~ "Account created successfully"
      assert html =~ "some account_name"
    end

    test "updates account in listing", %{conn: conn, account: account} do
      {:ok, index_live, _html} = live(conn, ~p"/accounts")

      assert index_live |> element("#accounts-#{account.id} a", "Edit") |> render_click() =~
               "Edit Account"

      assert_patch(index_live, ~p"/accounts/#{account}/edit")

      assert index_live
             |> form("#account-form", account: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#account-form", account: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/accounts")

      html = render(index_live)
      assert html =~ "Account updated successfully"
      assert html =~ "some updated account_name"
    end

    test "deletes account in listing", %{conn: conn, account: account} do
      {:ok, index_live, _html} = live(conn, ~p"/accounts")

      assert index_live |> element("#accounts-#{account.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#accounts-#{account.id}")
    end
  end

  describe "Show" do
    setup [:create_account]

    test "displays account", %{conn: conn, account: account} do
      {:ok, _show_live, html} = live(conn, ~p"/accounts/#{account}")

      assert html =~ "Show Account"
      assert html =~ account.account_name
    end

    test "updates account within modal", %{conn: conn, account: account} do
      {:ok, show_live, _html} = live(conn, ~p"/accounts/#{account}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Account"

      assert_patch(show_live, ~p"/accounts/#{account}/show/edit")

      assert show_live
             |> form("#account-form", account: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#account-form", account: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/accounts/#{account}")

      html = render(show_live)
      assert html =~ "Account updated successfully"
      assert html =~ "some updated account_name"
    end
  end
end
