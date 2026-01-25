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
Build a comprehensive mod catalog with Nexus Mod IDs by searching the API.

This script takes mod names and searches Nexus Mods API to find their IDs.
"""

import asyncio
import json
import os
import re
from pathlib import Path

import httpx
from dotenv import load_dotenv
from rich.console import Console
from rich.progress import Progress, SpinnerColumn, TextColumn, BarColumn, TaskProgressColumn

# Load API key
SCRIPT_DIR = Path(__file__).parent.parent
ENV_FILE = SCRIPT_DIR / ".env"
load_dotenv(ENV_FILE)

API_KEY = os.getenv("NEXUS_API_KEY") or open(ENV_FILE).read().strip()
BASE_URL = "https://api.nexusmods.com/v1"
GAME_DOMAIN = "stardewvalley"

console = Console()

# Known mod IDs for popular Stardew Valley mods (manual lookup for accuracy)
KNOWN_MODS = {
    # Core modding tools
    "SMAPI - Stardew Modding API": 2400,
    "Content Patcher": 1915,
    "Generic Mod Config Menu (GMCM)": 5098,
    "SpaceCore": 1348,
    "Content Patcher Animations": 3853,
    
    # Popular mods from Pathoschild
    "Automate": 1063,
    "Chests Anywhere": 518,
    "Lookup Anything": 541,
    
    # SVE and expansions
    "Stardew Valley Expanded": 3753,
    "East Scarp": 5787,
    "Ridgeside Village": 7286,
    
    # UI mods
    "UI Info Suite 2": 10879,
    "NPC Map Locations": 239,
    
    # Popular character mods
    "(CP) I Fixed Him - A Shane Consistency Mod": 21660,
    
    # Framework mods
    "Farm Type Manager (FTM)": 3231,
    "Mail Framework Mod": 1536,
    "Custom Companions": 8626,
    "Mapping Extensions and Extra Properties (MEEP)": 14493,
    "DaisyNiko's Tilesheets": 4736,
    "HxW Tilesheets": 6014,
    "Lumisteria Tilesheets - Indoor": 9599,
    "Lumisteria Tilesheets - Outdoor": 9601,
    
    # Quality of life
    "Better Crafting": 11115,
    "Better Signs": 20884,
    "Convenient Inventory": 18949,
    "Faster Path Speed": 11505,
    "Machine Input Return - Get Your Items Back": 17282,
    "Multi Save - Continued": 9927,
    "Relocate Buildings And Farm Animals": 20606,
    "Time Master (UNOFFICIAL UPDATE)": 14853,
    "Sit For Stamina": 2717,
    
    # Visuals
    "Animated Fish": 4468,
    "Animated Food and Drinks": 7548,
    "Animated Furniture and Stuff": 8456,
    "Animated Clothes": 11025,
    "Animated Gemstones 1.1.7": 14797,
    "Dynamic Reflections": 15833,
    "Font Settings": 12467,
    "Standardized Seed Sprites": 27098,
    
    # Characters/NPCs
    "Marnie Deserves Better": 14552,
    "Cuter Slimes Refreshed": 21629,
    "Seasonal Outfits - Slightly Cuter Aesthetic": 5450,
    
    # Events
    "Event Limiter": 10735,
    "Event Lookup": 8505,
    "Community Center Reimagined": 6966,
    
    # Other
    "(Content Patcher) Spouse Rooms Redesigned": 5906,
    "Add Berry Seasons to Calendar": 14815,
    "Anniversary on Calendar": 8351,
    "Buildable Ginger Island Farm": 20601,
    "Clint Reforged": 21536,
    "Dialogue Display Framework Continued (DDFC)": 18925,
    "Dialogue Display Tweaks - Configurable Dialogue Box UI": 22104,
    "Friends Forever (1.6)": 5767,
    "Integrated Minecarts - A Minecart Expansion": 11893,
    "Mini Bars - Healthbars Mod": 11818,
    "No Pam Enabling (CP)": 9792,
    "Part of the Community": 923,
    "Schedule Viewer": 19594,
    "Show Item Quality (1.6 Unofficial)": 19763,
    "SinZational Speedy Solutions": 22163,
    "Social Page Order Redux": 12217,
    "Solarium (Rooftop Spa House) - Continued": 21680,
    "Spouses React to Player 'Death'": 22154,
    "To-Dew": 7409,
    "Trinket Tinker": 22091,
    "World Maps everywhere": 20194,
    
    # Animated fish variants
    "Animated East Scarp Fish": 8489,
    "Animated Fish SVE": 8584,
    "Animated Ridgeside Village Fish": 10315,
    "Animated Slime Eggs and Loot": 11072,
    
    # Seasonal mods
    "Seasonal Mariner To Mermaid": 21635,
    "Seasonal Cute Characters for East Scarp": 13872,
    "Seasonal Outfits - Slightly Cuter Aesthetic for SVE": 5969,
    "Seasonal Outfits for Ridgeside Village": 15065,
    
    # Portraits  
    "They Deserve It Too - Portraits for Extras": 21785,
    "They Deserve It Too - Portraits for Vendors": 21786,
    
    # Misc
    "Tidy Pam (Content Patcher)": 21695,
    "Tiny Totem Statue Obelisks": 21680,
    "Yagisan's Custom NPCs for NPC Map Locations": 8174,
    "Stardew Valley VERY Configured (1.6)": 21652,
    "Button's Extra Trigger Action Stuff (BETAS)": 22163,
    
    # Optional mods
    "Additional Farm Cave": 16802,
    "Creative Differences - NPC Rodney (East Scarp)": 10389,
    "Downhill Project - Expanded Map for Custom NPCs": 21519,
    "Eli and Dylan - Custom NPCs for East Scarp": 10413,
    "Leilani (NPC for Ridgeside Village)": 10414,
    "Lurking in the Dark - NPC Sen (East Scarp)": 10413,
    "Nora The Herpetologist - Custom NPC for East Scarp": 10571,
    "Sword and Sorcery - A Fantasy Expansion for East Scarp": 12369,
}


async def search_mod_by_name(client: httpx.AsyncClient, name: str) -> int | None:
    """Search for a mod by name and return its ID"""
    # Clean up the name for searching
    clean_name = re.sub(r'\([^)]*\)', '', name).strip()  # Remove parenthetical content
    clean_name = clean_name.replace("'", "").replace('"', '')
    
    # Search terms to try
    search_terms = [
        clean_name,
        clean_name.split(' - ')[0].strip() if ' - ' in clean_name else None,
        ' '.join(clean_name.split()[:3]) if len(clean_name.split()) > 3 else None,
    ]
    
    for term in search_terms:
        if not term:
            continue
            
        try:
            # Use mods search endpoint
            resp = await client.get(
                f"{BASE_URL}/games/{GAME_DOMAIN}/mods/md5_search/{term}.json",
                headers={"apikey": API_KEY}
            )
            if resp.status_code == 200:
                data = resp.json()
                if data:
                    return data[0].get("mod_id")
        except:
            pass
    
    return None


async def build_catalog():
    """Build catalog with mod IDs"""
    # Load existing catalog
    catalog_file = SCRIPT_DIR / "collection-catalog.json"
    if not catalog_file.exists():
        console.print("[red]No collection-catalog.json found[/red]")
        return
    
    with open(catalog_file) as f:
        catalog = json.load(f)
    
    mods = catalog.get("mods", [])
    console.print(f"📦 Processing {len(mods)} mods...")
    
    async with httpx.AsyncClient(timeout=30) as client:
        with Progress(
            SpinnerColumn(),
            TextColumn("[progress.description]{task.description}"),
            BarColumn(),
            TaskProgressColumn(),
        ) as progress:
            task = progress.add_task("Looking up mod IDs...", total=len(mods))
            
            for mod in mods:
                name = mod.get("name", "")
                progress.update(task, description=f"Processing: {name[:30]}...")
                
                # Check known mods first
                mod_id = KNOWN_MODS.get(name)
                
                if not mod_id:
                    # Try API search
                    mod_id = await search_mod_by_name(client, name)
                
                if mod_id:
                    mod["mod_id"] = mod_id
                    mod["url"] = f"https://www.nexusmods.com/stardewvalley/mods/{mod_id}"
                
                progress.update(task, advance=1)
                await asyncio.sleep(0.3)  # Rate limiting
    
    # Save updated catalog
    output_file = SCRIPT_DIR / "collection-catalog-with-ids.json"
    with open(output_file, "w") as f:
        json.dump(catalog, f, indent=2)
    
    console.print(f"[green]✅ Saved catalog with IDs to: {output_file}[/green]")
    
    # Stats
    found = sum(1 for m in mods if m.get("mod_id"))
    console.print(f"📊 Found IDs for {found}/{len(mods)} mods")


if __name__ == "__main__":
    asyncio.run(build_catalog())

