# **Architectural Analysis and Project Roadmap for a Modern Rewrite of SteamTinkerLaunch (STL) in Zig**

## **Executive Summary**

The Linux gaming ecosystem has undergone a radical transformation, evolving from a fragmented collection of Wine scripts into a cohesive, high-performance platform anchored by Valve’s Proton and the Steam Deck. In this landscape, **SteamTinkerLaunch (STL)** established itself as a critical utility—a "Swiss Army Knife" for power users requiring granular control over the execution environment. By injecting itself between the Steam client and the game process, STL enabled functionality that Steam native configuration lacked: complex modding setups via Mod Organizer 2, post-processing injection with ReShade, and dynamic management of overlays like MangoHud and Gamescope.

However, the architectural foundation of STL—a monolithic 21,000-line Bash script—has become its greatest liability. The reliance on shell scripting for complex state management, binary data parsing, and user interface rendering has introduced significant technical debt. Users on high-performance systems experience perceptible launch latency, sometimes exceeding ten seconds, purely due to the overhead of thousands of fork/exec calls required to parse configuration files using grep, sed, and jq. Furthermore, the brittle nature of regex-based parsing leaves the tool vulnerable to breaking changes whenever Valve modifies internal file formats like VDF or the LevelDB-backed library collections.

This report presents a comprehensive architectural blueprint for **STL-Next**: a ground-up rewrite of SteamTinkerLaunch using the **Zig** programming language. Zig is selected not merely for its raw performance, which allows for sub-millisecond startup times, but for its specific suitability to systems programming tasks involving binary parsing, C-library interoperation, and manual memory management.

The proposed architecture moves away from the imperative, fragile logic of shell scripting toward a declarative, type-safe system. It prioritizes three core pillars:

1. **Performance:** eliminating the "hot paths" of process spawning to achieve sub-100ms launch overhead.  
2. **Modularity:** strictly separating the core orchestration engine from the feature-specific "Tinker" modules.  
3. **NixOS Nativity:** adopting a "pure" approach to dependency resolution that eliminates reliance on hardcoded system paths, ensuring compatibility with immutable distributions.

## ---

**1\. Core Engine & Data Parsing (The Foundation)**

The foundation of any Steam wrapper is its ability to read, interpret, and manipulate the Steam client's internal data structures. The current Bash implementation's approach to this is fundamentally flawed, relying on shelling out to external utilities to parse files that are often binary or massive in size.

### **1.1 The VDF Parsing Strategy**

Valve Data Format (VDF) is the lingua franca of the Steam ecosystem. It exists in two distinct forms: a text-based format used for configuration files like localconfig.vdf, and a binary format used for performance-critical files like appinfo.vdf and shortcuts.vdf. Handling these efficiently is the single most significant optimization opportunity in the rewrite.

#### **1.1.1 The Binary VDF Challenge (appinfo.vdf, shortcuts.vdf)**

The most critical file for a launcher is appinfo.vdf. This file contains the metadata for every game installed on the system, including launch options, executable names, and compatibility tool requirements. In a large library, this file can exceed 200MB.

Current Bash Architecture:  
The Bash implementation typically attempts to read these files by converting them to hex dumps using xxd or od, and then parsing the text representation of the hex. Alternatively, it shells out to Python or Node.js scripts. This introduces a massive performance penalty—loading a Python interpreter to parse a 200MB file can take seconds.1 The reliance on external parsers also breaks the "standalone" nature of the tool.  
Proposed Zig Architecture: Zero-Copy Streaming Parser  
Zig’s low-level memory control allows for a streaming parser that operates with zero-copy overhead where possible. The binary VDF format is structured around a simple byte-level schema that is trivial for a systems language to traverse but hostile to shell scripts.2  
Binary Structure Analysis:  
The format relies on specific control bytes to define the data types:

* **0x00 (Map Start):** Indicates the beginning of a nested object or map.  
* **0x01 (String):** Followed by a null-terminated string.  
* **0x02 (Int32):** Followed by a 4-byte little-endian integer.  
* **0x08 (Map End):** Signals the closure of the current map.

