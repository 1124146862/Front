param(
    [string]$PythonPath = "",
    [string]$OutputDir = "",
    [switch]$NoConsole
)

$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Split-Path -Parent $projectRoot
$scriptPath = Join-Path $projectRoot "tools\room_ws_bridge.py"
$defaultOutputDir = Join-Path $repoRoot "backend\dist"
$toolsOutputPath = Join-Path $projectRoot "tools\room_ws_bridge.exe"

function Resolve-ExistingPath {
    param(
        [string[]]$Candidates
    )

    foreach ($candidate in $Candidates) {
        if (-not [string]::IsNullOrWhiteSpace($candidate) -and (Test-Path -LiteralPath $candidate)) {
            return $candidate
        }
    }

    return $null
}

if ([string]::IsNullOrWhiteSpace($OutputDir)) {
    $OutputDir = $defaultOutputDir
}

$resolvedPython = Resolve-ExistingPath @(
    $PythonPath,
    $env:ROOM_WS_PYTHON,
    (Join-Path $repoRoot "backend\.venv\Scripts\python.exe"),
    (Join-Path "D:\DATA\GuanDan\backend\.venv\Scripts" "python.exe")
)

if (-not $resolvedPython) {
    throw "Python executable not found. Pass -PythonPath or set ROOM_WS_PYTHON."
}

if (-not (Test-Path -LiteralPath $scriptPath)) {
    throw "Bridge script not found: $scriptPath"
}

New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null

$arguments = @(
    "-m",
    "PyInstaller",
    "--onefile",
    "--noconsole",
    "--name",
    "room_ws_bridge",
    "--hidden-import",
    "websockets",
    "--distpath",
    $OutputDir,
    $scriptPath
)

& $resolvedPython @arguments
if ($LASTEXITCODE -ne 0) {
    throw "PyInstaller failed with exit code $LASTEXITCODE"
}

$builtExe = Join-Path $OutputDir "room_ws_bridge.exe"
if (-not (Test-Path -LiteralPath $builtExe)) {
    throw "Bridge EXE was not generated: $builtExe"
}

Copy-Item -LiteralPath $builtExe -Destination $toolsOutputPath -Force

Write-Host ""
Write-Host "Room WS bridge build completed." -ForegroundColor Green
Write-Host "Python      : $resolvedPython"
Write-Host "Source      : $scriptPath"
Write-Host "Built EXE   : $builtExe"
Write-Host "Copied EXE  : $toolsOutputPath"
Write-Host ""
