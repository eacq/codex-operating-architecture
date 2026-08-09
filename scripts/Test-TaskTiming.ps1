[CmdletBinding()]
param([string]$RepositoryRoot = 'F:\codex')

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath $RepositoryRoot).Path
$recorder = Join-Path $root 'scripts\Record-CodexTaskTiming.ps1'
if (-not (Test-Path -LiteralPath $recorder -PathType Leaf)) { throw 'Task timing recorder is missing.' }
$start = [datetime]::Parse('2026-08-06T06:48:08Z').ToUniversalTime()
$end = [datetime]::Parse('2026-08-06T07:22:07Z').ToUniversalTime()
$client = '{"source":"codex_app__read_thread","thread_id":"thread-fixture","turns":[{"id":"turn-a","status":"completed","startedAt":1786042088,"completedAt":1786044110,"durationMs":2025000,"in_scope":true}]}'
$json = & $recorder -RepositoryRoot $root -TaskStartedAt $start -TaskCompletedAt $end -HostWorkedSeconds 2025 -HostWorkedDisplay 'Worked for 33 minutes 45 seconds' -ClientTimingJson $client -ExternalElapsedSeconds 2022.4 -ScreenshotCaptureSeconds 1.2 -TaskId 'timing-fixture' -Evidence 'codex-thread-metadata','user-supplied-host-display','external-stopwatch','screenshot-stopwatch'
$result = $json | ConvertFrom-Json
if ($result.task_wall_clock_seconds -ne 2039) { throw 'Task lifecycle wall clock must use host task start/end.' }
if ($result.host_reported_worked_seconds -ne 2025) { throw 'Host Worked for value was not retained.' }
if ($result.user_visible_complete_seconds -ne 2022) { throw 'User-visible complete time must prefer the Codex client interval union.' }
if ($result.customer_visible_time_source -ne 'codex-client-task-wall-clock') { throw 'Codex client timing must be the primary customer-visible source.' }
if ($result.client_timing.client_turn_duration_sum_seconds -ne 2025) { throw 'Client durationMs was not retained as the active-work view.' }
if ($result.client_timing.client_task_wall_clock_seconds -ne 2022) { throw 'Client task wall clock must use interval union.' }
if ($result.cross_validation_status -ne 'consistent') { throw 'Client and external timing cross-validation failed.' }
if ($result.host_vs_lifecycle_delta_seconds -ne 14) { throw 'Host/lifecycle timing delta was not exposed.' }
$noHostJson = & $recorder -RepositoryRoot $root -TaskStartedAt $start -TaskCompletedAt $end -TaskId 'timing-no-host-fixture'
$noHost = $noHostJson | ConvertFrom-Json
if ($noHost.user_visible_complete_seconds -ne 2039) { throw 'Lifecycle time must be the fallback only when host Worked for is missing.' }
$parallelClient = '{"source":"codex_app__read_thread","thread_id":"parallel-fixture","turns":[{"id":"turn-a","status":"completed","startedAt":1786042088,"completedAt":1786042098,"durationMs":10000,"in_scope":true},{"id":"turn-b","status":"completed","startedAt":1786042093,"completedAt":1786042103,"durationMs":10000,"in_scope":true}]}'
$parallelJson = & $recorder -RepositoryRoot $root -TaskStartedAt $start -TaskCompletedAt $end -ClientTimingJson $parallelClient -TaskId 'timing-parallel-fixture'
$parallel = $parallelJson | ConvertFrom-Json
if ($parallel.client_timing.client_turn_duration_sum_seconds -ne 20) { throw 'Parallel client active-work duration must retain the durationMs sum.' }
if ($parallel.client_timing.client_task_wall_clock_seconds -ne 15) { throw 'Parallel client customer time must use the interval union, not the duration sum.' }
if ($parallel.user_visible_complete_seconds -ne 15) { throw 'Parallel client customer-visible time must use the interval union.' }
$unscopedClient = '{"source":"codex_app__read_thread","thread_id":"unscoped-fixture","turns":[{"id":"turn-old","status":"completed","startedAt":1786042088,"completedAt":1786042098,"durationMs":10000}]}'
$unscopedJson = & $recorder -RepositoryRoot $root -TaskStartedAt $start -TaskCompletedAt $end -ClientTimingJson $unscopedClient -TaskId 'timing-unscoped-fixture'
$unscoped = $unscopedJson | ConvertFrom-Json
if ($unscoped.client_timing.status -ne 'scope-required') { throw 'Unscoped read_thread snapshots must be rejected for customer timing.' }
if ($unscoped.customer_visible_time_source -ne 'task-lifecycle-fallback') { throw 'Unscoped client snapshots must use an explicit lifecycle fallback.' }
$controller = Get-Content -Raw -Encoding UTF8 (Join-Path $root 'scripts\Invoke-CodexVerification.ps1')
if ($controller -notmatch 'operation_wall_clock_seconds') { throw 'Verification controller must distinguish operation time.' }
if ($controller -notmatch 'task_time_status') { throw 'Verification controller must label missing task start evidence.' }
if ($controller -notmatch 'ClientTimingJson' -or $controller -notmatch 'customer_visible_complete_seconds') { throw 'Verification controller must accept and persist Codex client timing.' }
Write-Host 'Task timing contract test passed.'
