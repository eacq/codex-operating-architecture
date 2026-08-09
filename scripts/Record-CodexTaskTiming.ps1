[CmdletBinding()]
param(
    [string]$RepositoryRoot = 'F:\codex',
    [Parameter(Mandatory = $true)][datetime]$TaskStartedAt,
    [Parameter(Mandatory = $true)][datetime]$TaskCompletedAt,
    [Nullable[double]]$HostWorkedSeconds,
    [string]$HostWorkedDisplay,
    [string]$ClientTimingJson,
    [Nullable[double]]$ExternalElapsedSeconds,
    [Nullable[double]]$ScreenshotCaptureSeconds,
    [string]$TaskId = ('task-' + [guid]::NewGuid().ToString('N')),
    [string]$Source = 'codex-desktop-thread-metadata',
    [string[]]$Evidence = @(),
    [switch]$Apply
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath $RepositoryRoot).Path
. (Join-Path $root 'scripts\CodexTimingFunctions.ps1')
$start = $TaskStartedAt.ToUniversalTime()
$end = $TaskCompletedAt.ToUniversalTime()
if ($end -lt $start) { throw 'TaskCompletedAt cannot be earlier than TaskStartedAt.' }
$lifecycleSeconds = [math]::Round(($end - $start).TotalSeconds, 3)
$workedSeconds = if ($null -ne $HostWorkedSeconds) { [math]::Round([double]$HostWorkedSeconds, 3) } else { $null }
$delta = if ($null -ne $workedSeconds) { [math]::Round($lifecycleSeconds - $workedSeconds, 3) } else { $null }
$assessment = New-CodexTimingAssessment -ClientTimingJson $ClientTimingJson -LifecycleSeconds $lifecycleSeconds -HostWorkedSeconds $workedSeconds -ExternalElapsedSeconds $ExternalElapsedSeconds -ScreenshotCaptureSeconds $ScreenshotCaptureSeconds
$record = [ordered]@{
    schema_version = 2
    task_id = $TaskId
    source = $Source
    task_started_at = $start.ToString('o')
    task_completed_at = $end.ToString('o')
    task_wall_clock_seconds = $lifecycleSeconds
    host_reported_worked_seconds = $workedSeconds
    host_reported_worked_display = if ($HostWorkedDisplay) { $HostWorkedDisplay } else { $null }
    user_visible_complete_seconds = $assessment.customer_visible_complete_seconds
    customer_visible_time_source = $assessment.customer_visible_time_source
    host_vs_lifecycle_delta_seconds = $delta
    host_reported_worked_status = if ($null -ne $workedSeconds) { 'host-reported' } else { 'not-provided' }
    client_timing = $assessment.client
    external_monotonic_seconds = $assessment.external_monotonic_seconds
    screenshot_capture_seconds = $assessment.screenshot_capture_seconds
    screenshot_timing_status = $assessment.screenshot_timing_status
    cross_validation = $assessment.cross_validation
    cross_validation_status = $assessment.cross_validation_status
    timing_status = if ($assessment.customer_visible_time_source -eq 'codex-client-task-wall-clock' -and $assessment.cross_validation_status -ne 'needs-review') { 'complete-with-codex-client-and-cross-validation' } elseif ($assessment.customer_visible_time_source -eq 'codex-client-task-wall-clock') { 'complete-with-codex-client-needs-review' } elseif ($null -ne $workedSeconds) { 'complete-with-host-and-lifecycle-views' } else { 'complete-lifecycle-host-worked-missing' }
    evidence = @($Evidence)
    note = 'Codex client turn intervals are primary when supplied. Client task wall clock is the union of intervals, while duration sum remains a separate active-work view so parallel turns are not double-counted. External Stopwatch and screenshot timing are independent cross-checks; lifecycle timing is fallback only.'
}
$json = $record | ConvertTo-Json -Depth 8
if ($Apply) {
    $path = Join-Path $root '.codex\project\task-timing-last.json'
    [IO.File]::WriteAllText($path, $json, [Text.UTF8Encoding]::new($false))
    $record['record'] = '.codex/project/task-timing-last.json'
}
$record | ConvertTo-Json -Depth 8
