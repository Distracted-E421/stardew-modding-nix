defmodule ModDistributorWeb.HomeLive do
  @moduledoc """
  Home page - main entry point for users to download the modpack.
  """
  use ModDistributorWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    metadata = ModDistributor.Catalog.get_metadata()
    packages = ModDistributor.Packager.list_packages()
    
    # Find the full modpack if it exists
    full_package = Enum.find(packages, &(&1.name == "full"))
    
    socket = assign(socket,
      page_title: "Home",
      metadata: metadata,
      packages: packages,
      full_package: full_package
    )
    
    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-12">
      <!-- Hero Section -->
      <section class="text-center space-y-6 py-8">
        <div class="inline-flex items-center gap-2 px-4 py-2 bg-emerald-100 text-emerald-700 rounded-full text-sm font-semibold">
          <span class="relative flex h-2 w-2">
            <span class="animate-ping absolute inline-flex h-full w-full rounded-full bg-emerald-400 opacity-75"></span>
            <span class="relative inline-flex rounded-full h-2 w-2 bg-emerald-500"></span>
          </span>
          Compatible with Stardew Valley <%= @metadata.game_version %>
        </div>
        
        <h1 class="text-4xl sm:text-5xl lg:text-6xl font-extrabold text-amber-900 tracking-tight">
          <span class="bg-gradient-to-r from-amber-600 to-orange-600 bg-clip-text text-transparent">
            Mega Expanded
          </span>
          <br />
          <span class="text-amber-800">Stardew Valley</span>
        </h1>
        
        <p class="max-w-2xl mx-auto text-lg text-amber-700">
          A curated collection of <strong><%= @metadata.total_mods %> mods</strong> including
          Stardew Valley Expanded, Ridgeside Village, East Scarp, and more.
          All tested and configured for the best co-op experience.
        </p>
        
        <div class="flex flex-col sm:flex-row items-center justify-center gap-4 pt-4">
          <.link navigate={~p"/download/full"}>
            <.button variant="primary" class="text-lg px-8 py-4">
              📦 Download Full Modpack
            </.button>
          </.link>
          
          <.link navigate={~p"/mods"}>
            <.button variant="outline" class="text-lg px-8 py-4">
              Browse Mods
            </.button>
          </.link>
        </div>
        
        <%= if @full_package do %>
          <p class="text-sm text-amber-600">
            Package size: <%= Float.round(@full_package.size_bytes / 1_000_000_000, 1) %> GB
          </p>
        <% end %>
      </section>
      
      <!-- Preset Cards -->
      <section class="space-y-6">
        <h2 class="text-2xl font-bold text-amber-800 text-center">
          Choose Your Adventure
        </h2>
        
        <div class="grid md:grid-cols-3 gap-6">
          <!-- Full Package -->
          <.card class="relative overflow-visible">
            <:header>
              <div class="flex items-center justify-between">
                <h3 class="font-bold text-amber-800">Full Mega Expanded</h3>
                <.badge variant="success">Recommended</.badge>
              </div>
            </:header>
            
            <div class="space-y-4">
              <p class="text-amber-700">
                The complete experience with all expansions, quality-of-life mods,
                and visual enhancements.
              </p>
              
              <ul class="text-sm text-amber-600 space-y-1">
                <li>✓ Stardew Valley Expanded</li>
                <li>✓ Ridgeside Village</li>
                <li>✓ East Scarp</li>
                <li>✓ Sunberry Village</li>
                <li>✓ 500+ additional mods</li>
              </ul>
            </div>
            
            <:footer>
              <.link navigate={~p"/download/full"} class="block">
                <.button variant="primary" class="w-full">
                  Download
                </.button>
              </.link>
            </:footer>
          </.card>
          
          <!-- Core Expansions -->
          <.card>
            <:header>
              <div class="flex items-center justify-between">
                <h3 class="font-bold text-amber-800">Core Expansions</h3>
                <.badge>Balanced</.badge>
              </div>
            </:header>
            
            <div class="space-y-4">
              <p class="text-amber-700">
                The essential expansions with proven compatibility.
                Great performance, lots of content.
              </p>
              
              <ul class="text-sm text-amber-600 space-y-1">
                <li>✓ Stardew Valley Expanded</li>
                <li>✓ Ridgeside Village</li>
                <li>✓ East Scarp</li>
                <li>✓ Essential frameworks</li>
                <li>✓ ~200 mods total</li>
              </ul>
            </div>
            
            <:footer>
              <.link navigate={~p"/download/core"} class="block">
                <.button variant="secondary" class="w-full">
                  Download
                </.button>
              </.link>
            </:footer>
          </.card>
          
          <!-- Custom Selection -->
          <.card>
            <:header>
              <div class="flex items-center justify-between">
                <h3 class="font-bold text-amber-800">Custom Selection</h3>
                <.badge variant="warning">Advanced</.badge>
              </div>
            </:header>
            
            <div class="space-y-4">
              <p class="text-amber-700">
                Pick exactly what you want. For experienced modders
                who know their preferences.
              </p>
              
              <ul class="text-sm text-amber-600 space-y-1">
                <li>→ Browse all <%= @metadata.total_mods %> mods</li>
                <li>→ Filter by category</li>
                <li>→ Check dependencies</li>
                <li>→ Build your own pack</li>
              </ul>
            </div>
            
            <:footer>
              <.link navigate={~p"/mods"} class="block">
                <.button variant="outline" class="w-full">
                  Browse & Select
                </.button>
              </.link>
            </:footer>
          </.card>
        </div>
      </section>
      
      <!-- Features Section -->
      <section class="space-y-6">
        <h2 class="text-2xl font-bold text-amber-800 text-center">
          What's Included
        </h2>
        
        <div class="grid sm:grid-cols-2 lg:grid-cols-4 gap-4">
          <div class="bg-white/60 backdrop-blur-sm rounded-xl p-4 border border-amber-200/50">
            <div class="text-3xl mb-2">🗺️</div>
            <h3 class="font-bold text-amber-800">New Areas</h3>
            <p class="text-sm text-amber-600">
              Explore expanded maps, new villages, and secret locations
            </p>
          </div>
          
          <div class="bg-white/60 backdrop-blur-sm rounded-xl p-4 border border-amber-200/50">
            <div class="text-3xl mb-2">👥</div>
            <h3 class="font-bold text-amber-800">New NPCs</h3>
            <p class="text-sm text-amber-600">
              Meet 50+ new characters with full stories and events
            </p>
          </div>
          
          <div class="bg-white/60 backdrop-blur-sm rounded-xl p-4 border border-amber-200/50">
            <div class="text-3xl mb-2">⚙️</div>
            <h3 class="font-bold text-amber-800">Quality of Life</h3>
            <p class="text-sm text-amber-600">
              Automate tasks, better UI, and time-saving features
            </p>
          </div>
          
          <div class="bg-white/60 backdrop-blur-sm rounded-xl p-4 border border-amber-200/50">
            <div class="text-3xl mb-2">🎨</div>
            <h3 class="font-bold text-amber-800">Visual Upgrades</h3>
            <p class="text-sm text-amber-600">
              Beautiful resprrites, new items, and seasonal decorations
            </p>
          </div>
        </div>
      </section>
      
      <!-- Getting Started -->
      <section class="space-y-6">
        <.card class="bg-gradient-to-br from-amber-100 to-orange-100 border-amber-300">
          <div class="flex flex-col lg:flex-row items-center gap-6">
            <div class="flex-1 space-y-4">
              <h2 class="text-2xl font-bold text-amber-800">
                First Time Modding?
              </h2>
              <p class="text-amber-700">
                Don't worry! Our step-by-step guide will walk you through
                everything from installing SMAPI to launching the game.
              </p>
              <.link navigate={~p"/guide"}>
                <.button variant="primary">
                  Read the Installation Guide →
                </.button>
              </.link>
            </div>
            <div class="text-8xl">
              📖
            </div>
          </div>
        </.card>
      </section>
    </div>
    """
  end
end

