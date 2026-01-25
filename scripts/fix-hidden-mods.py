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
Fix the 'hidden' mods by finding correct Nexus mod IDs.
The issue: our API search matched mod names to WRONG mod IDs.
"""

import asyncio
import json
import os
import re
from pathlib import Path

import httpx
from dotenv import load_dotenv
from rich.console import Console
from rich.progress import Progress, SpinnerColumn, TextColumn
from rich.table import Table

load_dotenv()
console = Console()

API_KEY = os.getenv("NEXUS_API_KEY")
GAME_DOMAIN = "stardewvalley"
BASE_URL = "https://api.nexusmods.com/v1"

# Known correct IDs for popular mods
KNOWN_CORRECT_IDS = {
    "UI Info Suite 2": 12752,  # The actual UI Info Suite 2
    "SMAPI - Stardew Modding API": 2400,
    "Content Patcher": 1915,
    "Generic Mod Config Menu": 5098,
    "SpaceCore": 1348,
    "Custom NPC Fixes": 3849,
    "Social Page Order Redux": 12217,  # Check if this one is correct
    "Stardew Valley Expanded": 3753,
    "Json Assets": 1720,
    "Mail Framework Mod": 1536,
    "PyTK": 1726,  # May be deprecated
    "TMXL Map Toolkit": 1820,
    "Quest Framework": 6414,
    "Farm Type Manager": 3231,
    "Custom Companions": 8626,
    "Custom Music": 3043,
    "Fashion Sense": 9969,
    "Alternative Textures": 9246,
    "Dynamic Game Assets": 9365,
    "Shop Tile Framework": 5005,
    "Producer Framework Mod": 4970,
    "Expanded Preconditions Utility": 6529,
    "Custom NPC Exclusions": 7089,
    "Ridgeside Village": 7286,
    "East Scarp": 5787,
    "Automate": 1063,
    "CJB Cheats Menu": 4,
    "CJB Item Spawner": 93,
    "Lookup Anything": 541,
    "Data Layers": 1691,
    "Chests Anywhere": 518,
    "Tractor Mod": 1401,
    "Horse Flute Anywhere": 7500,
    "Schedule Viewer": 19594,  # Check
}


# Mods that failed with "hidden" error
HIDDEN_MODS = [
    ("Animated Clothes", 11025),
    ("Animated East Scarp Fish", 8489),
    ("Animated Frog Pots", 17384),
    ("Animated Furniture and Stuff", 8456),
    ("Animated Ridgeside Village Fish", 10315),
    ("Dynamic Reflections", 15833),
    ("HxW Tilesheets", 6014),
    ("Kari's Delivery Service - A Seasonal Mailbox Mod", 21654),
    ("Kyuya's accessories pack", 17978),
    ("Kyuya's hats pack", 17977),
    ("Luny's Flower Veils for Fashion Sense", 21637),
    ("Precise Furniture", 21628),
    ("Pretty Wallpaper", 21647),
    ("Schedule Viewer", 19594),
    ("Seasonal Cute Characters for East Scarp", 13872),
    ("Shardust's Pastel Furniture for Alternative Textures", 17123),
    ("Shardust's Pastel Interiors - kitchen - for Alternative Textures", 17122),
    ("Sharogg's Tilesheets (modular bridges and more to come)", 21656),
    ("Social Page Order Redux", 12217),
    ("Solarium (Rooftop Spa House) - Continued", 21680),
    ("Tidy Pam (Content Patcher)", 21695),
    ("Tiny Totem Statue Obelisks", 21680),  # Duplicate ID issue!
    ("UI Info Suite 2", 10879),  # WRONG - should be 12752
    ("Universal Recolors", 21700),  # Check
]


async def check_mod_status(client: httpx.AsyncClient, mod_id: int, mod_name: str) -> dict:
    """Check if a mod is hidden, deleted, or has wrong ID"""
    try:
        resp = await client.get(
            f"{BASE_URL}/games/{GAME_DOMAIN}/mods/{mod_id}.json",
            headers={"apikey": API_KEY},
        )
        if resp.status_code == 200:
            data = resp.json()
            return {
                "status": "available",
                "actual_name": data.get("name"),
                "mod_id": mod_id,
                "expected_name": mod_name,
                "match": mod_name.lower() in data.get("name", "").lower() or data.get("name", "").lower() in mod_name.lower(),
            }
        elif resp.status_code == 404:
            return {"status": "not_found", "mod_id": mod_id, "expected_name": mod_name}
        elif resp.status_code == 403:
            return {"status": "hidden", "mod_id": mod_id, "expected_name": mod_name}
        else:
            return {"status": f"error_{resp.status_code}", "mod_id": mod_id, "expected_name": mod_name}
    except Exception as e:
        return {"status": f"error: {e}", "mod_id": mod_id, "expected_name": mod_name}


async def search_for_mod(client: httpx.AsyncClient, mod_name: str) -> list:
    """Search for a mod by name to find correct ID"""
    # Clean the name for search
    search_name = re.sub(r"\([^)]*\)", "", mod_name).strip()  # Remove parenthetical content
    search_name = search_name.split(" - ")[0].strip()  # Take first part before dash
    
    try:
        # Use the web search endpoint (undocumented but works)
        resp = await client.get(
            f"https://www.nexusmods.com/Core/Libs/Common/Widgets/ModList",
            params={
                "RH_ModList": f"game_id:1303,sort:date,order:DESC,advfilt:4,search:{search_name}",
                "format": "json",
            },
            headers={"apikey": API_KEY},
        )
        # This won't work directly - need different approach
        return []
    except Exception:
        return []


async def main():
    console.print("[bold cyan]🔍 Checking 'hidden' mods for wrong IDs...[/bold cyan]\n")
    
    results = {
        "wrong_id": [],
        "hidden": [],
        "available": [],
        "not_found": [],
    }
    
    async with httpx.AsyncClient(timeout=30.0) as client:
        with Progress(
            SpinnerColumn(),
            TextColumn("[progress.description]{task.description}"),
            console=console,
        ) as progress:
            task = progress.add_task("Checking mods...", total=len(HIDDEN_MODS))
            
            for mod_name, mod_id in HIDDEN_MODS:
                progress.update(task, description=f"Checking: {mod_name[:30]}...")
                
                result = await check_mod_status(client, mod_id, mod_name)
                
                if result["status"] == "available":
                    if not result["match"]:
                        results["wrong_id"].append({
                            **result,
                            "issue": f"ID {mod_id} is '{result['actual_name']}', NOT '{mod_name}'"
                        })
                    else:
                        results["available"].append(result)
                elif result["status"] == "hidden":
                    results["hidden"].append(result)
                elif result["status"] == "not_found":
                    results["not_found"].append(result)
                
                progress.advance(task)
                await asyncio.sleep(0.3)
    
    # Print results
    console.print("\n[bold green]✅ Results Summary[/bold green]\n")
    
    # Wrong IDs (the main issue!)
    if results["wrong_id"]:
        console.print(f"[bold red]🚨 WRONG MOD IDs ({len(results['wrong_id'])}):[/bold red]")
        table = Table()
        table.add_column("Expected Mod")
        table.add_column("Our ID")
        table.add_column("Actual Mod at ID")
        for r in results["wrong_id"]:
            table.add_row(r["expected_name"][:35], str(r["mod_id"]), r["actual_name"][:35])
        console.print(table)
    
    # Actually hidden
    if results["hidden"]:
        console.print(f"\n[bold yellow]🔒 Actually Hidden ({len(results['hidden'])}):[/bold yellow]")
        for r in results["hidden"]:
            console.print(f"  • {r['expected_name']} (ID: {r['mod_id']})")
    
    # Available (correct IDs)
    if results["available"]:
        console.print(f"\n[bold green]✅ Correct IDs ({len(results['available'])}):[/bold green]")
        for r in results["available"]:
            console.print(f"  • {r['expected_name']} → ID {r['mod_id']}")
    
    # Generate fixes
    console.print("\n[bold cyan]📝 Generating fix recommendations...[/bold cyan]")
    
    # Output the mods we need to manually look up
    console.print("\n[bold magenta]Mods needing manual ID lookup:[/bold magenta]")
    for r in results["wrong_id"]:
        console.print(f"  • {r['expected_name']}")
    for r in results["hidden"]:
        console.print(f"  • {r['expected_name']}")


if __name__ == "__main__":
    asyncio.run(main())

