#!/usr/bin/env python3
# /// script
# requires-python = ">=3.11"
# dependencies = [
#     "httpx>=0.27",
#     "rich>=13.7",
# ]
# ///
"""
Download missing Stardew Valley mods from GitHub releases.
"""

import asyncio
from pathlib import Path
import httpx
from rich.console import Console
from rich.progress import Progress, SpinnerColumn, TextColumn

console = Console()
DOWNLOAD_DIR = Path.home() / "StardewMods" / "downloads"

# Missing mods with GitHub sources
GITHUB_MODS = [
    {
        "name": "UI Info Suite 2",
        "repo": "sophiesalacia/UIInfoSuite2",
        "asset_pattern": "UIInfoSuite2",  # Match release asset name
    },
    {
        "name": "Dynamic Reflections",
        "repo": "Floogen/DynamicReflections",
        "asset_pattern": "DynamicReflections",
    },
    {
        "name": "Fashion Sense",
        "repo": "Floogen/FashionSense",
        "asset_pattern": "FashionSense",
    },
    {
        "name": "Alternative Textures",
        "repo": "Floogen/AlternativeTextures",
        "asset_pattern": "AlternativeTextures",
    },
    {
        "name": "Solid Foundations",
        "repo": "Floogen/SolidFoundations",
        "asset_pattern": "SolidFoundations",
    },
]


async def get_latest_release(client: httpx.AsyncClient, repo: str) -> dict | None:
    """Get latest release info from GitHub"""
    try:
        resp = await client.get(
            f"https://api.github.com/repos/{repo}/releases/latest",
            headers={"Accept": "application/vnd.github.v3+json"},
        )
        if resp.status_code == 200:
            return resp.json()
        elif resp.status_code == 404:
            console.print(f"[yellow]No releases found for {repo}[/yellow]")
        return None
    except Exception as e:
        console.print(f"[red]Error fetching {repo}: {e}[/red]")
        return None


async def download_asset(client: httpx.AsyncClient, url: str, dest: Path) -> bool:
    """Download a file"""
    try:
        async with client.stream("GET", url) as resp:
            resp.raise_for_status()
            with open(dest, "wb") as f:
                async for chunk in resp.aiter_bytes(chunk_size=8192):
                    f.write(chunk)
        return True
    except Exception as e:
        console.print(f"[red]Download failed: {e}[/red]")
        return False


async def main():
    console.print("\n[bold cyan]🐙 GitHub Mod Downloader[/bold cyan]\n")
    
    DOWNLOAD_DIR.mkdir(parents=True, exist_ok=True)
    
    async with httpx.AsyncClient(follow_redirects=True, timeout=60.0) as client:
        with Progress(
            SpinnerColumn(),
            TextColumn("[progress.description]{task.description}"),
            console=console,
        ) as progress:
            
            for mod in GITHUB_MODS:
                task = progress.add_task(f"Fetching {mod['name']}...", total=1)
                
                release = await get_latest_release(client, mod['repo'])
                
                if not release:
                    progress.update(task, description=f"[yellow]⚠️ {mod['name']}: No release[/yellow]")
                    progress.advance(task)
                    continue
                
                # Find matching asset
                assets = release.get("assets", [])
                target_asset = None
                
                for asset in assets:
                    if mod['asset_pattern'].lower() in asset['name'].lower():
                        if asset['name'].endswith('.zip'):
                            target_asset = asset
                            break
                
                if not target_asset:
                    # Try any zip file
                    for asset in assets:
                        if asset['name'].endswith('.zip'):
                            target_asset = asset
                            break
                
                if not target_asset:
                    progress.update(task, description=f"[yellow]⚠️ {mod['name']}: No zip asset[/yellow]")
                    progress.advance(task)
                    continue
                
                # Download
                dest_path = DOWNLOAD_DIR / f"{mod['name'].replace(' ', '_')}_{release['tag_name']}.zip"
                
                if dest_path.exists():
                    progress.update(task, description=f"[blue]📦 {mod['name']}: Already downloaded[/blue]")
                    progress.advance(task)
                    continue
                
                progress.update(task, description=f"Downloading {mod['name']}...")
                
                success = await download_asset(client, target_asset['browser_download_url'], dest_path)
                
                if success:
                    progress.update(task, description=f"[green]✅ {mod['name']}: Downloaded ({release['tag_name']})[/green]")
                else:
                    progress.update(task, description=f"[red]❌ {mod['name']}: Failed[/red]")
                
                progress.advance(task)
    
    console.print("\n[bold green]Done! Re-run extract-mods.py to install.[/bold green]")


if __name__ == "__main__":
    asyncio.run(main())

