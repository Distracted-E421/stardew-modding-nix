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
Nexus Mods API Integration for Stardew Valley Mod Management

This script provides API-based mod downloading and management for Nexus Mods.
Designed to integrate with the homelab's existing dashboard/TUI infrastructure.

Usage:
    uv run nexus-api.py search "Content Patcher"        # Search for mods
    uv run nexus-api.py info 1915                       # Get mod details
    uv run nexus-api.py download-collection <json>      # Download all mods from catalog
    uv run nexus-api.py validate-key                    # Validate API key
    uv run nexus-api.py user                            # Show user info

Environment:
    Reads API key from .env file in the script directory

Author: e421 homelab automation
"""

import asyncio
import json
import os
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Optional

import httpx
from dotenv import load_dotenv
from rich.console import Console
from rich.progress import Progress, SpinnerColumn, TextColumn, BarColumn, TaskProgressColumn
from rich.table import Table
from rich import print as rprint

# ═══════════════════════════════════════════════════════════════════════════════
# CONFIGURATION
# ═══════════════════════════════════════════════════════════════════════════════

SCRIPT_DIR = Path(__file__).parent.parent
ENV_FILE = SCRIPT_DIR / ".env"

# Load API key from .env
load_dotenv(ENV_FILE)

API_KEY = os.getenv("NEXUS_API_KEY") or open(ENV_FILE).read().strip()
BASE_URL = "https://api.nexusmods.com/v1"
GAME_DOMAIN = "stardewvalley"

# Output paths
DOWNLOAD_DIR = Path.home() / "StardewMods" / "downloads"
MODS_DIR = Path.home() / ".local/share/Steam/steamapps/common/Stardew Valley/Mods"

console = Console()


# ═══════════════════════════════════════════════════════════════════════════════
# DATA CLASSES
# ═══════════════════════════════════════════════════════════════════════════════

@dataclass
class ModInfo:
    """Information about a Nexus Mods mod"""
    mod_id: int
    name: str
    summary: str
    author: str
    version: str
    category_id: int
    endorsement_count: int
    downloads: int
    
    @classmethod
    def from_api(cls, data: dict) -> "ModInfo":
        return cls(
            mod_id=data.get("mod_id", 0),
            name=data.get("name", "Unknown"),
            summary=data.get("summary", ""),
            author=data.get("author", "Unknown"),
            version=data.get("version", "1.0"),
            category_id=data.get("category_id", 0),
            endorsement_count=data.get("endorsement_count", 0),
            downloads=data.get("mod_downloads", 0),
        )


@dataclass
class FileInfo:
    """Information about a mod file"""
    file_id: int
    name: str
    version: str
    category: str
    size_kb: int
    is_primary: bool
    
    @classmethod
    def from_api(cls, data: dict) -> "FileInfo":
        return cls(
            file_id=data.get("file_id", 0),
            name=data.get("name", "Unknown"),
            version=data.get("version", "1.0"),
            category=data.get("category_name", "Main"),
            size_kb=data.get("size_in_bytes", 0) // 1024,
            is_primary=data.get("is_primary", False),
        )


# ═══════════════════════════════════════════════════════════════════════════════
# API CLIENT
# ═══════════════════════════════════════════════════════════════════════════════

class NexusAPI:
    """Async client for Nexus Mods API"""
    
    def __init__(self, api_key: str, game_domain: str = GAME_DOMAIN):
        self.api_key = api_key
        self.game_domain = game_domain
        self.headers = {
            "apikey": api_key,
            "accept": "application/json",
        }
        self._client: Optional[httpx.AsyncClient] = None
    
    async def __aenter__(self):
        self._client = httpx.AsyncClient(
            base_url=BASE_URL,
            headers=self.headers,
            timeout=30.0,
        )
        return self
    
    async def __aexit__(self, *args):
        if self._client:
            await self._client.aclose()
    
    async def validate_key(self) -> dict:
        """Validate API key and return user info"""
        resp = await self._client.get("/users/validate.json")
        resp.raise_for_status()
        return resp.json()
    
    async def search_mods(self, query: str, include_adult: bool = False) -> list[dict]:
        """Search for mods by name"""
        # Note: Nexus search API is limited, we use the game mods endpoint
        # and filter client-side for better results
        resp = await self._client.get(
            f"/games/{self.game_domain}/mods/updated.json",
            params={"period": "1m"}
        )
        resp.raise_for_status()
        
        # Filter by query (case-insensitive)
        query_lower = query.lower()
        return [
            mod for mod in resp.json()
            if query_lower in mod.get("name", "").lower()
        ]
    
    async def get_mod(self, mod_id: int) -> ModInfo:
        """Get detailed information about a mod"""
        resp = await self._client.get(f"/games/{self.game_domain}/mods/{mod_id}.json")
        resp.raise_for_status()
        return ModInfo.from_api(resp.json())
    
    async def get_mod_files(self, mod_id: int) -> list[FileInfo]:
        """Get all files for a mod"""
        resp = await self._client.get(f"/games/{self.game_domain}/mods/{mod_id}/files.json")
        resp.raise_for_status()
        return [FileInfo.from_api(f) for f in resp.json().get("files", [])]
    
    async def get_download_link(self, mod_id: int, file_id: int) -> str:
        """Get download link for a file (requires Premium)"""
        resp = await self._client.get(
            f"/games/{self.game_domain}/mods/{mod_id}/files/{file_id}/download_link.json"
        )
        resp.raise_for_status()
        links = resp.json()
        if links:
            return links[0].get("URI", "")
        return ""
    
    async def search_by_name(self, name: str) -> Optional[int]:
        """Search for a mod by exact name and return its ID"""
        # Use the MD5 search endpoint which allows more specific queries
        # Or fall back to searching through updated mods
        name_lower = name.lower().strip()
        
        # Try to find in recently updated first
        resp = await self._client.get(
            f"/games/{self.game_domain}/mods/updated.json",
            params={"period": "1m"}
        )
        if resp.status_code == 200:
            for mod in resp.json():
                if mod.get("name", "").lower().strip() == name_lower:
                    return mod.get("mod_id")
        
        # If not found, we'll need to use alternative methods
        return None


# ═══════════════════════════════════════════════════════════════════════════════
# COMMANDS
# ═══════════════════════════════════════════════════════════════════════════════

async def cmd_validate_key():
    """Validate API key and show status"""
    async with NexusAPI(API_KEY) as api:
        try:
            user = await api.validate_key()
            
            table = Table(title="🔑 Nexus Mods API Key Validation")
            table.add_column("Property", style="cyan")
            table.add_column("Value", style="green")
            
            table.add_row("User ID", str(user.get("user_id", "N/A")))
            table.add_row("Username", user.get("name", "N/A"))
            table.add_row("Email", user.get("email", "N/A"))
            table.add_row("Premium", "✅ Yes" if user.get("is_premium") else "❌ No")
            table.add_row("Supporter", "✅ Yes" if user.get("is_supporter") else "❌ No")
            
            console.print(table)
            
            if user.get("is_premium"):
                console.print("\n[green]✅ Premium account - direct downloads available![/green]")
            else:
                console.print("\n[yellow]⚠️  Free account - manual downloads only[/yellow]")
                
        except httpx.HTTPStatusError as e:
            console.print(f"[red]❌ API Key validation failed: {e}[/red]")
            sys.exit(1)


async def cmd_user():
    """Show user information"""
    await cmd_validate_key()


async def cmd_search(query: str):
    """Search for mods"""
    async with NexusAPI(API_KEY) as api:
        console.print(f"🔍 Searching for: [cyan]{query}[/cyan]")
        
        mods = await api.search_mods(query)
        
        if not mods:
            console.print("[yellow]No mods found matching your query[/yellow]")
            return
        
        table = Table(title=f"Search Results ({len(mods)} found)")
        table.add_column("ID", style="cyan", width=8)
        table.add_column("Name", style="green")
        table.add_column("Author", style="blue")
        table.add_column("Downloads", style="magenta", justify="right")
        
        for mod in mods[:20]:  # Show top 20
            table.add_row(
                str(mod.get("mod_id", "")),
                mod.get("name", "")[:50],
                mod.get("author", "")[:20],
                f"{mod.get('mod_downloads', 0):,}",
            )
        
        console.print(table)


async def cmd_info(mod_id: int):
    """Get detailed mod information"""
    async with NexusAPI(API_KEY) as api:
        mod = await api.get_mod(mod_id)
        files = await api.get_mod_files(mod_id)
        
        # Mod info table
        table = Table(title=f"📦 {mod.name}")
        table.add_column("Property", style="cyan")
        table.add_column("Value", style="green")
        
        table.add_row("Mod ID", str(mod.mod_id))
        table.add_row("Author", mod.author)
        table.add_row("Version", mod.version)
        table.add_row("Downloads", f"{mod.downloads:,}")
        table.add_row("Endorsements", f"{mod.endorsement_count:,}")
        table.add_row("Summary", mod.summary[:100] + "..." if len(mod.summary) > 100 else mod.summary)
        
        console.print(table)
        
        # Files table
        if files:
            files_table = Table(title="📁 Available Files")
            files_table.add_column("File ID", style="cyan")
            files_table.add_column("Name", style="green")
            files_table.add_column("Version", style="blue")
            files_table.add_column("Category", style="yellow")
            files_table.add_column("Size", justify="right")
            files_table.add_column("Primary", justify="center")
            
            for f in files:
                size_str = f"{f.size_kb / 1024:.1f} MB" if f.size_kb > 1024 else f"{f.size_kb} KB"
                files_table.add_row(
                    str(f.file_id),
                    f.name[:40],
                    f.version,
                    f.category,
                    size_str,
                    "✅" if f.is_primary else "",
                )
            
            console.print(files_table)


async def cmd_download(mod_id: int, file_id: Optional[int] = None):
    """Download a mod file"""
    DOWNLOAD_DIR.mkdir(parents=True, exist_ok=True)
    
    async with NexusAPI(API_KEY) as api:
        # Get mod info
        mod = await api.get_mod(mod_id)
        console.print(f"📦 Downloading: [cyan]{mod.name}[/cyan]")
        
        # Get files
        files = await api.get_mod_files(mod_id)
        if not files:
            console.print("[red]❌ No files available for this mod[/red]")
            return
        
        # Select file
        if file_id:
            target_file = next((f for f in files if f.file_id == file_id), None)
        else:
            # Default to primary file or first main file
            target_file = next((f for f in files if f.is_primary), None)
            if not target_file:
                target_file = next((f for f in files if f.category == "MAIN"), None)
            if not target_file:
                target_file = files[0]
        
        if not target_file:
            console.print("[red]❌ Could not find target file[/red]")
            return
        
        console.print(f"📁 File: [green]{target_file.name}[/green] ({target_file.version})")
        
        # Get download link (requires Premium)
        try:
            download_url = await api.get_download_link(mod_id, target_file.file_id)
            if not download_url:
                console.print("[yellow]⚠️  No download URL returned - Premium may be required[/yellow]")
                return
        except httpx.HTTPStatusError as e:
            if e.response.status_code == 403:
                console.print("[red]❌ Premium account required for direct downloads[/red]")
                console.print(f"   Manual download: https://www.nexusmods.com/{GAME_DOMAIN}/mods/{mod_id}?tab=files")
                return
            raise
        
        # Download the file
        output_path = DOWNLOAD_DIR / f"{mod.name.replace(' ', '_')}_{target_file.version}.zip"
        
        async with httpx.AsyncClient() as download_client:
            with Progress(
                SpinnerColumn(),
                TextColumn("[progress.description]{task.description}"),
                BarColumn(),
                TaskProgressColumn(),
            ) as progress:
                task = progress.add_task(f"Downloading...", total=target_file.size_kb * 1024)
                
                async with download_client.stream("GET", download_url) as response:
                    response.raise_for_status()
                    with open(output_path, "wb") as f:
                        async for chunk in response.aiter_bytes():
                            f.write(chunk)
                            progress.update(task, advance=len(chunk))
        
        console.print(f"[green]✅ Downloaded: {output_path}[/green]")
        return output_path


async def cmd_download_collection(catalog_path: str):
    """Download all mods from a collection catalog JSON"""
    catalog_file = Path(catalog_path)
    if not catalog_file.exists():
        console.print(f"[red]❌ Catalog file not found: {catalog_path}[/red]")
        sys.exit(1)
    
    with open(catalog_file) as f:
        catalog = json.load(f)
    
    mods = catalog.get("mods", [])
    console.print(f"📦 Collection: [cyan]{catalog.get('collection', 'Unknown')}[/cyan]")
    console.print(f"📊 Total mods: [green]{len(mods)}[/green]")
    
    # Create download directory
    collection_dir = DOWNLOAD_DIR / catalog.get("collection", "collection").replace(" ", "_")
    collection_dir.mkdir(parents=True, exist_ok=True)
    
    # Validate API key first
    async with NexusAPI(API_KEY) as api:
        user = await api.validate_key()
        is_premium = user.get("is_premium", False)
        
        if not is_premium:
            console.print("[yellow]⚠️  Free account detected - generating manual download links[/yellow]")
        
        results = {
            "downloaded": [],
            "manual_required": [],
            "failed": [],
            "not_found": [],
        }
        
        with Progress(
            SpinnerColumn(),
            TextColumn("[progress.description]{task.description}"),
            BarColumn(),
            TaskProgressColumn(),
        ) as progress:
            task = progress.add_task("Processing mods...", total=len(mods))
            
            for mod in mods:
                mod_name = mod.get("name", "Unknown")
                progress.update(task, description=f"Processing: {mod_name[:30]}...")
                
                # Skip bundled assets (no Nexus page)
                if mod.get("section") == "Bundled Assets":
                    progress.update(task, advance=1)
                    continue
                
                # Search for the mod
                try:
                    mod_id = await api.search_by_name(mod_name)
                    
                    if not mod_id:
                        # Try a fuzzy search
                        search_results = await api.search_mods(mod_name.split()[0])
                        for result in search_results:
                            if mod_name.lower() in result.get("name", "").lower():
                                mod_id = result.get("mod_id")
                                break
                    
                    if not mod_id:
                        results["not_found"].append(mod_name)
                        progress.update(task, advance=1)
                        continue
                    
                    # Get files
                    files = await api.get_mod_files(mod_id)
                    if not files:
                        results["failed"].append((mod_name, "No files available"))
                        progress.update(task, advance=1)
                        continue
                    
                    # Get primary file
                    target_file = next((f for f in files if f.is_primary), None) or files[0]
                    
                    if is_premium:
                        # Download directly
                        try:
                            download_url = await api.get_download_link(mod_id, target_file.file_id)
                            output_path = collection_dir / f"{mod_name.replace(' ', '_')}.zip"
                            
                            async with httpx.AsyncClient(timeout=300) as dl_client:
                                response = await dl_client.get(download_url)
                                response.raise_for_status()
                                with open(output_path, "wb") as f:
                                    f.write(response.content)
                            
                            results["downloaded"].append(mod_name)
                        except Exception as e:
                            results["failed"].append((mod_name, str(e)))
                    else:
                        # Generate manual download link
                        results["manual_required"].append({
                            "name": mod_name,
                            "mod_id": mod_id,
                            "file_id": target_file.file_id,
                            "url": f"https://www.nexusmods.com/{GAME_DOMAIN}/mods/{mod_id}?tab=files",
                        })
                    
                except Exception as e:
                    results["failed"].append((mod_name, str(e)))
                
                progress.update(task, advance=1)
                
                # Rate limiting - be nice to the API
                await asyncio.sleep(0.5)
        
        # Summary
        console.print("\n" + "═" * 60)
        console.print("[bold]📊 Download Summary[/bold]")
        console.print("═" * 60)
        
        if results["downloaded"]:
            console.print(f"\n[green]✅ Downloaded ({len(results['downloaded'])}):[/green]")
            for name in results["downloaded"][:10]:
                console.print(f"   • {name}")
            if len(results["downloaded"]) > 10:
                console.print(f"   ... and {len(results['downloaded']) - 10} more")
        
        if results["manual_required"]:
            console.print(f"\n[yellow]📥 Manual download required ({len(results['manual_required'])}):[/yellow]")
            
            # Save manual download list
            manual_file = collection_dir / "manual_downloads.json"
            with open(manual_file, "w") as f:
                json.dump(results["manual_required"], f, indent=2)
            console.print(f"   Saved to: {manual_file}")
            
            # Also create a simple text file with URLs
            urls_file = collection_dir / "download_urls.txt"
            with open(urls_file, "w") as f:
                for mod in results["manual_required"]:
                    f.write(f"{mod['name']}\n")
                    f.write(f"  {mod['url']}\n\n")
            console.print(f"   URLs saved to: {urls_file}")
        
        if results["not_found"]:
            console.print(f"\n[red]❓ Not found ({len(results['not_found'])}):[/red]")
            for name in results["not_found"]:
                console.print(f"   • {name}")
        
        if results["failed"]:
            console.print(f"\n[red]❌ Failed ({len(results['failed'])}):[/red]")
            for name, error in results["failed"][:5]:
                console.print(f"   • {name}: {error[:50]}")


# ═══════════════════════════════════════════════════════════════════════════════
# MAIN ENTRY POINT
# ═══════════════════════════════════════════════════════════════════════════════

def main():
    if len(sys.argv) < 2:
        console.print("""
