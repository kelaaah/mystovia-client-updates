@echo off
:: Mystovia Launcher with Auto-Update
:: This script checks for updates before launching

cd /d "%~dp0"

:: Run updater script with admin privileges (hidden window)
powershell.exe -ExecutionPolicy Bypass -Command "Start-Process powershell -ArgumentList '-ExecutionPolicy Bypass -WindowStyle Hidden -File \"%~dp0update-client.ps1\"' -Verb RunAs -WindowStyle Hidden -Wait"

:: Launch the actual launcher
start "" "%~dp0MystoviaLauncher.exe"

exit
