param(
    [string]$LoveDir = "C:\Program Files\LOVE",
    [string]$OutputDir = "",
    [string]$ExeName = "GuanDan",
    [string]$IconPath = "",
    [switch]$IncludeDevSteamAppId
)

$ErrorActionPreference = "Stop"

$projectRoot = $PSScriptRoot

if ([string]::IsNullOrWhiteSpace($OutputDir)) {
    $OutputDir = Join-Path (Split-Path -Parent $projectRoot) "build"
}

$tempZip = Join-Path $OutputDir "$ExeName.zip"
$loveFile = Join-Path $OutputDir "$ExeName.love"
$exeFile = Join-Path $OutputDir "$ExeName.exe"

$bridgeSourceDir = Join-Path $projectRoot "src\infra\steam\bridge"
$bridgeOutputDir = Join-Path $OutputDir "steam_bridge"
$steamAppId = "4582780"

$rceditPath = Join-Path $projectRoot "tools\rcedit-x64.exe"

function Require-Path {
    param(
        [string]$Path,
        [string]$Description
    )

    if (-not (Test-Path $Path)) {
        throw "$Description not found: $Path"
    }
}

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

function Copy-Item-Safe {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Source,

        [Parameter(Mandatory = $true)]
        [string]$Destination
    )

    if (-not (Test-Path $Source)) {
        return
    }

    $srcFull = [System.IO.Path]::GetFullPath($Source)
    $dstFull = [System.IO.Path]::GetFullPath($Destination)

    $dstDir = Split-Path -Parent $dstFull
    if (-not (Test-Path $dstDir)) {
        New-Item -ItemType Directory -Force -Path $dstDir | Out-Null
    }

    if ($srcFull -eq $dstFull) {
        Write-Host "Skip copy to same path: $srcFull" -ForegroundColor DarkYellow
        return
    }

    Copy-Item $srcFull -Destination $dstFull -Force
}

Require-Path $LoveDir "LOVE directory"
Require-Path (Join-Path $LoveDir "love.exe") "love.exe"
Require-Path (Join-Path $projectRoot "main.lua") "main.lua"
Require-Path (Join-Path $projectRoot "conf.lua") "conf.lua"

if ([string]::IsNullOrWhiteSpace($IconPath)) {
    $IconPath = Resolve-ExistingPath @(
        (Join-Path $projectRoot "guandan_icon_transparent.ico"),
        (Join-Path $projectRoot "icon.ico"),
        (Join-Path (Split-Path -Parent $projectRoot) "build\game.ico")
    )
}

New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null

foreach ($path in @($tempZip, $loveFile, $exeFile)) {
    if ($path -and (Test-Path $path)) {
        Remove-Item $path -Force
    }
}

Get-ChildItem -LiteralPath $LoveDir -File | ForEach-Object {
    Copy-Item $_.FullName -Destination (Join-Path $OutputDir $_.Name) -Force
}

$archiveInputs = @(
    (Join-Path $projectRoot "assets"),
    (Join-Path $projectRoot "src"),
    (Join-Path $projectRoot "main.lua"),
    (Join-Path $projectRoot "conf.lua")
)

Compress-Archive -Path $archiveInputs -DestinationPath $tempZip -Force
Rename-Item $tempZip ([System.IO.Path]::GetFileName($loveFile))

cmd /c "copy /b `"$OutputDir\love.exe`"+`"$loveFile`" `"$exeFile`"" | Out-Null
Remove-Item (Join-Path $OutputDir "love.exe") -Force

if ($IconPath -and (Test-Path $IconPath) -and (Test-Path $rceditPath)) {
    Write-Host "Setting EXE icon..." -ForegroundColor Yellow
    & $rceditPath $exeFile --set-icon $IconPath
} else {
    Write-Host "Icon or rcedit not found, skipping icon step." -ForegroundColor DarkYellow
}

if (Test-Path $bridgeSourceDir) {
    New-Item -ItemType Directory -Force -Path $bridgeOutputDir | Out-Null

    $bridgeFiles = @(
        "steam_id_bridge.exe",
        "steam_api64.dll"
    )

    if ($IncludeDevSteamAppId) {
        $bridgeFiles += "steam_appid.txt"
    }

    foreach ($bridgeFile in $bridgeFiles) {
        $sourceFile = Join-Path $bridgeSourceDir $bridgeFile
        if (Test-Path $sourceFile) {
            Copy-Item-Safe -Source $sourceFile -Destination (Join-Path $bridgeOutputDir $bridgeFile)
        }
    }

    Set-Content -LiteralPath (Join-Path $bridgeOutputDir "steam_appid.txt") -Value $steamAppId -Encoding ASCII
}

Write-Host ""
Write-Host "Build completed successfully." -ForegroundColor Green
Write-Host "EXE          : $exeFile"
Write-Host "LOVE package : $loveFile"
Write-Host "Output dir   : $OutputDir"
