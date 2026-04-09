$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$compiler = "C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe"

if (-not (Test-Path $compiler)) {
    throw "csc.exe not found at $compiler"
}

& $compiler /nologo /target:exe /platform:x64 /out:"$scriptDir\steam_id_bridge.exe" "$scriptDir\SteamIdBridge.cs"

Write-Host "Built steam_id_bridge.exe"
