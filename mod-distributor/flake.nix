{
  description = "Stardew Valley Mod Distributor - Phoenix LiveView Application";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        
        # Elixir/Erlang versions
        erlang = pkgs.erlang_27;
        elixir = pkgs.elixir_1_17;
        
        # Node for asset building (TailwindCSS)
        nodejs = pkgs.nodejs_22;
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = [
            erlang
            elixir
            nodejs
            
            # Build tools
            pkgs.gnumake
            pkgs.gcc
            
            # File watching for dev
            pkgs.inotify-tools
            
            # Useful CLI tools
            pkgs.jq
            pkgs.p7zip
            pkgs.zip
            pkgs.unzip
          ];

          shellHook = ''
            # Set up hex and rebar locally
            export MIX_HOME="$PWD/.mix"
            export HEX_HOME="$PWD/.hex"
            export PATH="$MIX_HOME/bin:$HEX_HOME/bin:$PATH"
            
            # Install hex and rebar if not present
            if [ ! -d "$MIX_HOME" ]; then
              echo "Setting up Elixir development environment..."
              mix local.hex --force --if-missing
              mix local.rebar --force --if-missing
            fi
            
            echo ""
            echo "🌾 Stardew Mod Distributor Development Environment"
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo "Elixir:  $(elixir --version | head -1)"
            echo "Erlang:  $(erl -eval 'io:fwrite(\"~s~n\", [erlang:system_info(otp_release)]), halt().' -noshell)"
            echo "Node:    $(node --version)"
            echo ""
            echo "Commands:"
            echo "  mix deps.get      - Install dependencies"
            echo "  mix phx.server    - Start development server"
            echo "  mix test          - Run tests"
            echo "  iex -S mix        - Interactive Elixir shell"
            echo ""
          '';
        };

        # Production package (for deployment)
        packages.default = pkgs.beamPackages.mixRelease {
          pname = "mod_distributor";
          version = "0.1.0";
          src = ./.;
          
          mixFodDeps = pkgs.beamPackages.fetchMixDeps {
            pname = "mod-distributor-deps";
            version = "0.1.0";
            src = ./.;
            sha256 = pkgs.lib.fakeSha256; # Will need to be updated after first build
          };
        };
      }
    );
}

