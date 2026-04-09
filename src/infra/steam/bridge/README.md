# SteamIDGet bridge notes

## Goal

Read the current Steam user's SteamID from a Lua/LÖVE project without depending on a Lua Steam binding.

This prototype uses a tiny native bridge executable instead of `luasteam`.

## Why the bridge approach won

The `luasteam` Windows binary loaded successfully from disk but failed at runtime because it depended on `lua51.dll`.
`LOVE 11.5` uses its own embedded LuaJIT runtime, so the prebuilt `luasteam.dll` was not ABI-compatible with the current project setup.

The bridge executable avoids that problem:

- Steamworks is accessed from a separate process.
- Lua only needs to launch the executable and parse stdout.
- Packaging is simpler because the game does not need to load Steamworks through LuaJIT.

## Files in this folder

- `SteamIdBridge.cs`
  Cross-platform C# source for the SteamID bridge.
- `build_bridge.ps1`
  Windows build script using `csc.exe`.
- `build_bridge_macos.sh`
  macOS build script for `mcs` or `csc`.
- `steam_id_bridge.exe`
  Built Windows bridge binary.
- `steam_api64.dll`
  Windows Steamworks runtime library.
- `libsteam_api.dylib`
  macOS Steamworks runtime library.
- `steam_appid.txt`
  Development-only AppID file used for local testing.

## Current Windows test result

The bridge already works locally on this machine and returned a real SteamID:

`76561198964368608`

Observed bridge output:

```text
Setting breakpad minidump AppID = 480
SteamInternal_SetMinidumpSteamID:  Caching Steam ID: 76561198964368608 [API loaded no]
76561198964368608
```

The Steam logs are normal here. The Lua side extracts the numeric line.

## Windows build steps

Source files:

- `SteamIdBridge.cs`
- `steam_api64.dll`
- `steam_appid.txt`

Build:

```powershell
powershell -ExecutionPolicy Bypass -File .\build_bridge.ps1
```

Run:

```powershell
.\steam_id_bridge.exe
```

Expected success output includes a numeric SteamID.

## macOS prep

Files to keep together on macOS:

- `SteamIdBridge.cs`
- `build_bridge_macos.sh`
- `libsteam_api.dylib`
- `steam_appid.txt`

Suggested build on macOS:

```sh
sh ./build_bridge_macos.sh
```

Suggested run on macOS:

```sh
mono ./steam_id_bridge.exe
```

If you later switch to a native `dotnet publish` flow, the same source file can still be reused.

## How Lua currently uses it

Prototype UI:

- `src/features/gameplay/card_themes/steam_id_test.lua`

Provider integration:

- `src/features/session/steam_id_provider.lua`

Current behavior:

- The test page looks for `SteamIDGet/steam_id_bridge.exe`.
- It launches the executable with `io.popen`.
- It scans stdout/stderr and extracts the first all-digit line as the SteamID.
- `SteamIDProvider` now supports `source = "bridge"`.

## When moving this outside the prototype folder

Keep the bridge as a small self-contained package.

Recommended structure:

```text
steam_bridge/
  SteamIdBridge.cs
  steam_id_bridge.exe
  steam_appid.txt
  windows/
    steam_api64.dll
  macos/
    libsteam_api.dylib
```

The important rule is simple: the bridge executable and the matching Steam runtime library must stay in the same runtime bundle.

## Release note

`steam_appid.txt` is for local development. Before shipping through Steam, remove it from the final shipped build and rely on the real Steam launch environment.
