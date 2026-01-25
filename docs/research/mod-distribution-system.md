# Stardew Mod Distribution System

## Overview

A self-hosted web application that allows Jared, Ashley, and others to easily download and install the curated Stardew Valley modpack without needing technical knowledge.

## Goals

1. **Simple**: Non-technical users can get mods installed in minutes
2. **Reliable**: Works consistently, no manual file hunting
3. **Maintainable**: Easy for us to update mods and push changes
4. **Secure**: Accessible only via Tailscale or local network

---

## Architecture Options

### Option A: Framework Laptop as Web Host (Recommended)

```
┌─────────────────────────────────────────────────────────────┐
│                    Framework Laptop                          │
│  ┌─────────────────────────────────────────────────────┐    │
│  │              Mod Distribution Server                 │    │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  │    │
│  │  │  Web UI     │  │  API        │  │  Mod Files  │  │    │
│  │  │  (Phoenix/  │  │  (REST)     │  │  Storage    │  │    │
│  │  │   FastAPI)  │  │             │  │             │  │    │
│  │  └─────────────┘  └─────────────┘  └─────────────┘  │    │
│  └─────────────────────────────────────────────────────┘    │
│                           ▲                                  │
└───────────────────────────┼──────────────────────────────────┘
                            │ Tailscale
        ┌───────────────────┼───────────────────┐
        │                   │                   │
        ▼                   ▼                   ▼
   ┌─────────┐        ┌─────────┐        ┌─────────┐
   │ Jared's │        │Ashley's │        │  Your   │
   │   PC    │        │   PC    │        │   PC    │
   └─────────┘        └─────────┘        └─────────┘
```

**Pros:**
- Framework is lightweight, low power
- Already part of Tailscale network
- NixOS makes deployment reproducible
- Can run headless when needed

**Cons:**
- Framework needs to be online for others to access
- Limited storage (but mods are small, ~5-10GB total)

### Option B: NAS-Based Distribution

```
┌─────────────────────────────────────────────────────────────┐
│                         NAS                                  │
│  ┌─────────────────────────────────────────────────────┐    │
│  │     SMB Share: \\nas\stardew-mods                   │    │
│  │     or HTTP: http://nas.local/stardew/              │    │
│  └─────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────┘
```

**Pros:**
- Always on
- More storage

**Cons:**
- Needs web server setup on NAS
- May not have nice UI capabilities
- SMB requires more client setup

### Recommendation: **Option A** with NAS as backup storage

---

## User Experience Flow

### For End Users (Jared/Ashley)

1. **Access the Web UI**
   - Navigate to `http://framework.tailscale:8080` (or Tailscale IP)
   - See a clean, friendly interface

2. **Choose Installation Type**
   - "Full Modpack" - Everything pre-configured
   - "Custom Selection" - Pick specific mods

3. **Download**
   - Click "Download Modpack"
   - Get a single ZIP file with correct folder structure

4. **Install**
   - Guided instructions shown on screen
   - "Extract to your Stardew Valley folder"
   - Or: Run included installer script

5. **Verify**
   - "Test Your Installation" button
   - Checklist of what should work

### Advanced: One-Click Installer

For Windows users, we could provide a small installer that:
1. Detects Steam/GOG Stardew installation
2. Backs up existing mods
3. Extracts new mods to correct location
4. Verifies installation

---

## Technical Implementation

### Tech Stack Options

#### Option 1: Elixir Phoenix (Recommended)

```elixir
# Ideal for:
# - Fault-tolerant, long-running service
# - Real-time updates (LiveView)
# - Hot code reloading
# - Excellent for the homelab ecosystem

# Structure:
# lib/
#   mod_distributor/
#     mods.ex          # Mod catalog management
#     packager.ex      # ZIP generation
#     installer.ex     # Installation scripts
#   mod_distributor_web/
#     live/
#       mod_browser_live.ex
#       download_live.ex
```

#### Option 2: Python FastAPI + HTMX

```python
# Ideal for:
# - Rapid prototyping
# - Simple deployment
# - Easy to maintain

# Structure:
# src/
#   main.py           # FastAPI app
#   mods.py           # Mod catalog
#   packager.py       # ZIP generation
#   templates/        # Jinja2 + HTMX
```

#### Option 3: Rust Axum + Leptos

```rust
// Ideal for:
// - Maximum performance
// - Type safety
// - Single binary deployment

// Overkill for this use case, but cool
```

### Recommended: **Elixir Phoenix** (fits homelab philosophy)

---

## Data Model

### Mod Catalog (JSON/Database)

```json
{
  "modpack_version": "1.0.0",
  "game_version": "1.6.15",
  "smapi_version": "4.1.0",
  "mods": [
    {
      "id": "Pathoschild.ContentPatcher",
      "name": "Content Patcher",
      "version": "2.0.0",
      "author": "Pathoschild",
      "category": "framework",
      "required": true,
      "nexus_id": 1915,
      "dependencies": ["SMAPI"],
      "file_path": "mods/ContentPatcher/",
      "description": "Loads content packs without replacing XNB files"
    },
    {
      "id": "FlashShifter.SVE",
      "name": "Stardew Valley Expanded",
      "version": "1.14.0",
      "author": "FlashShifter",
      "category": "expansion",
      "required": false,
      "nexus_id": 3753,
      "dependencies": [
        "Pathoschild.ContentPatcher",
        "EscaMMC.FarmTypeManager"
      ],
      "file_path": "mods/StardewValleyExpanded/",
      "description": "The largest content expansion"
    }
  ],
  "presets": {
    "full": ["all mods"],
    "core": ["frameworks + SVE + RSV + ES"],
    "minimal": ["frameworks + QoL only"]
  }
}
```

