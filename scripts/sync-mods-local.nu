#!/usr/bin/env nu

# Stardew Valley Mod Sync - Local Network Transfer
# Syncs mods from this PC to another PC on the local network (via Tailscale/SSH)

def main [
    target: string = "evie@evie-desktop-1"  # SSH target (user@host)
    --dry-run (-n)                          # Show what would be transferred
    --reverse (-r)                          # Pull FROM target instead of push
    --include-saves                         # Also sync save files
] {
    let stardew_base = $"($env.HOME)/.steam/steam/steamapps/common/Stardew Valley"
    let mods_path = $"($stardew_base)/Mods"
    let saves_path = $"($env.HOME)/.config/StardewValley/Saves"
    
    # Verify local mods folder exists
    if not ($mods_path | path exists) {
        print $"(ansi red)Error:(ansi reset) Local Mods folder not found at:"
        print $"  ($mods_path)"
        print ""
        print "Make sure Stardew Valley is installed and SMAPI has been run at least once."
        exit 1
    }
    
    # Count local mods
    let local_mods = (ls $mods_path | where type == dir | length)
    print $"(ansi cyan)━━━ Stardew Mod Sync ━━━(ansi reset)"
    print $"Local mods found: (ansi green)($local_mods)(ansi reset)"
    print $"Target: (ansi yellow)($target)(ansi reset)"
    print ""
    
    # Build rsync command
    let rsync_opts = if $dry_run { "-avzn --progress" } else { "-avz --progress" }
    
    if $reverse {
        # Pull FROM remote
        print $"(ansi magenta)← Pulling mods FROM ($target)(ansi reset)"
        let remote_mods = $"($target):~/.steam/steam/steamapps/common/Stardew\\ Valley/Mods/"
        
        if $dry_run {
            print "(ansi yellow)DRY RUN - No changes will be made(ansi reset)"
        }
        
        rsync ...($rsync_opts | split row " ") $remote_mods $"($mods_path)/"
        
    } else {
        # Push TO remote
        print $"(ansi green)→ Pushing mods TO ($target)(ansi reset)"
        let remote_mods = $"($target):~/.steam/steam/steamapps/common/Stardew\\ Valley/Mods/"
        
        if $dry_run {
            print "(ansi yellow)DRY RUN - No changes will be made(ansi reset)"
        }
        
        # First ensure remote directory exists
        print "Ensuring remote Mods directory exists..."
        ssh $target "mkdir -p ~/.steam/steam/steamapps/common/Stardew\\ Valley/Mods"
        
        rsync ...($rsync_opts | split row " ") $"($mods_path)/" $remote_mods
    }
    
    # Optionally sync saves
    if $include_saves {
        print ""
        print $"(ansi cyan)━━━ Syncing Save Files ━━━(ansi reset)"
        
        if not ($saves_path | path exists) {
            print $"(ansi yellow)Warning:(ansi reset) No saves found at ($saves_path)"
        } else {
            let save_count = (ls $saves_path | where type == dir | length)
            print $"Local saves found: (ansi green)($save_count)(ansi reset)"
            
            let remote_saves = $"($target):~/.config/StardewValley/Saves/"
            
            if $reverse {
                rsync ...($rsync_opts | split row " ") $remote_saves $"($saves_path)/"
            } else {
                ssh $target "mkdir -p ~/.config/StardewValley/Saves"
                rsync ...($rsync_opts | split row " ") $"($saves_path)/" $remote_saves
            }
        }
    }
    
    print ""
    if $dry_run {
        print $"(ansi yellow)Dry run complete. Run without -n to actually sync.(ansi reset)"
    } else {
        print $"(ansi green)✓ Sync complete!(ansi reset)"
    }
}

