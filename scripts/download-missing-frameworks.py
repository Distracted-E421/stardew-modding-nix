#!/usr/bin/env python3
# /// script
# requires-python = ">=3.11"
# dependencies = [
#     "httpx>=0.27",
#     "rich>=13.7",
#     "python-dotenv>=1.0",
# ]
# ///
"""
Download missing framework mods required by Stardew Valley collections.

These are dependency mods that collections often don't include directly.

Usage:
    uv run scripts/download-missing-frameworks.py
    uv run scripts/download-missing-frameworks.py --extract
"""

import asyncio
import os
import sys
import zipfile
from pathlib import Path

import httpx
from dotenv import load_dotenv
from rich.console import Console
from rich.progress import Progress, SpinnerColumn, TextColumn

console = Console()

# Missing framework mods identified from SMAPI errors
MISSING_FRAMEWORKS = [
    {"name": "Json Assets", "mod_id": 1720},
    {"name": "Producer Framework Mod", "mod_id": 4970},
    {"name": "Shop Tile Framework", "mod_id": 5005},
    {"name": "Expanded Preconditions Utility", "mod_id": 6529},
    {"name": "Custom NPC Exclusions", "mod_id": 7089},
    {"name": "SAAT - Audio API and Toolkit", "mod_id": 15775},
    {"name": "Extra Map Layers", "mod_id": 9633},  # Esca.EMP
    {"name": "Custom Cask Mod", "mod_id": 2642},
    {"name": "Bigger Craftables", "mod_id": 7530},
    {"name": "Get Glam", "mod_id": 5044},
    {"name": "AntiSocial NPCs", "mod_id": 5371},
    {"name": "Farmhouse Fixes", "mod_id": 12667},
]

# Mods folder location
MODS_FOLDER = Path.home() / ".local/share/Steam/steamapps/common/Stardew Valley/Mods"
DOWNLOAD_FOLDER = Path.home() / "stardew-modding-nix/downloads/frameworks"


async def get_download_link(client: httpx.AsyncClient, api_key: str, mod_id: int) -> tuple[str, str] | None:
    """Get download link for a mod (Premium required)."""
    try:
        # Get mod files
        resp = await client.get(
            f"https://api.nexusmods.com/v1/games/stardewvalley/mods/{mod_id}/files.json",
            headers={"apikey": api_key},
        )
        resp.raise_for_status()
        files = resp.json()["files"]
        
        if not files:
            return None
            
        # Get the main file (usually the first one or the one with is_primary)
        main_file = next((f for f in files if f.get("is_primary")), files[0])
        file_id = main_file["file_id"]
        filename = main_file["file_name"]
        
        # Get download links (Premium required)
        resp = await client.get(
            f"https://api.nexusmods.com/v1/games/stardewvalley/mods/{mod_id}/files/{file_id}/download_link.json",
            headers={"apikey": api_key},
        )
        resp.raise_for_status()
        links = resp.json()
        
        if links:
            return links[0]["URI"], filename
    except Exception as e:
        console.print(f"[red]Error getting link for mod {mod_id}: {e}[/red]")
    return None


async def download_mod(client: httpx.AsyncClient, url: str, filename: str, dest_folder: Path) -> Path | None:
    """Download a mod file."""
    try:
        dest_folder.mkdir(parents=True, exist_ok=True)
        dest_path = dest_folder / filename
        
        if dest_path.exists():
            console.print(f"  [yellow]Already downloaded: {filename}[/yellow]")
            return dest_path
            
        resp = await client.get(url, follow_redirects=True)
        resp.raise_for_status()
        
        dest_path.write_bytes(resp.content)
        return dest_path
    except Exception as e:
        console.print(f"[red]Download failed: {e}[/red]")
    return None


def extract_mod(zip_path: Path, mods_folder: Path) -> bool:
    """Extract a mod zip to the Mods folder."""
    try:
        with zipfile.ZipFile(zip_path, 'r') as zf:
            # Check if zip has a single root folder
            names = zf.namelist()
            roots = {n.split('/')[0] for n in names if '/' in n}
            
            if len(roots) == 1:
                # Extract directly
                zf.extractall(mods_folder)
            else:
                # Create folder based on zip name
                mod_name = zip_path.stem
                dest = mods_folder / mod_name
                dest.mkdir(exist_ok=True)
                zf.extractall(dest)
        return True
    except Exception as e:
        console.print(f"[red]Extract failed: {e}[/red]")
        return False


async def main():
    load_dotenv()
    api_key = os.getenv("NEXUS_API_KEY") or open(".env").read().strip()
    
    if not api_key:
        console.print("[red]No Nexus API key found! Create .env file with your key.[/red]")
        sys.exit(1)
    
    do_extract = "--extract" in sys.argv
    
    console.print("[bold cyan]═══════════════════════════════════════════[/bold cyan]")
    console.print("[bold cyan]   Missing Framework Mods Downloader       [/bold cyan]")
    console.print("[bold cyan]═══════════════════════════════════════════[/bold cyan]")
    console.print(f"[dim]Mods folder: {MODS_FOLDER}[/dim]")
    console.print(f"[dim]Download to: {DOWNLOAD_FOLDER}[/dim]")
    console.print(f"[dim]Extract: {do_extract}[/dim]")
    console.print()
    
    async with httpx.AsyncClient(timeout=60.0) as client:
        for mod in MISSING_FRAMEWORKS:
            console.print(f"[cyan]▶ {mod['name']}[/cyan] (mod {mod['mod_id']})")
            
            result = await get_download_link(client, api_key, mod["mod_id"])
            if not result:
                console.print(f"  [red]✗ Could not get download link[/red]")
                continue
                
            url, filename = result
            console.print(f"  [dim]Downloading {filename}...[/dim]")
            
            path = await download_mod(client, url, filename, DOWNLOAD_FOLDER)
            if path:
                console.print(f"  [green]✓ Downloaded[/green]")
                
                if do_extract:
                    if extract_mod(path, MODS_FOLDER):
                        console.print(f"  [green]✓ Extracted to Mods[/green]")
            console.print()
    
    console.print("[bold green]Done![/bold green]")
    if not do_extract:
        console.print(f"[dim]Run with --extract to install to Mods folder[/dim]")


if __name__ == "__main__":
    asyncio.run(main())

