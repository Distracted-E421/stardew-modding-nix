#!/usr/bin/env nu

# Download critical mod updates for Stardew Valley
# These mods are broken in the current installation and need fresh downloads

const MODS_DIR = "~/.local/share/Steam/steamapps/common/Stardew Valley/Mods" | path expand
const DOWNLOAD_DIR = "~/StardewMods/critical-updates" | path expand

# Critical mods that need updating with their Nexus URLs
# Format: { name, nexus_id, nexus_url, notes }
const CRITICAL_MODS = [
    { 
        name: "Ridgeside Village", 
        nexus_id: 7286, 
        current: "2.5.0",
        latest: "2.5.16",
        notes: "SMAPI component incompatible - major expansion mod"
    },
    {
        name: "Get Glam",
        nexus_id: 5044,
        current: "1.0.0",
        latest: "1.1.0+",
        notes: "Causes character appearance issues (bald/no arms)"
    },
    {
        name: "Automate",
        nexus_id: 1063,
        current: "1.10.1",
        latest: "2.0.0+",
        notes: "Incompatible with SDV 1.6 API"
    },
    {
        name: "Chests Anywhere",
        nexus_id: 518,
        current: "1.13.0", 
        latest: "2.0.0+",
        notes: "Incompatible with SDV 1.6 API"
    },
    {
        name: "Better Crafting",
        nexus_id: 11115,
        current: "0.9.0",
        latest: "1.0.0+",
        notes: "Incompatible with SDV 1.6 API"
    }
]

def banner [] {
    print "╔══════════════════════════════════════════════════════════════╗"
    print "║     🔄 Critical Mod Updates for Stardew Valley 🔄          ║"
    print "╚══════════════════════════════════════════════════════════════╝"
    print ""
}

def show-update-summary [] {
    print "📋 Mods Requiring Manual Download:"
    print ""
    
    $CRITICAL_MODS | each { |mod|
        print $"  🔴 ($mod.name)"
        print $"     Current: ($mod.current) → Latest: ($mod.latest)"
        print $"     Issue: ($mod.notes)"
        print $"     Download: https://www.nexusmods.com/stardewvalley/mods/($mod.nexus_id)"
        print ""
    }
    
    print "═══════════════════════════════════════════════════════════════"
    print ""
    print "📥 DOWNLOAD INSTRUCTIONS:"
    print ""
    print "1. Visit each Nexus Mods link above"
    print "2. Click 'Manual' download button"
    print "3. Save to: ~/StardewMods/critical-updates/"
    print "4. Run: nu scripts/install-updates.nu"
    print ""
    print "💡 OR with Nexus Premium, use API download:"
    print "   uv run scripts/nexus-api.py download 7286  # Ridgeside Village"
    print "   uv run scripts/nexus-api.py download 5044  # Get Glam"
    print ""
}

def check-existing-downloads [] {
    if not ($DOWNLOAD_DIR | path exists) {
        mkdir $DOWNLOAD_DIR
        print $"📁 Created download directory: ($DOWNLOAD_DIR)"
        return
    }
    
    let files = (ls $DOWNLOAD_DIR | where type == "file")
    if ($files | is-empty) {
        print "📭 No downloads found yet in ~/StardewMods/critical-updates/"
    } else {
        print "📦 Existing downloads:"
        $files | each { |f| print $"   - ($f.name | path basename)" }
    }
    print ""
}

def generate-download-commands [] {
    print ""
    print "🔧 Quick Download Commands (Nexus Premium required):"
    print ""
    
    $CRITICAL_MODS | each { |mod|
        print $"# ($mod.name)"
        print $"uv run scripts/nexus-api.py download ($mod.nexus_id)"
        print ""
    }
}

def main [] {
    banner
    check-existing-downloads
    show-update-summary
}

main

