# NixOS Module for Stardew Valley Modding
# System-wide configuration for steam-tinker-launch visibility
#
# Usage in configuration.nix:
#   imports = [ inputs.stardew-modding.nixosModules.default ];
#   services.stardew-modding.enable = true;

{ config, lib, pkgs, ... }:

let
  cfg = config.services.stardew-modding;
in
{
  options.services.stardew-modding = {
    enable = lib.mkEnableOption "Stardew Valley modding system support";

    users = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      example = [ "e421" "evie" ];
      description = ''  
        Users to configure STL symlinks for.
        Each user will get Steam compatibility tool symlinks.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    # ═══════════════════════════════════════════════════════════════════════
    # SYSTEM PACKAGES
    # ═══════════════════════════════════════════════════════════════════════
    environment.systemPackages = with pkgs; [
      steamtinkerlaunch
      yad
      p7zip
      unzip
    ];

    # ═══════════════════════════════════════════════════════════════════════
    # STEAM COMPATIBILITY TOOLS SYMLINKS
    # ═══════════════════════════════════════════════════════════════════════
    # Create symlinks for each user to make STL visible in Steam
    system.activationScripts.stardew-modding = {
      text = lib.concatMapStringsSep "\n" (user: ''
        mkdir -p /home/${user}/.local/share/Steam/compatibilitytools.d/
        ln -sfn ${pkgs.steamtinkerlaunch}/bin/steamtinkerlaunch \
          /home/${user}/.local/share/Steam/compatibilitytools.d/SteamTinkerLaunch
        chown -R ${user}:users /home/${user}/.local/share/Steam/compatibilitytools.d/
      '') cfg.users;
    };
  };
}
