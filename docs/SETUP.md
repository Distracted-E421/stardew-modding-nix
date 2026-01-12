# 🔧 Detailed Setup Guide

This guide walks through every step of setting up Stardew Valley modding on NixOS.

## Prerequisites

- NixOS with flakes enabled
- Steam installed (via `programs.steam.enable = true` or nixpkgs)
- Stardew Valley purchased and installed via Steam
- (Optional) Nexus Mods account (Premium recommended for collections)

## Step 1: Install This Flake

### Option A: Home Manager (Recommended)

Add to your flake inputs:

```nix
# flake.nix
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    
    stardew-modding = {
      url = "github:Distracted-E421/stardew-modding-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  
  outputs = { nixpkgs, home-manager, stardew-modding, ... }:
  {
    # ... your config
  };
}
```

In your Home Manager config:

```nix
# home.nix
{ inputs, ... }:
{
  imports = [
    inputs.stardew-modding.homeManagerModules.default
  ];

  programs.stardew-modding.enable = true;
}
```

### Option B: NixOS System Module

For system-wide installation:

```nix
# configuration.nix
{ inputs, ... }:
{
  imports = [
    inputs.stardew-modding.nixosModules.default
  ];

  services.stardew-modding = {
    enable = true;
    users = [ "e421" "evie" ];  # Users who need STL
  };
}
```

### Option C: Standalone (nix develop)

```bash
nix develop github:Distracted-E421/stardew-modding-nix
```

## Step 2: Rebuild System

```bash
# With home-manager
home-manager switch --flake .#your-config

# Or full system rebuild
sudo nixos-rebuild switch --flake .#your-host
```

## Step 3: Verify Installation

```bash
# Check STL is available
which steamtinkerlaunch

# Check symlink exists
ls -la ~/.local/share/Steam/compatibilitytools.d/SteamTinkerLaunch

# Or use the check script
nix run github:Distracted-E421/stardew-modding-nix#check-setup
```

## Step 4: Configure Steam

1. **Restart Steam** (important - Steam caches compatibility tools on startup)

2. Open **Steam Library**

3. Right-click **Stardew Valley** → **Properties**

4. Go to **Compatibility** tab

5. Check "Force the use of a specific Steam Play compatibility tool"

6. Select **Steam Tinker Launch** from the dropdown

   If STL doesn't appear:
   - Restart Steam completely
   - Check the symlink exists: `ls ~/.local/share/Steam/compatibilitytools.d/`
   - Ensure you have a Proton version installed

## Step 5: First Launch & Vortex Setup

1. **Launch Stardew Valley** from Steam

2. The **STL Menu** should appear (not the game!)

   If the game launches directly:
   - STL might not be set as compatibility tool
   - Or STL's STARTGAME option is set to 1 (auto-start game)

3. Click the **Vortex** button in the STL menu

4. STL will download Vortex installer (~150MB)

5. Follow the Vortex installer prompts
   - Install to default location (Wine prefix)
   - When asked about NXM links, say **Yes**

6. Wait for Vortex to fully install and launch

## Step 6: Add Stardew Valley to Vortex

1. In Vortex sidebar, click **Games**

2. Search for "Stardew Valley"

3. Click the **Manage** button on Stardew Valley

4. Vortex will scan for the game location

5. If prompted about SMAPI:
   - Click **Yes** to install SMAPI
   - This is required for all Stardew mods

## Step 7: Configure NXM Links

For one-click installs from Nexus Mods website:

### In STL:

1. From the STL menu, go to **Main Menu**
2. Click **Global Settings**
3. Find **ASSOCNXM** and set to **1** (enabled)
4. Save and close

### In Vortex:

1. Go to **Settings** → **Download**
2. Enable "Handle NXM Links"
3. Test by clicking a download link on Nexus Mods

### In Firefox/Browser:

When you first click an NXM link, your browser will ask what to do:

1. Select "Open with" → search for `steamtinkerlaunch` or Vortex
2. Check "Remember this choice"

## Step 8: Install Mod Collections

### With Nexus Premium (Recommended)

1. Go to [VERY Expanded Collection](https://www.nexusmods.com/games/stardewvalley/collections/tckf0m)
2. Click **Install with Vortex**
3. Vortex will auto-download all mods
4. Repeat for [Fairycore](https://www.nexusmods.com/games/stardewvalley/collections/tjvl0j)

### Without Premium

You'll need to manually click "Slow Download" for each mod:

1. Open the collection page
2. Click "View Mods" to see all mods
3. For each mod:
   - Click the mod name
   - Go to Files tab
   - Click "Slow Download" (wait for timer)
   - Repeat for ~50+ mods

**Alternative**: Have a Windows friend with Premium download the collection, then share the Mods folder with you.

## Step 9: Deploy Mods

1. In Vortex, go to **Mods** tab
2. All downloaded mods should show "Enabled"
3. Click **Deploy Mods** button
4. Vortex will install mods to the game folder

## Step 10: Launch the Game!

1. Launch from Steam (STL menu appears)
2. Click **Start Game** or just close the menu
3. SMAPI console should show all mods loading
4. Game should launch with mods active!

## Common Issues

See [Troubleshooting](#troubleshooting) in main README.

## Next Steps

- Set up [cloud sync](./WINDOWS_SYNC.md) for multiplayer with friends
- Configure other games (Skyrim, Fallout 4, etc.)
- Backup your mod configuration
