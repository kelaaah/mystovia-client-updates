# Mystovia Client Auto-Updater
# This script downloads updated files from GitHub

param(
    [string]$RepoUrl = "https://raw.githubusercontent.com/kelaaah/mystovia-client-updates/main",
    [string]$InstallPath = "$env:ProgramFiles\Mystovia"
)

# Check if running as administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    # Restart as administrator
    $arguments = "-ExecutionPolicy Bypass -NoProfile -File `"$PSCommandPath`""
    Start-Process powershell.exe -ArgumentList $arguments -Verb RunAs -Wait
    exit
}

Clear-Host
Write-Host ""
Write-Host "         MYSTOVIA" -ForegroundColor Cyan
Write-Host ""
Write-Host "  ACTUALIZADOR OFICIAL - MYSTOVIA CLIENT" -ForegroundColor White
Write-Host ""
Write-Host "  [*] Verificando actualizaciones disponibles" -ForegroundColor Yellow
Write-Host ""

# Check version to see if update is needed
$versionUrl = "$RepoUrl/version.txt"
$localVersionFile = Join-Path $InstallPath "version.txt"

try {
    $remoteVersion = (Invoke-WebRequest -Uri $versionUrl -UseBasicParsing -ErrorAction Stop).Content.Trim()

    # Check local version
    $localVersion = ""
    if (Test-Path $localVersionFile) {
        $localVersion = (Get-Content $localVersionFile -Raw).Trim()
    }

    # Compare versions
    if ($localVersion -eq $remoteVersion -and $localVersion -ne "") {
        Write-Host "  [v] Tu cliente esta actualizado! (v$localVersion)" -ForegroundColor Green
        Write-Host "  [*] Iniciando cliente" -ForegroundColor Cyan
        Start-Sleep -Seconds 2
        exit
    }

    Write-Host "  [!] Nueva version disponible: v$remoteVersion" -ForegroundColor Yellow
}
catch {
    Write-Host "  [!] No se pudo verificar la version remota" -ForegroundColor Yellow
}

# Download the update manifest (list of files to update)
$manifestUrl = "$RepoUrl/update-manifest.txt"
$tempManifest = "$env:TEMP\mystovia-manifest.txt"

try {
    Invoke-WebRequest -Uri $manifestUrl -OutFile $tempManifest -UseBasicParsing -ErrorAction Stop
    $filesToUpdate = Get-Content $tempManifest | Where-Object { $_ -match '\S' -and $_ -notmatch '^#' }
}
catch {
    Write-Host "  [!] No se pudo verificar actualizaciones" -ForegroundColor Yellow
    Write-Host "  [*] Iniciando cliente" -ForegroundColor Cyan
    Start-Sleep -Seconds 2
    exit
}

if ($filesToUpdate.Count -eq 0) {
    Write-Host "  [v] Tu cliente esta actualizado!" -ForegroundColor Green
    Write-Host "  [*] Iniciando cliente" -ForegroundColor Cyan
    Start-Sleep -Seconds 2
    exit
}

Write-Host "  [v] Se encontraron $($filesToUpdate.Count) actualizaciones disponibles" -ForegroundColor Green
Write-Host "  [*] Descargando archivos" -ForegroundColor Cyan
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
        Write-Host "  [->] $destPath" -ForegroundColor Gray

        # Download to temp file first
        $tempFile = "$env:TEMP\mystovia-download-$(Get-Random).tmp"
        Invoke-WebRequest -Uri $url -OutFile $tempFile -UseBasicParsing -ErrorAction Stop

        # Remove existing file if it exists
        if (Test-Path $destination) {
            Remove-Item $destination -Force -ErrorAction SilentlyContinue
        }

        # Move temp file to destination
        Move-Item $tempFile $destination -Force

        $updated++
    }
    catch {
        Write-Host "  [X] Error: $destPath" -ForegroundColor Red
        $failed++
        # Clean up temp file if it exists
        if (Test-Path $tempFile) {
            Remove-Item $tempFile -Force -ErrorAction SilentlyContinue
        }
    }
}

Write-Host ""
Write-Host "  ACTUALIZACION COMPLETADA!" -ForegroundColor Green
Write-Host ""
Write-Host "  [v] Archivos actualizados: $updated" -ForegroundColor Green
if ($failed -gt 0) {
    Write-Host "  [X] Archivos con error: $failed" -ForegroundColor Red
}
Write-Host ""

# Update version number in init.lua and save version.txt locally
try {
    $versionUrl = "$RepoUrl/version.txt"
    $newVersion = (Invoke-WebRequest -Uri $versionUrl -UseBasicParsing -ErrorAction Stop).Content.Trim()

    # Save version.txt locally
    $localVersionFile = Join-Path $InstallPath "version.txt"
    $newVersion | Set-Content $localVersionFile

    $initLuaPath = Join-Path $InstallPath "client\init.lua"
    if (Test-Path $initLuaPath) {
        $initContent = Get-Content $initLuaPath
        $newContent = @()
        foreach ($line in $initContent) {
            if ($line -match '^APP_VERSION\s*=') {
                $newContent += "APP_VERSION = `"$newVersion`"       -- client version"
            } else {
                $newContent += $line
            }
        }
        $newContent | Set-Content $initLuaPath
        Write-Host "  [v] Version actualizada a $newVersion" -ForegroundColor Green
    }
}
catch {
    Write-Host "  [!] No se pudo actualizar el numero de version" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "  [*] Iniciando Mystovia Client" -ForegroundColor Cyan
Write-Host ""

# Wait a moment before continuing
Start-Sleep -Seconds 3
