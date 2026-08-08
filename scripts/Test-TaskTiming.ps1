[CmdletBinding()]
param([string]$RepositoryRoot = 'F:\codex')

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath $RepositoryRoot).Path
$recorder = Join-Path $root 'scripts\Record-CodexTaskTiming.ps1'
if (-not (Test-Path -LiteralPath $recorder -PathType Leaf)) { throw 'Task timing recorder is missing.' }
$start = [datetime]::Parse('2026-08-06T06:48:08Z').ToUniversalTime()
$end = [datetime]::Parse('2026-08-06T07:22:07Z').ToUniversalTime()
$json = & $recorder -RepositoryRoot $root -TaskStartedAt $start -TaskCompletedAt $end -HostWorkedSeconds 2025 -HostWorkedDisplay 'Worked for 33 minutes 45 seconds' -TaskId 'timing-fixture' -Evidence 'codex-thread-metadata','user-supplied-host-display'
$result = $json | ConvertFrom-Json
if ($result.task_wall_clock_seconds -ne 2039) { throw 'Task lifecycle wall clock must use host task start/end.' }
if ($result.host_reported_worked_seconds -ne 2025) { throw 'Host Worked for value was not retained.' }
if ($result.user_visible_complete_seconds -ne 2025) { throw 'User-visible complete time must prefer host Worked for.' }
if ($result.host_vs_lifecycle_delta_seconds -ne 14) { throw 'Host/lifecycle timing delta was not exposed.' }
$noHostJson = & $recorder -RepositoryRoot $root -TaskStartedAt $start -TaskCompletedAt $end -TaskId 'timing-no-host-fixture'
$noHost = $noHostJson | ConvertFrom-Json
if ($noHost.user_visible_complete_seconds -ne 2039) { throw 'Lifecycle time must be the fallback only when host Worked for is missing.' }
$controller = Get-Content -Raw -Encoding UTF8 (Join-Path $root 'scripts\Invoke-CodexVerification.ps1')
if ($controller -notmatch 'operation_wall_clock_seconds') { throw 'Verification controller must distinguish operation time.' }
if ($controller -notmatch 'task_time_status') { throw 'Verification controller must label missing task start evidence.' }
Write-Host 'Task timing contract test passed.'
