defmodule ProjectZekWeb.UserLoginLive do
  use ProjectZekWeb, :live_view

  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-sm text-gray-200">
      <div class="text-center">
        <h1 class="text-lg font-semibold leading-8 text-white">Sign in to account</h1>
        <p class="mt-2 text-sm leading-6 text-gray-400">
          Don't have an account?
          <.link navigate={~p"/users/register"} class="font-semibold text-indigo-400 hover:underline">
            Sign up
          </.link>
          for an account now.
        </p>
      </div>

      <.form for={@form} id="login_form" action={~p"/users/log_in"} phx-update="ignore" class="mt-6">
        <div class="space-y-6 rounded-lg border border-gray-700 bg-gray-800 p-6">
          <div>
            <label for="user_email" class="block text-sm font-semibold leading-6 text-gray-200">Email</label>
            <input
              type="email"
              name="user[email]"
              id="user_email"
              required
              class="mt-2 block w-full rounded-lg border border-gray-600 bg-gray-700 text-white focus:border-indigo-400 focus:ring-0 sm:text-sm sm:leading-6"
            />
          </div>

          <div>
            <label for="user_password" class="block text-sm font-semibold leading-6 text-gray-200">Password</label>
            <input
              type="password"
              name="user[password]"
              id="user_password"
              required
              class="mt-2 block w-full rounded-lg border border-gray-600 bg-gray-700 text-white focus:border-indigo-400 focus:ring-0 sm:text-sm sm:leading-6"
            />
          </div>

          <div class="mt-2 flex items-center justify-between gap-6">
            <label class="flex items-center gap-2 text-sm leading-6 text-gray-300">
              <input type="hidden" name="user[remember_me]" value="false" />
              <input
                type="checkbox"
                id="user_remember_me"
                name="user[remember_me]"
                value="true"
                class="rounded border-gray-600 bg-gray-700 text-indigo-500 focus:ring-0"
              />
              Keep me logged in
            </label>
            <.link href={~p"/users/reset_password"} class="text-sm font-semibold text-indigo-400">
              Forgot your password?
            </.link>
          </div>

          <div>
            <button class="w-full rounded-lg bg-indigo-600 py-2 px-3 text-sm font-semibold leading-6 text-white hover:bg-indigo-500" phx-disable-with="Signing in...">
              Sign in <span aria-hidden="true">→</span>
            </button>
          </div>
        </div>
      </.form>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    email = live_flash(socket.assigns.flash, :email)
    form = to_form(%{"email" => email}, as: "user")
    {:ok, assign(socket, form: form), temporary_assigns: [form: form]}
  end
end
