[CmdletBinding()]
param(
    [string]$RepositoryRoot = 'F:\codex'
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath $RepositoryRoot).Path
$manifestPath = Join-Path $root 'config\agent-system.json'
if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) {
    throw 'Agent system manifest is missing: config\agent-system.json'
}

$manifest = Get-Content -LiteralPath $manifestPath -Raw -Encoding UTF8 | ConvertFrom-Json
if ($manifest.schema_version -ne 4 -or $manifest.status -ne 'active' -or $manifest.model -ne 'agent-system') {
    throw 'Agent system manifest header is invalid.'
}
if ($manifest.template.source -ne 'https://github.com/earendil-works/pi') {
    throw 'Agent system manifest does not name earendil-works/pi as the template source.'
}
if ($manifest.template.runtime_policy -ne 'do-not-install-pi-runtime-by-default') {
    throw 'Agent system manifest does not preserve the no-runtime-install boundary.'
}
$minimalTemplatePath = Join-Path $root 'config\minimal-agent-template.json'
if (-not (Test-Path -LiteralPath $minimalTemplatePath -PathType Leaf)) { throw 'Minimal Agent template file is missing.' }
$minimalTemplate = Get-Content -LiteralPath $minimalTemplatePath -Raw -Encoding UTF8 | ConvertFrom-Json
foreach ($unit in @('memory_system','intent_recognition','doc_parse_pipeline','chunking_retrieval','rerank_calibration','agent_loop','memory_as_skill')) {
    if ($unit -notin @($minimalTemplate.required_units.feynman_structural_scaffold)) {
        throw "Minimal Agent template is missing inherited feynman scaffold unit: $unit"
    }
}
if ($manifest.harness.owner -ne 'codex-self-evolution') {
    throw 'Agent system harness must be owned by codex-self-evolution.'
}
if (-not $manifest.filesystem -or $manifest.filesystem.manifest -ne 'agent/agent-filesystem.json' -or $manifest.filesystem.canonical_runtime_root -ne 'agent/40-runtime') {
    throw 'Agent system manifest does not expose the physical Agent filesystem authority.'
}

foreach ($requiredResponsibility in @('project_entry', 'task_contract', 'authority_snapshot', 'resource_selection', 'phase_control', 'caller_and_model_abstraction', 'subagent_lifecycle', 'tool_gate_routing', 'save_point_acceptance', 'closeout_boundary')) {
    if ($requiredResponsibility -notin @($manifest.harness.responsibilities)) {
        throw "Agent system harness is missing responsibility: $requiredResponsibility"
    }
}
foreach ($entryScope in @('all Codex project entries by default unless explicit user-authorized skip', 'global experience system', 'learning and external method adoption', 'agent architecture', 'global iteration', 'auto-Git or release synchronization')) {
    if ($entryScope -notin @($manifest.global_experience_agent_entry.applies_to)) {
        throw "Agent system entry route is missing scope: $entryScope"
    }
}
if ($manifest.global_experience_agent_entry.default_route -notmatch 'every Codex project entry' -or $manifest.global_experience_agent_entry.default_route -notmatch 'explicitly authorizes') {
    throw 'Agent system entry route must auto-start or resume the Global Experience Agent by default unless explicitly skipped by the user.'
}
$startupPolicy = $manifest.global_experience_agent_entry.startup_policy
if (-not $startupPolicy -or $startupPolicy.default -ne 'auto-start-or-resume' -or $startupPolicy.skip_requires -ne 'explicit user authorization for this turn') {
    throw 'Agent system startup policy must require default auto-start/resume and explicit per-turn skip authorization.'
}
foreach ($startupOperation in @('Run StartWork', 'Resume', 'Continue')) {
    if ($startupOperation -notin @($startupPolicy.startup_operations)) {
        throw "Agent system startup policy is missing operation: $startupOperation"
    }
}
foreach ($nonBypass in @('codex-self-evolution lifecycle entry', 'Codebase Memory F-codex startup and indexing when applicable', 'safety, privacy, rollback, and validation gates', 'owner routing', 'permission checks')) {
    if ($nonBypass -notin @($startupPolicy.skip_does_not_bypass)) {
        throw "Agent system startup skip boundary is missing: $nonBypass"
    }
}
if ($startupPolicy.authority_boundary -notmatch 'does not authorize Git' -or $startupPolicy.authority_boundary -notmatch 'Agent-structure mutation') {
    throw 'Agent system startup policy must preserve high-risk owner gates and Agent-structure authorization boundaries.'
}
foreach ($entryStep in @('load project authority', 'refresh F-codex graph when callable', 'classify Auto intent before operation permission evaluation', 'create bounded task contract', 'select smallest owner/resource set', 'create turn snapshot', 'route gated actions to owners')) {
    if ($entryStep -notin @($manifest.global_experience_agent_entry.entry_protocol)) {
        throw "Agent system entry protocol is missing step: $entryStep"
    }
}
if ($manifest.global_experience_agent_entry.transfer_rule -notmatch 'harness resource call') {
    throw 'Agent system entry transfer rule must route legacy global experience work through the harness.'
}

