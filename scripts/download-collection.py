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
Download all mods from a Stardew Valley collection using Nexus Mods API.

Requires Premium for direct downloads. Uses the collection catalog with mod IDs.

Usage:
    uv run download-collection.py                    # Download all mods
    uv run download-collection.py --extract          # Download and extract to Mods folder
    uv run download-collection.py --list             # Just list what would be downloaded
    uv run download-collection.py --mod <mod_id>     # Download a single mod
"""

import asyncio
import json
import os
import shutil
import sys
import zipfile
from pathlib import Path
from typing import Optional

import httpx
from dotenv import load_dotenv
from rich.console import Console
from rich.progress import Progress, SpinnerColumn, TextColumn, BarColumn, DownloadColumn, TransferSpeedColumn, TaskProgressColumn
from rich.table import Table

# Configuration
SCRIPT_DIR = Path(__file__).parent.parent
ENV_FILE = SCRIPT_DIR / ".env"
load_dotenv(ENV_FILE)

API_KEY = os.getenv("NEXUS_API_KEY") or open(ENV_FILE).read().strip()
BASE_URL = "https://api.nexusmods.com/v1"
GAME_DOMAIN = "stardewvalley"

# Paths
DOWNLOAD_DIR = Path.home() / "StardewMods" / "downloads"
MODS_DIR = Path.home() / ".local/share/Steam/steamapps/common/Stardew Valley/Mods"
# Use merged catalog by default (VERY Expanded + Fairycore)
CATALOG_FILE = SCRIPT_DIR / "merged-collection-catalog.json"
# Fallback to single collection if merged doesn't exist
CATALOG_FALLBACK = SCRIPT_DIR / "collection-catalog-with-ids.json"

console = Console()


class NexusDownloader:
    """Async downloader for Nexus Mods"""
    
    def __init__(self, api_key: str):
        self.api_key = api_key
        self.headers = {"apikey": api_key}
        self._client: Optional[httpx.AsyncClient] = None
    
    async def __aenter__(self):
        self._client = httpx.AsyncClient(
            headers=self.headers,
            timeout=60.0,
            follow_redirects=True,
        )
        return self
    
    async def __aexit__(self, *args):
        if self._client:
            await self._client.aclose()
    
    async def validate_premium(self) -> bool:
        """Check if user has Premium"""
        try:
            resp = await self._client.get(f"{BASE_URL}/users/validate.json")
            resp.raise_for_status()
            user = resp.json()
            return user.get("is_premium", False)
        except Exception as e:
            console.print(f"[red]Error validating API key: {e}[/red]")
            return False
    
    async def get_mod_files(self, mod_id: int) -> tuple[list[dict], str]:
        """Get available files for a mod. Returns (files, error_reason)"""
        try:
            resp = await self._client.get(
                f"{BASE_URL}/games/{GAME_DOMAIN}/mods/{mod_id}/files.json"
            )
            resp.raise_for_status()
            return resp.json().get("files", []), ""
        except httpx.HTTPStatusError as e:
            if e.response.status_code == 403:
                return [], "hidden_or_deleted"
            elif e.response.status_code == 404:
                return [], "not_found"
            return [], f"http_{e.response.status_code}"
        except Exception as e:
            console.print(f"[yellow]Error getting files for mod {mod_id}: {e}[/yellow]")
            return [], "error"
    
    async def get_download_link(self, mod_id: int, file_id: int) -> str:
        """Get download link for a file (Premium only)"""
        try:
            resp = await self._client.get(
                f"{BASE_URL}/games/{GAME_DOMAIN}/mods/{mod_id}/files/{file_id}/download_link.json"
            )
            resp.raise_for_status()
            links = resp.json()
            if links:
                return links[0].get("URI", "")
        except httpx.HTTPStatusError as e:
            if e.response.status_code == 403:
                console.print(f"[red]Premium required for direct downloads[/red]")
            raise
        return ""
    
    async def download_file(self, url: str, output_path: Path, file_size: int = 0) -> bool:
        """Download a file with progress"""
        try:
            async with self._client.stream("GET", url) as response:
                response.raise_for_status()
                total = int(response.headers.get("content-length", file_size)) or file_size
                
                with open(output_path, "wb") as f:
                    downloaded = 0
                    async for chunk in response.aiter_bytes(chunk_size=8192):
                        f.write(chunk)
                        downloaded += len(chunk)
                        # Print progress inline
                        if total > 0:
                            pct = (downloaded / total) * 100
                            console.print(f"\r  Progress: {pct:.1f}% ({downloaded:,}/{total:,} bytes)", end="")
                    console.print()  # New line after download
            return True
        except Exception as e:
            console.print(f"\n[red]Download error: {e}[/red]")
            return False


async def download_mod(downloader: NexusDownloader, mod: dict, download_dir: Path) -> tuple[str, Path | None]:
    """Download a single mod, returns (status, file_path)"""
    mod_id = mod.get("mod_id")
    mod_name = mod.get("name", f"Mod {mod_id}")
    
    if not mod_id:
        return "no_id", None
    
    # Get available files
    files, file_error = await downloader.get_mod_files(mod_id)
    if not files:
        if file_error == "hidden_or_deleted":
            return "hidden", None
        elif file_error == "not_found":
            return "not_found", None
        return "no_files", None
    
    # Select the main/primary file
    main_file = None
    for f in files:
        if f.get("is_primary"):
            main_file = f
            break
    
    # If no primary, try to find "Main" category
    if not main_file:
        for f in files:
            if f.get("category_name") == "MAIN":
                main_file = f
                break
    
    # Fall back to first file
    if not main_file:
        main_file = files[0]
    
    file_id = main_file.get("file_id")
    file_name = main_file.get("file_name", f"{mod_name}.zip")
    file_size = main_file.get("size_in_bytes") or main_file.get("size") or 0
    
    # Output path
    safe_name = "".join(c if c.isalnum() or c in "._- " else "_" for c in mod_name)
    output_path = download_dir / f"{safe_name}_{main_file.get('version', 'latest')}.zip"
    
    # Skip if already downloaded
    if output_path.exists() and output_path.stat().st_size > 0:
        return "cached", output_path
    
    # Get download link with retry for rate limiting
    max_retries = 3
    for attempt in range(max_retries):
        try:
            download_url = await downloader.get_download_link(mod_id, file_id)
            if not download_url:
                return "no_link", None
            break
        except httpx.HTTPStatusError as e:
            if e.response.status_code == 403:
                if attempt < max_retries - 1:
                    console.print(f"  [yellow]⏳ Rate limited, waiting 5s (attempt {attempt + 1}/{max_retries})...[/yellow]")
                    await asyncio.sleep(5)
                else:
                    return "rate_limited", None
            elif e.response.status_code == 404:
                return "not_found", None
            else:
                raise
    
    # Download
    size_mb = file_size / 1024 / 1024 if file_size else 0
    size_str = f"{size_mb:.1f} MB" if file_size else "unknown size"
    console.print(f"  📥 Downloading: {file_name} ({size_str})")
    success = await downloader.download_file(download_url, output_path, file_size or 0)
    
    if success:
        return "downloaded", output_path
    else:
        return "failed", None


async def main():
    args = sys.argv[1:]
    
    # Parse arguments
    extract_mode = "--extract" in args
    list_mode = "--list" in args
    single_mod = None
    
    if "--mod" in args:
        idx = args.index("--mod")
        if idx + 1 < len(args):
            single_mod = int(args[idx + 1])
    
    # Load catalog (prefer merged, fallback to single collection)
    catalog_path = CATALOG_FILE
    if not CATALOG_FILE.exists():
        if CATALOG_FALLBACK.exists():
            catalog_path = CATALOG_FALLBACK
            console.print(f"[yellow]Using fallback catalog: {CATALOG_FALLBACK}[/yellow]")
        else:
            console.print(f"[red]No catalog found![/red]")
            console.print("Run merge-collections.py or build-mod-catalog.py first!")
            sys.exit(1)
    
    with open(catalog_path) as f:
        catalog = json.load(f)
    
    mods = catalog.get("mods", [])
    collection_name = catalog.get("collection", "Unknown")
    
    console.print(f"\n[bold cyan]🌾 Stardew Valley Mod Collection Downloader[/bold cyan]")
    console.print(f"   Collection: [green]{collection_name}[/green]")
    console.print(f"   Total mods: [yellow]{len(mods)}[/yellow]")
    console.print()
    
    # Filter to single mod if specified
    if single_mod:
        mods = [m for m in mods if m.get("mod_id") == single_mod]
        if not mods:
            console.print(f"[red]Mod {single_mod} not found in catalog[/red]")
            sys.exit(1)
    
    # List mode
    if list_mode:
        table = Table(title="Mods to Download")
        table.add_column("ID", style="cyan")
        table.add_column("Name", style="green")
        table.add_column("Category", style="blue")
        table.add_column("Section", style="yellow")
        
        for mod in mods:
            if mod.get("mod_id"):
                table.add_row(
                    str(mod.get("mod_id", "N/A")),
                    mod.get("name", "Unknown")[:50],
                    mod.get("category", ""),
                    mod.get("section", ""),
                )
        
        console.print(table)
        console.print(f"\n[dim]Run without --list to download[/dim]")
        return
    
    # Create download directory
    DOWNLOAD_DIR.mkdir(parents=True, exist_ok=True)
    
    # Download
    async with NexusDownloader(API_KEY) as downloader:
        # Validate Premium
        if not await downloader.validate_premium():
            console.print("[red]Premium account required for direct downloads![/red]")
            console.print("Manual downloads are available at the mod URLs in the catalog.")
            sys.exit(1)
        
        console.print("[green]✅ Premium validated - direct downloads enabled[/green]\n")
        
        results = {
            "downloaded": [],
            "cached": [],
            "failed": [],
            "no_id": [],
            "premium_required": [],
            "no_files": [],
            "no_link": [],
            "rate_limited": [],
            "not_found": [],
            "hidden": [],
        }
        
        for i, mod in enumerate(mods, 1):
            mod_name = mod.get("name", "Unknown")
            section = mod.get("section", "Required")
            
            console.print(f"[{i}/{len(mods)}] [cyan]{mod_name}[/cyan] ({section})")
            
            status, file_path = await download_mod(downloader, mod, DOWNLOAD_DIR)
            results[status].append((mod, file_path))
            
            if status == "downloaded":
                console.print(f"  [green]✅ Downloaded[/green]")
            elif status == "cached":
                console.print(f"  [blue]📦 Already downloaded[/blue]")
            elif status == "no_id":
                console.print(f"  [yellow]⚠️  No mod ID (bundled asset?)[/yellow]")
            elif status == "failed":
                console.print(f"  [red]❌ Download failed[/red]")
            elif status == "rate_limited":
                console.print(f"  [red]🚫 Rate limited - try again later[/red]")
            elif status == "not_found":
                console.print(f"  [yellow]⚠️  Mod not found on Nexus[/yellow]")
            elif status == "no_files":
                console.print(f"  [yellow]⚠️  No files available[/yellow]")
            elif status == "hidden":
                console.print(f"  [magenta]🔒 Mod hidden/deleted by author[/magenta]")
            
            # Rate limiting - be respectful to Nexus API
            # Nexus allows ~30 requests per second for Premium, but downloads are heavier
            await asyncio.sleep(1.0)
    
    # Summary
    console.print("\n" + "=" * 60)
    console.print("[bold]📊 Download Summary[/bold]")
    console.print("=" * 60)
    
    console.print(f"[green]✅ Downloaded: {len(results['downloaded'])}[/green]")
    console.print(f"[blue]📦 Cached: {len(results['cached'])}[/blue]")
    console.print(f"[red]❌ Failed: {len(results['failed'])}[/red]")
    console.print(f"[red]🚫 Rate limited: {len(results['rate_limited'])}[/red]")
    console.print(f"[yellow]⚠️  No ID: {len(results['no_id'])}[/yellow]")
    console.print(f"[yellow]⚠️  Not found: {len(results['not_found'])}[/yellow]")
    console.print(f"[magenta]🔒 Hidden/deleted: {len(results['hidden'])}[/magenta]")
    
    # List hidden mods (need alternative source)
    if results['hidden']:
        console.print("\n[bold magenta]Hidden/Deleted mods (need manual download or alternative):[/bold magenta]")
        for mod, _ in results['hidden']:
            mod_id = mod.get('mod_id')
            console.print(f"  • {mod.get('name')} (ID: {mod_id})")
            console.print(f"    URL: https://www.nexusmods.com/stardewvalley/mods/{mod_id}")
    
    # List failed mods for retry
    if results['rate_limited']:
        console.print("\n[bold yellow]Rate-limited mods (retry later):[/bold yellow]")
        for mod, _ in results['rate_limited']:
            console.print(f"  • {mod.get('name')} (ID: {mod.get('mod_id')})")
    
    # Extract mode
    if extract_mode and (results['downloaded'] or results['cached']):
        console.print("\n[bold]📦 Extracting to Mods folder...[/bold]")
        
        if not MODS_DIR.exists():
            console.print(f"[yellow]Creating Mods folder: {MODS_DIR}[/yellow]")
            MODS_DIR.mkdir(parents=True, exist_ok=True)
        
        extracted = 0
        for status in ['downloaded', 'cached']:
            for mod, file_path in results[status]:
                if file_path and file_path.exists():
                    try:
                        with zipfile.ZipFile(file_path, 'r') as zf:
                            # Extract to Mods folder
                            zf.extractall(MODS_DIR)
                            extracted += 1
                            console.print(f"  ✅ Extracted: {mod.get('name')}")
                    except zipfile.BadZipFile:
                        console.print(f"  [red]❌ Bad zip: {mod.get('name')}[/red]")
                    except Exception as e:
                        console.print(f"  [red]❌ Extract error: {e}[/red]")
        
        console.print(f"\n[green]✅ Extracted {extracted} mods to {MODS_DIR}[/green]")
    
    console.print(f"\n[dim]Download location: {DOWNLOAD_DIR}[/dim]")


if __name__ == "__main__":
    asyncio.run(main())

