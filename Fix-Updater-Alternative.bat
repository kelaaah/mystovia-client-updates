@echo off
echo ========================================
echo Mystovia - Reparador de Actualizador
echo ========================================
echo.
echo Este script reparara el actualizador del cliente.
echo.
pause

cd /d "%ProgramFiles%\Mystovia"

echo.
echo [1/2] Descargando MystoviaLauncher-Updater.bat...
curl -L -o "MystoviaLauncher-Updater.bat" "https://raw.githubusercontent.com/kelaaah/mystovia-client-updates/main/MystoviaLauncher-Updater.bat"

echo [2/2] Descargando update-client.ps1...
curl -L -o "update-client.ps1" "https://raw.githubusercontent.com/kelaaah/mystovia-client-updates/main/update-client.ps1"

echo.
echo ========================================
echo Reparacion completada!
echo Ahora podes ejecutar MystoviaLauncher-Updater.bat
echo ========================================
echo.
pause
