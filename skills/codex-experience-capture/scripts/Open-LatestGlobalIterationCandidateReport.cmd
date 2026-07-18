@echo off
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Open-LatestGlobalIterationCandidateReport.ps1" -ProjectRoot "%~dp0..\..\.." -Open
