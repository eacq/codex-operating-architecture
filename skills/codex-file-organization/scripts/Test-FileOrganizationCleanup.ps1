$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
$fixture = & (Join-Path $root 'scripts\Resolve-CodexRunRoot.ps1') -ArchitectureRoot $root -Kind tmp -ChildPath ('codex-cleanup-test-' + [guid]::NewGuid().ToString('N')) -Create
$backup = $fixture + '-backup'
try {
    [IO.Directory]::CreateDirectory((Join-Path $fixture '.codex\project')) | Out-Null
    [IO.Directory]::CreateDirectory((Join-Path $fixture 'cache\__pycache__')) | Out-Null
    [IO.Directory]::CreateDirectory((Join-Path $fixture 'empty-folder')) | Out-Null
    Set-Content -LiteralPath (Join-Path $fixture 'tracked.tmp') -Value 'keep' -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $fixture 'remove.tmp') -Value 'remove' -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $fixture 'cache\__pycache__\module.pyc') -Value 'cache' -Encoding UTF8
    & git -C $fixture init --quiet
    & git -C $fixture add -- tracked.tmp
    $trackedPath = Join-Path $fixture '.codex\project\source-tracked.txt'
    & git -C $fixture ls-files | Set-Content -LiteralPath $trackedPath -Encoding UTF8
    $result = & (Join-Path $PSScriptRoot 'Remove-UnnecessaryOrganizationArtifacts.ps1') -ProjectRoot $fixture -BackupRoot $backup -TrackedPathsFile $trackedPath -Apply | ConvertFrom-Json
    if (-not (Test-Path -LiteralPath (Join-Path $fixture 'tracked.tmp'))) { throw 'Cleanup removed a tracked disposable-looking file.' }
    if (Test-Path -LiteralPath (Join-Path $fixture 'remove.tmp')) { throw 'Cleanup retained an untracked disposable file.' }
    if (Test-Path -LiteralPath (Join-Path $fixture 'cache\__pycache__\module.pyc')) { throw 'Cleanup retained an untracked cache file.' }
    if (Test-Path -LiteralPath (Join-Path $fixture 'empty-folder')) { throw 'Cleanup retained an empty directory.' }
    if ($result.files_deleted -ne 2 -or -not $result.quarantine_created -or -not (Test-Path -LiteralPath $result.detail_manifest)) { throw 'Cleanup result or quarantine evidence is incomplete.' }
    if ($result.candidate_scan -ne 'git-untracked-and-ignored') { throw 'Cleanup did not use Git-backed untracked/ignored candidate discovery.' }
    Set-Content -LiteralPath (Join-Path $fixture 'remove-again.tmp') -Value 'remove' -Encoding UTF8
    $lightweight = & (Join-Path $PSScriptRoot 'Remove-UnnecessaryOrganizationArtifacts.ps1') -ProjectRoot $fixture -BackupRoot $backup -TrackedPathsFile $trackedPath -LightweightDirectoryCleanup -Apply | ConvertFrom-Json
    if ($lightweight.empty_directory_scan -ne 'candidate-parents-only' -or (Test-Path -LiteralPath (Join-Path $fixture 'remove-again.tmp'))) { throw 'Lightweight cleanup did not use candidate-parent directory cleanup.' }
    Write-Host 'File-organization cleanup isolation test passed.'
} finally {
    if (Test-Path -LiteralPath $fixture) { Remove-Item -LiteralPath $fixture -Recurse -Force }
    if (Test-Path -LiteralPath $backup) { Remove-Item -LiteralPath $backup -Recurse -Force }
}
