@echo off
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0Manage-CodexEnvironment.ps1" %*
exit /b %ERRORLEVEL%
