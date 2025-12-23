defmodule ProjectZekWeb.Router do
  use ProjectZekWeb, :router

  import ProjectZekWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {ProjectZekWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_user
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", ProjectZekWeb do
    pipe_through :browser

    live "/", HomeLive.Index, :index
    # Leaderboard (renamed from /players). Keep /players for compatibility if desired.
    live "/leaderboard", PvpStatLive.Index, :index
    live "/players", PvpStatLive.Index, :index
    live "/guilds", GuildLive.Index, :index
    live "/teams", TeamLive.Index, :index
    live "/pvp_entries", PvpEntryLive.Index, :index
    live "/kills", PvpEntryLive.Gallery, :index
    live "/guilds/:id", GuildLive.Show, :show
  end

  # Other scopes may use custom stacks.
  # scope "/api", ProjectZekWeb do
  #   pipe_through :api
  # end

  ## Authentication routes

  scope "/", ProjectZekWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    live_session :redirect_if_user_is_authenticated,
      on_mount: [{ProjectZekWeb.UserAuth, :redirect_if_user_is_authenticated}] do
      live "/users/register", UserRegistrationLive, :new
      live "/users/log_in", UserLoginLive, :new
      live "/users/reset_password", UserForgotPasswordLive, :new
      live "/users/reset_password/:token", UserResetPasswordLive, :edit
    end

    post "/users/log_in", UserSessionController, :create
  end

  scope "/", ProjectZekWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :require_authenticated_user,
      on_mount: [{ProjectZekWeb.UserAuth, :ensure_authenticated}] do
      live "/users/settings", UserSettingsLive, :edit
      live "/users/settings/confirm_email/:token", UserSettingsLive, :confirm_email

      live "/loginserver/accounts", AccountLive.Index, :index
      live "/loginserver/accounts/new", AccountLive.Index, :new
      live "/loginserver/accounts/:id", AccountLive.Show, :show
      live "/loginserver/accounts/:id/edit", AccountLive.Index, :edit

      live "/characters", CharacterLive.Index, :index
      live "/characters/:id", CharacterLive.Show, :show
      live "/pvp_entries/:id/edit", PvpEntryLive.Edit, :edit

      # Galleries removed
    end
  end

  scope "/", ProjectZekWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :superadmin_only,
      on_mount: [
        {ProjectZekWeb.UserAuth, :ensure_authenticated},
        {ProjectZekWeb.SuperadminAuth, :ensure_superadmin}
      ] do
      live "/admin/loginserver/accounts", AccountAdminLive.Index, :index
      live "/admin/banned_ips", BannedIpAdminLive.Index, :index
    end
  end

  scope "/", ProjectZekWeb do
    pipe_through [:browser]

    delete "/users/log_out", UserSessionController, :delete

    live_session :current_user,
      on_mount: [{ProjectZekWeb.UserAuth, :mount_current_user}] do
      live "/users/confirm/:token", UserConfirmationLive, :edit
      live "/users/confirm", UserConfirmationInstructionsLive, :new
    end
  end
end
