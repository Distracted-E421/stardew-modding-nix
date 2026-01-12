#!/usr/bin/env nu
# Stardew Valley Mod Sync Script
# Syncs mods between local game folder, backups, and cloud storage
#
# Usage:
#   nu sync-mods.nu backup       # Backup mods to local backup dir
#   nu sync-mods.nu restore      # Restore mods from backup
#   nu sync-mods.nu export       # Create shareable zip for Windows friends
#   nu sync-mods.nu import <zip> # Import mods from Windows friend's zip
#   nu sync-mods.nu cloud push   # Push to cloud storage
#   nu sync-mods.nu cloud pull   # Pull from cloud storage
#   nu sync-mods.nu status       # Show current mod status

# ═══════════════════════════════════════════════════════════════════════════════
# CONFIGURATION
# ═══════════════════════════════════════════════════════════════════════════════

let config = {
    # Default paths (can be overridden via env vars)
    steam_path: ($env.STEAM_PATH? | default $"($env.HOME)/.local/share/Steam")
    game_name: "Stardew Valley"
    game_id: 413150
    backup_dir: ($env.STARDEW_BACKUP? | default $"($env.HOME)/StardewBackups")
    cloud_dir: ($env.STARDEW_CLOUD? | default $"($env.HOME)/OneDrive/StardewMods")
    export_dir: ($env.STARDEW_EXPORT? | default $"($env.HOME)/StardewExports")
}

# Derived paths
let game_path = $"($config.steam_path)/steamapps/common/($config.game_name)"
let mods_path = $"($game_path)/Mods"

# ═══════════════════════════════════════════════════════════════════════════════
# HELPER FUNCTIONS
# ═══════════════════════════════════════════════════════════════════════════════

def ensure-dir [path: string] {
    if not ($path | path exists) {
        mkdir $path
        print $"📁 Created directory: ($path)"
    }
}

def get-mod-count [path: string] -> int {
    if ($path | path exists) {
        ls $path | where type == "dir" | length
    } else {
        0
    }
}

def format-size [bytes: int] -> string {
    if $bytes < 1024 {
        $"($bytes) B"
    } else if $bytes < (1024 * 1024) {
        $"(($bytes / 1024) | math round --precision 1) KB"
    } else if $bytes < (1024 * 1024 * 1024) {
        $"(($bytes / 1024 / 1024) | math round --precision 1) MB"
    } else {
        $"(($bytes / 1024 / 1024 / 1024) | math round --precision 2) GB"
    }
}

# ═══════════════════════════════════════════════════════════════════════════════
# COMMANDS
# ═══════════════════════════════════════════════════════════════════════════════

def "main status" [] {
    print "🌾 Stardew Valley Mod Status"
    print "═══════════════════════════════════════════════════════════════════════════════"
    print ""
    
    # Check game installation
    if ($game_path | path exists) {
        print $"✅ Game found: ($game_path)"
    } else {
        print $"❌ Game not found at: ($game_path)"
        print "   Set STEAM_PATH environment variable if using custom location"
        return
    }
    
    # Check mods folder
    if ($mods_path | path exists) {
        let mod_count = (get-mod-count $mods_path)
        print $"✅ Mods folder: ($mods_path)"
        print $"   📦 Mods installed: ($mod_count)"
        
        # List top-level mods
        if $mod_count > 0 {
            print ""
            print "   Installed mods:"
            ls $mods_path 
            | where type == "dir" 
            | sort-by name 
            | each { |it| print $"   • ($it.name)" }
        }
    } else {
        print "⚠️  Mods folder not found (SMAPI not installed yet?)"
    }
    
    # Check backup
    print ""
    if ($config.backup_dir | path exists) {
        let backup_count = (get-mod-count $config.backup_dir)
        print $"✅ Backup location: ($config.backup_dir)"
        print $"   📦 Backed up mods: ($backup_count)"
    } else {
        print $"⚠️  No backup found at: ($config.backup_dir)"
    }
    
    # Check cloud
    print ""
    if ($config.cloud_dir | path exists) {
        let cloud_count = (get-mod-count $config.cloud_dir)
        print $"✅ Cloud sync location: ($config.cloud_dir)"
        print $"   ☁️  Synced mods: ($cloud_count)"
    } else {
        print $"⚠️  Cloud folder not configured: ($config.cloud_dir)"
    }
    
    print ""
    print "═══════════════════════════════════════════════════════════════════════════════"
}

def "main backup" [] {
    print "🔄 Backing up Stardew Valley mods..."
    
    if not ($mods_path | path exists) {
        print "❌ Mods folder not found. Install SMAPI first!"
        return
    }
    
    ensure-dir $config.backup_dir
    
    let timestamp = (date now | format date "%Y%m%d_%H%M%S")
    let backup_path = $"($config.backup_dir)/mods_($timestamp)"
    
    print $"📁 Backing up to: ($backup_path)"
    
    # Use rsync for efficient incremental backup
    ^rsync -av --progress $"($mods_path)/" $backup_path
    
    let mod_count = (get-mod-count $backup_path)
    print ""
    print $"✅ Backup complete! ($mod_count) mods backed up"
    print $"   Location: ($backup_path)"
}

