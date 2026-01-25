#!/usr/bin/env nu

# Stardew Valley Mods Cleanup and Update Script
# Cleans up broken mod folders, loose files, and identifies mods needing updates

const MODS_DIR = "~/.local/share/Steam/steamapps/common/Stardew Valley/Mods" | path expand
const BACKUP_DIR = "~/.local/share/Steam/steamapps/common/Stardew Valley/Mods-backup" | path expand

# Files that should NOT be in the Mods folder directly (loose files from bad extraction)
const LOOSE_FILE_PATTERNS = [
    "*.xnb",
    "*.png",
    "*.txt",
    "content.json",  # This should be inside a mod folder, not root
]

# Known empty/broken folders to remove
const EMPTY_FOLDERS = [
    "Caroline Non Romanceable",
    "Caroline Romanceable", 
    "content",
    "SO Matching Sprites Yellow",
    "[FS] Colorful Hand Mirrors [sweetbeagaming]",
    "__MACOSX",
    "SMAPI 3.4.1 installer",
]

# Mods that are critically outdated and need manual update
const OUTDATED_MODS = {
    "GetGlam": { nexus_id: 5044, min_version: "1.1.0", reason: "Causes character appearance issues" },
    "Automate": { nexus_id: 1063, min_version: "2.0.0", reason: "Incompatible with SDV 1.6" },
    "ChestsAnywhere": { nexus_id: 518, min_version: "2.0.0", reason: "Incompatible with SDV 1.6" },
    "BetterCrafting": { nexus_id: 11115, min_version: "1.0.0", reason: "Incompatible with SDV 1.6" },
}

# Display banner
def banner [] {
    print "╔══════════════════════════════════════════════════════════════╗"
    print "║     🌾 Stardew Valley Mods Cleanup & Update Utility 🌾      ║"
    print "╠══════════════════════════════════════════════════════════════╣"
    print $"║  Mods Directory: ($MODS_DIR)"
    print "╚══════════════════════════════════════════════════════════════╝"
    print ""
}

# Find all loose files that shouldn't be in Mods root
def find-loose-files [] {
    print "🔍 Scanning for loose files in Mods root..."
    
    let loose_files = (
        ls $MODS_DIR 
        | where type == "file"
        | get name
    )
    
    if ($loose_files | is-empty) {
        print "  ✅ No loose files found"
        return []
    }
    
    print $"  ⚠️  Found ($loose_files | length) loose files:"
    $loose_files | each { |f| print $"     - ($f | path basename)" }
    
    $loose_files
}

# Find empty or broken mod folders
def find-broken-folders [] {
    print ""
    print "🔍 Scanning for empty/broken mod folders..."
    
    let all_dirs = (
        ls $MODS_DIR 
        | where type == "dir"
        | get name
    )
    
    let broken = $all_dirs | where { |dir|
        let manifest = ($dir | path join "manifest.json")
        let has_manifest = ($manifest | path exists)
        let dir_name = ($dir | path basename)
        
        # Check if it's a known empty folder or has no manifest
        ($dir_name in $EMPTY_FOLDERS) or (not $has_manifest and (
            # Also check subdirs for manifest (nested extraction)
            (ls $dir | where type == "dir" | each { |sub| 
                ($sub.name | path join "manifest.json" | path exists)
            } | any { |x| $x }) == false
        ))
    }
    
    if ($broken | is-empty) {
        print "  ✅ No broken folders found"
        return []
    }
    
    print $"  ⚠️  Found ($broken | length) broken/empty folders:"
    $broken | each { |f| print $"     - ($f | path basename)" }
    
    $broken
}

# Find mods with missing dependencies  
def find-missing-deps [] {
    print ""
    print "🔍 Checking for mods with missing dependencies..."
    # This would require parsing manifest.json files - simplified for now
    print "  ℹ️  Check SMAPI log for detailed dependency errors"
}

# Backup before cleanup
def backup-mods [] {
    print ""
    print "📦 Creating backup..."
    
    if ($BACKUP_DIR | path exists) {
        print $"  ⚠️  Backup already exists at ($BACKUP_DIR)"
        print "     Skipping backup (delete manually if you want a fresh backup)"
        return
    }
    
    mkdir $BACKUP_DIR
    # Only backup the problematic items, not the whole folder
    print "  ✅ Backup directory created"
}