### Mod File Storage

```
/srv/stardew-mods/
├── catalog.json           # Mod metadata
├── SMAPI/
│   └── SMAPI-4.1.0.zip
├── frameworks/
│   ├── ContentPatcher/
│   ├── GMCM/
│   ├── SpaceCore/
│   └── ...
├── expansions/
│   ├── StardewValleyExpanded/
│   ├── RidgesideVillage/
│   ├── EastScarp/
│   └── ...
├── qol/
│   ├── LookupAnything/
│   ├── NPCMapLocations/
│   └── ...
└── presets/
    ├── full-mega-expanded.zip      # Pre-built complete pack
    ├── core-expansions.zip
    └── minimal-qol.zip
```

---

## Web UI Design

### Home Page

```
┌─────────────────────────────────────────────────────────────┐
│  🌾 Stardew Valley Modpack Distributor                      │
│                                                             │
│  Welcome! This tool helps you install our curated           │
│  Stardew Valley modpack with ease.                          │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │                                                     │   │
│  │   [ 📦 Download Full Modpack ]                     │   │
│  │                                                     │   │
│  │   500+ mods, pre-configured and tested             │   │
│  │   Version: 1.0.0 | Game: 1.6.15 | Size: ~8GB       │   │
│  │                                                     │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  Or choose a preset:                                        │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │ Core Only    │  │ SVE + QoL    │  │ Custom       │      │
│  │ ~200 mods    │  │ ~150 mods    │  │ Pick & Mix   │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
│                                                             │
│  📋 Installation Guide  |  🔧 Troubleshooting  |  📝 Notes │
└─────────────────────────────────────────────────────────────┘
```

### Download Page

```
┌─────────────────────────────────────────────────────────────┐
│  Preparing Your Download...                                 │
│                                                             │
│  ████████████████████████░░░░░░░░░  75%                    │
│  Packaging: StardewValleyExpanded                          │
│                                                             │
│  Selected: 522 mods (8.2 GB)                               │
│                                                             │
│  [Cancel]                                                   │
└─────────────────────────────────────────────────────────────┘
```

### Installation Guide

```
┌─────────────────────────────────────────────────────────────┐
│  Installation Instructions                                  │
│                                                             │
│  Step 1: Locate Your Game                                  │
│  ─────────────────────────                                 │
│  Steam: Right-click Stardew Valley → Properties →          │
│         Local Files → Browse                               │
│                                                             │
│  Typical location:                                          │
│  C:\Program Files (x86)\Steam\steamapps\common\            │
│  Stardew Valley                                            │
│                                                             │
│  Step 2: Extract the Modpack                               │
│  ─────────────────────────────                             │
│  Extract the downloaded ZIP directly into your             │
│  Stardew Valley folder. Say "Yes" to overwrite.           │
│                                                             │
│  Step 3: Launch the Game                                   │
│  ─────────────────────────                                 │
│  Launch via "StardewModdingAPI.exe" (not the regular       │
│  Stardew Valley.exe)                                       │
│                                                             │
│  Step 4: Configure (Optional)                              │
│  ─────────────────────────────                             │
│  Press Escape → Mod Options (scroll down)                  │
│  Adjust settings via GMCM                                  │
│                                                             │
│  [Watch Video Tutorial]  [Common Issues]                   │
└─────────────────────────────────────────────────────────────┘
```

---

## Implementation Plan

### Phase 1: Basic File Server (MVP)

1. [ ] Set up simple HTTP file server on Framework
2. [ ] Organize mods into proper folder structure
3. [ ] Create pre-built ZIP packages
4. [ ] Basic HTML page with download links
5. [ ] Test with Jared/Ashley

### Phase 2: Web UI

1. [ ] Create Phoenix/FastAPI application
2. [ ] Implement mod catalog system
3. [ ] Build download page with progress
4. [ ] Add installation guide pages
5. [ ] Deploy to Framework via NixOS

### Phase 3: Enhanced Features

1. [ ] Custom mod selection UI
2. [ ] Automatic update notifications
3. [ ] Version tracking
4. [ ] One-click Windows installer
5. [ ] Sync with NAS for redundancy

---

## NixOS Deployment

### Framework Configuration

```nix
# In Framework's NixOS config
{ config, pkgs, ... }:

{
  # Stardew mod distribution service
  services.stardew-mod-distributor = {
    enable = true;
    port = 8080;
    modPath = "/srv/stardew-mods";
    
    # Only accessible via Tailscale
    openFirewall = false;
  };

  # Ensure Tailscale is running
  services.tailscale.enable = true;

  # Storage location
  fileSystems."/srv/stardew-mods" = {
    device = "/dev/disk/by-label/stardew";
    fsType = "ext4";
  };
}
```

### Tailscale Access

Users access via:
- `http://framework:8080` (if DNS configured)
- `http://100.x.x.x:8080` (Tailscale IP)
- `http://framework.tailnet-name.ts.net:8080` (MagicDNS)

---

## Security Considerations

1. **Tailscale Only**: No public internet exposure
2. **Read-Only**: Users can only download, not modify
3. **No Authentication Needed**: Tailscale provides identity
4. **Audit Logging**: Track who downloads what (optional)

---

## Next Steps

1. [ ] Decide on tech stack (Elixir vs Python)
2. [ ] Set up basic file structure on Framework
3. [ ] Create initial mod catalog JSON
4. [ ] Build MVP file server
5. [ ] Test with real users
6. [ ] Iterate based on feedback

