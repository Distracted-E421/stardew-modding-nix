# 🌾 Stardew Valley Modding for NixOS

Reproducible Stardew Valley modding environment using NixOS + steam-tinker-launch + Vortex.

## 🎯 What This Does

- **Declarative Setup**: All modding tools configured via Nix flake
- **steam-tinker-launch**: Windows tool wrapper that runs Vortex natively on NixOS
- **SMAPI Integration**: Vortex handles SMAPI installation automatically
- **Cross-Platform Sharing**: Sync mods with Windows friends via zip exports or cloud storage
- **Reproducible**: Come back in 6 months and everything still works

## 📦 Target Collections

- [Stardew Valley VERY Expanded](https://www.nexusmods.com/games/stardewvalley/collections/tckf0m)
- [Fairycore Visual Pack](https://www.nexusmods.com/games/stardewvalley/collections/tjvl0j)

## 🚀 Quick Start

### For NixOS Users (Recommended)

1. **Add to your flake inputs:**

```nix
# flake.nix
{
  inputs = {
    # ... your other inputs ...
    stardew-modding = {
      url = "github:Distracted-E421/stardew-modding-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
}
```

2. **Import the Home Manager module:**

```nix
# home.nix or wherever your home-manager config lives
{ inputs, ... }:
{
  imports = [
    inputs.stardew-modding.homeManagerModules.default
  ];

  programs.stardew-modding = {
    enable = true;
    # Optional: customize paths
    # steamPath = "~/.local/share/Steam";
    # backupDir = "~/StardewBackups";
    # syncToCloud = true;
    # cloudPath = "~/OneDrive/StardewMods";
  };
}
```

3. **Rebuild:**

```bash
sudo nixos-rebuild switch --flake .#your-host
```

### Standalone Usage (nix develop)

```bash
# Enter development shell with all tools
nix develop github:Distracted-E421/stardew-modding-nix

# Check setup
stardew-check-setup

# Launch steam-tinker-launch
steamtinkerlaunch
```

## 🔧 Initial Setup

After installing, you need to configure Steam to use steam-tinker-launch:

### Step 1: Configure Steam

1. Open Steam
2. Right-click **Stardew Valley** → **Properties**
3. Go to **Compatibility** tab
4. Check "Force the use of a specific Steam Play compatibility tool"
5. Select **Steam Tinker Launch** from dropdown

### Step 2: Install Vortex via STL

1. Launch Stardew Valley from Steam
2. The **STL menu** will appear (not the game)
3. Click **Vortex** button
4. STL will download and install Vortex into a Wine prefix
5. Wait for installation to complete

### Step 3: Configure Vortex

1. In Vortex, click "Games" and find Stardew Valley
2. Click "Manage" to add the game
3. Vortex will detect SMAPI is missing and offer to install it
4. Accept the SMAPI installation

### Step 4: Install Collections

1. Go to Nexus Mods in your browser
2. Navigate to the [VERY Expanded collection](https://www.nexusmods.com/games/stardewvalley/collections/tckf0m)
3. Click "Add to Vortex" / "Install with Vortex"
4. STL's NXM link handler should open Vortex
5. Repeat for [Fairycore collection](https://www.nexusmods.com/games/stardewvalley/collections/tjvl0j)

> **Note**: If you don't have Nexus Premium, you'll need to manually click "Slow Download" for each mod in the collection. This can be tedious for large collections!

## 📂 Mod Sync & Sharing

Use the included Nushell sync script:

```bash
# Check current status
nu scripts/sync-mods.nu status

# Backup mods locally
nu scripts/sync-mods.nu backup

# Create zip for Windows friends
nu scripts/sync-mods.nu export

# Import mods from Windows friend's zip
nu scripts/sync-mods.nu import ~/Downloads/StardewMods.zip

# Sync to cloud storage (OneDrive/Google Drive)
nu scripts/sync-mods.nu cloud push
nu scripts/sync-mods.nu cloud pull
```

### Shell Aliases (if using Home Manager module)

```bash
stardew-mods     # cd to Mods folder
stardew-backup   # Quick backup
stardew-restore  # Restore from latest backup
stardew-check    # Verify STL setup
```

## 👥 Playing with Windows Friends

### The Golden Rules

1. **Mod Parity**: Everyone needs the **exact same mods** for multiplayer
2. **Version Sync**: Same version of SMAPI and each mod
3. **One Source of Truth**: Designate one person to manage the mod list

### Recommended Workflow

1. **You (NixOS)**: Set up mods via Vortex, test that game launches
2. **Export**: `nu scripts/sync-mods.nu export`
3. **Share**: Send the zip to Windows friends (OneDrive, Google Drive, etc.)
4. **Windows Friends**: Extract zip to their Stardew Valley folder, overwriting `Mods`
5. **Verify**: Everyone launches game to verify SMAPI loads all mods

### For Evie (Also on NixOS - Same Network)

**Option A: Local Network Sync (Fastest)**

Since both PCs are on Tailscale, transfer mods directly over SSH:

```bash
# From Obsidian: Push mods to Evie's PC
nu scripts/sync-mods-local.nu evie@evie-desktop-1

# Dry run first to see what will transfer
nu scripts/sync-mods-local.nu evie@evie-desktop-1 --dry-run

# Include save files too
nu scripts/sync-mods-local.nu evie@evie-desktop-1 --include-saves

# Pull mods FROM Evie's PC (reverse)
nu scripts/sync-mods-local.nu evie@evie-desktop-1 --reverse
```

Or use the installed command (after rebuild):
```bash
stardew-sync-local evie@evie-desktop-1
```

**Option B: Cloud Sync (If not on same network)**

```bash
# You: push mods to cloud
nu scripts/sync-mods.nu cloud push

# Her: pull mods from cloud
nu scripts/sync-mods.nu cloud pull
```

## 🎮 Other Games

Once STL is configured, it works for **any Steam game** that uses Vortex/Nexus Mods:

- **Skyrim** (Special/Anniversary Edition)
- **Fallout 4**
- **Cyberpunk 2077**
- **Baldur's Gate 3**
- **The Witcher 3**
- And many more!

Just set STL as the compatibility tool for each game and use Vortex to manage mods.

## 🔍 Troubleshooting

### STL Not Appearing in Steam

The Home Manager module creates the symlink automatically. If it's missing:

```bash
# Check if symlink exists
ls -la ~/.local/share/Steam/compatibilitytools.d/

# Manually create if needed
mkdir -p ~/.local/share/Steam/compatibilitytools.d/
ln -sf $(which steamtinkerlaunch) ~/.local/share/Steam/compatibilitytools.d/SteamTinkerLaunch
```

### NXM Links Not Working

STL needs to register as the handler for `nxm://` links:

1. Open STL menu (launch any game with STL)
2. Go to **Main Menu** → **Global Settings**
3. Enable **Associate NXM Links**

### Vortex Won't Install

Check that you have a Proton version installed:

1. In Steam, go to **Settings** → **Compatibility**
2. Enable "Steam Play for all other titles"
3. Select a Proton version (Proton Experimental recommended)

### Game Won't Launch After Installing Mods

Check the SMAPI console output:

```bash
# Find SMAPI log
cat ~/.local/share/Steam/steamapps/common/Stardew\ Valley/ErrorLogs/SMAPI-latest.txt | tail -100
```

Common issues:
- **Missing dependency**: Install the required mod listed in error
- **Version mismatch**: Update SMAPI or the mod
- **Conflicting mods**: Disable recently added mods one by one

## 📁 Project Structure

```
stardew-modding-nix/
├── flake.nix                    # Main Nix flake
├── home-manager/
│   └── stardew-modding.nix     # Home Manager module
├── nixos/
│   └── stardew-modding.nix     # NixOS system module
├── scripts/
│   └── sync-mods.nu            # Nushell sync script
├── docs/
│   ├── SETUP.md                # Detailed setup guide
│   └── WINDOWS_SYNC.md         # Windows friend sync guide
└── README.md
```

## 🤝 Contributing

PRs welcome! Especially for:
- Additional game configurations
- Improved sync scripts
- Better NXM link handling
- Documentation improvements

## 📜 License

MIT - Do whatever you want with it.

## 🙏 Credits

- [steam-tinker-launch](https://github.com/sonic2kk/steamtinkerlaunch) - The magic behind running Windows tools on Linux
- [Vortex Mod Manager](https://www.nexusmods.com/about/vortex/) - Nexus's official mod manager
- [SMAPI](https://smapi.io/) - Stardew Valley Modding API
- [NixOS](https://nixos.org/) - The reproducible Linux distro