[bold cyan]🎮 Nexus Mods API Tool[/bold cyan]

Usage:
  [green]uv run nexus-api.py validate-key[/green]              Validate API key
  [green]uv run nexus-api.py user[/green]                      Show user information
  [green]uv run nexus-api.py search "query"[/green]            Search for mods
  [green]uv run nexus-api.py info <mod_id>[/green]             Get mod details
  [green]uv run nexus-api.py download <mod_id>[/green]         Download a mod
  [green]uv run nexus-api.py download-collection <json>[/green] Download all mods from catalog

Environment:
  API key is read from [cyan].env[/cyan] file in the stardew-modding-nix directory
        """)
        return
    
    command = sys.argv[1]
    
    if command == "validate-key":
        asyncio.run(cmd_validate_key())
    elif command == "user":
        asyncio.run(cmd_user())
    elif command == "search" and len(sys.argv) > 2:
        asyncio.run(cmd_search(sys.argv[2]))
    elif command == "info" and len(sys.argv) > 2:
        asyncio.run(cmd_info(int(sys.argv[2])))
    elif command == "download" and len(sys.argv) > 2:
        file_id = int(sys.argv[3]) if len(sys.argv) > 3 else None
        asyncio.run(cmd_download(int(sys.argv[2]), file_id))
    elif command == "download-collection" and len(sys.argv) > 2:
        asyncio.run(cmd_download_collection(sys.argv[2]))
    else:
        console.print("[red]Unknown command or missing arguments[/red]")
        console.print("Run without arguments to see usage")


if __name__ == "__main__":
    main()

