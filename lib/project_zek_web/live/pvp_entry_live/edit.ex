defmodule ProjectZekWeb.PvpEntryLive.Edit do
  use ProjectZekWeb, :live_view

  alias ProjectZek.{Repo, LoginServer}
  alias ProjectZek.Characters
  alias ProjectZek.Characters.{PvpEntry, Character}
  alias ProjectZek.Uploaders.PvpScreenshot
  alias ProjectZek.World.Account, as: WorldAccount

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    entry = Characters.get_pvp_entry!(id)

    changeset = PvpEntry.changeset(entry, %{})

    socket =
      socket
      |> assign(:entry, entry)
      |> assign(:form, to_form(changeset))
      |> assign(:authorized?, authorized?(socket.assigns.current_user, entry))
      |> assign(:can_upload_screenshot, is_nil(entry.screenshot))
      |> then(fn s ->
        if s.assigns.can_upload_screenshot do
          allow_upload(s, :screenshot,
            accept: ~w(.jpg .jpeg .png),
            max_entries: 1,
            max_file_size: 5_000_000,
            auto_upload: false
          )
        else
          s
        end
      end)

    {:ok, socket}
  end

  defp authorized?(nil, _entry), do: false
  defp authorized?(user, %PvpEntry{killer_id: killer_char_id}) do
    with %Character{account_id: acct_id} <- Repo.get(Character, killer_char_id),
         usernames when is_list(usernames) <- user_login_usernames(user.id),
         true <- usernames != [],
         world_ids when is_list(world_ids) <- world_account_ids_for_usernames(usernames),
         true <- acct_id in world_ids do
      true
    else
      _ -> false
    end
  end

  defp user_login_usernames(user_id) do
    LoginServer.list_accounts_by_user_id(user_id)
    |> Enum.map(& &1.username)
  end

  defp world_account_ids_for_usernames(usernames) do
    import Ecto.Query
    from(a in WorldAccount, where: a.name in ^usernames, select: a.id)
    |> Repo.all()
  end

  @impl true
  def handle_event("validate", %{"pvp_entry" => params}, socket) do
    changeset =
      socket.assigns.entry
      |> PvpEntry.changeset(params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :form, to_form(changeset))}
  end

  @impl true
  def handle_event("save", %{"pvp_entry" => params}, %{assigns: %{authorized?: true}} = socket) do
    uploaded =
      if socket.assigns.can_upload_screenshot do
        consume_uploaded_entries(socket, :screenshot, fn %{path: path}, _entry ->
          case PvpScreenshot.store({path, socket.assigns.entry}) do
            {:ok, file} -> {:ok, file}
            {:error, _} = err -> err
          end
        end)
      else
        []
      end

    screenshot_params =
      cond do
        socket.assigns.can_upload_screenshot and match?([{:ok, _}], uploaded) ->
          [{:ok, file}] = uploaded
          Map.put(params, "screenshot", file)

        true ->
          # Ensure screenshot cannot be modified once present
          Map.delete(params, "screenshot")
      end

    case Characters.update_pvp_entry(socket.assigns.entry, screenshot_params) do
      {:ok, entry} ->
        {:noreply,
         socket
         |> put_flash(:info, "Updated entry")
         |> assign(:entry, entry)
         |> assign(:can_upload_screenshot, is_nil(entry.screenshot))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  def handle_event("save", _params, socket) do
    {:noreply, put_flash(socket, :error, "Not authorized to update this entry")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="bg-gray-900">
      <div class="mx-auto max-w-3xl">
        <div class="bg-gray-800 py-8 px-6 rounded-lg">
          <h2 class="text-white text-lg font-semibold">Edit PvP Entry <%= @entry.id %></h2>
          <p class="text-gray-400 text-sm mb-6">Upload a screenshot or link a YouTube video.</p>

          <%= if @authorized? do %>
            <.simple_form for={@form} id="pvp-entry-form" phx-change="validate" phx-submit="save">
              <.input field={@form[:video_url]} type="text" label="YouTube URL" placeholder="https://youtu.be/..."/>

              <%= if @can_upload_screenshot do %>
                <div class="mt-4">
                  <label class="block text-sm font-medium leading-6 text-white">Screenshot (PNG or JPG)</label>
                  <.live_file_input upload={@uploads.screenshot} class="mt-2 text-white" />
                  <div class="mt-2 text-xs text-gray-400">
                    Max 1 file. Accepted: .png, .jpg, .jpeg
                  </div>
                </div>
              <% else %>
                <div class="mt-4 text-sm text-gray-300">
                  Screenshot already uploaded for this kill. Uploading another is not allowed.
                </div>
              <% end %>

              <:actions>
                <.button phx-disable-with="Saving...">Save</.button>
              </:actions>
            </.simple_form>
          <% else %>
            <div class="text-red-400">You are not authorized to edit this entry.</div>
          <% end %>

          <%= if @entry.screenshot do %>
            <div class="mt-6">
              <h3 class="text-white text-sm font-semibold">Current Screenshot</h3>
              <img class="mt-2 max-h-64 rounded" src={ProjectZek.Uploaders.PvpScreenshot.url(@entry.screenshot)} />
            </div>
          <% end %>

          <%= if @entry.video_url do %>
            <div class="mt-6">
              <h3 class="text-white text-sm font-semibold">Video</h3>
              <a class="text-indigo-400 underline" href={@entry.video_url} target="_blank" rel="noreferrer">Open video</a>
            </div>
          <% end %>
        </div>
      </div>
    </div>
    """
  end
end
