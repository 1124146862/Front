#!/bin/sh
set -eu

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"

if [ ! -f "$SCRIPT_DIR/SteamIdBridge.cs" ]; then
  echo "SteamIdBridge.cs not found" >&2
  exit 1
fi

if command -v mcs >/dev/null 2>&1; then
  mcs -platform:x64 -out:"$SCRIPT_DIR/steam_id_bridge.exe" "$SCRIPT_DIR/SteamIdBridge.cs"
  echo "Built steam_id_bridge.exe with mcs"
  exit 0
fi

if command -v csc >/dev/null 2>&1; then
  csc /nologo /target:exe /platform:x64 /out:"$SCRIPT_DIR/steam_id_bridge.exe" "$SCRIPT_DIR/SteamIdBridge.cs"
  echo "Built steam_id_bridge.exe with csc"
  exit 0
fi

echo "No C# compiler found. Install Mono (mcs) or .NET SDK (csc)." >&2
exit 1