$runtime = $manifest.agent_runtime
if (-not $runtime) { throw 'Agent system manifest is missing the executable agent runtime contract.' }
if ($runtime.loop_policy -ne 'config/agent-loop-policy.json') {
    throw 'Agent runtime must point to the canonical Agent loop policy.'
}
foreach ($mode in @('Inspect', 'Verify', 'Run', 'Continue', 'Resume', 'Abort')) {
    if ($mode -notin @($runtime.modes)) { throw "Agent runtime is missing mode: $mode" }
}
foreach ($operation in @('Auto', 'ClassifyIntent', 'VerifyAgent', 'DescribeFilesystem', 'ResolveAgentPath', 'DescribeInterfaces', 'EvaluateAccess', 'RetrieveContext', 'StartWork', 'StoreMemory', 'SearchMemory', 'ConsolidateMemory', 'RenderMemorySnapshot', 'RouteOwner', 'DelegateSubagent', 'CompleteSubagent', 'JoinSubagent', 'CancelSubagent', 'CompleteIteration', 'CandidateReport', 'RequestStructureChange')) {
    if ($operation -notin @($runtime.operations)) { throw "Agent runtime is missing operation: $operation" }
}
foreach ($stateFile in @('state.json', 'events.jsonl')) {
    if ($stateFile -notin @($runtime.state_files)) { throw "Agent runtime is missing durable state file: $stateFile" }
}
foreach ($step in @('record caller, model, compatible host, interface, and authority scope labels', 'deny unauthorized operations before durable session mutation', 'create durable session entry', 'create immutable turn snapshot', 'select resources and tool gate', 'persist operation and tool-call lifecycle', 'flush pending writes after tool result', 'commit accepted or interrupted save point')) {
    if ($step -notin @($runtime.run_contract)) { throw "Agent runtime run contract is missing: $step" }
}
if ($runtime.resume_contract -notmatch 'unfinished non-idempotent operations interrupted') {
    throw 'Agent runtime resume contract must conservatively interrupt unfinished non-idempotent operations.'
}
if ($runtime.continue_contract -notmatch 'authorized caller or compatible model' -or $runtime.continue_contract -notmatch 'idle session') { throw 'Agent runtime Continue contract is not caller/model neutral.' }
if (-not $manifest.agent_registry -or $manifest.agent_registry.source -ne 'config/global-experience-agent-registry.json') { throw 'Agent system manifest is missing the canonical Agent registry.' }
$agentRegistryPath = Join-Path $root ([string]$manifest.agent_registry.source)
if (-not (Test-Path -LiteralPath $agentRegistryPath -PathType Leaf)) { throw 'Canonical Agent registry file is missing.' }
$agentRegistry = Get-Content -LiteralPath $agentRegistryPath -Raw -Encoding UTF8 | ConvertFrom-Json
if ($agentRegistry.root_agent.id -ne 'global-experience-agent' -or @($agentRegistry.concept_agents).Count -lt 1 -or $agentRegistry.dynamic_subagents.policy -ne 'executable-under-current-authority') { throw 'Agent registry root, concept, or dynamic-child contract is invalid.' }
$interfacePolicyPath = Join-Path $root ([string]$manifest.agent_registry.interface_policy)
if (-not (Test-Path -LiteralPath $interfacePolicyPath -PathType Leaf)) { throw 'Canonical Agent interface policy file is missing.' }
$interfacePolicy = Get-Content -LiteralPath $interfacePolicyPath -Raw -Encoding UTF8 | ConvertFrom-Json
if ($agentRegistry.interface_policy.source -ne 'config/agent-interface-policy.json' -or $interfacePolicy.default_decision -ne 'deny' -or @($interfacePolicy.interfaces).Count -ne 4) { throw 'Agent registry and interface policy are not aligned.' }
if ($runtime.abort_contract -notmatch 'preserve nextTurn and pending writes') {
    throw 'Agent runtime abort contract must preserve nextTurn and pending writes.'
}
foreach ($runtimePath in @($runtime.controller, $runtime.implementation)) {
    if (-not (Test-Path -LiteralPath (Join-Path $root ([string]$runtimePath)) -PathType Leaf)) {
        throw "Agent runtime references a missing implementation: $runtimePath"
    }
}

