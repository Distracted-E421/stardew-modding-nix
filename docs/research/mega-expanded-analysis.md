# Mega Expanded Stardew Collection Analysis

**Collection URL**: https://www.nexusmods.com/games/stardewvalley/collections/g3i395
**Total Mods**: 522 + 6 off-site assets = 528 total
**Game Version**: 1.6.15.24356
**Last Updated**: January 2026

## Overview

This document analyzes the "Mega Expanded Stardew" collection to understand:
1. Critical framework dependencies
2. Major content expansions
3. Known conflicts and load order requirements
4. GMCM settings recommendations
5. Performance considerations

---

## Critical Framework Mods (MUST HAVE)

These are the core framework mods that many other mods depend on. Install these first.

### Tier 1: Essential Frameworks

| Mod | Author | Purpose | Dependencies |
|-----|--------|---------|--------------|
| **Content Patcher** | Pathoschild | Loads content packs without replacing XNB files | SMAPI |
| **Generic Mod Config Menu (GMCM)** | spacechase0 | In-game mod configuration UI | SMAPI |
| **SpaceCore** | spacechase0 | Core library for many mods | SMAPI |
| **StardewHack** | bcmpinc | Core hacking library | SMAPI |
| **Farm Type Manager (FTM)** | EscaMMC | Custom spawning on any map | SMAPI, Content Patcher |
| **Expanded Preconditions Utility (EPU)** | CherryChain | Extended event/dialogue conditions | SMAPI |

### Tier 2: Common Frameworks

| Mod | Author | Purpose | Used By |
|-----|--------|---------|---------|
| **Alternative Textures** | PeacefulEnd | Texture variants system | Many furniture/crop mods |
| **Mail Framework Mod** | Digus | Custom mail system | NPCs, quests |
| **Shop Tile Framework** | CherryChain | Custom shops anywhere | Map expansions |
| **Furniture Framework** | Leroymilo | Custom furniture types | HxW mods, etc. |
| **Item Extensions** | mistyspring | Extended item properties | Various |
| **Custom Bush** | LeFauxMatt | Custom bush types | Growable Forage |
| **Expanded Storage** | LeFauxMatt | Custom storage containers | Various |
| **Custom Companions** | PeacefulEnd | NPC companions | Pet mods |
| **Mapping Extensions (MEEP)** | DecidedlyHuman | Extended map properties | Map expansions |
| **More Nightly Events** | KhloeLeclair | Custom night events | Various |
| **Trinket Tinker** | mushymato | Custom trinkets | Various |
| **Producer Framework Mod** | Digus | Custom machines | Artisan mods |

### Tier 3: Utility Frameworks

| Mod | Author | Purpose |
|-----|--------|---------|
| **Stardust Core** | Omegasis | Utility library |
| **Birb Core** | drbirbdev | Core library |
| **SorryLab Core** | YunHikari | Core library |
| **PoohCore** | poohnhi | Core library |
| **Pi Core** | weizinai | Core library |
| **Calcifer** | sophiesalacia | Core library |
| **Cross-Mod Compatibility Tokens (CMCT)** | Spiderbuttons | Inter-mod compatibility |
| **Custom Tokens** | TheMightyAmondee | Custom CP tokens |
| **Gender Neutrality Mod Tokens** | Hanatsuki | Gender-neutral dialogue |
| **Secret Note Framework** | ichortower | Custom secret notes |

---

## Major Content Expansions

### Tier 1: Large Map Expansions (Pick Carefully!)

These expansions add significant new areas and NPCs. They can conflict with each other.

