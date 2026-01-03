@echo off
:: Mystovia Launcher with Auto-Update
:: This script checks for updates before launching

cd /d "%~dp0"

:: Run updater script
powershell.exe -ExecutionPolicy Bypass -NoProfile -File "%~dp0update-client.ps1"

:: Launch the actual launcher
start "" "%~dp0MystoviaLauncher.exe"

exit
