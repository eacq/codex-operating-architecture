@echo off
setlocal
echo Codex CLI login is intentionally not automated from this helper because Windows may reject codex.exe from elevated cmd.
echo.
echo A saved ChatGPT login profile will be restored automatically when available.
echo Only sign in through the Codex desktop app or ChatGPT UI if the profile is missing or expired.
echo.
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0switch-provider.ps1" chatgpt
echo.
pause
