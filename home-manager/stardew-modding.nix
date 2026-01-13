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
    ];

    # ═══════════════════════════════════════════════════════════════════════
    # STEAM COMPATIBILITY TOOLS DIRECTORY
    # ═══════════════════════════════════════════════════════════════════════
    # Steam needs a directory with compatibilitytool.vdf + the script
    # This creates the proper structure for Steam to recognize STL
    
    # The toolmanifest.vdf file that Steam requires
    home.file.".local/share/Steam/compatibilitytools.d/SteamTinkerLaunch/toolmanifest.vdf".text = ''
      "manifest"
      {
        "version" "2"
        "commandline" "/proton %verb%"
      }
    '';
    
    # The compatibilitytool.vdf that makes it show in Steam's dropdown
    home.file.".local/share/Steam/compatibilitytools.d/SteamTinkerLaunch/compatibilitytool.vdf".text = ''
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
    '';
    
    # The actual STL script (renamed to 'proton' as Steam calls it via %verb%)
    home.file.".local/share/Steam/compatibilitytools.d/SteamTinkerLaunch/proton" = {
      source = "${pkgs.steamtinkerlaunch}/bin/steamtinkerlaunch";
      executable = true;
    };

    # ═══════════════════════════════════════════════════════════════════════
    # STL GLOBAL CONFIGURATION
    # ═══════════════════════════════════════════════════════════════════════
    # Pre-configured for NixOS compatibility
    home.file.".config/steamtinkerlaunch/global.conf".text = ''
      # Steam Tinker Launch - Global Configuration
      # Managed by Home Manager (stardew-modding-nix)
      #
      # Manual edits will be overwritten on next home-manager switch!
      # To customize, modify your home.nix configuration.

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
      # Show STL menu on game launch
      STARTGAME="0"
      
      # Enable notifications
      USENOTIFY="1"
      
      # Wine/Proton settings (STL handles this automatically)
      USEPROCHOICE="1"
    '';

    # ═══════════════════════════════════════════════════════════════════════
    # STARDEW-SPECIFIC STL CONFIG
    # ═══════════════════════════════════════════════════════════════════════
    # Game ID: 413150 (Stardew Valley)
    home.file.".config/steamtinkerlaunch/gamecfgs/413150.conf".text = ''
      # Stardew Valley - Steam Tinker Launch Configuration
      # Game ID: 413150
      
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

    # ═══════════════════════════════════════════════════════════════════════
    # SHELL ALIASES
    # ═══════════════════════════════════════════════════════════════════════
    programs.zsh.shellAliases = lib.mkIf config.programs.zsh.enable {
      # Quick access to Stardew mods folder
      "stardew-mods" = "cd '${gamePath}/Mods'";
      
      # Backup mods
      "stardew-backup" = "rsync -av --progress '${gamePath}/Mods/' '${cfg.backupDir}/'";
      
      # Restore mods from backup
      "stardew-restore" = "rsync -av --progress '${cfg.backupDir}/' '${gamePath}/Mods/'";
      
      # Check STL setup
      "stardew-check" = "steamtinkerlaunch checkaliases && echo 'STL ready!'";
    };

    # Also add to bash if used
    programs.bash.shellAliases = lib.mkIf config.programs.bash.enable {
      "stardew-mods" = "cd '${gamePath}/Mods'";
      "stardew-backup" = "rsync -av --progress '${gamePath}/Mods/' '${cfg.backupDir}/'";
      "stardew-restore" = "rsync -av --progress '${cfg.backupDir}/' '${gamePath}/Mods/'";
      "stardew-check" = "steamtinkerlaunch checkaliases && echo 'STL ready!'";
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
  };
}
