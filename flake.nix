# Stardew Valley Modding Environment - NixOS Flake
# Reproducible modding with steam-tinker-launch + Vortex
#
# Usage:
#   Home Manager (recommended): Add to your flake inputs and import the module
#   Standalone: nix develop (enters dev shell with all tools)
#   System-wide: Import nixosModule into your configuration
#
# Target collections:
#   - Stardew Valley VERY Expanded (https://www.nexusmods.com/games/stardewvalley/collections/tckf0m)
#   - Fairycore (https://www.nexusmods.com/games/stardewvalley/collections/tjvl0j)

{
  description = "Reproducible Stardew Valley modding environment for NixOS";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    
    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # For users who want to use this with their existing homelab flake
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs = inputs @ { nixpkgs, home-manager, flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" ];

      flake = {
        # ═══════════════════════════════════════════════════════════════════════
        # HOME MANAGER MODULE - Recommended for NixOS users
        # ═══════════════════════════════════════════════════════════════════════
        # Import into your home.nix:
        #   imports = [ inputs.stardew-modding.homeManagerModules.default ];
        #   programs.stardew-modding.enable = true;
        homeManagerModules.default = ./home-manager/stardew-modding.nix;

        # ═══════════════════════════════════════════════════════════════════════
        # NIXOS MODULE - System-wide configuration
        # ═══════════════════════════════════════════════════════════════════════
        # For users who want system-level integration
        nixosModules.default = ./nixos/stardew-modding.nix;
      };

      perSystem = { pkgs, system, ... }: {
        # ═══════════════════════════════════════════════════════════════════════
        # DEVELOPMENT SHELL - Standalone usage
        # ═══════════════════════════════════════════════════════════════════════
        # Enter with: nix develop
        devShells.default = pkgs.mkShell {
          name = "stardew-modding";
          
          packages = with pkgs; [
            # Core modding tools
            steamtinkerlaunch  # Windows tool wrapper for Steam/Proton
            yad                # GUI dialogs for STL
            
            # Mod management
            p7zip              # Archive extraction
            unzip
            
            # Sync tools (for sharing with Windows friends)
            rsync
            rclone             # Cloud sync (OneDrive, Google Drive)
            
            # Shell scripting (Tier 1 language per homelab standards)
            nushell
          ];

          shellHook = ''
            echo "🌾 Stardew Valley Modding Environment"
            echo ""
            echo "Available commands:"
            echo "  steamtinkerlaunch  - Launch STL configuration"
            echo "  nu sync-mods.nu    - Sync mods with backup location"
            echo ""
            echo "Steam game path (typical): ~/.local/share/Steam/steamapps/common/Stardew Valley"
            echo ""
          '';
        };

        # ═══════════════════════════════════════════════════════════════════════
        # PACKAGES - Convenience wrappers
        # ═══════════════════════════════════════════════════════════════════════
        packages = {
          # Mod sync script as a package
          sync-mods = pkgs.writeShellScriptBin "stardew-sync-mods" ''
            ${pkgs.nushell}/bin/nu ${./scripts/sync-mods.nu} "$@"
          '';

          # Quick setup check
          check-setup = pkgs.writeShellScriptBin "stardew-check-setup" ''
            echo "Checking Stardew Valley modding setup..."
            echo ""
            
            STEAM_PATH="$HOME/.local/share/Steam/steamapps/common/Stardew Valley"
            
            if [ -d "$STEAM_PATH" ]; then
              echo "✅ Stardew Valley found at: $STEAM_PATH"
            else
              echo "❌ Stardew Valley not found at expected path"
              echo "   Expected: $STEAM_PATH"
            fi
            
            if [ -d "$STEAM_PATH/Mods" ]; then
              MOD_COUNT=$(ls -1 "$STEAM_PATH/Mods" 2>/dev/null | wc -l)
              echo "✅ Mods folder exists ($MOD_COUNT mods installed)"
            else
              echo "⚠️  Mods folder does not exist (SMAPI not installed yet?)"
            fi
            
            if command -v steamtinkerlaunch &> /dev/null; then
              echo "✅ steam-tinker-launch available"
            else
              echo "❌ steam-tinker-launch not found in PATH"
            fi
            
            if [ -f "$HOME/.config/steamtinkerlaunch/global.conf" ]; then
              echo "✅ STL global config exists"
            else
              echo "⚠️  STL global config not found (first run will create it)"
            fi
            
            echo ""
            echo "Setup complete! See README.md for next steps."
          '';
        };
      };
    };
}
