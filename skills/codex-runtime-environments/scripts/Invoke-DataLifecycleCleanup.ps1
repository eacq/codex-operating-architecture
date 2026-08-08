[CmdletBinding()]
param(
    [string]$RepositoryRoot = 'F:\codex',
    [switch]$Apply,
    [int]$TmpRetentionHours = 24,
    [int]$BackupSnapshotKeepLatest = 2,
    [int]$IterationLogKeepLatest = 20,
    [int]$WorkspaceRetentionDays = 30,
    [string]$ReleaseScript
)

$ErrorActionPreference = 'Stop'
$root = [IO.Path]::GetFullPath((Resolve-Path -LiteralPath $RepositoryRoot).Path).TrimEnd('\')
$projectPath = Join-Path $root '.codex\project'
$siblingBackupRoot = Join-Path (Split-Path -Parent $root) ('.' + (Split-Path -Leaf $root) + '-codex-backups')

if (-not $ReleaseScript) {
    $ReleaseScript = Join-Path $root 'skills\codex-runtime-environments\scripts\Invoke-ScriptResourceRelease.ps1'
}
$tmpResult = $null
if (Test-Path -LiteralPath $ReleaseScript -PathType Leaf) {
    $releaseArgs = @{
        RepositoryRoot = $root
        TmpRetentionHours = $TmpRetentionHours
        WorkspaceRetentionDays = $WorkspaceRetentionDays
        SkipProcesses = $true
    }
    if ($Apply) { $releaseArgs.Apply = $true }
    $tmpResult = & $ReleaseScript @releaseArgs | ConvertFrom-Json
}

$backupCandidates = New-Object System.Collections.Generic.List[object]
$backupPruned = New-Object System.Collections.Generic.List[string]
function Add-BackupIterations {
    param([string]$BackupRoot)
    $iterationsRoot = Join-Path $BackupRoot 'iterations'
    if (-not (Test-Path -LiteralPath $iterationsRoot -PathType Container)) { return }
    $stamps = @(Get-ChildItem -LiteralPath $iterationsRoot -Directory -Force | Sort-Object Name -Descending)
    if ($stamps.Count -gt $BackupSnapshotKeepLatest) {
        foreach ($old in @($stamps | Select-Object -Skip $BackupSnapshotKeepLatest)) {
            $backupCandidates.Add([pscustomobject]@{ path = $old.FullName; last_write = $old.LastWriteTime.ToString('o') }) | Out-Null
            if ($Apply) {
                Remove-Item -LiteralPath $old.FullName -Recurse -Force
                $backupPruned.Add($old.FullName) | Out-Null
            }
        }
    }
}
Add-BackupIterations -BackupRoot $siblingBackupRoot
if (Test-Path -LiteralPath $projectPath -PathType Container) {
    foreach ($backupDir in @(Get-ChildItem -LiteralPath $projectPath -Directory -Force | Where-Object { $_.Name -like '*-codex-backups' })) {
        Add-BackupIterations -BackupRoot $backupDir.FullName
    }
}

$logCandidates = New-Object System.Collections.Generic.List[object]
$logsPruned = New-Object System.Collections.Generic.List[string]
$logsRoot = Join-Path $projectPath 'iteration-runs'
if (Test-Path -LiteralPath $logsRoot -PathType Container) {
    $logs = @(Get-ChildItem -LiteralPath $logsRoot -File | Sort-Object Name -Descending)
    if ($logs.Count -gt $IterationLogKeepLatest) {
        foreach ($old in @($logs | Select-Object -Skip $IterationLogKeepLatest)) {
            $logCandidates.Add([pscustomobject]@{ name = $old.Name; last_write = $old.LastWriteTime.ToString('o') }) | Out-Null
            if ($Apply) {
                Remove-Item -LiteralPath $old.FullName -Force
                $logsPruned.Add($old.Name) | Out-Null
            }
        }
    }
}

$protectedRoots = @('agent-sessions','agent-memory','timing-evidence','timing-analysis','candidate-archive','candidate-reports','release-backups','structural-optimization-records','host-recovery')
$protectedPresent = @()
foreach ($name in $protectedRoots) {
    if (Test-Path -LiteralPath (Join-Path $projectPath $name) -PathType Container) { $protectedPresent += $name }
}

$backupCandidateCount = $backupCandidates.Count
$backupPrunedCount = $backupPruned.Count
$logCandidateCount = $logCandidates.Count
$logPrunedCount = $logsPruned.Count

[pscustomobject]@{
    schema_version = 1
    result = if ($Apply) { 'released' } else { 'dry-run' }
    policy = 'config/data-lifecycle-policy.json'
    repository_root = $root
    tmp = $tmpResult
    backup_snapshot_candidate_count = $backupCandidateCount
    backup_snapshot_candidates = @($backupCandidates.ToArray())
    backup_snapshot_pruned = @($backupPruned.ToArray())
    iteration_log_candidate_count = $logCandidateCount
    iteration_log_candidates = @($logCandidates.ToArray())
    iteration_log_pruned = @($logsPruned.ToArray())
    workspace_stale_candidate_count = if ($tmpResult) { $tmpResult.workspace_stale_candidate_count } else { 0 }
    protected_preserved = $protectedPresent
    note = 'Durable sessions, memory, timing evidence, archives, reports, proofs, gates, envelopes, and release backups are never auto-deleted; stale workspaces stay advisory.'
} | ConvertTo-Json -Depth 8
