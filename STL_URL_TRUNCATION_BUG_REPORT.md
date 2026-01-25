# Bug Report: NXM Collection URLs Truncated - Forward Slashes Stripped

## System Information
- **SteamTinkerLaunch version**: 12.12-unstable-2025-07-14 (NixOS package)
- **Distribution**: NixOS 25.11 (Xantusia)
- **Installation Method**: Nix package `steamtinkerlaunch`
- **Vortex Version**: 1.14.8

## Issue Description

When using `steamtinkerlaunch vortex u <nxm_url>` to download Nexus Mods **collections**, the URL is truncated and Vortex fails with an "Invalid URL" error.

### Root Cause Analysis

The issue occurs because Wine's command-line parsing interprets forward slashes (`/`) as command-line switches (Windows convention). When STL passes a collection URL like:

```
nxm://stardewvalley/collections/tckf0m/revisions/100
```

...to Wine via the `wineVortexRun` function, the `/revisions/100` portion is stripped because Wine interprets `/revisions` as a command-line switch argument.

**What STL sends:**
```
nxm://stardewvalley/collections/tckf0m/revisions/100
```

**What Vortex receives:**
```
nxm://stardewvalley/collections/tckf0m
```

This causes Vortex to log:
```
Invalid URL: invalid nxm url "nxm://stardewvalley/collections/tckf0m"
```

### Evidence

**1. STL Log shows full URL being passed:**
```
INFO - startVortex - Starting Vortex now with command 'runVortex "-d" "nxm://stardewvalley/collections/tckf0m/revisions/100"'
```

**2. Vortex Log shows truncated URL received:**
```
2026-01-14T14:46:52.078Z - warn: Invalid URL: invalid nxm url "nxm://stardewvalley/collections/tckf0m"
```

**3. Direct Wine test confirms the issue:**
```bash
# STL passes URL like this internally:
WINEPREFIX="..." wine Vortex.exe -d "nxm://stardewvalley/collections/tckf0m/revisions/100"

# Wine interprets /revisions as a switch, stripping it from the URL
```

### Code Location

The issue is in the `wineVortexRun` function around line 16019 in the STL script. The URL is passed as `"$@"` without URL encoding:

```bash
PATH="$STLPATH" LD_LIBRARY_PATH="" LD_PRELOAD="" WINE="$VORTEXWINE" WINEARCH="win64" WINEDEBUG="-all" WINEPREFIX="$VORTEXPFX" "$@" > "$VWRUN" 2>/dev/null
```

### Proposed Fix

URL-encode forward slashes in the URL before passing to Wine. Replace `/` with `%2F` in the path portion of the URL (after the `://` scheme):

```bash
# Before passing to Wine:
URL="$3"
# URL-encode forward slashes in path portion
ENCODED_URL=$(echo "$URL" | sed 's|/|%2F|g4')  # Skip first 3 slashes (nxm://)
```

Or use a more robust approach that specifically handles the `nxm://` scheme:

```bash
if [[ "$URL" == nxm://* ]]; then
    # Extract scheme and path
    SCHEME="${URL%%://*}://"
    PATH_PART="${URL#*://}"
    # URL-encode the path part
    ENCODED_PATH=$(python3 -c "import urllib.parse; print(urllib.parse.quote('$PATH_PART', safe=''))")
    URL="${SCHEME}${ENCODED_PATH}"
fi
```

### Workaround

Currently, there is **no workaround** for downloading collections via STL/Vortex. Individual mods work fine because their URLs don't contain the `/revisions/` path component.

### Reproducible Steps

1. Install Vortex via STL
2. Sign in to Nexus Mods in Vortex
3. Navigate to a Nexus Mods collection page (e.g., https://next.nexusmods.com/stardewvalley/collections/tckf0m)
4. Click "Add collection (Desktop only)"
5. Accept the browser prompt to open the `nxm://` link
6. Observe that Vortex receives a truncated URL and fails

### Impact

- **Severity**: High for collection users
- **Affected functionality**: All Nexus Mods collection downloads
- **Individual mod downloads**: Working correctly (no `/revisions/` in URL)

### Environment Details

```bash
$ which steamtinkerlaunch
/nix/store/gy8jfsfv1wh51xppgnlc011rmdg743vl-steamtinkerlaunch-12.12-unstable-2025-07-14/bin/steamtinkerlaunch

$ steamtinkerlaunch --version
SteamTinkerLaunch v12.12.20250714

$ wine --version
wine-9.16 (GE-Proton9-16)
```

### Related Issues

- #1143 - Unable to pull in downloads to vortex (same `sed` error observed, closed)
- #1112 - Vortex nxm link opening code/pointers (closed, different issue)

### References

- Wine bug tracker: Forward slashes interpreted as switches is a known Windows compatibility behavior
- Vortex expects the full collection URL including `/revisions/<revision_id>` to properly identify which revision to download

---

**Note to maintainers**: This bug specifically affects Nexus Mods **collections**, which have become increasingly important as they're the only way to install curated mod packs. Individual mod downloads still work correctly.