$requiredFiles = @(
    @($manifest.resources.information_units) +
    @($manifest.resources.functional_units) +
    @($manifest.harness.interfaces)
) | ForEach-Object { $_ } | Sort-Object -Unique
foreach ($relative in $requiredFiles) {
    $path = Join-Path $root ([string]$relative)
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        throw "Agent system manifest references a missing file: $relative"
    }
}

foreach ($phase in @('idle', 'turn', 'compaction', 'branch_summary', 'retry')) {
    if ($phase -notin @($manifest.phase_model.phases)) {
        throw "Agent system phase model is missing: $phase"
    }
}
foreach ($unit in @('active model/provider choice', 'available tool gates', 'selected resources', 'system prompt or project instructions')) {
    if ($unit -notin @($manifest.runtime_config.latest_config_units)) {
        throw "Agent system runtime config is missing unit: $unit"
    }
}
if ($manifest.runtime_config.setter_rule -notmatch 'next snapshot' -or $manifest.runtime_config.setter_rule -notmatch 'active evidence') {
    throw 'Agent system runtime config does not preserve future-snapshot semantics.'
}
foreach ($unit in @('persisted session evidence', 'resolved resources', 'all available tools', 'active tools', 'derived session id')) {
    if ($unit -notin @($manifest.turn_snapshot.snapshot_units)) {
        throw "Agent system turn snapshot is missing unit: $unit"
    }
}
foreach ($operation in @('steer', 'followUp', 'nextTurn', 'abort', 'runtime config setters')) {
    if ($operation -notin @($manifest.queue_operations.turn_safe_operations)) {
        throw "Agent system queue operations are missing turn-safe operation: $operation"
    }
}
foreach ($operation in @('prompt', 'skill', 'promptFromTemplate', 'compact', 'navigateTree')) {
    if ($operation -notin @($manifest.queue_operations.structural_operations)) {
        throw "Agent system queue operations are missing structural operation: $operation"
    }
}
foreach ($shape in @('pending write enqueue record', 'pending write applied record', 'deterministic target reference')) {
    if ($shape -notin @($manifest.pending_session_writes.write_shapes)) {
        throw "Agent system pending session writes are missing shape: $shape"
    }
}
foreach ($flushPoint in @('save point', 'operation settlement', 'failure cleanup')) {
    if ($flushPoint -notin @($manifest.pending_session_writes.flush_points)) {
        throw "Agent system pending session writes are missing flush point: $flushPoint"
    }
}
foreach ($unit in @('tool gate definitions', 'active tool names', 'idempotency metadata', 'retry-safety metadata', 'provenance')) {
    if ($unit -notin @($manifest.tool_registry.registry_units)) {
        throw "Agent system tool registry is missing unit: $unit"
    }
}
foreach ($unit in @('provider id', 'model id', 'api identifier', 'auth source label', 'last-known model list', 'explicit refresh boundary', 'stream behavior owner')) {
    if ($unit -notin @($manifest.model_registry.registry_units)) {
        throw "Agent system model registry is missing unit: $unit"
    }
}
foreach ($unit in @('typed event', 'observer', 'result-producing handler', 'event-specific reducer', 'cleanup', 'source metadata', 'facade context')) {
    if ($unit -notin @($manifest.hook_system.event_model)) {
        throw "Agent system hook system is missing unit: $unit"
    }
}
foreach ($unit in @('trace id', 'span id', 'parent span id', 'start', 'end', 'error', 'safe event payload')) {
    if ($unit -notin @($manifest.observability.event_contract)) {
        throw "Agent system observability contract is missing unit: $unit"
    }
}
foreach ($eventName in @('pi.agent.prompt', 'pi.agent.skill', 'pi.agent.session.append_entry', 'pi.ai.provider.request')) {
    if ($eventName -notin @($manifest.observability.minimal_events)) {
        throw "Agent system observability is missing minimal event: $eventName"
    }
}
foreach ($event in @('user_goal_received', 'experience_context_loaded', 'agent_resources_selected', 'tool_gate_requested', 'tool_result_recorded', 'save_point_committed')) {
    if ($event -notin @($manifest.event_loop.event)) {
        throw "Agent system event loop is missing: $event"
    }
}
$loopPolicy = Get-Content -LiteralPath (Join-Path $root 'config\agent-loop-policy.json') -Raw -Encoding UTF8 | ConvertFrom-Json
if ($loopPolicy.model -ne 'global-experience-agent-loop-policy' -or $loopPolicy.owner -ne 'codex-self-evolution') {
    throw 'Agent loop policy is not aligned to the self-evolution harness owner.'
}
foreach ($phase in @('plan', 'act', 'observe', 'reflect', 'settle')) {
    if ($phase -notin @($loopPolicy.loop_contract.phases)) {
        throw "Agent loop policy is missing control-plane phase: $phase"
    }
}
if ([int]$loopPolicy.control_points.max_iterations.default -ne 10 -or @($loopPolicy.control_points.termination.stop_conditions).Count -lt 3) {
    throw 'Agent loop policy does not expose bounded iteration and multi-condition termination.'
}
if ($loopPolicy.control_points.error_recovery.rule -notmatch 'explicit Observation/ErrorFeedback') {
    throw 'Agent loop policy does not make errors explicit observations.'
}
foreach ($exitStep in @('record tool results or error feedback', 'run narrowest proving check', 'accept or reject save point', 'update lifecycle state or candidate records', 'generate current candidate report after complete global iterations')) {
    if ($exitStep -notin @($manifest.agent_exit_alignment.exit_protocol)) {
        throw "Agent system exit protocol is missing step: $exitStep"
    }
}
foreach ($output in @('global-experience-agent-last-run.json', 'complete iteration proof', 'candidate report', 'publication envelope', 'validated Git commit', 'verified release evidence')) {
    if ($output -notin @($manifest.agent_exit_alignment.save_point_outputs)) {
        throw "Agent system exit alignment is missing save-point output: $output"
    }
}
if ($manifest.agent_exit_alignment.alignment_rule -notmatch 'proof' -or $manifest.agent_exit_alignment.alignment_rule -notmatch 'state') {
    throw 'Agent system exit alignment must bind proof and state.'
}
foreach ($decision in @('approve', 'edit', 'reject', 'respond')) {
    if ($decision -notin @($manifest.human_review_and_evals.review_decisions)) {
        throw "Agent system human review is missing decision: $decision"
    }
}
foreach ($evalSurface in @('topology contract tests', 'harness contract tests', 'global experience agent run test', 'global validation', 'global install validation', 'complete iteration proof')) {
    if ($evalSurface -notin @($manifest.human_review_and_evals.eval_surfaces)) {
        throw "Agent system eval surface is missing: $evalSurface"
    }
}
if ($manifest.human_review_and_evals.eval_rule -notmatch 'repeatable tests') {
    throw 'Agent system eval rule must require repeatable tests.'
}

