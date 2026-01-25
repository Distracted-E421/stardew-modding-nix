#!/usr/bin/env python3
# /// script
# requires-python = ">=3.11"
# dependencies = [
#     "rich>=13.7",
#     "py7zr>=0.22",
#     "rarfile>=4.2",
# ]
# ///
"""
Extract downloaded Stardew Valley mods to the game's Mods folder.
Handles ZIP, RAR, and 7z formats.
"""

import os
import shutil
import subprocess
import zipfile
from pathlib import Path

try:
    import py7zr
    HAS_7Z = True
except ImportError:
    HAS_7Z = False

try:
    import rarfile
    HAS_RAR = True
except ImportError:
    HAS_RAR = False

from rich.console import Console
from rich.progress import Progress, SpinnerColumn, TextColumn, BarColumn

console = Console()

# Paths
DOWNLOAD_DIR = Path.home() / "StardewMods" / "downloads"
MODS_DIR = Path.home() / ".local/share/Steam/steamapps/common/Stardew Valley/Mods"
BACKUP_DIR = Path.home() / "StardewMods" / "backup"

def backup_existing_mods():
    """Backup existing mods folder"""
    if MODS_DIR.exists() and any(MODS_DIR.iterdir()):
        console.print(f"\n[bold yellow]📦 Backing up existing mods...[/bold yellow]")
        BACKUP_DIR.mkdir(parents=True, exist_ok=True)
        
        # Create timestamped backup
        from datetime import datetime
        backup_path = BACKUP_DIR / f"mods_backup_{datetime.now().strftime('%Y%m%d_%H%M%S')}"
        shutil.copytree(MODS_DIR, backup_path, dirs_exist_ok=True)
        console.print(f"[green]✅ Backup created at: {backup_path}[/green]")
        return backup_path
    return None

def detect_archive_type(file_path: Path) -> str:
    """Detect archive type by magic bytes"""
    with open(file_path, 'rb') as f:
        header = f.read(8)
    
    if header[:4] == b'PK\x03\x04':
        return 'zip'
    elif header[:6] == b'Rar!\x1a\x07':
        return 'rar'
    elif header[:6] == b"7z\xbc\xaf'\x1c":
        return '7z'
    else:
        return 'unknown'


def extract_mod(archive_path: Path, dest_dir: Path) -> tuple[bool, str]:
    """
    Extract a mod archive to the destination directory.
    Handles ZIP, RAR, and 7z formats.
    """
    archive_type = detect_archive_type(archive_path)
    
    try:
        if archive_type == 'zip':
            return extract_zip(archive_path, dest_dir)
        elif archive_type == '7z':
            return extract_7z(archive_path, dest_dir)
        elif archive_type == 'rar':
            return extract_rar(archive_path, dest_dir)
        else:
            # Try zip as fallback
            return extract_zip(archive_path, dest_dir)
    except Exception as e:
        return False, str(e)


def extract_zip(zip_path: Path, dest_dir: Path) -> tuple[bool, str]:
    """Extract a ZIP archive"""
    try:
        with zipfile.ZipFile(zip_path, 'r') as zf:
            files = zf.namelist()
            manifest_locations = [f for f in files if f.endswith('manifest.json')]
            
            if not manifest_locations:
                zf.extractall(dest_dir)
                return True, "extracted (no manifest)"
            
            shallowest = min(manifest_locations, key=lambda x: x.count('/'))
            
            if shallowest == 'manifest.json':
                mod_name = zip_path.stem.split('_')[0]
                mod_dir = dest_dir / mod_name
                mod_dir.mkdir(exist_ok=True)
                zf.extractall(mod_dir)
                return True, f"extracted to {mod_name}"
            else:
                zf.extractall(dest_dir)
                mod_folder = shallowest.split('/')[0]
                return True, f"extracted {mod_folder}"
    except zipfile.BadZipFile:
        return False, "bad zip file"


def extract_7z(archive_path: Path, dest_dir: Path) -> tuple[bool, str]:
    """Extract a 7z archive"""
    if not HAS_7Z:
        # Fallback to command line 7z
        try:
            result = subprocess.run(
                ['7z', 'x', str(archive_path), f'-o{dest_dir}', '-y'],
                capture_output=True, text=True
            )
            if result.returncode == 0:
                return True, "extracted (7z cli)"
            return False, result.stderr
        except FileNotFoundError:
            return False, "7z not installed (try: nix-shell -p p7zip)"
    
    try:
        with py7zr.SevenZipFile(archive_path, 'r') as szf:
            files = szf.getnames()
            manifest_locations = [f for f in files if f.endswith('manifest.json')]
            
            if not manifest_locations:
                szf.extractall(dest_dir)
                return True, "extracted (7z, no manifest)"
            
            shallowest = min(manifest_locations, key=lambda x: x.count('/'))
            
            if shallowest == 'manifest.json':
                mod_name = archive_path.stem.split('_')[0]
                mod_dir = dest_dir / mod_name
                mod_dir.mkdir(exist_ok=True)
                szf.extractall(mod_dir)
                return True, f"extracted to {mod_name} (7z)"
            else:
                szf.extractall(dest_dir)
                mod_folder = shallowest.split('/')[0]
                return True, f"extracted {mod_folder} (7z)"
    except Exception as e:
        return False, f"7z error: {e}"


