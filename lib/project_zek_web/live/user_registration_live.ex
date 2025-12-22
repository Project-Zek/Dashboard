defmodule ProjectZekWeb.UserRegistrationLive do
  use ProjectZekWeb, :live_view

  alias ProjectZek.Accounts
  alias ProjectZek.Accounts.User

  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-sm text-gray-200">
      <div class="text-center">
        <h1 class="text-lg font-semibold leading-8 text-white">Register for an account</h1>
        <p class="mt-2 text-sm leading-6 text-gray-400">
          Already registered?
          <.link navigate={~p"/users/log_in"} class="font-semibold text-indigo-400 hover:underline">
            Sign in
          </.link>
          to your account now.
        </p>
      </div>

      <.form
        for={@form}
        id="registration_form"
        phx-submit="save"
        phx-change="validate"
        phx-trigger-action={@trigger_submit}
        action={~p"/users/log_in?_action=registered"}
        method="post"
        class="mt-6"
      >
        <div class="space-y-6 rounded-lg border border-gray-700 bg-gray-800 p-6">
          <.error :if={@check_errors}>
            Oops, something went wrong! Please check the errors below.
          </.error>

          <div>
            <label for="user_email" class="block text-sm font-semibold leading-6 text-gray-200">Email</label>
            <input
              type="email"
              name="user[email]"
              id="user_email"
              value={@form[:email].value}
              required
              class="mt-2 block w-full rounded-lg border border-gray-600 bg-gray-700 text-white focus:border-indigo-400 focus:ring-0 sm:text-sm sm:leading-6"
            />
            <.error :for={msg <- Enum.map(@form[:email].errors, &translate_error(&1))}><%= msg %></.error>
          </div>

          <div>
            <label for="user_password" class="block text-sm font-semibold leading-6 text-gray-200">Password</label>
            <input
              type="password"
              name="user[password]"
              id="user_password"
              phx-update="ignore"
              phx-debounce="blur"
              autocomplete="new-password"
              required
              class="mt-2 block w-full rounded-lg border border-gray-600 bg-gray-700 text-white focus:border-indigo-400 focus:ring-0 sm:text-sm sm:leading-6"
            />
            <.error :for={msg <- Enum.map(@form[:password].errors, &translate_error(&1))}><%= msg %></.error>
          </div>

          <div>
            <label for="user_password_confirmation" class="block text-sm font-semibold leading-6 text-gray-200">Password confirmation</label>
            <input
              type="password"
              name="user[password_confirmation]"
              id="user_password_confirmation"
              phx-update="ignore"
              phx-debounce="blur"
              autocomplete="new-password"
              required
              class="mt-2 block w-full rounded-lg border border-gray-600 bg-gray-700 text-white focus:border-indigo-400 focus:ring-0 sm:text-sm sm:leading-6"
            />
            <.error :for={msg <- Enum.map(@form[:password_confirmation].errors, &translate_error(&1))}><%= msg %></.error>
          </div>

          <div>
            <button class="w-full rounded-lg bg-indigo-600 py-2 px-3 text-sm font-semibold leading-6 text-white hover:bg-indigo-500" phx-disable-with="Creating account...">Create an account</button>
          </div>
        </div>
      </.form>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    changeset = Accounts.change_user_registration(%User{})

    socket =
      socket
      |> assign(trigger_submit: false, check_errors: false)
      |> assign_form(changeset)

    {:ok, socket, temporary_assigns: [form: nil]}
  end

  def handle_event("save", %{"user" => user_params}, socket) do
    case Accounts.register_user(user_params) do
      {:ok, user} ->
        {:ok, _} =
          Accounts.deliver_user_confirmation_instructions(
            user,
            &url(~p"/users/confirm/#{&1}")
          )

        changeset = Accounts.change_user_registration(user)
        {:noreply, socket |> assign(trigger_submit: true) |> assign_form(changeset)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, socket |> assign(check_errors: true) |> assign_form(changeset)}
    end
  end

  def handle_event("validate", %{"user" => user_params}, socket) do
    changeset = Accounts.change_user_registration(%User{}, user_params)
    {:noreply, assign_form(socket, Map.put(changeset, :action, :validate))}
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    form = to_form(changeset, as: "user")

    if changeset.valid? do
      assign(socket, form: form, check_errors: false)
    else
      assign(socket, form: form)
    end
  end
end
