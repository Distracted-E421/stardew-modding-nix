# Custom Stardew Valley Modpack Plan

**Target Version**: Stardew Valley 1.6.15
**SMAPI Version**: Latest compatible with 1.6.15
**Harmony Version**: 2.x+

## Design Goals

1. **Stability First**: Prioritize proven compatibility over bleeding-edge features
2. **Performance**: Keep load times under 90 seconds
3. **Cohesion**: Mods should feel like a unified experience
4. **Maintainability**: Document everything for future updates

---

## Phase 1: Core Frameworks

Status: [ ] Not Started / [~] In Progress / [x] Complete

### Essential (Must Have)

- [ ] **SMAPI** - Stardew Modding API
- [ ] **Content Patcher** - Pathoschild
- [ ] **Generic Mod Config Menu (GMCM)** - spacechase0
- [ ] **SpaceCore** - spacechase0

### Common Frameworks (Most Mods Need)

- [ ] **Farm Type Manager (FTM)** - EscaMMC
- [ ] **Expanded Preconditions Utility (EPU)** - CherryChain
- [ ] **StardewHack** - bcmpinc
- [ ] **Alternative Textures** - PeacefulEnd
- [ ] **Mail Framework Mod** - Digus
- [ ] **Shop Tile Framework** - CherryChain

### Optional Frameworks (As Needed)

- [ ] Furniture Framework
- [ ] Custom Bush
- [ ] Expanded Storage
- [ ] Producer Framework Mod
- [ ] Mapping Extensions (MEEP)
- [ ] More Nightly Events

---

## Phase 2: Content Expansions

### Primary Expansion Choice

Choose ONE primary expansion setup:

**Option A: Full Mega Expanded**
- [x] SVE + RSV + ES + SBV + AGE
- Pros: Maximum content
- Cons: Long load times, more potential conflicts

**Option B: SVE + RSV Only**
- [ ] SVE + RSV
- Pros: Proven stable combo, faster loads
- Cons: Less content

**Option C: SVE Only**
- [ ] SVE
- Pros: Most stable, best performance
- Cons: Least new content

**Option D: No Major Expansions**
- [ ] Skip large expansions
- Pros: Fastest, most stable
- Cons: Vanilla+ experience only

### Selected: **Full Mega Expanded** (SVE + RSV + ES + SBV + AGE + LAO-SV)

---

## Phase 3: Quality of Life

### Essential QoL

- [ ] Lookup Anything
- [ ] NPC Map Locations
- [ ] UI Info Suite 2
- [ ] Gift Taste Helper

### Automation QoL

- [ ] AutoAnimalDoors
- [ ] Carry Chests
- [ ] Better Crafting

### Combat QoL

- [ ] Combat Controls Redux
- [ ] Mini Bars

### Optional QoL

- [ ] CJB Cheats Menu
- [ ] CJB Item Spawner
- [ ] Noclip Mode

---

## Phase 4: Visual Enhancements

### Character Art

- [ ] Seasonal Outfits (vanilla)
- [ ] Seasonal Outfits (SVE)
- [ ] Seasonal Outfits (RSV)
- [ ] Portraits (choose style: _______)

### Environmental

- [ ] Better Water 2
- [ ] Simple Foliage
- [ ] Dynamic Reflections (⚠️ performance impact)
- [ ] Cloudy Skies

### UI Themes

- [ ] Choose interface theme: _______

---

## Phase 5: Additional Content

### Crops & Farming

- [ ] Cornucopia - More Crops
- [ ] Cornucopia - More Flowers
- [ ] Cornucopia - Artisan Machines
- [ ] Growable Forage and Crop Bushes

### Animals

- [ ] Elle's New Barn Animals
- [ ] Elle's New Coop Animals
- [ ] Alpacas
- [ ] Mizu's Quail
- [ ] Mizu's Turkey

### NPCs (beyond expansions)

- [ ] Jorts and Jean (helper cats)
- [ ] Alecto the Witch
- [ ] Mister Ginger

### Dialogue & Events

- [ ] Canon-Friendly Dialogue Expansion
- [ ] Date Night Redux
- [ ] Happy Birthday

---

## Phase 6: Furniture & Decoration

### Core Furniture Sets

- [ ] HxW Furniture (full set)
- [ ] Orangeblossom's Furniture
- [ ] MolaMole's Furniture
- [ ] Pixie's MCM Furniture

### Catalogues

- [ ] HxW Everything Catalogue
- [ ] Orangeblossom's Catalogue
- [ ] Pixie's MCM Catalogue

---

## Testing Protocol

### After Each Phase

1. Launch game via SMAPI
2. Check SMAPI console for errors
3. Load/create test save
4. Play through one full day
5. Check for visual glitches
6. Upload log to https://smapi.io/log if errors

### Known Problem Indicators

- Red text in SMAPI console
- "Failed to load" messages
- NPCs in wrong locations
- Missing textures (pink/purple boxes)
- Crashes on specific actions

---

## Version Tracking

| Mod | Version | Last Tested | Status |
|-----|---------|-------------|--------|
| SMAPI | | | |
| Content Patcher | | | |
| SVE | | | |
| RSV | | | |
| (add as installed) | | | |

---

## Issues Log

| Date | Issue | Affected Mods | Resolution |
|------|-------|---------------|------------|
| | | | |

---

## Notes

- Always backup saves before testing new mods
- Keep a "known good" mod folder for rollback
- Update one mod at a time when troubleshooting