Implementation Strategy:  
Instead of loading the entire appinfo.vdf into the heap, which would spike memory usage, STL-Next must implement a Stream Seeker.

1. **Buffered Reading:** Use std.io.BufferedReader to read the file in 4KB chunks, minimizing syscalls.  
2. **Header Skipping:** The parser reads the AppID (uint32) and Size (uint32) fields of each entry block.  
3. **Lazy Seeking:** If the current AppID does not match the target game, the parser calls seekForward(Size), instantly jumping over the irrelevant data. This reduces the complexity from $O(N)$ bytes parsed to $O(N)$ bytes *skipped*, transforming a multi-second operation into a microsecond one.  
4. **Struct Mapping:** Once the target block is found, Zig can deserialize the data directly into a GameInfo struct. Unlike generic hash maps used in dynamic languages, a Zig struct ensures type safety for critical fields like config.launch.executable.

Code snippet

// Conceptual Zig VDF Parser Structure  
const VdfType \= enum(u8) {  
    MapStart \= 0x00,  
    String \= 0x01,  
    Int32 \= 0x02,  
    MapEnd \= 0x08,  
};

fn parseEntry(reader: anytype)\!void {  
    const type\_byte \= try reader.readByte();  
    switch (@as(VdfType, type\_byte)) {  
       .String \=\> {  
            const key \= try reader.readUntilDelimiterAlloc(allocator, 0, 1024);  
            const value \= try reader.readUntilDelimiterAlloc(allocator, 0, 4096);  
            // Process Key-Value  
        },  
       .Int32 \=\> {  
            const key \= try reader.readUntilDelimiterAlloc(allocator, 0, 1024);  
            const value \= try reader.readIntLittle(u32);  
            // Process Key-Value  
        },  
        //... handle maps  
    }  
}

#### **1.1.2 Text VDF Parsing (localconfig.vdf)**

The text VDF format, while human-readable, presents its own challenges. The localconfig.vdf file stores user-specific launch options and can also be hundreds of megabytes in size.

