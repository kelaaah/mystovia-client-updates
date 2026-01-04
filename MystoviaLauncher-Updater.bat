@echo off
:: Mystovia Launcher with Auto-Update
:: This script checks for updates before launching

cd /d "%~dp0"

:: Check for admin rights and request if needed
net session >nul 2>&1
if %errorLevel% neq 0 (
    :: Not running as admin, restart with admin rights
    powershell.exe -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

:: Run updater script with admin rights
powershell.exe -ExecutionPolicy Bypass -NoProfile -File "%~dp0update-client.ps1"

:: Launch the actual launcher
start "" "%~dp0MystoviaLauncher.exe"

exit
