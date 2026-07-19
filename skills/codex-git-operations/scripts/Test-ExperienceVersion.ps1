$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
$calculator = Join-Path $root 'skills\codex-git-operations\scripts\Get-ExperienceVersion.ps1'
$private = & $calculator -Action PrivateRelease -RepositoryRoot $root -CurrentVersion '1.1.0.0' -PublicReleaseRows @('v1.1 Latest v1.1 2026-07-18') -PrivateReleaseRows @('v1.1 Latest private-v1.1 2026-07-18') -UseProvidedReleaseRows | ConvertFrom-Json
if ($private.version -ne '1.2.0.0' -or $private.release_tag -ne 'v1.2') { throw 'Private release version did not increment from the existing private release.' }
$firstPrivate = & $calculator -Action PrivateRelease -RepositoryRoot $root -CurrentVersion '1.1.0.0' -PublicReleaseRows @('v1.1 Latest v1.1 2026-07-18') -PrivateReleaseRows @() -UseProvidedReleaseRows | ConvertFrom-Json
if ($firstPrivate.version -ne '1.0.0.0' -or $firstPrivate.release_tag -ne 'v1.0') { throw 'First private release version did not retain the initialized private component.' }
Write-Host 'Experience version test passed.'
