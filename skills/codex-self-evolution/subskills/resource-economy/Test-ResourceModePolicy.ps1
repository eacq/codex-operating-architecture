[CmdletBinding()]
param(
    [string]$RepositoryRoot = 'F:\codex'
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath $RepositoryRoot).Path
$policyPath = Join-Path $root 'config\loopx-resource-policy.json'
$policy = Get-Content -LiteralPath $policyPath -Raw -Encoding UTF8 | ConvertFrom-Json
$modes = @('economy', 'balanced', 'full')
$required = @($policy.required_function_set)
if ($required.Count -lt 1) { throw 'The resource policy has no required function set.' }
if ($policy.speed_quality_contract.primary_metric -ne 'customer_visible_complete_seconds') { throw 'The resource policy primary customer-visible metric is missing.' }
foreach ($mode in $modes) {
    $level = $policy.levels.PSObject.Properties[$mode].Value
    $version = $policy.execution_versions.PSObject.Properties[$mode].Value
    if ($null -eq $level -or $null -eq $version) { throw "Resource mode '$mode' is missing a level or execution-version contract." }
    if ([string]::IsNullOrWhiteSpace([string]$version.quality_role)) { throw "Resource mode '$mode' has no quality role." }
    if (@($version.speed_levers).Count -lt 1) { throw "Resource mode '$mode' has no speed levers." }
}
$floor = @($policy.speed_quality_contract.quality_floor)
foreach ($item in @('required_function_set', 'owner_route', 'authority_check', 'privacy_redaction', 'evidence_boundary', 'rollback_boundary', 'required_validation', 'typed_exit')) {
    if ($floor -notcontains $item) { throw "Quality floor is missing '$item'." }
}
if ($policy.speed_quality_contract.speed_never_buys.Count -lt 1) { throw 'Speed non-regression blacklist is missing.' }
foreach ($metric in @('task_wall_clock_time', 'host_reported_worked_time', 'agent_session_wall_clock_time', 'child_agent_wall_clock_time', 'controller_wall_clock_time', 'tool_wait_time', 'recovery_retry_time', 'validation_writeback_time')) {
    if (@($policy.speed_quality_contract.additional_metrics) -notcontains $metric) { throw "Additional timing metric '$metric' is missing." }
}
foreach ($metric in @('customer_visible_complete_seconds', 'codex_client_task_wall_clock_seconds', 'external_monotonic_seconds', 'screenshot_capture_seconds')) {
    if (@($policy.speed_quality_contract.additional_metrics) -notcontains $metric) { throw "Additional customer timing metric '$metric' is missing." }
}
foreach ($dimension in @('requested_mode', 'effective_mode', 'step_timings', 'task_started_at', 'task_completed_at', 'task_wall_clock_seconds', 'task_time_status', 'host_reported_worked_seconds', 'agent_session_started_at', 'agent_session_wall_clock_seconds', 'controller_wall_clock_seconds', 'step_time_sum_seconds', 'unaccounted_time_seconds')) {
    if (@($policy.speed_quality_contract.measurement_contract.required_dimensions) -notcontains $dimension) { throw "Timing contract dimension '$dimension' is missing." }
}
foreach ($dimension in @('customer_visible_complete_seconds', 'customer_visible_time_source', 'client_timing', 'client_task_wall_clock_seconds', 'client_turn_duration_sum_seconds', 'external_monotonic_seconds', 'screenshot_capture_seconds', 'cross_validation_status')) {
    if (@($policy.speed_quality_contract.measurement_contract.required_dimensions) -notcontains $dimension) { throw "Timing contract customer dimension '$dimension' is missing." }
}
if (-not $policy.verification_profiles.auto -or [string]::IsNullOrWhiteSpace([string]$policy.verification_profiles.auto.high_risk_fallback)) { throw 'Automatic verification profile is missing its high-risk fallback.' }
if (-not $policy.verification_profiles.balanced -or [string]::IsNullOrWhiteSpace([string]$policy.verification_profiles.balanced.completion_boundary)) { throw 'Balanced preliminary verification profile is missing its closeout boundary.' }
if (@($policy.timing_optimization_contract.layers).Count -lt 6) { throw 'Timing optimization contract must cover all metric layers.' }
foreach ($gate in @('required_function_set','evidence_boundary','authority_scope','privacy_redaction','rollback_ready','typed_exit','equivalent_validation')) {
    if ($gate -notin @($policy.timing_optimization_contract.no_regression_gates)) { throw "Timing optimization contract is missing no-regression gate '$gate'." }
}
foreach ($goalLayer in @('user_outcome', 'agent_coordination', 'controller', 'script', 'validation_and_writeback')) {
    $metrics = $policy.speed_quality_contract.measurement_contract.metric_selection_by_goal.PSObject.Properties[$goalLayer].Value
    if (@($metrics).Count -lt 1) { throw "Metric selection is missing for goal layer '$goalLayer'." }
}
Write-Output 'Resource mode policy test passed.'
