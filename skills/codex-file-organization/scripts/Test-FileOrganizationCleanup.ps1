$ErrorActionPreference = 'Stop'
$fixture = Join-Path ([IO.Path]::GetTempPath()) ('codex-cleanup-test-' + [guid]::NewGuid().ToString('N'))
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
    Write-Host 'File-organization cleanup isolation test passed.'
} finally {
    if (Test-Path -LiteralPath $fixture) { Remove-Item -LiteralPath $fixture -Recurse -Force }
    if (Test-Path -LiteralPath $backup) { Remove-Item -LiteralPath $backup -Recurse -Force }
}
