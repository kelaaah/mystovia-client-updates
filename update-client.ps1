# Mystovia Client Auto-Updater
# This script downloads updated files from GitHub

param(
[string]$RepoUrl = "https://raw.githubusercontent.com/kelaaah/mystovia-client-updates/main",
    [string]$InstallPath = "$env:ProgramFiles\Mystovia"
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "   Mystovia Client Updater v2.0" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "*** SISTEMA DE ACTUALIZACION AUTOMATICA ACTIVO ***" -ForegroundColor Green
Write-Host "Checking for updates..." -ForegroundColor Yellow

# Download the update manifest (list of files to update)
$manifestUrl = "$RepoUrl/update-manifest.txt"
$tempManifest = "$env:TEMP\mystovia-manifest.txt"

try {
    Invoke-WebRequest -Uri $manifestUrl -OutFile $tempManifest -UseBasicParsing -ErrorAction Stop
    $filesToUpdate = Get-Content $tempManifest | Where-Object { $_ -match '\S' -and $_ -notmatch '^#' }
}
catch {
    Write-Host "Could not check for updates. Continuing with launcher..." -ForegroundColor Yellow
    Start-Sleep -Seconds 2
    exit 0
}

if ($filesToUpdate.Count -eq 0) {
    Write-Host "No updates available." -ForegroundColor Green
    Start-Sleep -Seconds 1
    exit 0
}

Write-Host "Found $($filesToUpdate.Count) file(s) to update" -ForegroundColor Cyan
Write-Host ""

$updated = 0
$failed = 0

foreach ($file in $filesToUpdate) {
    # Parse file path and destination
    # Format: source_path|destination_path
    if ($file -match '\|') {
        $parts = $file -split '\|'
        $sourceFile = $parts[0].Trim()
        $destPath = $parts[1].Trim()
    }
    else {
        $sourceFile = $file.Trim()
        $destPath = $file.Trim()
    }

    # Determine full destination path
    if ($destPath -match '^APPDATA\\') {
        $destination = Join-Path $env:APPDATA ($destPath -replace '^APPDATA\\', '')
    }
    else {
        $destination = Join-Path $InstallPath $destPath
    }

    $url = "$RepoUrl/$sourceFile"

    # Create directory if needed
    $fileDir = Split-Path $destination -Parent
    if (-not (Test-Path $fileDir)) {
        New-Item -ItemType Directory -Path $fileDir -Force | Out-Null
    }

    try {
        Write-Host "[Updating] $destPath" -ForegroundColor Gray
        Invoke-WebRequest -Uri $url -OutFile $destination -UseBasicParsing -ErrorAction Stop
        $updated++
    }
    catch {
        Write-Host "  [FAILED] $destPath" -ForegroundColor Red
        Write-Host "  Error: $_" -ForegroundColor DarkRed
        $failed++
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "Update complete!" -ForegroundColor Green
Write-Host "Updated: $updated file(s)" -ForegroundColor Green
if ($failed -gt 0) {
    Write-Host "Failed: $failed file(s)" -ForegroundColor Red
}
Write-Host "========================================" -ForegroundColor Green

# Update version number in init.lua
try {
    $versionUrl = "$RepoUrl/version.txt"
    $newVersion = (Invoke-WebRequest -Uri $versionUrl -UseBasicParsing -ErrorAction Stop).Content.Trim()

    $initLuaPath = Join-Path $InstallPath "client\init.lua"
    if (Test-Path $initLuaPath) {
        $initContent = Get-Content $initLuaPath -Raw
        $initContent = $initContent -replace 'APP_NAME = "mystovia".*', "APP_NAME = `"mystovia`"  -- client name`r`nAPP_VERSION = `"$newVersion`"       -- client version"
        Set-Content $initLuaPath -Value $initContent -NoNewline
        Write-Host "Version updated to $newVersion" -ForegroundColor Green
    }
}
catch {
    Write-Host "Could not update version number" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Starting launcher..." -ForegroundColor Cyan

# Wait a moment before continuing
Start-Sleep -Seconds 2
