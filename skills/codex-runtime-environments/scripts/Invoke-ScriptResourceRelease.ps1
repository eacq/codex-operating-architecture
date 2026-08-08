[CmdletBinding()]
param(
    [string]$RepositoryRoot = 'F:\codex',
    [switch]$Apply,
    [string]$TmpRoot,
    [int]$TmpRetentionHours = 24,
    [string]$WorkspaceRoot,
    [int]$WorkspaceRetentionDays = 30,
    [switch]$SkipProcesses,
    [string]$ProcessName = 'node_repl',
    [string]$ScopePattern = 'OpenAI\Codex\runtimes\cua_node',
    [object[]]$ProcessTable
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath $RepositoryRoot).Path
if (-not $TmpRoot) { $TmpRoot = Join-Path $root '.runtime\tmp' }
if (-not $WorkspaceRoot) { $WorkspaceRoot = Join-Path $root '.runtime\work' }
$tmpFull = [IO.Path]::GetFullPath($TmpRoot)
$workFull = [IO.Path]::GetFullPath($WorkspaceRoot)

$releaseScript = Join-Path $root 'skills\codex-runtime-environments\scripts\Release-UsedTaskProcesses.ps1'
$processResult = $null
if (-not $SkipProcesses -and (Test-Path -LiteralPath $releaseScript -PathType Leaf)) {
    $releaseArgs = @{
        RepositoryRoot = $root
        ProcessName = $ProcessName
        ScopePattern = $ScopePattern
    }
    if ($ProcessTable) { $releaseArgs.ProcessTable = $ProcessTable }
    if ($Apply) { $releaseArgs.Apply = $true }
    $processResult = & $releaseScript @releaseArgs | ConvertFrom-Json
}

$now = [DateTime]::UtcNow
$tmpCutoff = $now.AddHours(-[double]$TmpRetentionHours)
$workCutoff = $now.AddDays(-[double]$WorkspaceRetentionDays)
$tmpCandidates = @()
$tmpCleaned = @()
$tmpBytes = 0
if (Test-Path -LiteralPath $tmpFull -PathType Container) {
    foreach ($item in Get-ChildItem -LiteralPath $tmpFull -Force) {
        if ($item.LastWriteTime.ToUniversalTime() -lt $tmpCutoff) {
            $tmpBytes += [long]$item.Length
            $tmpCandidates += [pscustomobject]@{ name = $item.Name; kind = if ($item.PSIsContainer) { 'directory' } else { 'file' }; last_write = $item.LastWriteTime.ToString('o'); bytes = $item.Length }
            if ($Apply) {
                if ($item.PSIsContainer) { Remove-Item -LiteralPath $item.FullName -Recurse -Force }
                else { Remove-Item -LiteralPath $item.FullName -Force }
                $tmpCleaned += $item.Name
            }
        }
    }
}

$workspaceCandidates = @()
if (Test-Path -LiteralPath $workFull -PathType Container) {
    foreach ($dir in Get-ChildItem -LiteralPath $workFull -Directory -Force) {
        if ($dir.LastWriteTime.ToUniversalTime() -lt $workCutoff) {
            $workspaceCandidates += [pscustomobject]@{ name = $dir.Name; last_write = $dir.LastWriteTime.ToString('o') }
        }
    }
}

[pscustomobject]@{
    schema_version = 1
    result = if ($Apply) { 'released' } else { 'dry-run' }
    repository_root = $root
    tmp_root = $tmpFull
    tmp_retention_hours = $TmpRetentionHours
    workspace_root = $workFull
    workspace_retention_days = $WorkspaceRetentionDays
    processes = $processResult
    tmp_candidate_count = @($tmpCandidates).Count
    tmp_candidates = $tmpCandidates
    tmp_cleaned = $tmpCleaned
    workspace_stale_candidate_count = @($workspaceCandidates).Count
    workspace_stale_candidates = $workspaceCandidates
    estimated_bytes = $tmpBytes
    estimated_mb = [math]::Round($tmpBytes / 1MB, 2)
    note = 'Workspace candidates are advisory only and are never deleted automatically; processes and disposable tmp files are released only with -Apply.'
} | ConvertTo-Json -Depth 8