foreach ($gate in @('git', 'release', 'install', 'credential', 'external', 'global_iteration', 'top_owner_change', 'agent_structure')) {
    $entry = @($manifest.tool_gates | Where-Object { $_.name -eq $gate })
    if ($entry.Count -ne 1) { throw "Agent system tool gate is missing or duplicated: $gate" }
    foreach ($state in @('requested', 'preflighted', 'authorized', 'executed', 'observed', 'verified', 'captured_or_reported')) {
        if ($state -notin @($entry[0].lifecycle)) {
            throw "Agent system tool gate $gate is missing lifecycle state: $state"
        }
    }
}

foreach ($storageUnit in @('metadata header', 'tree entry', 'leaf entry', 'compaction checkpoint', 'branch summary', 'custom extension entry', 'tool result evidence')) {
    if ($storageUnit -notin @($manifest.session.storage_units)) {
        throw "Agent system session model is missing storage unit: $storageUnit"
    }
}
foreach ($entry in @('queue_enqueued', 'queue_consumed', 'pending_write_enqueued', 'pending_write_applied', 'operation_started', 'operation_interrupted', 'turn_started', 'provider_request_started', 'tool_call_started')) {
    if ($entry -notin @($manifest.durable_recovery.durable_entries)) {
        throw "Agent system durable recovery is missing entry: $entry"
    }
}
foreach ($entryType in @('session', 'message', 'model_change', 'thinking_level_change', 'compaction', 'branch_summary', 'custom', 'custom_message', 'label', 'session_info', 'leaf')) {
    if ($entryType -notin @($manifest.session_entry_schema.entry_types)) {
        throw "Agent system session entry schema is missing type: $entryType"
    }
}
foreach ($effect in @('clear steer queue', 'clear followUp queue', 'preserve nextTurn queue', 'preserve pending session writes')) {
    if ($effect -notin @($manifest.abort_semantics.effects)) {
        throw "Agent system abort semantics are missing effect: $effect"
    }
}
foreach ($retryEvent in @('retry_scheduled', 'retry_attempt_start', 'retry_finished')) {
    if ($retryEvent -notin @($manifest.compaction_and_branching.retry_events)) {
        throw "Agent system compaction/branching is missing retry event: $retryEvent"
    }
}
foreach ($surface in @('MCP servers', 'hooks', 'subagent patterns')) {
    if ($surface -notin @($manifest.extensions.surfaces)) {
        throw "Agent system extension model is missing surface: $surface"
    }
}
if ($manifest.extensions.raw_pi_extension_policy -ne 'do-not-load-by-default') {
    throw 'Agent system must not load raw Pi extensions by default.'
}
foreach ($blocked in @('credential mutation', 'installation', 'publication', 'remote release', 'non-idempotent tool call')) {
    if ($blocked -notin @($manifest.recovery.non_retryable_without_owner_proof)) {
        throw "Agent system recovery policy is missing non-retryable boundary: $blocked"
    }
}
foreach ($condition in @('isolated write surfaces', 'shared acceptance criteria', 'merge verifier', 'current authority')) {
    if ($condition -notin @($manifest.subagents.required_conditions)) {
        throw "Agent system subagent policy is missing condition: $condition"
    }
}
if ('feynman structural scaffold' -notin @($manifest.subagents.required_conditions)) {
    throw 'Agent system subagent policy must require the feynman structural scaffold.'
}
foreach ($profile in @($manifest.subagents.named_profiles)) {
    foreach ($unit in @('memory_system','intent_recognition','doc_parse_pipeline','chunking_retrieval','rerank_calibration','agent_loop','memory_as_skill')) {
        if ($unit -notin @($profile.feynman_structural_scaffold)) {
            throw "Agent system named child profile $($profile.id) is missing feynman scaffold unit: $unit"
        }
    }
}
if ($manifest.subagents.policy -ne 'executable-under-current-authority') { throw 'Agent system subagent lifecycle is not executable.' }
foreach ($state in @('delegated','completed','joined','cancelled')) { if ($state -notin @($manifest.subagents.lifecycle)) { throw "Agent subagent lifecycle is missing state: $state" } }
$registryTest = (& (Join-Path $root 'scripts\Test-GlobalExperienceAgentRegistry.ps1') -RepositoryRoot $root) | ConvertFrom-Json
if ($registryTest.status -ne 'passed' -or $registryTest.specialist_agents -ne 23 -or $registryTest.concept_agents -lt 1) { throw 'Agent registry runtime test did not pass.' }

