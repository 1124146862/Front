param(
    [string]$Identity = "guandan_front",
    [string]$LogFileName = "http_debug.log"
)

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "=== Runtime Diagnostics ===" -ForegroundColor Cyan
Write-Host "Identity    : $Identity"
Write-Host "Log file    : $LogFileName"
Write-Host "User        : $env:USERNAME"
Write-Host "AppData     : $env:APPDATA"
Write-Host ""

$loveRoot = Join-Path $env:APPDATA "LOVE"
$identityRoot = Join-Path $loveRoot $Identity

Write-Host "=== Expected Save Paths ===" -ForegroundColor Cyan
Write-Host "LOVE root   : $loveRoot"
Write-Host "Identity dir: $identityRoot"
Write-Host "LOVE exists : $(Test-Path -LiteralPath $loveRoot)"
Write-Host "Ident exists: $(Test-Path -LiteralPath $identityRoot)"
Write-Host ""

Write-Host "=== curl.exe Detection ===" -ForegroundColor Cyan
try {
    $curlCandidates = @(where.exe curl.exe 2>$null) | Where-Object { $_ -and $_.Trim() -ne "" }
    if ($curlCandidates.Count -eq 0) {
        Write-Host "No curl.exe found in PATH." -ForegroundColor Yellow
    } else {
        $curlCandidates | ForEach-Object { Write-Host $_ }
    }
} catch {
    Write-Host "Failed to run where.exe curl.exe" -ForegroundColor Yellow
}
Write-Host ""

Write-Host "=== Known Runtime Files ===" -ForegroundColor Cyan
$knownFiles = @(
    (Join-Path $identityRoot "user_settings.lua"),
    (Join-Path $identityRoot $LogFileName)
)

foreach ($file in $knownFiles) {
    $exists = Test-Path -LiteralPath $file
    Write-Host "$file  =>  $exists"
}
Write-Host ""

Write-Host "=== Searching User Profile ===" -ForegroundColor Cyan
$searchRoots = @(
    $env:APPDATA,
    $env:LOCALAPPDATA,
    (Join-Path $env:USERPROFILE "Documents"),
    (Join-Path $env:USERPROFILE "Desktop")
) | Where-Object { $_ -and (Test-Path -LiteralPath $_) }

$matches = @()
foreach ($root in $searchRoots) {
    Write-Host "Scanning: $root"
    try {
        $found = Get-ChildItem -LiteralPath $root -Recurse -File -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -eq $LogFileName -or $_.Name -eq "user_settings.lua" }
        if ($found) {
            $matches += $found
        }
    } catch {
        Write-Host "Skipped inaccessible path: $root" -ForegroundColor Yellow
    }
}

if (-not $matches -or $matches.Count -eq 0) {
    Write-Host ""
    Write-Host "No runtime log or settings file found in common user locations." -ForegroundColor Yellow
    exit 0
}

Write-Host ""
Write-Host "=== Found Files ===" -ForegroundColor Green
$matches | Sort-Object FullName -Unique | ForEach-Object {
    Write-Host $_.FullName
}

$logMatch = $matches | Where-Object { $_.Name -eq $LogFileName } | Sort-Object LastWriteTime -Descending | Select-Object -First 1
if ($logMatch) {
    Write-Host ""
    Write-Host "=== Latest Log Preview ===" -ForegroundColor Green
    Write-Host "Path: $($logMatch.FullName)"
    Write-Host ""
    try {
        Get-Content -LiteralPath $logMatch.FullName -Tail 80
    } catch {
        Write-Host "Failed to read log file." -ForegroundColor Yellow
    }
}