| Mod | Author | Scope | NPCs | Compatibility Notes |
|-----|--------|-------|------|---------------------|
| **Stardew Valley Expanded (SVE)** | FlashShifter | Massive - new areas, NPCs, events | 15+ new NPCs | THE flagship expansion |
| **Ridgeside Village (RSV)** | Rafseazz | Large - new village area | 30+ new NPCs | Works with SVE |
| **East Scarp (ES)** | lemurkat | Medium - eastern coastal area | 8+ new NPCs | Works with SVE + RSV |
| **Sunberry Village (SBV)** | skellady | Medium - southern village | 6+ new NPCs | Designed to work with all |
| **Adventurer's Guild Expanded (AGE)** | underanesthesia | Small - guild expansion | 2 new NPCs | Works with SVE |
| **Law and Order SV (LAO-SV)** | sdvhead | Small - police station | 2+ NPCs | Works with all |
| **Distant Lands (Witch Swamp)** | Aimon111 | Small - witch swamp area | NPCs | Works with all |

### Expansion Compatibility Matrix

```
SVE + RSV + ES + SBV + AGE + LAO-SV = ✓ Compatible (this collection's setup)

Key patches required:
- Jorts and Jean SVE Festival Fix (required when using Jorts and Jean + SVE)
- Little Red School House SVE Patch (if using LRSH + SVE)
```

### Additional NPCs for Expansions

Many custom NPCs are designed for specific expansions:

**For East Scarp:**
- Creative Differences - NPC Rodney
- Eli and Dylan
- Lurking in the Dark - NPC Sen
- Metalcore Goes Cottagecore
- Nora The Herpetologist
- Sword and Sorcery

**For Sunberry Village:**
- Always Raining in the Valley NPCs
- Dao
- Jonghyuk and Spanner
- Lani
- Ripley the Farmer
- Rose and the Alchemist
- Wren the Plumber

**For Ridgeside Village:**
- Leilani

**Standalone:**
- Alecto the Witch
- Mister Ginger (cat NPC)
- Jorts and Jean (helper cats)
- Roses In The Sand (Sandy romance)

---

## Known Load Order Rules

**CRITICAL**: These must be loaded in specific order or the game will break!

1. **Alternative Isla** → loads AFTER → **Isla**
2. **Portraited Changing Skies Interiors** → loads AFTER → **Portraited Changing Skies Beta**
3. **Jorts and Jean Festival Fix SVE** → loads AFTER → **Jorts and Jean**
4. **Little Red School House SVE Patch** → loads AFTER → **Little Red School House**
5. **Vintage Interface compatibility patches** → load AFTER → **originals**

---

## GMCM Settings Recommendations

These settings from the collection's documentation should be applied via GMCM after first launch:

### Alternative Textures
- **Keep default textures when placing items**: ON

### Better Crafting
- **Replace cooking menu**: OFF

### Better Friendship
- **Turn distance down** (reduces "bubble" range)

### Combat Controls Redux
- **Enable Regular Tools Fix**: ON

### Dynamic Reflections
- **Remap hotkey or REMOVE** (default key can freeze game!)

### Event Limiter
- **Max daily events**: 6 or more (default is too low for expanded content)

### Fast Animations
- Adjust eating/drinking speeds to preference

### Dynamic Night Time
- Configure to preference

### Horse Overhaul
- Adjust horse speed settings

### UI Info Suite 2
- Configure HUD elements to preference

---

## Known Issues & Bugs

### Expected Behavior (Not Bugs)

1. **NPCs spawning multiple times**: Known issue with many NPC mods
2. **Small freezes at 09:00, 13:00, 17:00**: NPCs changing schedules
3. **Long load times (60+ seconds)**: Expected with 500+ mods

### Performance Tips

1. **Disable unused mods**: Especially visual/cosmetic ones
2. **Reduce NPC expansions**: If load times are unbearable
3. **Lower graphic settings**: Especially Dynamic Reflections
4. **Use SSD**: Mandatory for acceptable load times

---

## Farm Maps in Collection

| Farm | Author | Style |
|------|--------|-------|
| **Immersive Farm 2** (SVE) | FlashShifter | Large expanded farm |
| **Frontier Farm** (SVE) | FlashShifter | Frontier-themed |
| **Overgrown Garden Farm** | DaisyNiko | Overgrown aesthetic |
| **Waterfall Forest Farms** | ArchibaldTK | Forest waterfall |
| **Beach Farm Redone** | pluviophist | Improved beach farm |
| **Tweakable Meadowlands Farm** | ItsBenter | Customizable meadowlands |