def "main restore" [] {
    print "🔄 Restoring Stardew Valley mods from backup..."
    
    if not ($config.backup_dir | path exists) {
        print "❌ No backups found!"
        return
    }
    
    # Find latest backup
    let backups = (ls $config.backup_dir 
        | where type == "dir" 
        | where name =~ "mods_"
        | sort-by modified 
        | reverse)
    
    if ($backups | length) == 0 {
        print "❌ No backup folders found!"
        return
    }
    
    let latest = ($backups | first)
    print $"📁 Restoring from: ($latest.name)"
    
    ensure-dir $game_path
    
    # Backup current mods first (safety)
    if ($mods_path | path exists) {
        let safety_backup = $"($config.backup_dir)/pre_restore_(date now | format date '%Y%m%d_%H%M%S')"
        print $"⚠️  Creating safety backup of current mods: ($safety_backup)"
        ^rsync -av $"($mods_path)/" $safety_backup
    }
    
    # Restore
    ^rsync -av --progress --delete $"($latest.name)/" $mods_path
    
    let mod_count = (get-mod-count $mods_path)
    print ""
    print $"✅ Restore complete! ($mod_count) mods restored"
}

def "main export" [] {
    print "📤 Creating shareable mod pack for Windows friends..."
    
    if not ($mods_path | path exists) {
        print "❌ Mods folder not found!"
        return
    }
    
    ensure-dir $config.export_dir
    
    let timestamp = (date now | format date "%Y%m%d")
    let zip_name = $"StardewMods_($timestamp).zip"
    let zip_path = $"($config.export_dir)/($zip_name)"
    
    print $"📦 Creating: ($zip_path)"
    print "   This may take a while for large mod collections..."
    print ""
    
    # Create zip
    cd $game_path
    ^zip -r $zip_path "Mods" -x "*.log" -x "*.old" -x ".cache/*"
    
    if ($zip_path | path exists) {
        let size = (ls $zip_path | first | get size)
        print ""
        print $"✅ Export complete!"
        print $"   File: ($zip_path)"
        print $"   Size: (format-size $size)"
        print ""
        print "📋 Instructions for Windows friends:"
        print "   1. Extract the zip to their Stardew Valley folder"
        print "   2. The Mods folder should merge/replace their existing one"
        print "   3. Ensure they have SMAPI installed!"
    } else {
        print "❌ Failed to create zip file"
    }
}

def "main import" [zip_file: string] {
    print $"📥 Importing mods from: ($zip_file)"
    
    if not ($zip_file | path exists) {
        print "❌ Zip file not found!"
        return
    }
    
    # Create safety backup first
    if ($mods_path | path exists) {
        main backup
    }
    
    ensure-dir $game_path
    
    print "📦 Extracting mods..."
    cd $game_path
    ^unzip -o $zip_file
    
    let mod_count = (get-mod-count $mods_path)
    print ""
    print $"✅ Import complete! ($mod_count) mods now installed"
}

def "main cloud push" [] {
    print "☁️  Pushing mods to cloud storage..."
    
    if not ($mods_path | path exists) {
        print "❌ Mods folder not found!"
        return
    }
    
    ensure-dir $config.cloud_dir
    
    print $"📤 Syncing to: ($config.cloud_dir)"
    ^rsync -av --progress --delete $"($mods_path)/" $config.cloud_dir
    
    print ""
    print "✅ Cloud sync complete!"
}

def "main cloud pull" [] {
    print "☁️  Pulling mods from cloud storage..."
    
    if not ($config.cloud_dir | path exists) {
        print "❌ Cloud folder not found!"
        return
    }
    
    # Safety backup
    if ($mods_path | path exists) {
        main backup
    }
    
    ensure-dir $game_path
    
    print $"📥 Syncing from: ($config.cloud_dir)"
    ^rsync -av --progress --delete $"($config.cloud_dir)/" $mods_path
    
    let mod_count = (get-mod-count $mods_path)
    print ""
    print $"✅ Cloud sync complete! ($mod_count) mods installed"
}

def main [] {
    print "🌾 Stardew Valley Mod Sync Tool"
    print ""
    print "Commands:"
    print "  status       - Show current mod status"
    print "  backup       - Backup mods to local directory"
    print "  restore      - Restore mods from latest backup"
    print "  export       - Create zip for Windows friends"
    print "  import <zip> - Import mods from Windows zip"
    print "  cloud push   - Sync mods to cloud storage"
    print "  cloud pull   - Sync mods from cloud storage"
    print ""
    print "Environment variables:"
    print "  STEAM_PATH     - Custom Steam installation path"
    print "  STARDEW_BACKUP - Custom backup directory"
    print "  STARDEW_CLOUD  - Cloud storage path (OneDrive/Google Drive)"
    print "  STARDEW_EXPORT - Export directory for zip files"
}
