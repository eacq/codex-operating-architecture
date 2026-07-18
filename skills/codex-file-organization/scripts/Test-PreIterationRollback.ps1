$ErrorActionPreference = 'Stop'
$fixture = Join-Path ([IO.Path]::GetTempPath()) ('codex-rollback-test-' + [guid]::NewGuid().ToString('N'))
$backup = $fixture + '-backup'
try {
    [IO.Directory]::CreateDirectory((Join-Path $fixture '.codex')) | Out-Null
    [IO.Directory]::CreateDirectory((Join-Path $fixture 'keep-empty')) | Out-Null
    Set-Content -LiteralPath (Join-Path $fixture 'keep.txt') -Value 'before' -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $fixture 'restore.txt') -Value 'restore-me' -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $fixture '.codex\protected.txt') -Value 'protected-before' -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $fixture '.env.local') -Value 'secret-shaped' -Encoding UTF8
    & git -C $fixture init --quiet
    & git -C $fixture add -- keep.txt restore.txt
    $snapshot = & (Join-Path $PSScriptRoot 'New-PreIterationRollbackSnapshot.ps1') -ProjectRoot $fixture -BackupRoot $backup -Apply | ConvertFrom-Json
    Set-Content -LiteralPath (Join-Path $fixture 'keep.txt') -Value 'after' -Encoding UTF8
    Remove-Item -LiteralPath (Join-Path $fixture 'restore.txt') -Force
    Set-Content -LiteralPath (Join-Path $fixture 'new.txt') -Value 'new' -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $fixture '.codex\protected.txt') -Value 'protected-after' -Encoding UTF8
    $restored = & (Join-Path $snapshot.snapshot_root 'restore.ps1') -ProjectRoot $fixture -SnapshotRoot $snapshot.snapshot_root -Apply | ConvertFrom-Json
    if ((Get-Content (Join-Path $fixture 'keep.txt') -Raw).Trim() -ne 'before') { throw 'Rollback did not restore modified content.' }
    if ((Get-Content (Join-Path $fixture 'restore.txt') -Raw).Trim() -ne 'restore-me') { throw 'Rollback did not restore a deleted file.' }
    if (Test-Path -LiteralPath (Join-Path $fixture 'new.txt')) { throw 'Rollback did not remove an iteration-added file.' }
    if ((Get-Content (Join-Path $fixture '.codex\protected.txt') -Raw).Trim() -ne 'protected-after') { throw 'Rollback modified a protected path.' }
    if ((Get-Content (Join-Path $fixture '.env.local') -Raw).Trim() -ne 'secret-shaped') { throw 'Rollback modified a secret-shaped protected file.' }
    if ($snapshot.file_inventory -ne 'git-tracked-untracked-ignored' -or $snapshot.copy_engine -ne 'robocopy-filtered-tree' -or $snapshot.hash_engine -ne 'dotnet-sha256-stream') { throw 'Rollback snapshot did not use the optimized privacy-filtered copy path.' }
    if ($snapshot.snapshot_name_policy -ne 'short-prefix' -or (Split-Path -Leaf $snapshot.snapshot_root) -notmatch '^pre-\d{8}-\d{6}$') { throw 'Rollback snapshot does not use the short path-budget prefix.' }
    if (-not (Test-Path -LiteralPath (Join-Path $fixture 'keep-empty')) -or $restored.result -ne 'rolled-back' -or -not $restored.hash_verified) { throw 'Rollback evidence is incomplete.' }
    Write-Host 'Pre-iteration rollback test passed.'
} finally {
    if (Test-Path -LiteralPath $fixture) { Remove-Item -LiteralPath $fixture -Recurse -Force }
    if (Test-Path -LiteralPath $backup) { Remove-Item -LiteralPath $backup -Recurse -Force }
}
