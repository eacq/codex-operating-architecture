[CmdletBinding()]
param(
    [string]$RepositoryRoot = 'F:\codex',
    [Parameter(Mandatory = $true)][datetime]$TaskStartedAt,
    [Parameter(Mandatory = $true)][datetime]$TaskCompletedAt,
    [Nullable[double]]$HostWorkedSeconds,
    [string]$HostWorkedDisplay,
    [string]$TaskId = ('task-' + [guid]::NewGuid().ToString('N')),
    [string]$Source = 'codex-desktop-thread-metadata',
    [string[]]$Evidence = @(),
    [switch]$Apply
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath $RepositoryRoot).Path
$start = $TaskStartedAt.ToUniversalTime()
$end = $TaskCompletedAt.ToUniversalTime()
if ($end -lt $start) { throw 'TaskCompletedAt cannot be earlier than TaskStartedAt.' }
$lifecycleSeconds = [math]::Round(($end - $start).TotalSeconds, 3)
$workedSeconds = if ($null -ne $HostWorkedSeconds) { [math]::Round([double]$HostWorkedSeconds, 3) } else { $null }
$delta = if ($null -ne $workedSeconds) { [math]::Round($lifecycleSeconds - $workedSeconds, 3) } else { $null }
$record = [ordered]@{
    schema_version = 1
    task_id = $TaskId
    source = $Source
    task_started_at = $start.ToString('o')
    task_completed_at = $end.ToString('o')
    task_wall_clock_seconds = $lifecycleSeconds
    host_reported_worked_seconds = $workedSeconds
    host_reported_worked_display = if ($HostWorkedDisplay) { $HostWorkedDisplay } else { $null }
    user_visible_complete_seconds = if ($null -ne $workedSeconds) { $workedSeconds } else { $lifecycleSeconds }
    host_vs_lifecycle_delta_seconds = $delta
    timing_status = if ($null -ne $workedSeconds) { 'complete-with-host-and-lifecycle-views' } else { 'complete-lifecycle-host-worked-missing' }
    evidence = @($Evidence)
    note = 'Task wall clock spans task acceptance to final verified result; host Worked for is retained as a separate host view and is never replaced by an operation timer.'
}
$json = $record | ConvertTo-Json -Depth 8
if ($Apply) {
    $path = Join-Path $root '.codex\project\task-timing-last.json'
    [IO.File]::WriteAllText($path, $json, [Text.UTF8Encoding]::new($false))
    $record['record'] = '.codex/project/task-timing-last.json'
}
$record | ConvertTo-Json -Depth 8
