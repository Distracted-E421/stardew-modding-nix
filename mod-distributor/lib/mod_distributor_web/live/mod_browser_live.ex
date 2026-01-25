defmodule ModDistributorWeb.ModBrowserLive do
  @moduledoc """
  Browse and select mods for a custom package.
  """
  use ModDistributorWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    mods = ModDistributor.Catalog.list_mods()
    metadata = ModDistributor.Catalog.get_metadata()
    
    categories = 
      mods 
      |> Enum.map(& &1.category) 
      |> Enum.uniq() 
      |> Enum.sort()
    
    socket = assign(socket,
      page_title: "Browse Mods",
      all_mods: mods,
      filtered_mods: mods,
      categories: categories,
      selected_category: "all",
      search_query: "",
      selected_mods: MapSet.new(),
      metadata: metadata
    )
    
    {:ok, socket}
  end

  @impl true
  def handle_event("filter_category", %{"category" => category}, socket) do
    filtered = filter_mods(socket.assigns.all_mods, category, socket.assigns.search_query)
    
    {:noreply, assign(socket, 
      selected_category: category,
      filtered_mods: filtered
    )}
  end

  @impl true
  def handle_event("search", %{"query" => query}, socket) do
    filtered = filter_mods(socket.assigns.all_mods, socket.assigns.selected_category, query)
    
    {:noreply, assign(socket,
      search_query: query,
      filtered_mods: filtered
    )}
  end

  @impl true
  def handle_event("toggle_mod", %{"mod-id" => mod_id}, socket) do
    selected = socket.assigns.selected_mods
    
    new_selected = 
      if MapSet.member?(selected, mod_id) do
        MapSet.delete(selected, mod_id)
      else
        MapSet.put(selected, mod_id)
      end
    
    {:noreply, assign(socket, selected_mods: new_selected)}
  end

  @impl true
  def handle_event("select_all", _params, socket) do
    mod_ids = Enum.map(socket.assigns.filtered_mods, & &1.id)
    {:noreply, assign(socket, selected_mods: MapSet.new(mod_ids))}
  end

  @impl true
  def handle_event("clear_selection", _params, socket) do
    {:noreply, assign(socket, selected_mods: MapSet.new())}
  end

  defp filter_mods(mods, category, query) do
    mods
    |> then(fn m ->
      if category == "all" do
        m
      else
        Enum.filter(m, &(&1.category == category))
      end
    end)
    |> then(fn m ->
      if query == "" do
        m
      else
        query_lower = String.downcase(query)
        Enum.filter(m, fn mod ->
          String.contains?(String.downcase(mod.name), query_lower) or
          String.contains?(String.downcase(mod.author || ""), query_lower) or
          String.contains?(String.downcase(mod.description || ""), query_lower)
        end)
      end
    end)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <div class="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4">
        <div>
          <h1 class="text-3xl font-bold text-amber-800">Browse Mods</h1>
          <p class="text-amber-600">
            <%= length(@all_mods) %> mods available · <%= MapSet.size(@selected_mods) %> selected
          </p>
        </div>
        
        <%= if MapSet.size(@selected_mods) > 0 do %>
          <.link navigate={~p"/download?mods=#{Enum.join(@selected_mods, ",")}"}>
            <.button variant="primary">
              Download <%= MapSet.size(@selected_mods) %> Selected →
            </.button>
          </.link>
        <% end %>
      </div>
      
      <!-- Filters -->
      <.card>
        <div class="flex flex-col lg:flex-row gap-4">
          <!-- Search -->
          <div class="flex-1">
            <label class="block text-sm font-semibold text-amber-700 mb-1">Search</label>
            <input
              type="text"
              value={@search_query}
              phx-keyup="search"
              phx-debounce="300"
              name="query"
              placeholder="Search by name, author, or description..."
              class="w-full rounded-xl border-2 border-amber-200 bg-white/80 px-4 py-2 text-amber-900 placeholder-amber-400 focus:border-amber-500 focus:ring-2 focus:ring-amber-200"
            />
          </div>
          
          <!-- Category Filter -->
          <div class="w-full lg:w-48">
            <label class="block text-sm font-semibold text-amber-700 mb-1">Category</label>
            <select
              phx-change="filter_category"
              name="category"
              class="w-full rounded-xl border-2 border-amber-200 bg-white/80 px-4 py-2 text-amber-900 focus:border-amber-500 focus:ring-2 focus:ring-amber-200"
            >
              <option value="all" selected={@selected_category == "all"}>All Categories</option>
              <%= for category <- @categories do %>
                <option value={category} selected={@selected_category == category}>
                  {String.capitalize(category)}
                </option>
              <% end %>
            </select>
          </div>
          
          <!-- Bulk Actions -->
          <div class="flex items-end gap-2">
            <button
              phx-click="select_all"
              class="px-4 py-2 rounded-xl bg-amber-100 text-amber-700 font-semibold hover:bg-amber-200 transition-colors"
            >
              Select All
            </button>
            <button
              phx-click="clear_selection"
              class="px-4 py-2 rounded-xl bg-amber-100 text-amber-700 font-semibold hover:bg-amber-200 transition-colors"
            >
              Clear
            </button>
          </div>
        </div>
      </.card>
      
      <!-- Mod List -->
      <div class="grid gap-3">
        <%= if length(@filtered_mods) == 0 do %>
          <.card class="text-center py-12">
            <p class="text-amber-600 text-lg">No mods found matching your criteria.</p>
            <button
              phx-click="filter_category"
              phx-value-category="all"
              class="mt-4 text-amber-500 hover:text-amber-700 underline"
            >
              Clear filters
            </button>
          </.card>
        <% else %>
          <%= for mod <- @filtered_mods do %>
            <div
              phx-click="toggle_mod"
              phx-value-mod-id={mod.id}
              class={[
                "group cursor-pointer rounded-xl border-2 p-4 transition-all duration-200",
                "hover:shadow-lg hover:shadow-amber-500/10",
                if(MapSet.member?(@selected_mods, mod.id),
                  do: "bg-emerald-50 border-emerald-400",
                  else: "bg-white/80 border-amber-200/50 hover:border-amber-300"
                )
              ]}
            >
              <div class="flex items-start gap-4">
                <!-- Checkbox -->
                <div class={[
                  "flex-none w-6 h-6 rounded-lg border-2 flex items-center justify-center transition-colors",
                  if(MapSet.member?(@selected_mods, mod.id),
                    do: "bg-emerald-500 border-emerald-500",
                    else: "border-amber-300 group-hover:border-amber-400"
                  )
                ]}>
                  <%= if MapSet.member?(@selected_mods, mod.id) do %>
                    <svg class="w-4 h-4 text-white" fill="currentColor" viewBox="0 0 20 20">
                      <path fill-rule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clip-rule="evenodd" />
                    </svg>
                  <% end %>
                </div>
                
                <!-- Content -->
                <div class="flex-1 min-w-0">
                  <div class="flex items-center gap-2 flex-wrap">
                    <h3 class="font-bold text-amber-800"><%= mod.name %></h3>
                    <%= if mod.required do %>
                      <.badge variant="error">Required</.badge>
                    <% end %>
                    <.badge>{String.capitalize(mod.category)}</.badge>
                  </div>
                  
                  <p class="text-sm text-amber-600 mt-1">
                    by <%= mod.author %> · v<%= mod.version %>
                    <%= if mod.size_mb > 0 do %>
                      · <%= mod.size_mb %> MB
                    <% end %>
                  </p>
                  
                  <%= if mod.description do %>
                    <p class="text-sm text-amber-700 mt-2 line-clamp-2">
                      <%= mod.description %>
                    </p>
                  <% end %>
                  
                  <%= if mod.dependencies && length(mod.dependencies) > 0 do %>
                    <p class="text-xs text-amber-500 mt-2">
                      Requires: {Enum.join(mod.dependencies, ", ")}
                    </p>
                  <% end %>
                </div>
                
                <!-- Nexus Link -->
                <%= if mod.nexus_id do %>
                  <a
                    href={"https://www.nexusmods.com/stardewvalley/mods/#{mod.nexus_id}"}
                    target="_blank"
                    rel="noopener"
                    onclick="event.stopPropagation()"
                    class="flex-none px-3 py-1 rounded-lg bg-amber-100 text-amber-700 text-sm font-medium hover:bg-amber-200 transition-colors"
                  >
                    Nexus →
                  </a>
                <% end %>
              </div>
            </div>
          <% end %>
        <% end %>
      </div>
      
      <!-- Floating Selection Bar -->
      <%= if MapSet.size(@selected_mods) > 0 do %>
        <div class="fixed bottom-6 left-1/2 -translate-x-1/2 z-50">
          <div class="bg-amber-800 text-white rounded-2xl px-6 py-4 shadow-2xl shadow-amber-900/30 flex items-center gap-6">
            <span class="font-semibold">
              <%= MapSet.size(@selected_mods) %> mods selected
            </span>
            <.link navigate={~p"/download?mods=#{Enum.join(@selected_mods, ",")}"}>
              <.button variant="primary" class="bg-white text-amber-800 hover:bg-amber-100">
                Create Package →
              </.button>
            </.link>
          </div>
        </div>
      <% end %>
    </div>
    """
  end
end