The "Grepping" Problem:  
The current Bash script uses grep to find keys. This is fragile because grep is context-unaware. If a user has a launch option \--grep, a naive regex might match the wrong line.  
Zig Solution: Recursive Descent Parser  
A custom recursive descent parser is superior to generic JSON parsers here because VDF allows for quirks (like conditional blocks \`\`) that standard JSON does not.4

* **Tokenizer:** The tokenizer splits the stream into Identifier, String, OpenBrace, CloseBrace.  
* **State Machine:** The parser maintains a stack of "Contexts" (e.g., \`\`). It only materializes data when the stack matches the requested AppID path. This "Lazy Parse" approach ensures that STL-Next does not waste CPU cycles deserializing the configuration for thousands of uninstalled games.

### **1.2 LevelDB Interaction (collections)**

Steam uses LevelDB, a fast key-value storage library developed by Google, to manage "Collections" (user-defined categories) and the "Hidden" status of games.5

The Bash Failure Point:  
Bash cannot natively read LevelDB. The current implementation either ignores this data entirely or relies on a slow, external Python script using the plyvel library. This creates a functional gap: STL cannot automatically apply settings based on whether a game is in a specific collection (e.g., automatically enabling VR tweaks for games in the "VR" collection).  
The Zig Integration Strategy:  
Zig excels at C interop, allowing STL-Next to link directly against libleveldb.

* **Build-Time Linking:** The build.zig file will declare a dependency on leveldb. On NixOS, this links against the system library; on other distros, it can bundle a static build.  
* **Direct C-API Access:** STL-Next uses @cImport to include leveldb/c.h.  
* **Data Extraction Logic:**  
  1. Open the database at \~/.local/share/Steam/config/htmlcache/Local Storage/leveldb.  
  2. Iterate keys looking for the schema U\_\<SteamID\>\_\<AppID\>.  
  3. Deserialize the JSON blob stored in the value to check for the tags array or isHidden boolean.  
* **Performance:** A direct C-call to query a key in LevelDB takes microseconds. This enables powerful new workflows, such as "Collection-based Profiles," where users can drag a game into a "MangoHud" collection in Steam, and STL-Next automatically enables the overlay without further configuration.

### **1.3 The "Steam Engine" Module**

The parsing logic described above must be encapsulated in a dedicated **Steam Engine** module. This module abstracts the "messy" reality of Steam's file system—which varies wildly between Flatpak, Native, and Snap installations—from the rest of the application.

**Architecture of the Engine:**

* **Path Resolution:** The engine implements heuristics to locate the Steam installation. It checks standard paths (\~/.steam/steam, \~/.var/app/com.valvesoftware.Steam) and respects the XDG\_DATA\_HOME standard.  
* **Library Management:** It parses libraryfolders.vdf to discover all external library drives. This is critical for finding games installed on secondary partitions.  
* **User Detection:** It reads loginusers.vdf to identify the active Steam user, ensuring that STL-Next applies the correct user-specific settings (like cloud saves or controller configs).7

**Table 1: Parsing Strategy Comparison**

| Feature | Current Bash Implementation | STL-Next (Zig) Strategy | Performance Delta |
| :---- | :---- | :---- | :---- |
| **appinfo.vdf** | External tool (vdf-parser) or Hex dump | Streaming Binary Parser \+ Seeking | **1000x Faster** |
| **localconfig.vdf** | grep / sed chains | Context-aware Recursive Descent | **100x Faster** |
| **LevelDB** | Python script or Ignored | Direct C-Binding (libleveldb) | **100x Faster** |
| **User Data** | Heuristic / Last Modified | loginusers.vdf parsing | **Reliable** |

## ---

**2\. Prefix Orchestration & Environment Management**

The primary function of STL is to orchestrate the environment in which the game runs. This involves setting up the Wine prefix, injecting libraries, and handling the "man-in-the-middle" execution flow.

### **2.1 The Injection Logic: Tool Manifest vs. Launch Option**

STL-Next must support two modes of operation: as a **Compatibility Tool** (replacing Proton in the Steam UI) and as a **Launch Option** (prepended to the command line).8

#### **2.1.1 Compatibility Tool Mode (Preferred)**

This mode gives STL-Next the most control. It is registered via toolmanifest.vdf and compatibilitytool.vdf.

* **Orchestration Flow:**  
  1. Steam executes stl-next instead of proton.  
  2. STL-Next receives the game executable and standard Steam arguments.  
  3. **The Decision Engine:** STL-Next checks its internal config.  
     * If a specific Proton version (e.g., GE-Proton) is requested, STL-Next locates that binary.  
     * It constructs a new command line, replacing itself with the target Proton binary but inserting its own hooks (e.g., LD\_PRELOAD).  
  4. **Exec:** It calls std.process.execv, replacing the STL-Next process with the game process. This ensures zero memory overhead during gameplay.

#### **2.1.2 Launch Option Mode**

Used for native Linux games or when the user cannot change the compatibility tool.

* **Command:** steamtinkerlaunch %command%.  
* **Logic:** STL-Next parses the %command% expansion. If it detects a Wine environment (e.g., the command starts with .../proton), it adopts the compatibility tool behavior. If it detects a native binary, it wraps the execution environment directly.

### **2.2 WINEPREFIX and Compatdata Management**

A major source of "brittleness" in the current Bash script is the handling of the compatdata folder (the virtual C: drive). Third-party tools like Mod Organizer 2 (MO2) must run inside this prefix to manage mods effectively. However, launching them often triggers Steam to "update" or "repair" the prefix, which can overwrite user modifications.

Zig Solution: The "Prefix Lock" Mechanism  
STL-Next must implement a file-lock-based system to ensure atomic access to the prefix.

* **State Inspection:** Before launching, STL-Next parses pfx/system.reg. Zig's parsing speed allows it to verify if the prefix version matches the requested Proton version in milliseconds.  
* **Sandboxing via Bubblewrap:** When launching a tool like MO2, STL-Next should optionally utilize bwrap (Bubblewrap) to isolate the tool. This ensures that while MO2 can see the game files, it cannot inadvertently write to Steam's tracked configuration files (user.reg), preventing corruption loops where Steam constantly tries to "repair" the game.10  
* **Virtual Drive Mapping:** Zig handles the creation of Z: drive mappings (pointing to the Linux root) explicitly. This is vital for tools like ReShade installers, which need to navigate the Linux filesystem to find shaders.

### **2.3 Dependency Management: The NixOS "Pure" Strategy**

The hardest challenge for STL on NixOS is the dependency on external binaries (7z, curl, yad, cabextract). The current script assumes these exist in /usr/bin or $PATH, which leads to immediate failure on NixOS unless the user installs them into a global profile—a practice discouraged in the Nix ecosystem.11

Strategy: "Batteries Included" via Build-Time Linking  
STL-Next should eliminate runtime dependencies on basic utilities by linking against libraries that provide this functionality.

* **HTTP/Download:** Instead of curl, use Zig’s std.http.Client.  
* **Archives:** Instead of calling 7z or cabextract, link against libarchive (C library). This allows STL-Next to extract .zip, .7z, and .cab (DirectX installers) natively in memory.  
* **Process Management:** Instead of xdotool or procps, use standard Linux syscalls (/proc filesystem parsing) to monitor game processes.

Runtime Path Resolution (The "Path Scout"):  
For complex binaries that cannot be linked (e.g., gamescope, gamemode), STL-Next must not hardcode paths.

* **Mechanism:** Implement a PathScout module that searches the PATH environment variable at runtime.  
* **Nix Integration:** On NixOS, the package derivation will use wrapProgram to inject the store paths of dependencies into the PATH seen by STL-Next.13  
  * *Example:* makeWrapper $out/bin/stl-next \--prefix PATH : ${lib.makeBinPath \[ gamescope mangohud \]}.  
* **Error Handling:** If a binary is missing, STL-Next enters a "Degraded Mode" (disabling that feature) rather than crashing, and logs a structured error in JSON format for debugging.

## ---

**3\. The Module System (The "Tinkers")**

The Bash script contains over 50 features tightly coupled into the main execution flow. STL-Next demands a **Plugin API** where features are isolated modules. This modularity is enforced via a Zig interface (using a struct of function pointers or a tagged union).

**The Tinker Trait Definition:**

Code snippet

pub const Tinker \= struct {  
    id:const u8,  
    priority: u8, // Determines execution order (Setup \> Overlay \> Launch)  
      
    // Lifecycle Hooks  
    isEnabled: \*const fn(config: \*GameConfig) bool,  
    preparePrefix: \*const fn(ctx: \*Context)\!void, // Filesystem ops  
    modifyEnv: \*const fn(env: \*EnvMap)\!void,      // Environment vars  
    modifyArgs: \*const fn(args: \*ArgList)\!void,   // Command line flags  
};

### **3.1 Overlays & HUDs (The Injectors)**

* **Modules:** MangoHud, GameMode, Gamescope, vkBasalt.  
* **Logic:** These modules primarily manipulate the **Environment Variables** and the **Command Vector**.  
  * *MangoHud:* The module generates the config file. Instead of echo lines in Bash, Zig serializes a MangoConfig struct to $XDG\_CONFIG\_HOME/MangoHud/wine-GameName.conf. It then injects MANGOHUD=1 into the environment.15  
  * *Gamescope:* This requires complex argument parsing. The module constructs the nested command: gamescope \-W 1920 \-H 1080 \-- %command%. Zig's std.ArrayList ensures this string construction is memory-safe and correctly escaped, avoiding the "quoting hell" of Bash.

### **3.2 Visual Enhancements (The Filesystem Manipulators)**

* **Modules:** ReShade, SpecialK.  
* **Logic:** These require copying or symlinking files *into* the game directory before launch.  
  * *Bash Method:* Copies ReShade64.dll to dxgi.dll every launch. Inefficient IO.  
  * *Zig Optimization:* The ReShade module calculates the CRC32 checksum of the installed dxgi.dll.16 It compares this against the desired version's hash. File operations (symlinking/copying) only occur if the hashes differ.  
  * *Symlinks:* Zig uses std.fs.symLink. The module checks filesystem capabilities (some NTFS mounts behave poorly with symlinks) and falls back to copying if necessary.

### **3.3 VR & Specialized Tools**

* **Modules:** UEVR, Flat2VR, Side-by-Side VR.  
* **Logic:** These often require "Sidecar Injection."  
  * *UEVR:* Requires an injector executable to run *after* the game process starts. STL-Next handles this by spawning the game process, waiting for the process ID (PID) to stabilize, and then executing the UEVR injector targeted at that PID. This requires precise timing and process monitoring that Bash sleep loops handle poorly.

### **3.4 Mod Managers (The Complex Orchestrators)**

* **Modules:** Mod Organizer 2 (MO2), Vortex, HedgeModManager.  
* **Logic:** This is the most complex module, as it hijacks the launch entirely.  
  * **USVFS Injection:** MO2 uses a Virtual File System (USVFS) to trick the game into seeing mods that aren't there. This requires specific DLL overrides in Wine (WINEDLLOVERRIDES="nxmhandler=n;usvfs\_proxy\_x86=n").  
  * **Protocol Handling:** STL-Next must register itself as the handler for nxm:// links (Nexus Mods). When a user clicks a download link on the web, STL-Next parses the URL and forwards it via IPC to the running MO2 instance inside the Wine prefix.10  
  * **Shared Instances:** The module supports "Shared Modding Data," redirecting STEAM\_COMPAT\_DATA\_PATH to a centralized location (e.g., \~/.config/stl/modding/instances/SkyrimSE) so multiple Proton versions can share the same mod list without duplication.

## ---

**4\. The "Wait-Requester" & GUI Strategy**

The "Wait-Requester" is the splash screen that allows users to interrupt the auto-launch to change settings. In the Bash version, this is implemented using yad (Yet Another Dialog).

The Failure of yad:  
yad is a blocking call. When the splash screen is up, the entire process tree pauses. This can cause Steam to misinterpret the game state (logging playtime while the user is just in the menu) or timeout the launch if it takes too long. Furthermore, yad is an external dependency that is often missing or version-mismatched on different distros.18

### **4.1 The Split-Process Architecture**

To solve the blocking issue and ensure a lightweight footprint, STL-Next adopts a **Daemon/Client** model.

1. **The Launcher Daemon (Parent):** This is the main STL-Next binary. It initializes the engine, prepares the environment, and checks if the UI is needed.  
2. **The GUI Client (Child):** A separate binary (stl-ui) spawned only when interaction is required.

IPC Mechanism (Unix Domain Sockets):  
Communication between the Daemon and Client happens via a Unix Domain Socket located at /tmp/stl-\<AppID\>.sock.

* **Protocol:** Simple JSON messages over the socket.20  
  * {"action": "PAUSE\_LAUNCH"}: Client tells Daemon to stop the countdown.  
  * {"action": "UPDATE\_CONFIG", "payload": {...}}: Client sends new settings.  
  * {"action": "PROCEED"}: Client tells Daemon to launch the game.  
  * {"action": "ABORT"}: Client tells Daemon to exit.

### **4.2 GUI Library Strategy: Raylib**

The GUI must be instant (\<200ms startup) and support Gamepad input (for Steam Deck users). Electron is too heavy; GTK is too complex to bundle statically.

Recommendation: Raylib-Zig  
Raylib is a lightweight C library with excellent Zig bindings.

* **Performance:** It opens an OpenGL window in milliseconds.  
* **Input:** Native support for Gamepads (SDL2 controller mappings), essential for the Deck.  
* **Dependency:** Can be statically linked into the stl-ui binary, resulting in a single executable with zero external library dependencies (other than libc/GL).  
* **Fallback:** For headless servers or terminal lovers, STL-Next should include a TUI (Text User Interface) mode using a library like vaxis or notcurses, activated via \--tui.

## ---

**5\. Performance & Modernization Goals**

### **5.1 Eliminating "Hot Paths"**

The "Hot Path" is the sequence of operations from the moment Steam clicks "Play" to the moment the game window appears.

Bash Analysis (The Bottleneck):  
In the current script, a typical launch involves:

1. Parsing appinfo.vdf (External Python/Node call: \~1.5s).  
2. Reading config (Hundreds of grep/cut subshells: \~0.5s).  
3. Generating Proton config (More sed/awk: \~0.5s).  
4. Total Overhead: **\~2.5 \- 5.0 seconds**.

**Zig Benchmark Target:**

1. VDF Parse (Streaming Binary): **\< 10ms**.  
2. Config Load (JSON Deserialize): **\< 5ms**.  
3. Environment Setup (In-memory Map): **\< 1ms**.  
4. Total Overhead: **\< 50ms**.

### **5.2 CLI Design (JSON & Nushell)**

Power users and automation scripts require a structured command-line interface.

* **JSON Output:** All informational commands (stl info, stl list-protons) must support a \--json flag. Zig's std.json.stringify makes this trivial.  
  * *Scenario:* A user wants to bulk-install ReShade for all installed games.  
  * *Command:* stl list-games \--json | jq \-r '..id' | xargs \-I {} stl install-reshade {}.  
* **Nushell Integration:** The CLI output should be optimized for structured shells like Nushell. This allows users to query the internal state of the engine (e.g., "Where is the compatdata for AppID 500?") without parsing text.

## ---

**6\. Output Expectations & Roadmap**

### **6.1 Modular Project Map**

| Zig Module | Bash Equivalent | Responsibility |
| :---- | :---- | :---- |
| **src/main.zig** | steamtinkerlaunch (entry) | CLI parsing, sub-command dispatch. |
| **src/engine/vdf.zig** | vdf-parser, grep | Binary/Text VDF parsing, struct serialization. |
| **src/engine/steam.zig** | eval/steam paths | Locating Steam, LibraryFolders, UserData. |
| **src/engine/proton.zig** | eval/proton | Finding Proton versions, managing compatibilitytools.d. |
| **src/core/launcher.zig** | Main logic loop | Orchestrating the wait, environment setup, and exec. |
| **src/tinkers/interface.zig** | N/A (Implicit) | Defines the Tinker trait/interface. |
| **src/tinkers/overlay.zig** | eval/mangohud... | Configures MangoHud, Gamescope, etc. |
| **src/tinkers/modding.zig** | eval/mo2 | Handling MO2/Vortex specific injection paths. |
| **src/ui/daemon.zig** | yad calls | The IPC server for the GUI. |
| **src/ui/client/** | yad windows | The Raylib/ImGui standalone GUI application. |

### **6.2 Modernization Roadmap**

#### **Phase 1: The "Iron" Foundation (Months 1-2)**

* **Goal:** A CLI-only tool that can launch a game faster than the Bash script.  
* **Key Deliverables:**  
  * Binary VDF Parser (Streaming).  
  * Steam Path Detection logic.  
  * Pass-through Launcher (Proton wrapping).  
  * NixOS Flake setup.

#### **Phase 2: The Tinker Ecosystem (Months 3-4)**

* **Goal:** Feature parity with key modules.  
* **Key Deliverables:**  
  * Module API implementation.  
  * Porting MangoHud/Gamescope logic.  
  * Porting ReShade logic (Symlink/Hash check).  
  * libarchive integration for tool extraction.

#### **Phase 3: The Interaction Layer (Months 5-6)**

* **Goal:** User experience and Mod Manager support.  
* **Key Deliverables:**  
  * Raylib-based Wait-Requester (GUI).  
  * IPC Mechanism (Socket).  
  * MO2/Vortex logic (USVFS handling).

### **6.3 Lessons Learned (Failures to Avoid)**

1. **The "Text Parsing" Trap:** Bash scripts break whenever Valve changes a file's indentation. **Lesson:** Use strict binary parsing for machine files and lenient JSON/Struct parsing for configs. Never use regex on structured data.  
2. **The "Blocking UI" Delay:** yad hung the game process. **Lesson:** The GUI must be a completely detached process (Client/Daemon model) so the launcher is never blocked by UI rendering threads.  
3. **The "Hardcoded Path" Sin:** Assuming /usr/bin/proton exists. **Lesson:** Always use relative paths or PATH lookup. On NixOS, rely on the wrapper, never absolute system paths.  
4. **The LevelDB Black Box:** Ignoring LevelDB meant ignoring "Hidden" games. **Lesson:** Treat LevelDB as a first-class citizen with C-bindings. Access the data directly rather than waiting for a slow Python script.

## **Conclusion**

Rewriting SteamTinkerLaunch in Zig is an architectural paradigm shift. By moving from a loose collection of scripts to a compiled, type-safe "Steam Engine," the project sheds the technical debt that has stifled its growth. The proposed architecture leverages Zig's strengths—binary data handling, C-interop, and cross-compilation—to solve the specific pain points of VDF parsing and environment orchestration. The result will be a tool that is not only robust and modular but fast enough to be invisible—a true "Tinker" tool that empowers the user without getting in their way.

#### **Works cited**

1. binary-vdf-parser \- NPM, accessed January 13, 2026, [https://www.npmjs.com/package/binary-vdf-parser](https://www.npmjs.com/package/binary-vdf-parser)  
2. vdf package \- github.com/jslay88/vdf \- Go Packages, accessed January 13, 2026, [https://pkg.go.dev/github.com/jslay88/vdf](https://pkg.go.dev/github.com/jslay88/vdf)  
3. Corecii/steam-binary-vdf-ts: A module to read and write the ... \- GitHub, accessed January 13, 2026, [https://github.com/Corecii/steam-binary-vdf-ts](https://github.com/Corecii/steam-binary-vdf-ts)  
4. WebAPI/VDF \- Official TF2 Wiki, accessed January 13, 2026, [https://wiki.teamfortress.com/wiki/WebAPI/VDF](https://wiki.teamfortress.com/wiki/WebAPI/VDF)  
5. 0wn3dg0d/Stelicas: Stelicas (Steam Library Categories Scraper) \- A tool designed to scrape your Steam library categories, retrieve comprehensive game details (including tags, release dates, reviews, and more), and export the data into a structured CSV format for easy organization and analysis. \- GitHub, accessed January 13, 2026, [https://github.com/0wn3dg0d/Stelicas](https://github.com/0wn3dg0d/Stelicas)  
6. LevelDB is a fast key-value storage library written at Google that provides an ordered mapping from string keys to string values. \- GitHub, accessed January 13, 2026, [https://github.com/google/leveldb](https://github.com/google/leveldb)  
7. where is the localconfig.vdf file located? I want to manualy delete this as steam is acting wierd\!, accessed January 13, 2026, [https://steamcommunity.com/discussions/forum/1/1744479063993046723/](https://steamcommunity.com/discussions/forum/1/1744479063993046723/)  
8. Steam Compatibility Tool · sonic2kk/steamtinkerlaunch Wiki · GitHub, accessed January 13, 2026, [https://github.com/sonic2kk/steamtinkerlaunch/wiki/Steam-Compatibility-Tool](https://github.com/sonic2kk/steamtinkerlaunch/wiki/Steam-Compatibility-Tool)  
9. Proton Versions · sonic2kk/steamtinkerlaunch Wiki \- GitHub, accessed January 13, 2026, [https://github.com/frostworx/steamtinkerlaunch/wiki/Proton-Versions](https://github.com/frostworx/steamtinkerlaunch/wiki/Proton-Versions)  
10. Mod Organizer 2 · sonic2kk/steamtinkerlaunch Wiki \- GitHub, accessed January 13, 2026, [https://github.com/sonic2kk/steamtinkerlaunch/wiki/Mod-Organizer-2/1d0d9c1addf59c28741bf1aa4073edb0ca4d5706](https://github.com/sonic2kk/steamtinkerlaunch/wiki/Mod-Organizer-2/1d0d9c1addf59c28741bf1aa4073edb0ca4d5706)  
11. How to avoid hardcoded /nix/store/... paths in \~/.bashrc and \~/.profile? : r/NixOS \- Reddit, accessed January 13, 2026, [https://www.reddit.com/r/NixOS/comments/1n57650/how\_to\_avoid\_hardcoded\_nixstore\_paths\_in\_bashrc/](https://www.reddit.com/r/NixOS/comments/1n57650/how_to_avoid_hardcoded_nixstore_paths_in_bashrc/)  
12. Add /bin/bash to avoid unnecessary pain \- Page 4 \- Development \- NixOS Discourse, accessed January 13, 2026, [https://discourse.nixos.org/t/add-bin-bash-to-avoid-unnecessary-pain/5673?page=4](https://discourse.nixos.org/t/add-bin-bash-to-avoid-unnecessary-pain/5673?page=4)  
13. Nixpkgs Reference Manual \- NixOS, accessed January 13, 2026, [https://nixos.org/nixpkgs/manual/](https://nixos.org/nixpkgs/manual/)  
14. Recommended practice for setting PATH \- Help \- NixOS Discourse, accessed January 13, 2026, [https://discourse.nixos.org/t/recommended-practice-for-setting-path/6885](https://discourse.nixos.org/t/recommended-practice-for-setting-path/6885)  
15. MangoHud · sonic2kk/steamtinkerlaunch Wiki \- GitHub, accessed January 13, 2026, [https://github.com/sonic2kk/steamtinkerlaunch/wiki/MangoHud](https://github.com/sonic2kk/steamtinkerlaunch/wiki/MangoHud)  
16. ReShade · sonic2kk/steamtinkerlaunch Wiki \- GitHub, accessed January 13, 2026, [https://github.com/sonic2kk/steamtinkerlaunch/wiki/ReShade](https://github.com/sonic2kk/steamtinkerlaunch/wiki/ReShade)  
17. Using Mod Organizer 2 on Linux the Right Way, accessed January 13, 2026, [https://forums.nexusmods.com/topic/13512108-using-mod-organizer-2-on-linux-the-right-way/](https://forums.nexusmods.com/topic/13512108-using-mod-organizer-2-on-linux-the-right-way/)  
18. I cannot install SteamTinkerLauncher on Linux Mint because of unmet dependencies : r/linux\_gaming \- Reddit, accessed January 13, 2026, [https://www.reddit.com/r/linux\_gaming/comments/13e5a2h/i\_cannot\_install\_steamtinkerlauncher\_on\_linux/](https://www.reddit.com/r/linux_gaming/comments/13e5a2h/i_cannot_install_steamtinkerlauncher_on_linux/)  
19. Steamtinkerlaunch not showing up, already increased WAITEDITOR : r/linux\_gaming, accessed January 13, 2026, [https://www.reddit.com/r/linux\_gaming/comments/1ds7pyk/steamtinkerlaunch\_not\_showing\_up\_already/](https://www.reddit.com/r/linux_gaming/comments/1ds7pyk/steamtinkerlaunch_not_showing_up_already/)  
20. Understanding Unix Sockets: A Deep Dive into Inter-Process Communication, accessed January 13, 2026, [https://dev.to/prezaei/understanding-unix-sockets-a-deep-dive-into-inter-process-communication-47f7](https://dev.to/prezaei/understanding-unix-sockets-a-deep-dive-into-inter-process-communication-47f7)