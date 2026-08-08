[CmdletBinding()]
param([string]$RepositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath $RepositoryRoot).Path
$scriptPath = Join-Path $root 'skills\codex-runtime-environments\scripts\Invoke-DataLifecycleCleanup.ps1'
if (-not (Test-Path -LiteralPath $scriptPath -PathType Leaf)) {
    throw "Missing data lifecycle cleanup controller: $scriptPath"
}

$fixtureRoot = Join-Path $root ('.runtime\tmp\dlc-test-' + [guid]::NewGuid().ToString('N'))
$repo = Join-Path $fixtureRoot 'repo'
$project = Join-Path $repo '.codex\project'
$logsRoot = Join-Path $project 'iteration-runs'
$localBackup = Join-Path $project 'fixture-local-codex-backups\iterations'
$siblingBackup = Join-Path $fixtureRoot ('.repo-codex-backups\iterations')
$tmpRoot = Join-Path $repo '.runtime\tmp'
$protectedRoot = Join-Path $project 'agent-sessions'
New-Item -ItemType Directory -Force -Path $logsRoot, $localBackup, $siblingBackup, $tmpRoot, $protectedRoot | Out-Null

foreach ($log in @('run-000001.log', 'run-000002.log', 'run-000003.log')) {
    [IO.File]::WriteAllText((Join-Path $logsRoot $log), 'x', [Text.UTF8Encoding]::new($false))
}
foreach ($stamp in @('20260808-000001', '20260808-000002', '20260808-000003')) {
    New-Item -ItemType Directory -Force -Path (Join-Path $localBackup $stamp) | Out-Null
    New-Item -ItemType Directory -Force -Path (Join-Path $siblingBackup $stamp) | Out-Null
    [IO.File]::WriteAllText((Join-Path (Join-Path $localBackup $stamp) 'marker.json'), 'x', [Text.UTF8Encoding]::new($false))
    [IO.File]::WriteAllText((Join-Path (Join-Path $siblingBackup $stamp) 'marker.json'), 'x', [Text.UTF8Encoding]::new($false))
}
[IO.File]::WriteAllText((Join-Path $tmpRoot 'old.log'), 'x', [Text.UTF8Encoding]::new($false))
[IO.File]::WriteAllText((Join-Path $tmpRoot 'fresh.log'), 'x', [Text.UTF8Encoding]::new($false))
[IO.File]::WriteAllText((Join-Path $protectedRoot 'session-a.json'), 'x', [Text.UTF8Encoding]::new($false))
[IO.File]::SetLastWriteTimeUtc((Join-Path $tmpRoot 'old.log'), [DateTime]::UtcNow.AddHours(-2))
[IO.File]::SetLastWriteTimeUtc((Join-Path $tmpRoot 'fresh.log'), [DateTime]::UtcNow.AddMinutes(-1))

try {
    $dry = & $scriptPath -RepositoryRoot $repo -ReleaseScript (Join-Path $root 'skills\codex-runtime-environments\scripts\Invoke-ScriptResourceRelease.ps1') -TmpRetentionHours 1 -BackupSnapshotKeepLatest 2 -IterationLogKeepLatest 2 | ConvertFrom-Json
    if ($dry.result -ne 'dry-run') { throw 'Default must be a dry-run.' }
    if ($dry.backup_snapshot_candidate_count -ne 2) { throw "Dry-run must list 2 prunable backup snapshots, got $($dry.backup_snapshot_candidate_count)." }
    if ($dry.iteration_log_candidate_count -ne 1) { throw "Dry-run must list 1 prunable iteration log, got $($dry.iteration_log_candidate_count)." }
    if ($dry.tmp.tmp_candidate_count -ne 1) { throw 'Dry-run must list the old tmp file.' }
    if (-not (Test-Path -LiteralPath (Join-Path $logsRoot 'run-000001.log'))) { throw 'Dry-run must not prune logs.' }
    if (-not (Test-Path -LiteralPath (Join-Path $protectedRoot 'session-a.json'))) { throw 'Protected session record must exist before Apply.' }

    $applied = & $scriptPath -RepositoryRoot $repo -ReleaseScript (Join-Path $root 'skills\codex-runtime-environments\scripts\Invoke-ScriptResourceRelease.ps1') -TmpRetentionHours 1 -BackupSnapshotKeepLatest 2 -IterationLogKeepLatest 2 -Apply | ConvertFrom-Json
    if ($applied.result -ne 'released') { throw 'Apply must report released.' }
    if (Test-Path -LiteralPath (Join-Path $logsRoot 'run-000001.log')) { throw 'Apply must prune the old log.' }
    if (-not (Test-Path -LiteralPath (Join-Path $logsRoot 'run-000002.log'))) { throw 'Apply must keep the newest logs.' }
    if (Test-Path -LiteralPath (Join-Path $localBackup '20260808-000001')) { throw 'Apply must prune the oldest local backup snapshot.' }
    if (Test-Path -LiteralPath (Join-Path $siblingBackup '20260808-000001')) { throw 'Apply must prune the oldest sibling backup snapshot.' }
    if (-not (Test-Path -LiteralPath (Join-Path $localBackup '20260808-000003'))) { throw 'Apply must keep the newest backup snapshots.' }
    if (Test-Path -LiteralPath (Join-Path $tmpRoot 'old.log')) { throw 'Apply must delete the old tmp file.' }
    if (-not (Test-Path -LiteralPath (Join-Path $tmpRoot 'fresh.log'))) { throw 'Apply must preserve the fresh tmp file.' }
    if (-not (Test-Path -LiteralPath (Join-Path $protectedRoot 'session-a.json'))) { throw 'Apply must preserve protected session records.' }
    if ('agent-sessions' -notin $applied.protected_preserved) { throw 'Protected roots must be reported as preserved.' }
} finally {
    if (Test-Path -LiteralPath $fixtureRoot) { Remove-Item -LiteralPath $fixtureRoot -Recurse -Force }
}

[pscustomobject]@{
    status = 'passed'
    model = 'codex-runtime-environments-data-lifecycle-cleanup'
    script = 'skills/codex-runtime-environments/scripts/Invoke-DataLifecycleCleanup.ps1'
    policy = 'config/data-lifecycle-policy.json'
    dry_run_default = $true
    tmp_retention_enforced = $true
    backup_snapshot_prune_enforced = $true
    iteration_log_prune_enforced = $true
    protected_preserved = $true
} | ConvertTo-Json -Depth 4
