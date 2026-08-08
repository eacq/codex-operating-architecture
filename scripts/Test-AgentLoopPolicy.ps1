[CmdletBinding()]
param(
    [string]$RepositoryRoot = 'F:\codex'
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath $RepositoryRoot).Path
$policyPath = Join-Path $root 'config\agent-loop-policy.json'
if (-not (Test-Path -LiteralPath $policyPath -PathType Leaf)) {
    throw 'Agent loop policy is missing: config\agent-loop-policy.json'
}

$policy = Get-Content -LiteralPath $policyPath -Raw -Encoding UTF8 | ConvertFrom-Json
if ($policy.schema_version -ne 1 -or $policy.status -ne 'active' -or $policy.model -ne 'global-experience-agent-loop-policy') {
    throw 'Agent loop policy header is invalid.'
}
if ($policy.owner -ne 'codex-self-evolution') {
    throw 'Agent loop policy must be owned by codex-self-evolution.'
}
if ($policy.source.repository -ne 'https://github.com/LesterYu0/feynman-build-workshop' -or $policy.source.path -ne 'episodes/06-agent-loop') {
    throw 'Agent loop policy does not cite feynman-build-workshop episode 06.'
}

foreach ($phase in @('plan', 'act', 'observe', 'reflect', 'settle')) {
    if ($phase -notin @($policy.loop_contract.phases)) {
        throw "Agent loop policy is missing phase: $phase"
    }
}
foreach ($event in @('user_goal_received', 'experience_context_loaded', 'agent_resources_selected', 'tool_gate_requested', 'tool_call_finished', 'tool_result_recorded', 'save_point_committed', 'typed_exit_returned')) {
    $mapped = @(
        @($policy.loop_contract.phase_mapping.plan) +
        @($policy.loop_contract.phase_mapping.act) +
        @($policy.loop_contract.phase_mapping.observe) +
        @($policy.loop_contract.phase_mapping.reflect) +
        @($policy.loop_contract.phase_mapping.settle)
    )
    if ($event -notin $mapped) {
        throw "Agent loop phase mapping is missing event: $event"
    }
}
if ($policy.loop_contract.one_step_rule -notmatch 'one registered bounded operation') {
    throw 'Agent loop policy must preserve one-step bounded operation settlement.'
}
if ($policy.loop_contract.owner_rule -notmatch 'owner tool gates') {
    throw 'Agent loop policy must preserve owner tool gates.'
}

if ([int]$policy.control_points.max_iterations.default -ne 10 -or $policy.control_points.max_iterations.hard_rule -notmatch 'while-true') {
    throw 'Agent loop max-iteration control point is invalid.'
}
if ($policy.control_points.error_recovery.rule -notmatch 'explicit Observation/ErrorFeedback' -or $policy.control_points.error_recovery.rule -notmatch 'never empty strings') {
    throw 'Agent loop error-recovery rule is invalid.'
}
$transportRecovery = $policy.control_points.transport_recovery
if ($transportRecovery.policy -ne 'config/agent-transport-recovery-policy.json' -or $transportRecovery.classifier -ne 'agent/40-runtime/Get-AgentTransportRecoverySignal.ps1') {
    throw 'Agent loop transport-recovery policy route is invalid.'
}
if ($transportRecovery.rule -notmatch 'stop automatic retry' -or $transportRecovery.rule -notmatch 'restart-required') {
    throw 'Agent loop transport-recovery rule must stop retry and return a restart-required exit.'
}
if ($policy.control_points.host_watchdog.detector -ne 'agent/40-runtime/Get-AgentHostRecoverySignal.ps1' -or [int]$policy.control_points.host_watchdog.threshold_seconds -lt 60 -or $policy.control_points.host_watchdog.action -notmatch 'persist') {
    throw 'Agent loop host watchdog contract is invalid.'
}
foreach ($component in @('codex', 'global-experience-agent', 'child-agent')) {
    if ($component -notin @($transportRecovery.applies_to)) { throw "Agent loop transport recovery is missing component: $component" }
}
if ([int]$policy.control_points.context_budget.minimum_retained_turns -lt 3 -or $policy.control_points.context_budget.no_regression -notmatch 'authority') {
    throw 'Agent loop context-budget rule is invalid.'
}
foreach ($stop in @('finish_action', 'final_answer_signal', 'max_iterations', 'save_point_settled', 'authority_boundary_reached', 'verification_failed')) {
    if ($stop -notin @($policy.control_points.termination.stop_conditions)) {
        throw "Agent loop termination control point is missing: $stop"
    }
}
if (@($policy.control_points.termination.stop_conditions).Count -lt 3 -or $policy.control_points.termination.failure_behavior -notmatch 'typed partial or blocked exit') {
    throw 'Agent loop termination fallback is invalid.'
}

