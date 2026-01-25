defmodule ModDistributorWeb.GuideLive do
  @moduledoc """
  Installation guide page.
  """
  use ModDistributorWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, page_title: "Installation Guide")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-4xl mx-auto space-y-8">
      <div class="text-center space-y-4">
        <h1 class="text-4xl font-bold text-amber-800">Installation Guide</h1>
        <p class="text-lg text-amber-600">
          Everything you need to get started with modded Stardew Valley
        </p>
      </div>
      
      <!-- Prerequisites -->
      <.card>
        <h2 class="text-2xl font-bold text-amber-800 mb-4">📋 Before You Begin</h2>
        <ul class="space-y-3 text-amber-700">
          <li class="flex items-start gap-3">
            <span class="text-emerald-500 font-bold">✓</span>
            <div>
              <strong>Stardew Valley</strong> installed via Steam or GOG (version 1.6.15+)
            </div>
          </li>
          <li class="flex items-start gap-3">
            <span class="text-emerald-500 font-bold">✓</span>
            <div>
              <strong>Run the game once</strong> before installing mods (creates config files)
            </div>
          </li>
          <li class="flex items-start gap-3">
            <span class="text-emerald-500 font-bold">✓</span>
            <div>
              <strong>~10GB free space</strong> for the full modpack
            </div>
          </li>
        </ul>
      </.card>
      
      <!-- Step 1: Find Game Folder -->
      <.card>
        <div class="flex items-start gap-4">
          <div class="flex-none w-12 h-12 rounded-full bg-amber-500 text-white font-bold text-xl flex items-center justify-center shadow-lg">
            1
          </div>
          <div class="space-y-4 flex-1">
            <h2 class="text-xl font-bold text-amber-800">Locate Your Game Folder</h2>
            
            <div class="bg-amber-50 rounded-xl p-4 space-y-4">
              <div>
                <h3 class="font-semibold text-amber-800">Steam:</h3>
                <ol class="text-sm text-amber-600 space-y-1 mt-2">
                  <li>1. Open Steam and go to your Library</li>
                  <li>2. Right-click "Stardew Valley" → Properties</li>
                  <li>3. Click "Installed Files" tab</li>
                  <li>4. Click "Browse..." button</li>
                </ol>
                <div class="mt-2 bg-white/80 rounded-lg px-3 py-2 font-mono text-sm text-amber-700">
                  C:\Program Files (x86)\Steam\steamapps\common\Stardew Valley
                </div>
              </div>
              
              <div>
                <h3 class="font-semibold text-amber-800">GOG:</h3>
                <div class="mt-2 bg-white/80 rounded-lg px-3 py-2 font-mono text-sm text-amber-700">
                  C:\GOG Games\Stardew Valley
                </div>
              </div>
            </div>
          </div>
        </div>
      </.card>
      
      <!-- Step 2: Install SMAPI -->
      <.card>
        <div class="flex items-start gap-4">
          <div class="flex-none w-12 h-12 rounded-full bg-amber-500 text-white font-bold text-xl flex items-center justify-center shadow-lg">
            2
          </div>
          <div class="space-y-4 flex-1">
            <h2 class="text-xl font-bold text-amber-800">Install SMAPI</h2>
            
            <p class="text-amber-700">
              SMAPI (Stardew Modding API) is required for all mods to work.
              <strong>Our modpack includes SMAPI</strong>, but you need to run its installer.
            </p>
            
            <div class="bg-amber-50 rounded-xl p-4 space-y-3">
              <p class="font-semibold text-amber-800">After extracting the modpack:</p>
              <ol class="text-sm text-amber-600 space-y-1">
                <li>1. Open your Stardew Valley folder</li>
                <li>2. Find the "SMAPI" folder</li>
                <li>3. Run <code class="bg-white/80 px-2 py-0.5 rounded">install.bat</code> (Windows) or <code class="bg-white/80 px-2 py-0.5 rounded">install.command</code> (Mac)</li>
                <li>4. Follow the prompts</li>
              </ol>
            </div>
            
            <div class="flex items-center gap-2 text-sm text-amber-600 bg-emerald-50 rounded-lg p-3">
              <span class="text-emerald-500">💡</span>
              Steam users: SMAPI will ask to configure Steam to launch SMAPI. Say yes!
            </div>
          </div>
        </div>
      </.card>
      
      <!-- Step 3: Extract Mods -->
      <.card>
        <div class="flex items-start gap-4">
          <div class="flex-none w-12 h-12 rounded-full bg-amber-500 text-white font-bold text-xl flex items-center justify-center shadow-lg">
            3
          </div>
          <div class="space-y-4 flex-1">
            <h2 class="text-xl font-bold text-amber-800">Extract the Modpack</h2>
            
            <ol class="space-y-3 text-amber-700">
              <li class="flex items-start gap-2">
                <span class="font-bold">1.</span>
                <span>Download the modpack from the <.link navigate={~p"/"} class="text-amber-600 underline hover:text-amber-800">home page</.link></span>
              </li>
              <li class="flex items-start gap-2">
                <span class="font-bold">2.</span>
                <span>Right-click the downloaded ZIP file</span>
              </li>
              <li class="flex items-start gap-2">
                <span class="font-bold">3.</span>
                <span>Select "Extract All..." or use 7-Zip/WinRAR</span>
              </li>
              <li class="flex items-start gap-2">
                <span class="font-bold">4.</span>
                <span>Choose your <strong>Stardew Valley folder</strong> as the destination</span>
              </li>
              <li class="flex items-start gap-2">
                <span class="font-bold">5.</span>
                <span>Click "Extract" and say "Yes" to overwrite if asked</span>
              </li>
            </ol>
            
            <div class="bg-rose-50 rounded-xl p-4 text-rose-700">
              <strong>⚠️ Important:</strong> Extract directly to the game folder, not to a subfolder inside it!
              <br />
              <span class="text-sm">Correct: <code class="bg-white/80 px-2 py-0.5 rounded">Stardew Valley/Mods/</code></span>
              <br />
              <span class="text-sm">Wrong: <code class="bg-white/80 px-2 py-0.5 rounded">Stardew Valley/modpack/Mods/</code></span>
            </div>
          </div>
        </div>
      </.card>
      
      <!-- Step 4: Launch -->
      <.card>
        <div class="flex items-start gap-4">
          <div class="flex-none w-12 h-12 rounded-full bg-amber-500 text-white font-bold text-xl flex items-center justify-center shadow-lg">
            4
          </div>
          <div class="space-y-4 flex-1">
            <h2 class="text-xl font-bold text-amber-800">Launch the Game</h2>
            
            <div class="bg-amber-50 rounded-xl p-4 space-y-4">
              <div>
                <h3 class="font-semibold text-amber-800">Steam:</h3>
                <p class="text-amber-600">
                  Just launch normally from Steam. SMAPI configured it automatically.
                </p>
              </div>
              
              <div>
                <h3 class="font-semibold text-amber-800">Manual/GOG:</h3>
                <p class="text-amber-600">
                  Run <code class="bg-white/80 px-2 py-0.5 rounded">StardewModdingAPI.exe</code> directly
                </p>
              </div>
            </div>
            
            <div class="flex items-center gap-2 text-sm text-amber-600 bg-emerald-50 rounded-lg p-3">
              <span class="text-emerald-500">⏱️</span>
              First launch takes 1-2 minutes as mods load. This is normal!
            </div>
          </div>
        </div>
      </.card>
      
      <!-- Step 5: Configure -->
      <.card>
        <div class="flex items-start gap-4">
          <div class="flex-none w-12 h-12 rounded-full bg-amber-500 text-white font-bold text-xl flex items-center justify-center shadow-lg">
            5
          </div>
          <div class="space-y-4 flex-1">
            <h2 class="text-xl font-bold text-amber-800">Configure Your Mods (Optional)</h2>
            
            <p class="text-amber-700">
              Most mods come pre-configured, but you can customize them using GMCM
              (Generic Mod Config Menu).
            </p>
            
            <ol class="space-y-2 text-amber-700">
              <li>1. Start or load a game</li>
              <li>2. Press <kbd class="px-2 py-1 bg-amber-100 rounded text-sm">Escape</kbd> to open the menu</li>
              <li>3. Scroll down to find "Mod Options"</li>
              <li>4. Browse and adjust settings per mod</li>
            </ol>
          </div>
        </div>
      </.card>
      
      <!-- Troubleshooting -->
      <.card class="bg-gradient-to-br from-amber-100 to-orange-100 border-amber-300">
        <h2 class="text-2xl font-bold text-amber-800 mb-4">🔧 Troubleshooting</h2>
        
        <div class="space-y-4">
          <div>
            <h3 class="font-semibold text-amber-800">Game crashes on startup?</h3>
            <ul class="text-sm text-amber-600 mt-1 space-y-1">
              <li>• Make sure you ran the SMAPI installer</li>
              <li>• Check that mods are in the correct Mods folder</li>
              <li>• Verify your game version is 1.6.15+</li>
            </ul>
          </div>
          
          <div>
            <h3 class="font-semibold text-amber-800">Missing content/errors in-game?</h3>
            <ul class="text-sm text-amber-600 mt-1 space-y-1">
              <li>• Check the SMAPI console for red error messages</li>
              <li>• Some mods may need their own dependencies</li>
              <li>• Try starting a new save file</li>
            </ul>
          </div>
          
          <div>
            <h3 class="font-semibold text-amber-800">Co-op isn't working?</h3>
            <ul class="text-sm text-amber-600 mt-1 space-y-1">
              <li>• All players need the SAME mods and versions</li>
              <li>• Use this same modpack for everyone</li>
              <li>• Host should load the world first</li>
            </ul>
          </div>
        </div>
      </.card>
      
      <!-- CTA -->
      <div class="text-center space-y-4">
        <p class="text-lg text-amber-700">Ready to get started?</p>
        <.link navigate={~p"/"}>
          <.button variant="primary" class="text-lg px-8 py-4">
            Download the Modpack →
          </.button>
        </.link>
      </div>
    </div>
    """
  end
end

