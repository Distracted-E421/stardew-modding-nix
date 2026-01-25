defmodule ModDistributorWeb.DownloadLive do
  @moduledoc """
  Download page with progress tracking via LiveView.
  """
  use ModDistributorWeb, :live_view

  @impl true
  def mount(params, _session, socket) do
    preset = params["preset"]
    custom_mods = params["mods"]
    
    socket = 
      socket
      |> assign(page_title: "Download")
      |> assign(preset: preset)
      |> assign(custom_mods: custom_mods)
      |> assign(status: :ready)
      |> assign(progress: 0)
      |> assign(message: nil)
      |> assign(download_url: nil)
      |> assign(error: nil)
    
    # Check if package already exists
    socket = maybe_find_existing_package(socket)
    
    {:ok, socket}
  end

  defp maybe_find_existing_package(socket) do
    case socket.assigns.preset do
      nil -> socket
      preset ->
        case ModDistributor.Packager.get_preset_path(preset) do
          {:ok, path} ->
            filename = Path.basename(path)
            assign(socket,
              status: :ready,
              download_url: "/downloads/#{filename}"
            )
          
          {:error, _} -> socket
        end
    end
  end

  @impl true
  def handle_event("start_download", _params, socket) do
    socket = assign(socket, status: :building, progress: 0, message: "Preparing package...")
    
    # Start async package building
    preset = socket.assigns.preset
    custom_mods = socket.assigns.custom_mods
    
    pid = self()
    
    Task.start(fn ->
      result = 
        if preset do
          send(pid, {:progress, 20, "Gathering #{preset} mods..."})
          ModDistributor.Packager.create_preset_package(preset)
        else
          mod_ids = String.split(custom_mods || "", ",") |> Enum.reject(&(&1 == ""))
          send(pid, {:progress, 20, "Gathering #{length(mod_ids)} mods..."})
          ModDistributor.Packager.create_custom_package(mod_ids)
        end
      
      send(pid, {:build_complete, result})
    end)
    
    {:noreply, socket}
  end

  @impl true
  def handle_info({:progress, percent, message}, socket) do
    {:noreply, assign(socket, progress: percent, message: message)}
  end

  @impl true
  def handle_info({:build_complete, {:ok, path}}, socket) do
    filename = Path.basename(path)
    
    socket = assign(socket,
      status: :complete,
      progress: 100,
      message: "Package ready!",
      download_url: "/downloads/#{filename}"
    )
    
    {:noreply, socket}
  end

  @impl true
  def handle_info({:build_complete, {:error, reason}}, socket) do
    socket = assign(socket,
      status: :error,
      error: "Failed to create package: #{inspect(reason)}"
    )
    
    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-2xl mx-auto space-y-8">
      <div class="text-center space-y-4">
        <h1 class="text-3xl font-bold text-amber-800">
          <%= if @preset do %>
            Download {String.capitalize(@preset)} Package
          <% else %>
            Download Custom Package
          <% end %>
        </h1>
        <p class="text-amber-600">
          <%= if @preset do %>
            Pre-configured and ready to install
          <% else %>
            Your custom selection of mods
          <% end %>
        </p>
      </div>
      
      <.card class="p-8">
        <%= case @status do %>
          <% :ready -> %>
            <div class="text-center space-y-6">
              <%= if @download_url do %>
                <div class="text-6xl">📦</div>
                <p class="text-amber-700">
                  Your package is ready!
                </p>
                <a href={@download_url} download class="inline-block">
                  <.button variant="primary" class="text-lg px-8 py-4">
                    ⬇️ Download Now
                  </.button>
                </a>
              <% else %>
                <div class="text-6xl">🔧</div>
                <p class="text-amber-700">
                  Click below to build your modpack package. This may take a minute.
                </p>
                <.button variant="primary" phx-click="start_download" class="text-lg px-8 py-4">
                  Build Package
                </.button>
              <% end %>
            </div>
          
          <% :building -> %>
            <div class="space-y-6">
              <div class="text-center">
                <div class="text-6xl animate-bounce">⚙️</div>
                <p class="text-lg font-semibold text-amber-800 mt-4">Building your package...</p>
                <p class="text-amber-600">{@message}</p>
              </div>
              
              <.progress value={@progress} max={100} />
              
              <p class="text-center text-sm text-amber-500">
                This may take a few minutes for large packages
              </p>
            </div>
          
          <% :complete -> %>
            <div class="text-center space-y-6">
              <div class="text-6xl">✅</div>
              <p class="text-lg font-semibold text-emerald-700">
                Package built successfully!
              </p>
              <a href={@download_url} download class="inline-block">
                <.button variant="primary" class="text-lg px-8 py-4">
                  ⬇️ Download Now
                </.button>
              </a>
              <p class="text-sm text-amber-600">
                Your download should start automatically. If not, click the button above.
              </p>
            </div>
          
          <% :error -> %>
            <div class="text-center space-y-6">
              <div class="text-6xl">❌</div>
              <p class="text-lg font-semibold text-rose-700">
                Something went wrong
              </p>
              <p class="text-amber-600">{@error}</p>
              <.button variant="outline" phx-click="start_download">
                Try Again
              </.button>
            </div>
        <% end %>
      </.card>
      
      <!-- Installation Instructions -->
      <.card>
        <h2 class="text-xl font-bold text-amber-800 mb-4">After Downloading</h2>
        <ol class="space-y-4 text-amber-700">
          <li class="flex gap-3">
            <span class="flex-none w-8 h-8 rounded-full bg-amber-100 text-amber-700 font-bold flex items-center justify-center">1</span>
            <div>
              <strong>Extract the ZIP</strong> directly into your Stardew Valley folder
              <p class="text-sm text-amber-500 mt-1">
                Right-click → Extract All → Choose game folder
              </p>
            </div>
          </li>
          <li class="flex gap-3">
            <span class="flex-none w-8 h-8 rounded-full bg-amber-100 text-amber-700 font-bold flex items-center justify-center">2</span>
            <div>
              <strong>Launch via SMAPI</strong>
              <p class="text-sm text-amber-500 mt-1">
                Run StardewModdingAPI.exe (not Stardew Valley.exe)
              </p>
            </div>
          </li>
          <li class="flex gap-3">
            <span class="flex-none w-8 h-8 rounded-full bg-amber-100 text-amber-700 font-bold flex items-center justify-center">3</span>
            <div>
              <strong>Configure in-game</strong>
              <p class="text-sm text-amber-500 mt-1">
                Press Escape → scroll down to Mod Options
              </p>
            </div>
          </li>
        </ol>
        
        <div class="mt-6 pt-6 border-t border-amber-200">
          <.link navigate={~p"/guide"} class="text-amber-600 hover:text-amber-800 font-semibold">
            📖 Read the full installation guide →
          </.link>
        </div>
      </.card>
    </div>
    """
  end
end