---

## Quality of Life Mods (Recommended)

### Essential QoL

| Mod | Author | Function |
|-----|--------|----------|
| **Lookup Anything** | Pathoschild | Hover info for everything |
| **NPC Map Locations** | Bouhm | NPCs on map |
| **UI Info Suite 2** | Abs0rbed | Enhanced HUD |
| **CJB Cheats Menu** | Pathoschild | Debug/cheats |
| **Gift Taste Helper** | JoXW | Gift preferences |

### Automation QoL

| Mod | Author | Function |
|-----|--------|----------|
| **AutoAnimalDoors** | taggartaa | Auto animal doors |
| **AutoGate** | Teban100 | Auto-open gates |
| **Carry Chests** | LeFauxMatt | Pick up full chests |
| **Better Crafting** | KhloeLeclair | Improved crafting UI |
| **Deluxe Grabber Redux** | Nykal145 | Auto-collect items |

### Combat QoL

| Mod | Author | Function |
|-----|--------|----------|
| **Combat Controls Redux** | NormanPCN | Better combat |
| **Mini Bars** | Coldopa | Enemy health bars |
| **Skull Cavern Elevator** | Bifibi | Elevator in skull cavern |

---

## Off-Site Assets (Manual Download Required)

These mods are NOT on Nexus and must be downloaded separately:

1. **Anything Anywhere**
2. **Non Destructive NPCs - 1.6 Unofficial update**
3. **Reset Terrain Features**
4. **Revised Ridgeside Village Bus Stop Edit**
5. **ThreeHeartDancePartner 1.6**
6. **[CC] Weather Wonders - Beta**
7. **[CP] Portraited Changing Skies - Beta**

---

## Mod Categories Summary

From the 522 mods:

| Category | Count | Examples |
|----------|-------|----------|
| **Expansions** | 12 | SVE, RSV, ES, SBV |
| **New Characters** | 35+ | Various NPCs |
| **Dialogue** | 30+ | Dialogue expansions |
| **Events** | 20+ | New events |
| **Portraits** | 15+ | Character art |
| **Maps** | 25+ | Farm and area maps |
| **Buildings** | 20+ | Building retextures |
| **Furniture** | 50+ | HxW, MCM, decorations |
| **Crops** | 20+ | Cornucopia, etc. |
| **Livestock/Animals** | 25+ | New animals |
| **Items** | 30+ | New items/recipes |
| **Gameplay Mechanics** | 60+ | Various mechanics |
| **User Interface** | 25+ | UI improvements |
| **Visuals/Graphics** | 50+ | Visual enhancements |
| **Modding Tools** | 40+ | Frameworks |
| **Cheats** | 5+ | Debug tools |
| **Clothing** | 10+ | Character clothing |
| **Audio** | 5+ | Sound mods |

---

## Building Our Custom Modpack

### Recommended Approach

1. **Start with frameworks** - Install all Tier 1 + Tier 2 frameworks
2. **Pick ONE primary expansion set** - SVE + RSV + ES is proven stable
3. **Add QoL mods** - The essential ones
4. **Test thoroughly** - Run the game, check SMAPI log
5. **Add content gradually** - NPCs, items, cosmetics
6. **Test after each batch** - Identify conflicts early

### Conflict Prevention

1. **Use SMAPI log parser**: https://smapi.io/log
2. **Check mod pages** for compatibility notes
3. **Search for patches** when combining mods
4. **When in doubt, check Discord** - Most mods have active communities

---

## Next Steps

1. [ ] Create prioritized mod list for our custom pack
2. [ ] Identify minimal framework set
3. [ ] Document specific version requirements
4. [ ] Test framework-only installation
5. [ ] Add expansions incrementally
6. [ ] Document any conflicts found

