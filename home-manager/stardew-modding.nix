# Home Manager Module for Stardew Valley Modding
# Integrates steam-tinker-launch + Vortex into your Home Manager config
#
# Usage in your home.nix:
#   imports = [ inputs.stardew-modding.homeManagerModules.default ];
#   programs.stardew-modding = {
#     enable = true;
#     steamPath = "~/.local/share/Steam";  # Optional, auto-detected
#   };

{ config, lib, pkgs, ... }:

let
  cfg = config.programs.stardew-modding;
  
  # Default paths
  defaultSteamPath = "${config.home.homeDirectory}/.local/share/Steam";
  gamePath = "${cfg.steamPath}/steamapps/common/Stardew Valley";
  stlConfigDir = "${config.home.homeDirectory}/.config/steamtinkerlaunch";
  
  # Initial config content (used as template, STL will manage the actual file)
  globalConfContent = ''
    # Steam Tinker Launch - Global Configuration
    # Initial config created by stardew-modding-nix
    # STL will manage this file after first run - feel free to edit!

    # ═══════════════════════════════════════════════════════════════════════
    # NIXOS COMPATIBILITY
    # ═══════════════════════════════════════════════════════════════════════
    # Skip internal dependency checks - NixOS paths confuse STL
    SKIPINTDEPCHECK="${if cfg.skipIntDepCheck then "1" else "0"}"

    # ═══════════════════════════════════════════════════════════════════════
    # PATHS
    # ═══════════════════════════════════════════════════════════════════════
    STEAM_DIR="${cfg.steamPath}"
    STEAM_LIBRARY="${cfg.steamPath}/steamapps"

    # ═══════════════════════════════════════════════════════════════════════
    # VORTEX CONFIGURATION
    # ═══════════════════════════════════════════════════════════════════════
    # Enable Vortex button in STL menu
    USEVORTEX="${if cfg.enableVortex then "1" else "0"}"
    
    # Associate NXM links (Nexus Mods one-click downloads)
    ASSOCNXM="1"

    # ═══════════════════════════════════════════════════════════════════════
    # GENERAL SETTINGS
    # ═══════════════════════════════════════════════════════════════════════
    # Show STL menu on game launch (0 = show menu, 1 = start game directly)
    STARTGAME="0"
    
    # Enable notifications
    USENOTIFY="1"
    
    # Wine/Proton settings (STL handles this automatically)
    USEPROCHOICE="1"
  '';

  stardewConfContent = ''
    # Stardew Valley - Steam Tinker Launch Configuration
    # Game ID: 413150
    # STL will manage this file - feel free to edit!
    
    # Show menu on launch (configure Vortex/SMAPI)
    STARTGAME="0"
    
    # Use Proton (required for Vortex)
    USEPROTON="1"
    
    # Enable Vortex for this game
    USEVORTEX="1"
    
    # Game-specific notes
    # SMAPI will be installed via Vortex
    # Collections: VERY Expanded + Fairycore
  '';

  # Setup script that initializes configs as writable copies
  setupScript = pkgs.writeShellScriptBin "stardew-modding-setup" ''
    #!/usr/bin/env bash
    set -e
    
    echo "🌾 Setting up Stardew Valley modding environment..."
    
    # Create directories
    mkdir -p "${stlConfigDir}"
    mkdir -p "${stlConfigDir}/gamecfgs"
    mkdir -p "${cfg.steamPath}/compatibilitytools.d/SteamTinkerLaunch"
    mkdir -p "${cfg.backupDir}"
    
    # Create/update global.conf (writable copy, not symlink)
    GLOBAL_CONF="${stlConfigDir}/global.conf"
    if [ ! -f "$GLOBAL_CONF" ] || [ -L "$GLOBAL_CONF" ]; then
      # Remove if it's a symlink (from old Home Manager setup)
      [ -L "$GLOBAL_CONF" ] && rm "$GLOBAL_CONF"
      echo "Creating initial STL global config..."
      cat > "$GLOBAL_CONF" << 'GLOBALEOF'
${globalConfContent}
GLOBALEOF
      chmod 644 "$GLOBAL_CONF"
    else
      echo "✓ STL global config exists (keeping user modifications)"
    fi
    
    # Create/update Stardew-specific config
    STARDEW_CONF="${stlConfigDir}/gamecfgs/413150.conf"
    if [ ! -f "$STARDEW_CONF" ] || [ -L "$STARDEW_CONF" ]; then
      [ -L "$STARDEW_CONF" ] && rm "$STARDEW_CONF"
      echo "Creating Stardew Valley STL config..."
      cat > "$STARDEW_CONF" << 'STARDEWEOF'
