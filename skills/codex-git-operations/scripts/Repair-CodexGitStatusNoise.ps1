[CmdletBinding()]
param(
    [string]$RepositoryRoot = (Get-Location).Path,
    [switch]$Apply
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath $RepositoryRoot).Path
$unstaged = @(& git -C $root diff --name-only | Where-Object { $_ })
$staged = @(& git -C $root diff --cached --name-only | Where-Object { $_ })
$untracked = @(& git -C $root ls-files --others --exclude-standard | Where-Object { $_ })
$realChanges = @($unstaged + $staged + $untracked | Sort-Object -Unique)
$statusPaths = @(& (Join-Path $root 'scripts\Get-CodexGitChangedPaths.ps1') -RepositoryRoot $root)

$result = [ordered]@{
    result = if ($realChanges.Count -gt 0) { 'real-changes-retained' } elseif ($statusPaths.Count -gt 0) { 'status-noise-detected' } else { 'clean' }
    real_change_count = $realChanges.Count
    status_noise_count = if ($realChanges.Count -eq 0) { $statusPaths.Count } else { 0 }
    refreshed_paths = @()
}
if (-not $Apply -or $realChanges.Count -gt 0 -or $statusPaths.Count -eq 0) {
    $result | ConvertTo-Json -Depth 4
    return
}

$runRoot = & (Join-Path $root 'scripts\Resolve-CodexRunRoot.ps1') -ArchitectureRoot $root -Kind tmp -Create
$pathspecFile = Join-Path $runRoot ("codex-status-refresh-" + [guid]::NewGuid().ToString('N') + '.txt')
try {
    [IO.File]::WriteAllLines($pathspecFile, $statusPaths, [Text.UTF8Encoding]::new($false))
    & git -C $root add --pathspec-from-file=$pathspecFile
    if ($LASTEXITCODE -ne 0) { throw 'Git status refresh failed.' }
    $unexpectedStaged = @(& git -C $root diff --cached --name-only | Where-Object { $_ })
    if ($unexpectedStaged.Count -gt 0) {
        & git -C $root reset -q HEAD --pathspec-from-file=$pathspecFile
        throw "Status refresh exposed real staged content changes and was reverted: $($unexpectedStaged -join ', ')"
    }
}
finally {
    if (Test-Path -LiteralPath $pathspecFile) { Remove-Item -LiteralPath $pathspecFile -Force }
}

$remaining = @(& (Join-Path $root 'scripts\Get-CodexGitChangedPaths.ps1') -RepositoryRoot $root)
if ($remaining.Count -gt 0) { throw "Git status refresh did not clear status-only entries: $($remaining -join ', ')" }
$result.result = 'status-noise-cleared'
$result.refreshed_paths = @($statusPaths)
$result | ConvertTo-Json -Depth 4
