# Stardew Mod Distributor

A self-hosted Elixir Phoenix application for distributing Stardew Valley modpacks to friends via Tailscale.

## Features

- 🌾 Beautiful, Stardew-themed web interface
- 📦 Pre-built modpack presets (Full, Core, Minimal)
- 🔍 Browse and select individual mods
- ⬇️ Real-time progress during package building
- 📖 Built-in installation guide
- 🔒 Secure access via Tailscale network
- 🔄 LiveView for instant UI updates

## Quick Start

### Development

```bash
# Enter development environment
nix develop

# Install dependencies
mix deps.get
mix setup

# Start the development server
mix phx.server
# or
iex -S mix phx.server
```

Visit http://localhost:4000

### Production (Framework Laptop)

```bash
# Build the release
MIX_ENV=prod mix release

# Or use the NixOS module (see below)
```

## Project Structure

```
mod-distributor/
├── lib/
│   ├── mod_distributor/           # Business logic
│   │   ├── application.ex         # OTP application
│   │   ├── catalog.ex             # Mod metadata management
│   │   └── packager.ex            # ZIP package creation
│   └── mod_distributor_web/       # Web interface
│       ├── components/            # Shared UI components
│       ├── controllers/           # API controllers
│       └── live/                  # LiveView pages
├── priv/
│   ├── catalog.json               # Mod catalog data
│   └── mods/                      # Actual mod files (gitignored)
├── assets/                        # CSS, JS, Tailwind
├── config/                        # Configuration files
├── flake.nix                      # Nix development environment
└── mix.exs                        # Elixir project file
```

## Configuration

### Adding Mods

1. Add mod files to `priv/mods/` following the structure:
   ```
   priv/mods/
   ├── ContentPatcher/
   │   ├── ContentPatcher.dll
   │   └── manifest.json
   └── StardewValleyExpanded/
       ├── ...
   ```

2. Update `priv/catalog.json` with mod metadata

3. Optionally add to presets

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `SECRET_KEY_BASE` | Phoenix secret (required in prod) | - |
| `PHX_HOST` | Host for URL generation | `localhost` |
| `PORT` | HTTP port | `8080` |
| `MOD_STORAGE_PATH` | Path to mod files | `/srv/stardew-mods` |

## NixOS Deployment

Add to your Framework laptop's configuration:

```nix
{ config, pkgs, ... }:

{
  # Import the module
  imports = [ ./path/to/mod-distributor/nixos-module.nix ];

  # Enable the service
  services.stardew-mod-distributor = {
    enable = true;
    port = 8080;
    modPath = "/srv/stardew-mods";
  };
}
```

## API

### GET /api/catalog
Returns all mod metadata and catalog info.

### GET /api/catalog/:mod_id
Returns metadata for a specific mod.

### GET /api/presets
Returns available mod presets.

### GET /api/packages
Returns list of pre-built packages.

### POST /api/packages/build
Builds a package. Body: `{"preset": "full"}` or `{"mod_ids": ["mod1", "mod2"]}`

## Tech Stack

- **Elixir 1.17+** - Functional programming language
- **Phoenix 1.7+** - Web framework
- **Phoenix LiveView** - Real-time UI
- **Tailwind CSS** - Styling
- **Bandit** - HTTP server
- **Nix** - Reproducible builds

## Development

### Running Tests

```bash
mix test
```

### Code Quality

```bash
mix credo
mix format --check-formatted
```

## License

MIT - Feel free to use and modify for your own modding communities!

---

Made with 💛 for cozy co-op gaming nights

