param(
    [string]$LoveDir = "C:\Program Files\LOVE",
    [string]$OutputDir = "",
    [string]$ExeName = "GuanDan",
    [string]$IconPath = "",
    [switch]$IncludeDevSteamAppId
)

$ErrorActionPreference = "Stop"

$projectRoot = $PSScriptRoot

function Invoke-Step {
    param(
        [string]$Title,
        [scriptblock]$Action
    )

    Write-Host ""
    Write-Host ("=" * 72) -ForegroundColor DarkGray
    Write-Host $Title -ForegroundColor Cyan
    Write-Host ("=" * 72) -ForegroundColor DarkGray
    & $Action
}

Invoke-Step -Title "Step 1/1: Build frontend package" -Action {
    $args = @{}
    if (-not [string]::IsNullOrWhiteSpace($LoveDir)) {
        $args["LoveDir"] = $LoveDir
    }
    if (-not [string]::IsNullOrWhiteSpace($OutputDir)) {
        $args["OutputDir"] = $OutputDir
    }
    if (-not [string]::IsNullOrWhiteSpace($ExeName)) {
        $args["ExeName"] = $ExeName
    }
    if (-not [string]::IsNullOrWhiteSpace($IconPath)) {
        $args["IconPath"] = $IconPath
    }
    if ($IncludeDevSteamAppId) {
        $args["IncludeDevSteamAppId"] = $true
    }

    & (Join-Path $projectRoot "build_exe_fixed.ps1") @args
}

Write-Host ""
Write-Host "Release build completed." -ForegroundColor Green
