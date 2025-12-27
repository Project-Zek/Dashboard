defmodule ProjectZek.AccountsDiscordTest do
  use ProjectZek.DataCase, async: true

  alias ProjectZek.Accounts
  alias ProjectZek.Accounts.User
  import ProjectZek.AccountsFixtures

  describe "link_discord/2" do
    test "links successfully when discord_user_id is unused" do
      user = user_fixture()

      assert {:ok, %User{} = updated} =
               Accounts.link_discord(user, %{
                 discord_user_id: "1234567890",
                 discord_username: "testuser",
                 discord_avatar: "https://cdn.discordapp.com/avatars/123/avatar.png"
               })

      assert updated.discord_user_id == "1234567890"
      assert updated.discord_username == "testuser"
      assert updated.discord_avatar =~ "/avatars/123/"
      assert not is_nil(updated.discord_linked_at)
    end

    test "rejects when discord_user_id is already linked to another account" do
      user1 = user_fixture()
      user2 = user_fixture()

      {:ok, _} =
        Accounts.link_discord(user1, %{
          discord_user_id: "999",
          discord_username: "one"
        })

      assert {:error, :discord_id_taken} =
               Accounts.link_discord(user2, %{
                 discord_user_id: "999",
                 discord_username: "two"
               })
    end

    test "rejects when user already linked to a different discord id" do
      user = user_fixture()

      {:ok, _} = Accounts.link_discord(user, %{discord_user_id: "abc"})
      assert {:error, :already_linked} = Accounts.link_discord(user, %{discord_user_id: "def"})
    end
  end

  describe "unlink_discord/1" do
    test "clears discord fields" do
      user = user_fixture()
      {:ok, user} = Accounts.link_discord(user, %{discord_user_id: "123"})

      assert {:ok, %User{} = unlinked} = Accounts.unlink_discord(user)
      assert unlinked.discord_user_id == nil
      assert unlinked.discord_username == nil
      assert unlinked.discord_avatar == nil
      assert unlinked.discord_linked_at == nil
    end
  end
end