foreach ($traceField in @('iteration', 'phase', 'event', 'owner', 'operation', 'tool_gate', 'result_type', 'error', 'safe_event_payload')) {
    if ($traceField -notin @($policy.harness_requirements.tracing)) {
        throw "Agent loop tracing contract is missing field: $traceField"
    }
}
foreach ($gated in @('external framework installation', 'OpenAI API or hosted model loop execution', 'FastAPI service exposure', 'background autonomous runner', 'non-idempotent retry', 'structural owner changes')) {
    if ($gated -notin @($policy.authority_boundary.requires_owner_gate)) {
        throw "Agent loop authority boundary is missing gated action: $gated"
    }
}
if ($policy.authority_boundary.privacy_rule -notmatch 'safe metadata' -or $policy.authority_boundary.privacy_rule -notmatch 'raw prompts') {
    throw 'Agent loop privacy rule must separate safe metadata from unsafe raw traces.'
}

$state = (& (Join-Path $root 'agent\40-runtime\Get-AgentHarnessState.ps1') -RepositoryRoot $root) | ConvertFrom-Json
if ($state.agent_loop_policy.model -ne 'global-experience-agent-loop-policy' -or $state.agent_loop_policy.owner -ne 'codex-self-evolution') {
    throw 'Agent harness state does not expose the Agent loop policy.'
}
foreach ($phase in @('plan', 'act', 'observe', 'reflect', 'settle')) {
    if ($phase -notin @($state.agent_loop_policy.phases)) {
        throw "Agent harness state loop policy is missing phase: $phase"
    }
}
if ($state.agent_loop_policy.max_iterations -ne 10 -or @($state.agent_loop_policy.stop_conditions).Count -lt 3) {
    throw 'Agent harness state loop guardrails are incomplete.'
}
if ($state.agent_loop_policy.owner_gate_rule -notmatch 'owner tool gates') {
    throw 'Agent harness state does not expose the owner-gate loop rule.'
}
if ($state.agent_transport_recovery.model -ne 'agent-transport-recovery-policy' -or $state.agent_transport_recovery.restart_required_exit -ne 'restart-required' -or $state.agent_transport_recovery.host_detector -ne 'agent/40-runtime/Get-AgentHostRecoverySignal.ps1') {
    throw 'Agent harness state does not expose transport recovery.'
}

$manifest = Get-Content -LiteralPath (Join-Path $root 'config\agent-system.json') -Raw -Encoding UTF8 | ConvertFrom-Json
if ('config/agent-loop-policy.json' -notin @($manifest.resources.information_units)) {
    throw 'Agent system manifest does not list the loop policy as an information unit.'
}
if ('config/agent-transport-recovery-policy.json' -notin @($manifest.resources.information_units)) {
    throw 'Agent system manifest does not list the transport recovery policy as an information unit.'
}
if ('scripts/Test-AgentLoopPolicy.ps1' -notin @($manifest.resources.functional_units)) {
    throw 'Agent system manifest does not list the loop policy test as a functional unit.'
}
if ('agent/40-runtime/Get-AgentTransportRecoverySignal.ps1' -notin @($manifest.resources.functional_units) -or 'scripts/Test-AgentTransportRecovery.ps1' -notin @($manifest.resources.functional_units)) {
    throw 'Agent system manifest does not list transport recovery functional units.'
}
if ('agent/40-runtime/Get-AgentHostRecoverySignal.ps1' -notin @($manifest.resources.functional_units) -or 'scripts/Test-AgentHostTransportRecovery.ps1' -notin @($manifest.resources.functional_units)) {
    throw 'Agent system manifest does not list host watchdog functional units.'
}
if ($manifest.agent_runtime.loop_policy -ne 'config/agent-loop-policy.json') {
    throw 'Agent runtime does not point to the loop policy.'
}

[pscustomobject]@{
    status = 'passed'
    model = $policy.model
    source = $policy.source.path
    phases = @($policy.loop_contract.phases).Count
    max_iterations = $policy.control_points.max_iterations.default
    stop_conditions = @($policy.control_points.termination.stop_conditions).Count
    owner_gate_preserved = $policy.loop_contract.owner_rule -match 'owner tool gates'
} | ConvertTo-Json -Compress