$contract = $manifest.architecture_contract
if (-not $contract -or @($contract.constraint_matrix).Count -lt 6) {
    throw 'Agent system architecture contract must define at least six constraint-matrix entries.'
}
foreach ($scope in @('harness', 'resources', 'filesystem', 'tool_gates', 'session_and_save_points', 'extensions_and_subagents', 'recovery_and_completion')) {
    $entry = @($contract.constraint_matrix | Where-Object { $_.scope -eq $scope })
    if ($entry.Count -ne 1) { throw "Agent system architecture contract is missing scope: $scope" }
    if (@($entry[0].required_structures).Count -lt 4) { throw "Agent system architecture contract has too few required structures for: $scope" }
    if (@($entry[0].required_protocols).Count -lt 3) { throw "Agent system architecture contract has too few required protocols for: $scope" }
    if (@($entry[0].constraints).Count -lt 3) { throw "Agent system architecture contract has too few constraints for: $scope" }
}
foreach ($diagramField in @('path', 'provenance', 'generator', 'mapping', 'owner_network', 'test', 'theme')) {
    if ([string]::IsNullOrWhiteSpace($contract.diagram.$diagramField)) {
        throw "Agent system architecture diagram contract is missing: $diagramField"
    }
}

$ownerConnections = (& (Join-Path $root 'scripts\Test-AgentOwnerConnections.ps1') -RepositoryRoot $root) | ConvertFrom-Json
if ($ownerConnections.status -ne 'passed' -or $ownerConnections.active_owner_coverage -ne 23) {
    throw 'Agent owner connection topology did not cover all active owners.'
}

[pscustomobject]@{
    status = 'passed'
    model = $manifest.model
    source = $manifest.template.source
    source_commit = $manifest.template.source_commit
    checked_files = @($requiredFiles).Count
    tool_gates = @($manifest.tool_gates).Count
    active_owner_coverage = $ownerConnections.active_owner_coverage
    owner_connections = $ownerConnections.connections
    concept_agents = @($agentRegistry.concept_agents).Count
    runtime_operations = @($runtime.operations).Count
} | ConvertTo-Json -Compress
