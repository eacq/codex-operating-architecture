$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
$fixture = & (Join-Path $root 'scripts\Resolve-CodexRunRoot.ps1') -ArchitectureRoot $root -Kind tmp -ChildPath ('git-status-noise-' + [guid]::NewGuid().ToString('N')) -Create

try {
    & git -C $fixture init -q
    & git -C $fixture config user.email 'fixture@example.invalid'
    & git -C $fixture config user.name 'Fixture'
    New-Item -ItemType Directory -Force -Path (Join-Path $fixture 'scripts') | Out-Null
    Copy-Item -LiteralPath (Join-Path $root 'scripts\Get-CodexGitChangedPaths.ps1') -Destination (Join-Path $fixture 'scripts\Get-CodexGitChangedPaths.ps1')
    Copy-Item -LiteralPath (Join-Path $root 'scripts\Resolve-CodexRunRoot.ps1') -Destination (Join-Path $fixture 'scripts\Resolve-CodexRunRoot.ps1')
    'baseline' | Set-Content -LiteralPath (Join-Path $fixture 'tracked.txt') -Encoding UTF8
    & git -C $fixture add .
    & git -C $fixture commit -q -m baseline

    $clean = & (Join-Path $PSScriptRoot 'Repair-CodexGitStatusNoise.ps1') -RepositoryRoot $fixture -Apply | ConvertFrom-Json
    if ($clean.result -ne 'clean') { throw 'A clean repository must remain a no-op.' }
    'changed' | Set-Content -LiteralPath (Join-Path $fixture 'tracked.txt') -Encoding UTF8
    $retained = & (Join-Path $PSScriptRoot 'Repair-CodexGitStatusNoise.ps1') -RepositoryRoot $fixture -Apply | ConvertFrom-Json
    if ($retained.result -ne 'real-changes-retained' -or $retained.real_change_count -ne 1) { throw 'Real content changes must never be hidden as status noise.' }
    if (-not (& git -C $fixture diff --name-only)) { throw 'Status repair removed a real worktree change.' }
    Write-Host 'Git status-noise repair test passed.'
}
finally {
    if (Test-Path -LiteralPath $fixture) { Remove-Item -LiteralPath $fixture -Recurse -Force }
}