# Remove loose files
def cleanup-loose-files [files: list] {
    if ($files | is-empty) { return }
    
    print ""
    print "🧹 Removing loose files..."
    
    $files | each { |f|
        let backup_path = ($BACKUP_DIR | path join ($f | path basename))
        mv $f $backup_path
        print $"  ✓ Moved ($f | path basename) to backup"
    }
}

# Remove broken folders
def cleanup-broken-folders [folders: list] {
    if ($folders | is-empty) { return }
    
    print ""
    print "🧹 Removing broken folders..."
    
    $folders | each { |f|
        let backup_path = ($BACKUP_DIR | path join ($f | path basename))
        if ($backup_path | path exists) {
            rm -rf $backup_path
        }
        mv $f $backup_path
        print $"  ✓ Moved ($f | path basename) to backup"
    }
}

# Check for outdated mods
def check-outdated [] {
    print ""
    print "🔍 Checking for critically outdated mods..."
    
    let outdated = $OUTDATED_MODS | columns | where { |mod_name|
        let mod_path = ($MODS_DIR | path join $mod_name)
        let manifest_path = ($mod_path | path join "manifest.json")
        
        if not ($manifest_path | path exists) {
            false
        } else {
            # Read raw and strip BOM, then parse JSON
            let raw = (open --raw $manifest_path | str trim | str replace -r '^\xEF\xBB\xBF' '')
            try {
                let manifest = ($raw | from json)
                let current_version = ($manifest | get Version)
                let min_version = ($OUTDATED_MODS | get $mod_name | get min_version)
                
                # Simple version comparison (assumes semver)
                $current_version < $min_version
            } catch {
                # Can't parse manifest, mark as needing attention
                true
            }
        }
    }
    
    if ($outdated | is-empty) {
        print "  ✅ No critically outdated mods found"
        return []
    }
    
    print $"  ⚠️  Found ($outdated | length) outdated mods needing manual update:"
    $outdated | each { |mod|
        let info = ($OUTDATED_MODS | get $mod)
        print $"     - ($mod): needs >= ($info.min_version)"
        print $"       Reason: ($info.reason)"
        print $"       Nexus: https://www.nexusmods.com/stardewvalley/mods/($info.nexus_id)"
    }
    
    $outdated
}

# Generate summary report
def generate-report [loose_count: int, broken_count: int, outdated: list] {
    print ""
    print "═══════════════════════════════════════════════════════════════"
    print "                      📊 CLEANUP SUMMARY                       "
    print "═══════════════════════════════════════════════════════════════"
    print $"  Loose files moved to backup:  ($loose_count)"
    print $"  Broken folders moved to backup: ($broken_count)"
    print $"  Mods needing manual update: ($outdated | length)"
    print ""
    
    if ($outdated | length) > 0 {
        print "⚠️  MANUAL ACTION REQUIRED:"
        print "   The following mods must be updated from Nexus Mods:"
        $outdated | each { |mod|
            let info = ($OUTDATED_MODS | get $mod)
            print $"   - ($mod): https://www.nexusmods.com/stardewvalley/mods/($info.nexus_id)"
        }
        print ""
    }
    
    print "💡 NEXT STEPS:"
    print "   1. Download updated mods from Nexus (see links above)"
    print "   2. Extract to Mods folder"
    print "   3. Run: nu scripts/sync-mods-local.nu evie@Evie-Desktop"
    print "   4. Test game launch"
    print ""
}

# Main execution
def main [
    --dry-run (-n)  # Don't actually delete, just show what would be done
    --skip-backup (-s)  # Skip backup step
] {
    banner
    
    if $dry_run {
        print "🔒 DRY RUN MODE - No changes will be made"
        print ""
    }
    
    # Find problems
    let loose_files = (find-loose-files)
    let broken_folders = (find-broken-folders)
    find-missing-deps
    let outdated = (check-outdated)
    
    if $dry_run {
        print ""
        print "═══════════════════════════════════════════════════════════════"
        print "  DRY RUN COMPLETE - Run without --dry-run to apply changes"
        print "═══════════════════════════════════════════════════════════════"
        return
    }
    
    # Perform cleanup
    if not $skip_backup {
        backup-mods
    }
    
    cleanup-loose-files $loose_files
    cleanup-broken-folders $broken_folders
    
    generate-report ($loose_files | length) ($broken_folders | length) $outdated
}

# Run main
main

