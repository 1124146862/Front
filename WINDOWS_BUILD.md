# Windows Build Guide

This frontend is a LÖVE project. The Windows packaging flow uses `build_exe.ps1` to create a runnable `.exe`.

## Prerequisites

- Windows
- PowerShell
- LÖVE 11.5 installed

This machine currently has LÖVE installed at:

```text
C:\Program Files\LOVE
```

The script default is already set to that path.

## Project Location

Frontend root:

```text
D:\DATA\Onedrive\GuanDan\Front
```

## Build Command

Open PowerShell and run:

```powershell
cd D:\DATA\Onedrive\GuanDan\Front
powershell -ExecutionPolicy Bypass -File .\build_exe.ps1
```

If your LÖVE installation is in a different location, pass it explicitly:

```powershell
powershell -ExecutionPolicy Bypass -File .\build_exe.ps1 -LoveDir "C:\Path\To\LOVE"
```

## Output

By default, build output is written to:

```text
D:\DATA\Onedrive\GuanDan\build
```

Important files:

- `GuanDan.exe`
- `GuanDan.love`
- `steam_bridge\steam_id_bridge.exe`
- `steam_bridge\steam_api64.dll`

Do not distribute only the `.exe`. Distribute the whole output directory.

## Steam Development Mode

For local Steam-related development, you can also copy `steam_appid.txt`:

```powershell
powershell -ExecutionPolicy Bypass -File .\build_exe.ps1 -IncludeDevSteamAppId
```

Use this only for local development and testing.

## Custom Output Directory

You can choose a different output directory:

```powershell
powershell -ExecutionPolicy Bypass -File .\build_exe.ps1 -OutputDir "D:\Builds\GuanDan"
```

## Custom EXE Name

You can also change the generated executable name:

```powershell
powershell -ExecutionPolicy Bypass -File .\build_exe.ps1 -ExeName "GuanDanDev"
```

## What the Script Does

`build_exe.ps1` performs these steps:

1. Validates the LÖVE installation path.
2. Packages `assets`, `src`, `main.lua`, and `conf.lua` into a `.love` file.
3. Copies the LÖVE runtime files into the output directory.
4. Combines `love.exe` and the `.love` package into a final `.exe`.
5. Copies Steam bridge files into `steam_bridge\`.

## Common Errors

### `LÖVE directory not found`

Your `-LoveDir` path is wrong.

Check whether this exists:

```powershell
Test-Path "C:\Program Files\LOVE"
```

If not, locate your LÖVE install and rerun with the correct path.

### `love.exe not found`

The folder exists, but it is not a valid LÖVE installation directory.

Check:

```powershell
Test-Path "C:\Program Files\LOVE\love.exe"
```

### Build succeeds but the game does not run

Check these items:

- `main.lua` and `conf.lua` exist in the frontend root.
- The entire output directory is kept together.
- Steam-related files are present if your current build needs them.

## Recommended Release Practice

- Keep `steam_appid.txt` out of formal release builds.
- Test the generated `GuanDan.exe` from the output directory before distributing it.
- Archive or ship the entire build folder, not a single file.