def extract_rar(archive_path: Path, dest_dir: Path) -> tuple[bool, str]:
    """Extract a RAR archive"""
    if not HAS_RAR:
        # Fallback to command line unrar
        try:
            result = subprocess.run(
                ['unrar', 'x', '-y', str(archive_path), str(dest_dir) + '/'],
                capture_output=True, text=True
            )
            if result.returncode == 0:
                return True, "extracted (unrar cli)"
            return False, result.stderr
        except FileNotFoundError:
            return False, "unrar not installed (try: nix-shell -p unrar)"
    
    try:
        with rarfile.RarFile(archive_path) as rf:
            files = rf.namelist()
            manifest_locations = [f for f in files if f.endswith('manifest.json')]
            
            if not manifest_locations:
                rf.extractall(dest_dir)
                return True, "extracted (rar, no manifest)"
            
            shallowest = min(manifest_locations, key=lambda x: x.count('/'))
            
            if shallowest == 'manifest.json':
                mod_name = archive_path.stem.split('_')[0]
                mod_dir = dest_dir / mod_name
                mod_dir.mkdir(exist_ok=True)
                rf.extractall(mod_dir)
                return True, f"extracted to {mod_name} (rar)"
            else:
                rf.extractall(dest_dir)
                mod_folder = shallowest.split('/')[0]
                return True, f"extracted {mod_folder} (rar)"
    except Exception as e:
        return False, f"rar error: {e}"

def main():
    console.print("\n[bold cyan]🌾 Stardew Valley Mod Extractor[/bold cyan]\n")
    
    # Check paths
    if not DOWNLOAD_DIR.exists():
        console.print(f"[red]❌ Download directory not found: {DOWNLOAD_DIR}[/red]")
        return
    
    # Get all zip files
    zip_files = list(DOWNLOAD_DIR.glob("*.zip"))
    
    if not zip_files:
        console.print(f"[yellow]No zip files found in {DOWNLOAD_DIR}[/yellow]")
        return
    
    console.print(f"Found [bold green]{len(zip_files)}[/bold green] mod files to extract")
    console.print(f"Destination: [bold blue]{MODS_DIR}[/bold blue]\n")
    
    # Prompt for backup
    console.print("[bold yellow]Options:[/bold yellow]")
    console.print("  1. Backup existing mods and extract (safe)")
    console.print("  2. Extract only (keep existing)")
    console.print("  3. Clean extract (remove existing mods first)")
    console.print("")
    
    # For scripted use, default to backup + extract
    choice = "1"  # Can be overridden with args
    
    import sys
    if len(sys.argv) > 1:
        if sys.argv[1] == "--clean":
            choice = "3"
        elif sys.argv[1] == "--keep":
            choice = "2"
    
    if choice == "1":
        backup_existing_mods()
    elif choice == "3":
        if MODS_DIR.exists():
            # Don't delete SMAPI or essential loader files
            for item in MODS_DIR.iterdir():
                if item.name not in ["ErrorHandler", "ConsoleCommands", "SaveBackup"]:
                    if item.is_dir():
                        shutil.rmtree(item)
                    else:
                        item.unlink()
            console.print("[yellow]Cleared existing mods (kept SMAPI essentials)[/yellow]")
    
    # Ensure mods directory exists
    MODS_DIR.mkdir(parents=True, exist_ok=True)
    
    # Extract mods
    results = {"success": 0, "failed": 0, "skipped": 0}
    
    with Progress(
        SpinnerColumn(),
        TextColumn("[progress.description]{task.description}"),
        BarColumn(),
        TextColumn("[progress.percentage]{task.percentage:>3.0f}%"),
        console=console,
    ) as progress:
        task = progress.add_task("Extracting mods...", total=len(zip_files))
        
        for zip_path in zip_files:
            mod_name = zip_path.stem.split('_')[0][:30]
            progress.update(task, description=f"Extracting: {mod_name}...")
            
            success, msg = extract_mod(zip_path, MODS_DIR)
            
            if success:
                results["success"] += 1
            else:
                results["failed"] += 1
                console.print(f"[red]  ❌ {zip_path.name}: {msg}[/red]")
            
            progress.advance(task)
    
    # Summary
    console.print(f"\n[bold green]✅ Extraction Complete![/bold green]")
    console.print(f"  Successful: [green]{results['success']}[/green]")
    console.print(f"  Failed: [red]{results['failed']}[/red]")
    
    # Count installed mods
    mod_folders = [d for d in MODS_DIR.iterdir() if d.is_dir() and (d / "manifest.json").exists()]
    console.print(f"\n[bold blue]📁 Total mods installed: {len(mod_folders)}[/bold blue]")
    
    console.print(f"\n[bold cyan]Next steps:[/bold cyan]")
    console.print("  1. Launch Stardew Valley with SMAPI")
    console.print("  2. Check for any missing dependencies in SMAPI console")
    console.print("  3. Configure SVE to use Frontier Farm (in Generic Mod Config Menu)")


if __name__ == "__main__":
    main()