${stardewConfContent}
STARDEWEOF
      chmod 644 "$STARDEW_CONF"
    else
      echo "✓ Stardew Valley config exists (keeping user modifications)"
    fi
    
    # Setup Steam compatibility tools
    STL_DIR="${cfg.steamPath}/compatibilitytools.d/SteamTinkerLaunch"
    
    # Create toolmanifest.vdf
    cat > "$STL_DIR/toolmanifest.vdf" << 'EOF'
"manifest"
{
  "version" "2"
  "commandline" "/proton %verb%"
}
EOF
    
    # Create compatibilitytool.vdf
    cat > "$STL_DIR/compatibilitytool.vdf" << 'EOF'
"compatibilitytools"
{
  "compat_tools"
  {
    "SteamTinkerLaunch"
    {
      "install_path" "."
      "display_name" "Steam Tinker Launch"
      "from_oslist" "windows"
      "to_oslist" "linux"
    }
  }
}
EOF

    # Link STL binary as 'proton' (Steam calls it this way)
    STL_BIN="${pkgs.steamtinkerlaunch}/bin/steamtinkerlaunch"
    if [ -f "$STL_BIN" ]; then
      ln -sf "$STL_BIN" "$STL_DIR/proton"
      chmod +x "$STL_DIR/proton"
    fi
    
    echo ""
    echo "✅ Setup complete!"
    echo ""
    echo "Next steps:"
    echo "1. Restart Steam (if running)"
    echo "2. Right-click Stardew Valley → Properties → Compatibility"
    echo "3. Enable 'Force Steam Play' and select 'Steam Tinker Launch'"
    echo "4. Launch Stardew Valley - STL menu will appear"
    echo "5. Click 'Vortex' to install/configure Vortex"
    echo "6. In Vortex: Games → Stardew Valley → Manage"
    echo "7. Install SMAPI when prompted"
    echo "8. Go to Nexus Mods and click 'Add to Vortex' on collections"
  '';

  # Check script
  checkScript = pkgs.writeShellScriptBin "stardew-check-setup" ''
    #!/usr/bin/env bash
    echo "🌾 Checking Stardew Valley modding setup..."
    echo ""
    
    STEAM_PATH="${cfg.steamPath}"
    GAME_PATH="${gamePath}"
    
    # Check Steam
    if [ -d "$STEAM_PATH" ]; then
      echo "✅ Steam found at: $STEAM_PATH"
    else
      echo "❌ Steam not found at expected path"
      echo "   Expected: $STEAM_PATH"
    fi
    
    # Check Stardew Valley
    if [ -d "$GAME_PATH" ]; then
      echo "✅ Stardew Valley found"
    else
      echo "❌ Stardew Valley not found at: $GAME_PATH"
    fi
    
    # Check SMAPI
    if [ -f "$GAME_PATH/StardewModdingAPI.exe" ]; then
      echo "✅ SMAPI installed"
    else
      echo "⚠️  SMAPI not found (install via Vortex)"
    fi
    
    # Check Mods folder
    if [ -d "$GAME_PATH/Mods" ]; then
      MOD_COUNT=$(ls -1d "$GAME_PATH/Mods"/*/ 2>/dev/null | wc -l)
      echo "✅ Mods folder exists ($MOD_COUNT mods installed)"
    else
      echo "⚠️  Mods folder doesn't exist"
    fi
    
    # Check STL
    if command -v steamtinkerlaunch &> /dev/null; then
      echo "✅ steam-tinker-launch available"
    else
      echo "❌ steam-tinker-launch not in PATH"
    fi
    
    # Check STL config
    STL_CONF="${stlConfigDir}/global.conf"
    if [ -f "$STL_CONF" ]; then
      if [ -L "$STL_CONF" ]; then
        echo "⚠️  STL config is a symlink (run stardew-modding-setup to fix)"
      elif [ -w "$STL_CONF" ]; then
        echo "✅ STL config exists and is writable"
      else
        echo "⚠️  STL config exists but is read-only"
      fi
    else
      echo "⚠️  STL config not found (run stardew-modding-setup)"
    fi
    
    # Check Steam compat tool
    STL_COMPAT="${cfg.steamPath}/compatibilitytools.d/SteamTinkerLaunch"
    if [ -d "$STL_COMPAT" ] && [ -f "$STL_COMPAT/proton" ]; then
      echo "✅ STL registered as Steam compatibility tool"
    else
      echo "⚠️  STL not registered with Steam (run stardew-modding-setup)"
    fi
    
    # Check Vortex
    VORTEX_EXE="${stlConfigDir}/vortex/compatdata/pfx/drive_c/Program Files/Black Tree Gaming Ltd/Vortex/Vortex.exe"
    if [ -f "$VORTEX_EXE" ]; then
      echo "✅ Vortex installed in STL prefix"
    else
      echo "⚠️  Vortex not found (install via STL menu)"
    fi
    
    echo ""
    echo "Run 'stardew-modding-setup' to fix any issues."
  '';

  # Sync mods locally (for sharing with Evie)
  syncLocalScript = pkgs.writeShellScriptBin "stardew-sync-local" ''
    #!/usr/bin/env bash
    # Sync Stardew Valley mods over local network
    # Usage: stardew-sync-local user@host [--dry-run] [--include-saves] [--reverse]
    
    set -e
    
    if [ $# -lt 1 ]; then
      echo "Usage: stardew-sync-local user@host [options]"
      echo ""
      echo "Options:"
      echo "  --dry-run        Show what would be transferred"
      echo "  --include-saves  Also sync save files"
      echo "  --reverse        Pull mods FROM remote instead of pushing"
      exit 1
    fi
    
    TARGET="$1"
    shift
    
    DRY_RUN=""
    INCLUDE_SAVES=""
    REVERSE=""
    
    while [ $# -gt 0 ]; do
      case "$1" in
        --dry-run) DRY_RUN="--dry-run" ;;
        --include-saves) INCLUDE_SAVES="1" ;;
        --reverse) REVERSE="1" ;;
        *) echo "Unknown option: $1"; exit 1 ;;
      esac
      shift
    done
    
    LOCAL_MODS="${gamePath}/Mods/"
    REMOTE_MODS="~/.local/share/Steam/steamapps/common/Stardew Valley/Mods/"
    
    if [ -n "$REVERSE" ]; then
      echo "🔄 Pulling mods FROM $TARGET..."
      ${pkgs.rsync}/bin/rsync -avz --progress $DRY_RUN \
        "$TARGET:$REMOTE_MODS" "$LOCAL_MODS"
    else
      echo "🔄 Pushing mods TO $TARGET..."
      ${pkgs.rsync}/bin/rsync -avz --progress $DRY_RUN \
        "$LOCAL_MODS" "$TARGET:$REMOTE_MODS"
    fi
    
    if [ -n "$INCLUDE_SAVES" ]; then
      LOCAL_SAVES="${config.home.homeDirectory}/.config/StardewValley/Saves/"
      REMOTE_SAVES="~/.config/StardewValley/Saves/"
      
      if [ -n "$REVERSE" ]; then
        echo "🔄 Pulling saves FROM $TARGET..."
        ${pkgs.rsync}/bin/rsync -avz --progress $DRY_RUN \
          "$TARGET:$REMOTE_SAVES" "$LOCAL_SAVES"
      else
        echo "🔄 Pushing saves TO $TARGET..."
        ${pkgs.rsync}/bin/rsync -avz --progress $DRY_RUN \
          "$LOCAL_SAVES" "$TARGET:$REMOTE_SAVES"
      fi
    fi
    
    echo "✅ Sync complete!"
  '';

in
{
  options.programs.stardew-modding = {
    enable = lib.mkEnableOption "Stardew Valley modding environment";

    steamPath = lib.mkOption {
      type = lib.types.str;
      default = defaultSteamPath;
      description = "Path to Steam installation directory";
    };

    enableVortex = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable Vortex mod manager via steam-tinker-launch";
    };

    skipIntDepCheck = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''  
        Skip STL internal dependency checks (required on NixOS).
        NixOS paths confuse STL's checks for things like unzip which
        are actually available in the Nix profile.
      '';
    };

    backupDir = lib.mkOption {
      type = lib.types.str;
      default = "${config.home.homeDirectory}/StardewBackups";
      description = "Directory for mod backups and sync staging";
    };

    syncToCloud = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable automatic sync to cloud storage (OneDrive/Google Drive)";
    };

    cloudPath = lib.mkOption {
      type = lib.types.str;
      default = "${config.home.homeDirectory}/OneDrive/StardewMods";
      description = "Cloud storage path for mod sharing";
    };
  };

  config = lib.mkIf cfg.enable {
    # ═══════════════════════════════════════════════════════════════════════
    # PACKAGES - Core modding tools
    # ═══════════════════════════════════════════════════════════════════════
    home.packages = with pkgs; [
      # Steam Tinker Launch - Windows tool wrapper
      steamtinkerlaunch
      
      # Required for STL GUI
      yad
      
      # Archive tools for mod extraction
      p7zip
      unzip
      
      # Sync tools
      rsync
      rclone
      
      # Nushell for scripting (Tier 1 language)
      nushell
      
      # Our setup/check scripts
      setupScript
      checkScript
      syncLocalScript
    ];

    # ═══════════════════════════════════════════════════════════════════════
    # ACTIVATION SCRIPT - Run setup on home-manager switch
    # ═══════════════════════════════════════════════════════════════════════
    # This runs stardew-modding-setup automatically during activation,
    # creating writable configs instead of symlinks
    home.activation.stardewModdingSetup = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      # Only run if Steam exists (don't fail activation if Steam not installed yet)
      if [ -d "${cfg.steamPath}" ]; then
        $DRY_RUN_CMD ${setupScript}/bin/stardew-modding-setup || true
      fi
    '';

    # ═══════════════════════════════════════════════════════════════════════
    # SHELL ALIASES
    # ═══════════════════════════════════════════════════════════════════════
    programs.zsh.shellAliases = lib.mkIf config.programs.zsh.enable {
      # Quick access to Stardew mods folder
      "stardew-mods" = "cd '${gamePath}/Mods'";
      
      # Backup mods
      "stardew-backup" = "${pkgs.rsync}/bin/rsync -av --progress '${gamePath}/Mods/' '${cfg.backupDir}/'";
      
      # Restore mods from backup
      "stardew-restore" = "${pkgs.rsync}/bin/rsync -av --progress '${cfg.backupDir}/' '${gamePath}/Mods/'";
      
      # Check/setup commands
      "stardew-check" = "stardew-check-setup";
      "stardew-setup" = "stardew-modding-setup";
    };

    # Also add to bash if used
    programs.bash.shellAliases = lib.mkIf config.programs.bash.enable {
      "stardew-mods" = "cd '${gamePath}/Mods'";
      "stardew-backup" = "${pkgs.rsync}/bin/rsync -av --progress '${gamePath}/Mods/' '${cfg.backupDir}/'";
      "stardew-restore" = "${pkgs.rsync}/bin/rsync -av --progress '${cfg.backupDir}/' '${gamePath}/Mods/'";
      "stardew-check" = "stardew-check-setup";
      "stardew-setup" = "stardew-modding-setup";
    };

    # ═══════════════════════════════════════════════════════════════════════
    # SYSTEMD USER SERVICE - Optional Cloud Sync
    # ═══════════════════════════════════════════════════════════════════════
    systemd.user.services.stardew-mod-sync = lib.mkIf cfg.syncToCloud {
      Unit = {
        Description = "Stardew Valley Mod Sync to Cloud";
        After = [ "network-online.target" ];
      };

      Service = {
        Type = "oneshot";
        ExecStart = ''
          ${pkgs.rsync}/bin/rsync -av --delete \
            '${gamePath}/Mods/' \
            '${cfg.cloudPath}/'
        '';
      };
    };

    # Timer for periodic sync (daily)
    systemd.user.timers.stardew-mod-sync = lib.mkIf cfg.syncToCloud {
      Unit.Description = "Daily Stardew Valley Mod Sync";
      Timer = {
        OnCalendar = "daily";
        Persistent = true;
      };
      Install.WantedBy = [ "timers.target" ];
    };

    # ═══════════════════════════════════════════════════════════════════════
    # XDG MIME - NXM Link Handler
    # ═══════════════════════════════════════════════════════════════════════
    # Register handler for nxm:// links (Nexus Mods one-click install)
    xdg.mimeApps.defaultApplications = {
      "x-scheme-handler/nxm" = "steamtinkerlaunch.desktop";
    };
    
    # Desktop file for NXM handler
    xdg.desktopEntries.steamtinkerlaunch-nxm = {
      name = "Steam Tinker Launch (NXM Handler)";
      comment = "Handle Nexus Mods one-click downloads";
      exec = "${pkgs.steamtinkerlaunch}/bin/steamtinkerlaunch nxm %u";
      terminal = false;
      type = "Application";
      categories = [ "Game" ];
      mimeType = [ "x-scheme-handler/nxm" ];
      noDisplay = true;
    };
  };
}
