@echo off
setlocal
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0switch-provider.ps1" yourapisource
echo.
pause
