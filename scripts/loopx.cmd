@echo off
setlocal
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0Invoke-LoopX.ps1" %*
exit /b %errorlevel%
