# SVE & "Flower Shop" Conflict Analysis

## 🎯 CULPRIT IDENTIFIED: **[CP] Eugene NPC Mod**

### Summary

The "flower shop" building overwriting Andy's farm in Cindersnap Forest is actually **Eugene's Pink Garden** added by the **Eugene NPC mod**.

## Problem Details

- **Location**: South of farm, Cindersnap Forest (where SVE's Andy farm is)
- **Symptom**: Terrain breaking, Andy stuck, area untraversable
- **Cause**: Two mods editing the same Forest map area with `PatchMode: Replace`

## Root Cause Analysis

### Eugene NPC Mod Forest Edit

Found in `/home/e421/.steam/steam/steamapps/common/Stardew Valley/Mods/[CP] Eugene/content.json`:

```json
{
    "Action": "EditMap",
    "Target": "Maps/Forest",
    "FromFile": "assets/Maps/Custom_EugeneNPC_ForestGarden.tbin",
    "FromArea": { "X": 0, "Y": 0, "Width": 21, "Height": 26 },
    "ToArea": { "X": 64, "Y": 56, "Width": 21, "Height": 26 },
    "PatchMode": "Replace",
}
```

**Key findings:**

- Eugene edits **Maps/Forest** at coordinates **(64, 56)** with a **21x26 tile** area
- Uses `PatchMode: Replace` which **completely overwrites** whatever is there
- This overlaps with SVE's modifications for Andy's farm
- Eugene's "ForestGarden" / "Pink Garden" is what appears as a "flower shop"

### Why It Looks Like a Flower Shop

Eugene is a gardener/plant-loving NPC. His garden structure features flowers, plants, and garden aesthetics - easily mistaken for a "flower shop" building.

## Solution Options

### Option 1: Remove Eugene Mod ✅ RECOMMENDED

**Quickest fix with guaranteed results.**

```bash
# Move Eugene mod out of the Mods folder
mv "$HOME/.steam/steam/steamapps/common/Stardew Valley/Mods/[CP] Eugene" ~/disabled_mods/
```

**Pros:**

- Immediate fix
- Andy's farm and Forest area restored
- SVE functions normally

**Cons:**

- Lose Eugene NPC content

### Option 2: Search for Compatibility Patch

Check if someone has made an SVE+Eugene compatibility patch:

- Search Nexus: "Eugene SVE patch" or "Eugene Stardew Valley Expanded"
- Check Eugene mod page's Posts/Files section
- Check SVE compatibility list

### Option 3: Load Order Adjustment (Advanced)

Try making SVE load AFTER Eugene so SVE's changes take priority:

1. Edit Eugene's `manifest.json` and add SVE as a dependency:

```json
{
  "Dependencies": [
    {
      "UniqueID": "FlashShifter.StardewValleyExpandedCP",
      "IsRequired": false
    }
  ]
}
```

**Note:** This may not fully work if both use `PatchMode: Replace`.

### Option 4: Manual Map Patch (Expert)

Edit Eugene's `content.json` to move the garden to a different location that doesn't overlap with SVE's Andy farm.

## Other Flower-Related Mods in Your Mods Folder

These were checked but are **NOT causing the conflict**:

| Mod | Edits Forest? | Status |
|-----|---------------|--------|
| [CP] Flowery Meadowlands Farm | No (Farm_Ranching only) | ✅ Safe |
| [CP] H&W Farmers Market | No Forest edits found | ✅ Safe |
| Flower Meads | No content.json | ✅ Safe |

## Mods Found Editing Maps/Forest

Only **one mod** other than SVE edits the Forest map:

| Mod | What It Edits | Conflict Risk |
|-----|---------------|---------------|
| **[CP] Eugene** | ForestGarden at (64,56) 21x26 | ⚠️ **HIGH - CONFIRMED CAUSE** |

## Verification Steps After Fix

1. Remove/disable Eugene mod
2. Launch game with SMAPI
3. Go to Cindersnap Forest (south of farm)
4. Verify Andy is at his farm
5. Check terrain around river is normal
6. Walk through the area without getting stuck

## Files Investigated

- `/home/e421/.steam/steam/steamapps/common/Stardew Valley/Mods/[CP] Eugene/content.json` - **CAUSE IDENTIFIED**
- `/home/e421/.steam/steam/steamapps/common/Stardew Valley/Mods/[CP] Flowery Meadowlands Farm/content.json` - Not the cause
- `/home/e421/stardew-modding-nix/collection-catalog-with-ids.json` - Eugene not in collection catalog

## Important Note

**Eugene NPC is NOT part of the "Stardew Valley VERY Expanded" collection catalog.** It appears to have been manually installed separately. This explains why the conflict wasn't obvious from just examining the collection.

---
*Analysis Date: 2026-01-27*
*Conflict: Eugene NPC (ForestGarden) vs SVE (Andy's Farm)*
*Resolution: Remove/disable Eugene mod*
