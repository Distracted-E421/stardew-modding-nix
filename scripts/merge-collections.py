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
Merge VERY Expanded + Fairycore collections with deduplication.

Excludes conflicting farm mods (only Immersive Farm 2/Frontier from SVE).
Includes ALL optional mods from both collections.
"""

import json
from pathlib import Path
from rich.console import Console
from rich.table import Table

console = Console()

SCRIPT_DIR = Path(__file__).parent.parent

# VERY Expanded catalog
VERY_EXPANDED_CATALOG = SCRIPT_DIR / "collection-catalog-with-ids.json"

# Known mod IDs (expanded for Fairycore mods)
KNOWN_MODS = {
    # === From build-mod-catalog.py ===
    "SMAPI - Stardew Modding API": 2400,
    "Content Patcher": 1915,
    "Generic Mod Config Menu (GMCM)": 5098,
    "SpaceCore": 1348,
    "Content Patcher Animations": 3853,
    "Automate": 1063,
    "Chests Anywhere": 518,
    "Lookup Anything": 541,
    "Stardew Valley Expanded": 3753,
    "East Scarp": 5787,
    "Ridgeside Village": 7286,
    "UI Info Suite 2": 10879,
    "NPC Map Locations": 239,
    "(CP) I Fixed Him - A Shane Consistency Mod": 21660,
    "Farm Type Manager (FTM)": 3231,
    "Mail Framework Mod": 1536,
    "Custom Companions": 8626,
    "Mapping Extensions and Extra Properties (MEEP)": 14493,
    "DaisyNiko's Tilesheets": 4736,
    "HxW Tilesheets": 6014,
    "Lumisteria Tilesheets - Indoor": 9599,
    "Lumisteria Tilesheets - Outdoor": 9601,
    "Better Crafting": 11115,
    "Font Settings": 12467,
    "Multi Save - Continued": 9927,
    "Relocate Buildings And Farm Animals": 20606,
    "Sit For Stamina": 2717,
    "Stardew Valley VERY Configured (1.6)": 21652,
    "Cuter Slimes Refreshed": 21629,
    "SinZational Speedy Solutions": 22163,
    "Tiny Totem Statue Obelisks": 21680,
    
    # === Fairycore-specific mods ===
    "Alternative Textures": 9246,
    "Fashion Sense": 9969,
    "(CP and AT) Nano's Garden Style Craftables": 21685,
    "(FS - CP) Kkunma Hair collection": 19654,
    "AT Sweetheart Furniture Set": 18917,
    "Aesthetic Secret Notes": 21639,
    "Animated Bird Tappers": 15423,
    "Animated Duck Crab Pots for Alternative Textures": 21645,
    "Animated Fairies for Alternative Textures": 21644,
    "Animated Frog Pots": 17384,
    "Bathhouse Hot Spring - Continued": 21679,
    "Bear Craftables (CP and AT)": 13881,
    "Casual Furniture Set": 21582,
    "Cottage Core Walls and Floors AT": 12469,
    "Cottagecore Fences for Alternative Textures": 11813,
    "Cute Pastel Calendar": 18534,
    "Cute Prize Tickets": 21631,
    "Cute and Tidy Coops and Barns": 18992,
    "Cute gift box": 21633,
    "Dawn's Hummingbird Wings for Fashion Sense": 21634,
    "Elle's Cuter Barn Animals": 3167,
    "Elle's Cuter Cats": 3872,
    "Elle's Cuter Coop Animals": 3168,
    "Elle's Cuter Dogs": 3871,
    "FS - Animal Features": 17591,
    "Fae Wing Set (Fashion Sense)": 14459,
    "Fae's Elf Ears": 21632,
    "Four sets of fairy clothes": 21636,
    "Frog Hat (FS) (CP) Available": 21642,
    "Furniture Example Pack for Alternative Textures (Pink-Blue)": 11817,
    "Happy Home Designer": 21671,
    "Kari's Delivery Service - A Seasonal Mailbox Mod": 21654,
    "Kyuya's accessories pack": 17978,
    "Kyuya's hats pack": 17977,
    "Luny's Flower Veils for Fashion Sense": 21637,
    "Mushroom Furniture for Alternative Textures": 14461,
    "Myc's Seasonal Fireplace for CP and AT": 13562,
    "Oh So Cute Kitchen": 21581,
    "Plain Slime Hutch Interior": 11920,
    "Precise Furniture": 21628,
    "Pretty Pink Furniture Recolour": 20839,
    "Pretty Pink Wallpaper": 21648,
    "Pretty Wallpaper": 21647,
    "SVE Trees Recolored - For Popular Recolors": 21661,
    "Seasonal Mariner To Mermaid": 21635,
    "Seasonal  Mariner To Mermaid": 21635,  # Handle spacing variant
    "Seasonal Hedge Fences (Starblue)": 21643,
    "Shardust's Pastel Furniture for Alternative Textures": 17123,
    "Shardust's Pastel Interiors - kitchen - crib - cellar - shed - cabin": 17122,
    "Sharogg's Tilesheets (modular bridges and more to come)": 21656,
    "Simple Foliage - Unofficial Update for 1.6": 21668,
    "Skell's Flowery Weapons": 21651,
    "Universal Recolors": 21669,
    "Yomi's Cute Princess Dress-FS (Applicable 1.6)": 21649,
    "Yomi's Golden Princess Hairstyle-FS (Applicable 1.6)": 21650,
    
    # === Fairycore Optional mods ===
    "Forest Wood Craftables": 17594,
    "Lnh's MiNi Farm": 21672,  # FARM MOD - exclude if not wanted
    "Overgrown Flowery Interface": 21640,
    "Seasonal Floral Bus Recolor": 21641,
    "Seasonal Flower Sprinklers Refreshed": 21646,
    "Skell's Flowery Tools": 21653,
    "Squishi's Rideable Deer for Content Patcher and Alternatve Textures": 16875,
    "Starblue Valley Unofficial": 21666,
    "Sunroom Greenhouse": 21667,
    "Tanga forest Buildings": 18374,
    "Tanga forest Gold Clock": 18376,
    "Additional Farm Cave": 16802,
    
    # === VERY Expanded Optional NPCs ===
    "Creative Differences - NPC Rodney (East Scarp)": 10389,
    "Downhill Project - Expanded Map for Custom NPCs": 21519,
    "Eli and Dylan - Custom NPCs for East Scarp": 10413,
    "Leilani (NPC for Ridgeside Village)": 10414,
    "Lurking in the Dark - NPC Sen (East Scarp)": 10413,
    "Nora The Herpetologist - Custom NPC for East Scarp": 10571,
    "Sword and Sorcery - A Fantasy Expansion for East Scarp": 12369,
}

# Mods to EXCLUDE (conflicting farm mods, duplicates of SVE Immersive Farm 2)
EXCLUDED_MODS = {
    "Grandpa's Farm",
    "Grandpas Farm",
    "Stardew Remastered",
    "2K Remastered",
    "Lnh's MiNi Farm",  # Different farm layout, conflicts with SVE Immersive Farm 2
}

# Fairycore collection data (extracted from Playwright)
FAIRYCORE_MODS = [
    {"name": "(CP and AT) Nano's Garden Style Craftables", "uploader": "NanoIsNotRobot", "category": "Crafting", "section": "Required"},
    {"name": "(FS - CP) Kkunma Hair collection", "uploader": "halpyy", "category": "Player", "section": "Required"},
    {"name": "AT Sweetheart Furniture Set", "uploader": "wabiii", "category": "Furniture", "section": "Required"},
    {"name": "Aesthetic Secret Notes", "uploader": "Wakasagihime99", "category": "Items", "section": "Required"},
    {"name": "Alternative Textures", "uploader": "PeacefulEnd", "category": "Modding Tools", "section": "Required"},
    {"name": "Animated Bird Tappers", "uploader": "dollynhoevida", "category": "Crafting", "section": "Required"},
    {"name": "Animated Duck Crab Pots for Alternative Textures", "uploader": "JennaJuffuffles", "category": "Visuals and Graphics", "section": "Required"},
    {"name": "Animated Fairies for Alternative Textures", "uploader": "JennaJuffuffles", "category": "Visuals and Graphics", "section": "Required"},
    {"name": "Animated Frog Pots", "uploader": "dollynhoevida", "category": "Crafting", "section": "Required"},
    {"name": "Bathhouse Hot Spring - Continued", "uploader": "Sandman53", "category": "Maps", "section": "Required"},
    {"name": "Bear Craftables (CP and AT)", "uploader": "holythesea", "category": "Visuals and Graphics", "section": "Required"},
    {"name": "Casual Furniture Set", "uploader": "katestardew", "category": "Furniture", "section": "Required"},
    {"name": "Content Patcher", "uploader": "Pathoschild", "category": "Modding Tools", "section": "Required"},
    {"name": "Cottage Core Walls and Floors AT", "uploader": "DatGrayFox", "category": "Buildings", "section": "Required"},
    {"name": "Cottagecore Fences for Alternative Textures", "uploader": "Gweniaczek", "category": "Visuals and Graphics", "section": "Required"},
    {"name": "Cute Pastel Calendar", "uploader": "naeldeus", "category": "Items", "section": "Required"},
    {"name": "Cute Prize Tickets", "uploader": "LooneyLuny", "category": "Items", "section": "Required"},
    {"name": "Cute and Tidy Coops and Barns", "uploader": "neuralwiles", "category": "Maps", "section": "Required"},
    {"name": "Cute gift box", "uploader": "Bitnaaa", "category": "User Interface", "section": "Required"},
    {"name": "Cuter Slimes Refreshed", "uploader": "JennaJuffuffles", "category": "Livestock and Animals", "section": "Required"},
    {"name": "DaisyNiko's Tilesheets", "uploader": "DaisyNiko", "category": "Modding Tools", "section": "Required"},
    {"name": "Dawn's Hummingbird Wings for Fashion Sense", "uploader": "LooneyLuny", "category": "Clothing", "section": "Required"},
    {"name": "Elle's Cuter Barn Animals", "uploader": "junimods", "category": "Livestock and Animals", "section": "Required"},
    {"name": "Elle's Cuter Cats", "uploader": "junimods", "category": "Pets / Horses", "section": "Required"},
    {"name": "Elle's Cuter Coop Animals", "uploader": "junimods", "category": "Livestock and Animals", "section": "Required"},
    {"name": "Elle's Cuter Dogs", "uploader": "junimods", "category": "Pets / Horses", "section": "Required"},
    {"name": "FS - Animal Features", "uploader": "MousyModder", "category": "Clothing", "section": "Required"},
    {"name": "Fae Wing Set (Fashion Sense)", "uploader": "hummingmints", "category": "Clothing", "section": "Required"},
    {"name": "Fae's Elf Ears", "uploader": "FaerieFangs0", "category": "Clothing", "section": "Required"},
    {"name": "Farm Type Manager (FTM)", "uploader": "EscaMMC", "category": "Modding Tools", "section": "Required"},
    {"name": "Fashion Sense", "uploader": "PeacefulEnd", "category": "Modding Tools", "section": "Required"},
    {"name": "Font Settings", "uploader": "Becks723", "category": "Visuals and Graphics", "section": "Required"},
    {"name": "Four sets of fairy clothes", "uploader": "damiemieteacher", "category": "Clothing", "section": "Required"},
    {"name": "Frog Hat (FS) (CP) Available", "uploader": "Schmellows", "category": "Player", "section": "Required"},
    {"name": "Furniture Example Pack for Alternative Textures (Pink-Blue)", "uploader": "lnss94", "category": "Visuals and Graphics", "section": "Required"},
    {"name": "Generic Mod Config Menu (GMCM)", "uploader": "spacechase0", "category": "Modding Tools", "section": "Required"},
    {"name": "Happy Home Designer", "uploader": "tlitookilakin", "category": "User Interface", "section": "Required"},
    {"name": "Kari's Delivery Service - A Seasonal Mailbox Mod", "uploader": "kariiiii", "category": "Visuals and Graphics", "section": "Required"},
    {"name": "Kyuya's accessories pack", "uploader": "Kyuya258369", "category": "Clothing", "section": "Required"},
    {"name": "Kyuya's hats pack", "uploader": "Kyuya258369", "category": "Clothing", "section": "Required"},
    {"name": "Luny's Flower Veils for Fashion Sense", "uploader": "LooneyLuny", "category": "Clothing", "section": "Required"},
    {"name": "Mail Framework Mod", "uploader": "Digus", "category": "Modding Tools", "section": "Required"},
    {"name": "Multi Save - Continued", "uploader": "recon88", "category": "Gameplay Mechanics", "section": "Required"},
    {"name": "Mushroom Furniture for Alternative Textures", "uploader": "farmerbeans", "category": "Visuals and Graphics", "section": "Required"},
    {"name": "Myc's Seasonal Fireplace for CP and AT", "uploader": "Mycenia", "category": "Furniture", "section": "Required"},
    {"name": "Oh So Cute Kitchen", "uploader": "katestardew", "category": "Interiors", "section": "Required"},
    {"name": "Plain Slime Hutch Interior", "uploader": "sparrows413", "category": "Buildings", "section": "Required"},
    {"name": "Precise Furniture", "uploader": "FearGodFishFish", "category": "Furniture", "section": "Required"},
    {"name": "Pretty Pink Furniture Recolour", "uploader": "twinkle22", "category": "Furniture", "section": "Required"},
    {"name": "Pretty Pink Wallpaper", "uploader": "twinkle22", "category": "Interiors", "section": "Required"},
    {"name": "Pretty Wallpaper", "uploader": "twinkle22", "category": "Interiors", "section": "Required"},
    {"name": "SMAPI - Stardew Modding API", "uploader": "Pathoschild", "category": "Modding Tools", "section": "Required"},
    {"name": "SVE Trees Recolored - For Popular Recolors", "uploader": "Morghoula", "category": "Visuals and Graphics", "section": "Required"},
    {"name": "Seasonal Mariner To Mermaid", "uploader": "JennaJuffuffles", "category": "Characters", "section": "Required"},
    {"name": "Seasonal Hedge Fences (Starblue)", "uploader": "JennaJuffuffles", "category": "Visuals and Graphics", "section": "Required"},
    {"name": "Shardust's Pastel Furniture for Alternative Textures", "uploader": "Shardust", "category": "Visuals and Graphics", "section": "Required"},
    {"name": "Shardust's Pastel Interiors - kitchen - crib - cellar - shed - cabin", "uploader": "Shardust", "category": "Interiors", "section": "Required"},
    {"name": "Sharogg's Tilesheets (modular bridges and more to come)", "uploader": "Sharogg", "category": "Modding Tools", "section": "Required"},
    {"name": "Simple Foliage - Unofficial Update for 1.6", "uploader": "Morghoula", "category": "Visuals and Graphics", "section": "Required"},
    {"name": "SinZational Speedy Solutions", "uploader": "SinZ163", "category": "Miscellaneous", "section": "Required"},
    {"name": "Skell's Flowery Weapons", "uploader": "skellady", "category": "Visuals and Graphics", "section": "Required"},
    {"name": "Stardew Valley Expanded", "uploader": "FlashShifter", "category": "Expansions", "section": "Required"},
    {"name": "Stardew Valley VERY Configured (1.6)", "uploader": "JennaJuffuffles", "category": "Miscellaneous", "section": "Required"},
    {"name": "Tiny Totem Statue Obelisks", "uploader": "JennaJuffuffles", "category": "Visuals and Graphics", "section": "Required"},
    {"name": "Universal Recolors", "uploader": "herbivoor", "category": "Visuals and Graphics", "section": "Required"},
    {"name": "Yomi's Cute Princess Dress-FS (Applicable 1.6)", "uploader": "Yomi2023", "category": "Clothing", "section": "Required"},
    {"name": "Yomi's Golden Princess Hairstyle-FS (Applicable 1.6)", "uploader": "Yomi2023", "category": "Clothing", "section": "Required"},
    # Optional mods
    {"name": "Forest Wood Craftables", "uploader": "TangaS2", "category": "Crafting", "section": "Optional"},
    {"name": "Overgrown Flowery Interface", "uploader": "SugarSugarRuin", "category": "User Interface", "section": "Optional"},
    {"name": "Seasonal Floral Bus Recolor", "uploader": "herbivoor", "category": "Visuals and Graphics", "section": "Optional"},
    {"name": "Seasonal Flower Sprinklers Refreshed", "uploader": "JennaJuffuffles", "category": "Visuals and Graphics", "section": "Optional"},
    {"name": "Skell's Flowery Tools", "uploader": "skellady", "category": "Visuals and Graphics", "section": "Optional"},
    {"name": "Squishi's Rideable Deer for Content Patcher and Alternatve Textures", "uploader": "altroquinine", "category": "Pets / Horses", "section": "Optional"},
    {"name": "Starblue Valley Unofficial", "uploader": "CherrySymphony", "category": "Visuals and Graphics", "section": "Optional"},
    {"name": "Sunroom Greenhouse", "uploader": "Sharogg", "category": "Maps", "section": "Optional"},
    {"name": "Tanga forest Buildings", "uploader": "TangaS2", "category": "Buildings", "section": "Optional"},
    {"name": "Tanga forest Gold Clock", "uploader": "TangaS2", "category": "Buildings", "section": "Optional"},
    {"name": "Additional Farm Cave", "uploader": "tikamin557", "category": "Maps", "section": "Optional"},
]


def main():
    console.print("[bold cyan]🌾 Merging VERY Expanded + Fairycore Collections[/bold cyan]")
    console.print()
    
    # Load VERY Expanded catalog
    with open(VERY_EXPANDED_CATALOG) as f:
        very_expanded = json.load(f)
    
    very_expanded_mods = very_expanded.get("mods", [])
    console.print(f"📦 VERY Expanded: {len(very_expanded_mods)} mods")
    console.print(f"📦 Fairycore: {len(FAIRYCORE_MODS)} mods")
    
    # Merge with deduplication
    merged = {}
    duplicates = []
    excluded = []
    
    # Add VERY Expanded first (it's the primary collection)
    for mod in very_expanded_mods:
        name = mod.get("name", "").strip()
        
        # Check exclusions
        if any(ex.lower() in name.lower() for ex in EXCLUDED_MODS):
            excluded.append(name)
            continue
        
        merged[name.lower()] = mod
    
    # Add Fairycore, tracking duplicates
    for mod in FAIRYCORE_MODS:
        name = mod.get("name", "").strip()
        key = name.lower()
        
        # Check exclusions  
        if any(ex.lower() in name.lower() for ex in EXCLUDED_MODS):
            excluded.append(name)
            continue
        
        if key in merged:
            duplicates.append(name)
        else:
            # Add mod ID if known
            mod_id = KNOWN_MODS.get(name)
            if mod_id:
                mod["mod_id"] = mod_id
                mod["url"] = f"https://www.nexusmods.com/stardewvalley/mods/{mod_id}"
            mod["source"] = "Fairycore"
            merged[key] = mod
    
    # Convert to list
    final_mods = list(merged.values())
    
    # Sort by section then name
    section_order = {"Required": 0, "Optional": 1, "Bundled Assets": 2}
    final_mods.sort(key=lambda m: (section_order.get(m.get("section", "Required"), 99), m.get("name", "").lower()))
    
    # Count stats
    with_ids = sum(1 for m in final_mods if m.get("mod_id"))
    
    # Print stats
    console.print()
    console.print(f"[green]✅ Merged: {len(final_mods)} unique mods[/green]")
    console.print(f"[blue]📋 With IDs: {with_ids}[/blue]")
    console.print(f"[yellow]🔄 Duplicates skipped: {len(duplicates)}[/yellow]")
    console.print(f"[red]❌ Excluded (farm conflicts): {len(excluded)}[/red]")
    
    if duplicates:
        console.print("\n[dim]Duplicates (from VERY Expanded):[/dim]")
        for d in duplicates[:10]:
            console.print(f"  [dim]• {d}[/dim]")
        if len(duplicates) > 10:
            console.print(f"  [dim]... and {len(duplicates) - 10} more[/dim]")
    
    if excluded:
        console.print("\n[dim]Excluded mods:[/dim]")
        for e in excluded:
            console.print(f"  [dim]• {e}[/dim]")
    
    # Create merged catalog
    merged_catalog = {
        "collection": "VERY Expanded + Fairycore (Merged)",
        "sources": [
            {"name": "Stardew Valley VERY Expanded", "url": "https://www.nexusmods.com/games/stardewvalley/collections/tckf0m"},
            {"name": "Aesthetic Valley | Fairycore", "url": "https://www.nexusmods.com/games/stardewvalley/collections/tjvl0j"}
        ],
        "notes": [
            "FARM CONFIG: When configuring SVE, select 'Frontier Farm' (not Immersive Farm 2 or Grandpa's Farm).",
            "Frontier Farm is an SVE config option with expansive land bordering the Ferngill Republic Frontier.",
            "All optional mods from both collections included.",
            "Deduplicated - each mod appears once.",
            "Lnh's MiNi Farm excluded (conflicts with SVE Frontier Farm).",
        ],
        "total_mods": len(final_mods),
        "mods_with_ids": with_ids,
        "mods": final_mods,
    }
    
    # Save
    output_file = SCRIPT_DIR / "merged-collection-catalog.json"
    with open(output_file, "w") as f:
        json.dump(merged_catalog, f, indent=2)
    
    console.print(f"\n[green]💾 Saved to: {output_file}[/green]")
    
    # Show breakdown by category
    console.print("\n[bold]📊 Category Breakdown:[/bold]")
    categories = {}
    for mod in final_mods:
        cat = mod.get("category", "Unknown")
        categories[cat] = categories.get(cat, 0) + 1
    
    table = Table()
    table.add_column("Category", style="cyan")
    table.add_column("Count", style="green", justify="right")
    
    for cat, count in sorted(categories.items(), key=lambda x: -x[1]):
        table.add_row(cat, str(count))
    
    console.print(table)


if __name__ == "__main__":
    main()

