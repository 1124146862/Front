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

$tempZip = Join-Path $env:TEMP ("{0}_{1}.zip" -f $ExeName, [guid]::NewGuid().ToString("N"))
$loveFile = Join-Path $OutputDir "$ExeName.love"
$exeFile = Join-Path $OutputDir "$ExeName.exe"
$launcherPath = Join-Path $LoveDir "love.exe"

$bridgeSourceDir = Join-Path $projectRoot "src\infra\steam\bridge"
$bridgeOutputDir = Join-Path $OutputDir "steam_bridge"
$steamAppId = "4582780"

$rceditPath = Join-Path $projectRoot "tools\rcedit-x64.exe"

function Require-Path {
    param(
        [string]$Path,
        [string]$Description
    )

    if (-not (Test-Path -LiteralPath $Path)) {
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

    if (-not (Test-Path -LiteralPath $Source)) {
        return
    }

    $srcFull = [System.IO.Path]::GetFullPath($Source)
    $dstFull = [System.IO.Path]::GetFullPath($Destination)
    $dstDir = Split-Path -Parent $dstFull

    if (-not (Test-Path -LiteralPath $dstDir)) {
        New-Item -ItemType Directory -Force -Path $dstDir | Out-Null
    }

    if ($srcFull -eq $dstFull) {
        Write-Host "Skip copy to same path: $srcFull" -ForegroundColor DarkYellow
        return
    }

    Copy-Item -LiteralPath $srcFull -Destination $dstFull -Force
}

function Merge-BinaryFiles {
    param(
        [Parameter(Mandatory = $true)]
        [string]$LauncherPath,

        [Parameter(Mandatory = $true)]
        [string]$LoveFilePath,

        [Parameter(Mandatory = $true)]
        [string]$OutputExePath
    )

    $launcherFull = [System.IO.Path]::GetFullPath($LauncherPath)
    $loveFull = [System.IO.Path]::GetFullPath($LoveFilePath)
    $outputFull = [System.IO.Path]::GetFullPath($OutputExePath)

    $outputDirPath = Split-Path -Parent $outputFull
    if (-not (Test-Path -LiteralPath $outputDirPath)) {
        New-Item -ItemType Directory -Force -Path $outputDirPath | Out-Null
    }

    $buffer = New-Object byte[] (1024 * 1024)
    $outputStream = [System.IO.File]::Open($outputFull, [System.IO.FileMode]::Create, [System.IO.FileAccess]::Write, [System.IO.FileShare]::None)
    try {
        foreach ($source in @($launcherFull, $loveFull)) {
            $inputStream = [System.IO.File]::OpenRead($source)
            try {
                while (($read = $inputStream.Read($buffer, 0, $buffer.Length)) -gt 0) {
                    $outputStream.Write($buffer, 0, $read)
                }
            } finally {
                $inputStream.Dispose()
            }
        }
    } finally {
        $outputStream.Dispose()
    }
}

function Remove-PathWithRetry {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [int]$Attempts = 10,
        [int]$DelayMs = 300
    )

    for ($attempt = 1; $attempt -le $Attempts; $attempt++) {
        try {
            if (Test-Path -LiteralPath $Path) {
                Remove-Item -LiteralPath $Path -Force
            }
            return
        } catch {
            if ($attempt -eq $Attempts) {
                throw
            }
            Start-Sleep -Milliseconds $DelayMs
        }
    }
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

foreach ($path in @($loveFile, $exeFile)) {
    if ($path -and (Test-Path -LiteralPath $path)) {
        Remove-PathWithRetry -Path $path
    }
}

Get-ChildItem -LiteralPath $LoveDir -File | ForEach-Object {
    if ($_.Name -ieq "love.exe") {
        return
    }
    Copy-Item -LiteralPath $_.FullName -Destination (Join-Path $OutputDir $_.Name) -Force
}

$archiveInputs = @(
    (Join-Path $projectRoot "assets"),
    (Join-Path $projectRoot "src"),
    (Join-Path $projectRoot "main.lua"),
    (Join-Path $projectRoot "conf.lua")
)

Compress-Archive -Path $archiveInputs -DestinationPath $tempZip -Force
Copy-Item -LiteralPath $tempZip -Destination $loveFile -Force
Remove-PathWithRetry -Path $tempZip

Merge-BinaryFiles -LauncherPath $launcherPath -LoveFilePath $loveFile -OutputExePath $exeFile

$exeInfo = Get-Item -LiteralPath $exeFile
$loveInfo = Get-Item -LiteralPath $loveFile
if ($exeInfo.Length -le $loveInfo.Length) {
    throw "Packed EXE looks invalid: $exeFile (size=$($exeInfo.Length)) did not include launcher bytes."
}

if ($IconPath -and (Test-Path -LiteralPath $IconPath) -and (Test-Path -LiteralPath $rceditPath)) {
    Write-Host "Skipping icon patch for now because rcedit is unstable on fused LOVE executables in this environment." -ForegroundColor DarkYellow
} else {
    Write-Host "Icon or rcedit not found, skipping icon step." -ForegroundColor DarkYellow
}

if (Test-Path -LiteralPath $bridgeSourceDir) {
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
        if (Test-Path -LiteralPath $sourceFile) {
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
