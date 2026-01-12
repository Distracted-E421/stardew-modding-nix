# 👥 Syncing Mods with Windows Friends

This guide covers sharing mods between NixOS and Windows players for multiplayer.

## The Golden Rules of Modded Multiplayer

1. **Everyone needs identical mods** - Same mods, same versions
2. **Same SMAPI version** - Host and all clients
3. **One mod manager** - Whoever manages mods is the source of truth

## Recommended Workflow

### You Are the Mod Manager

Since you're the dev of the group, you probably should manage the mods:

1. **Set up mods** on your NixOS machine via Vortex
2. **Test** that the game launches and mods load correctly
3. **Export** the Mods folder as a zip
4. **Share** with your group
5. **Everyone extracts** to their game folder

### Export Commands

```bash
# Using the sync script
nu scripts/sync-mods.nu export

# Or manually
cd ~/.local/share/Steam/steamapps/common/Stardew\ Valley
zip -r ~/StardewMods_$(date +%Y%m%d).zip Mods -x "*.log" -x ".cache/*"
```

The zip will be created in `~/StardewExports/` (default) or your home directory.

### For Windows Friends

Send them these instructions:

```
📋 STARDEW VALLEY MOD INSTALLATION (Windows)

1. Make sure you have SMAPI installed:
   - Download from https://smapi.io
   - Run the installer
   - Select your Stardew Valley folder

2. Backup your current Mods folder:
   - Go to: C:\Program Files (x86)\Steam\steamapps\common\Stardew Valley
   - Rename "Mods" to "Mods_backup"

3. Extract the mod pack:
   - Extract StardewMods_YYYYMMDD.zip
   - Drag the "Mods" folder into your Stardew Valley folder

4. Launch the game:
   - Open Steam
   - Launch Stardew Valley
   - SMAPI console should show all mods loading

5. Join multiplayer:
   - One person hosts (Co-op → Host → Load or New Farm)
   - Others join via Co-op → Join LAN Game or invite code
```

## Cloud Sync Setup

For easier sharing, set up cloud sync:

### OneDrive (Recommended for Windows Friends)

```nix
# home.nix
programs.stardew-modding = {
  enable = true;
  syncToCloud = true;
  cloudPath = "~/OneDrive/StardewMods";  # Synced automatically
};
```

Usage:
```bash
# Push your mods to OneDrive
nu scripts/sync-mods.nu cloud push

# Friends can access: OneDrive → StardewMods folder
```

### Google Drive

```nix
programs.stardew-modding = {
  enable = true;
  syncToCloud = true;
  cloudPath = "~/GoogleDrive/StardewMods";
};
```

### For Your Wife (NixOS)

Since she's also on NixOS:

1. Add this flake to her config (same imports)
2. Set the same cloud path
3. She runs `cloud pull`, you run `cloud push`

```bash
# You (after making changes)
nu scripts/sync-mods.nu cloud push

# Her (to get updates)
nu scripts/sync-mods.nu cloud pull
```

## Updating Mods

When mods update:

1. **You** update via Vortex
2. **Test** game still works
3. **Export** new zip: `nu scripts/sync-mods.nu export`
4. **Share** with everyone
5. **Everyone** replaces their Mods folder

### Version Tracking

Keep notes on what version everyone should have:

```markdown
# Mod Pack Versions

## v3 (2026-01-15)
- Added: Fairy visual pack
- Updated: SVE to 1.14.2
- Fixed: Combat mod conflict

## v2 (2026-01-10)
- Full VERY Expanded collection
- SMAPI 4.0.0

## v1 (2026-01-05)
- Initial pack
- Base SVE only
```

## Troubleshooting Multiplayer

### "Mod Version Mismatch"

- Everyone needs the **exact** same mod versions
- Re-sync from the shared zip/cloud folder
- Check SMAPI console for version numbers

### "Host Has Mods You Don't Have"

- Someone is missing mods
- Re-extract the full mod pack
- Don't pick and choose mods!

### "Connection Failed"

Not a mod issue, but:
- Check firewalls
- Try Steam invite codes instead of LAN
- Use Hamachi/ZeroTier if behind CGNAT

### "Game Crashes on Join"

- Usually a content mod conflict
- Check SMAPI logs on crashing machine
- Try disabling large content mods one by one

## Game-Specific Notes

### Stardew Valley VERY Expanded

This collection includes:
- **Stardew Valley Expanded** - Main content mod
- **SMAPI** - Required mod loader
- **Content Patcher** - Framework for other mods
- **50+ additional mods** - Visuals, QoL, etc.

All players need ALL of these for multiplayer to work.

### Fairycore

Purely visual mod pack:
- Changes building/farm aesthetics
- Safe for multiplayer
- Visual differences between players are OK

## Quick Reference

```bash
# Check what you have installed
nu scripts/sync-mods.nu status

# Backup before changes
nu scripts/sync-mods.nu backup

# Create zip for friends
nu scripts/sync-mods.nu export

# Sync to cloud
nu scripts/sync-mods.nu cloud push

# Get from cloud (wife/other NixOS user)
nu scripts/sync-mods.nu cloud pull

# Import from Windows friend's zip
nu scripts/sync-mods.nu import ~/Downloads/TheirMods.zip
```
