[CmdletBinding()]
param(
    [string]$RepositoryRoot = 'F:\codex'
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath $RepositoryRoot).Path

$paths = [ordered]@{
    terminology = 'docs\SKILL-TERMINOLOGY.md'
    globalSystem = 'knowledge-vault\30-Knowledge\Global Experience System.md'
    piLearning = 'knowledge-vault\30-Knowledge\Pi Agent Harness Network Learning.md'
    unitPrinciple = 'knowledge-vault\30-Knowledge\Information and Functional Unit Principle.md'
    learningGovernance = 'knowledge-vault\30-Knowledge\Learning Governance.md'
    selfEvolution = 'skills\codex-self-evolution\SKILL.md'
    moduleRegistry = 'module-registry.json'
    agentSystem = 'config\agent-system.json'
    ownerNetwork = 'config\agent-owner-connections.json'
    agentRegistry = 'config\global-experience-agent-registry.json'
    agentFilesystem = 'agent\agent-filesystem.json'
    harnessState = 'agent\40-runtime\Get-AgentHarnessState.ps1'
    agentMemoryKnowledge = 'knowledge-vault\30-Knowledge\Agent Memory System.md'
    agentIntentKnowledge = 'knowledge-vault\30-Knowledge\Agent Intent Recognition System.md'
    agentLoopKnowledge = 'knowledge-vault\30-Knowledge\Agent Loop System.md'
    transportRecoveryPolicy = 'config\agent-transport-recovery-policy.json'
    transportRecoveryClassifier = 'agent\40-runtime\Get-AgentTransportRecoverySignal.ps1'
    transportRecoveryTest = 'scripts\Test-AgentTransportRecovery.ps1'
    hostRecoveryDetector = 'agent\40-runtime\Get-AgentHostRecoverySignal.ps1'
    hostRecoveryModule = 'agent\40-runtime\HostTransportRecovery.ps1'
    hostRecoveryTest = 'scripts\Test-AgentHostTransportRecovery.ps1'
    agentDocParseKnowledge = 'knowledge-vault\30-Knowledge\Agent Document Parse Pipeline.md'
    agentIntentPolicy = 'config\agent-intent-policy.json'
    agentLoopPolicy = 'config\agent-loop-policy.json'
    agentMemorySkillPolicy = 'config\agent-memory-skill-policy.json'
    agentIntentTest = 'scripts\Test-AgentIntentRecognition.ps1'
    agentLoopTest = 'scripts\Test-AgentLoopPolicy.ps1'
    agentDocParseTest = 'scripts\Test-AgentDocParsePipeline.ps1'
    agentMemoryBackend = 'agent\40-runtime\Invoke-AgentMemoryStore.py'
    agentMemoryTest = 'scripts\Test-AgentMemorySystem.ps1'
    agentMemorySkillTest = 'scripts\Test-AgentMemoryAsSkillPolicy.ps1'
    globalExperienceAgent = 'agent\40-runtime\Invoke-GlobalExperienceAgent.ps1'
    globalExperienceAgentRuntime = 'agent\40-runtime\Invoke-GlobalExperienceAgentRuntime.ps1'
    globalExperienceAgentTest = 'scripts\Test-GlobalExperienceAgent.ps1'
    agentSystemTopology = 'scripts\Test-AgentSystemTopology.ps1'
    ownerConnectionTest = 'scripts\Test-AgentOwnerConnections.ps1'
    agentRegistryTest = 'scripts\Test-GlobalExperienceAgentRegistry.ps1'
}

$contents = @{}
foreach ($key in $paths.Keys) {
    $path = Join-Path $root $paths[$key]
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        throw "Required agent-harness contract file is missing: $($paths[$key])"
    }
    $contents[$key] = [IO.File]::ReadAllText($path, [Text.UTF8Encoding]::new($false))
}

$requiredTerminology = @(
    'Agent Harness',
    'Agent Resource',
    'Agent Tool Gate',
    'Session Branch',
    'Save Point',
    'Extension Surface',
    'Project Trust',
    'Specialist Agent',
    'Concept Agent',
    'Subagent',
    'Agent Loop',
    'Agent Phase',
    'Durable Session Entry',
    'Tool Call Lifecycle'
)
$missingTerms = @($requiredTerminology | Where-Object { $contents.terminology -notmatch [regex]::Escape($_) })
if ($missingTerms.Count -gt 0) {
    throw "Agent terminology is missing required terms: $($missingTerms -join ', ')"
}

$requiredLearning = @(
    'earendil-works/pi',
    'agent harness method system',
    'codex-self-evolution',
    'tool gates',
    'session tree',
    'extension surfaces',
    'Do not install Pi'
)
$missingLearning = @($requiredLearning | Where-Object { $contents.piLearning -notmatch [regex]::Escape($_) })
if ($missingLearning.Count -gt 0) {
    throw "Pi learning note is missing required contract text: $($missingLearning -join ', ')"
}

if ($contents.globalSystem -notmatch '## Global Experience Agent') {
    throw 'Global Experience System does not expose the executable Global Experience Agent contract.'
}
if ($contents.globalSystem -notmatch [regex]::Escape('[[Pi Agent Harness Network Learning]]')) {
    throw 'Global Experience System does not link to Pi Agent Harness Network Learning.'
}
if ($contents.globalSystem -notmatch [regex]::Escape('[[Agent Memory System]]')) {
    throw 'Global Experience System does not link to Agent Memory System.'
}
foreach ($requiredMemoryText in @('SQLite/FTS5', 'TTL', 'supersession', 'Frozen Snapshot', 'StoreMemory', 'SearchMemory', 'ConsolidateMemory', 'RenderMemorySnapshot', 'search before store', 'memory-action traces')) {
    if ($contents.agentMemoryKnowledge -notmatch [regex]::Escape($requiredMemoryText)) {
        throw "Agent Memory System note is missing required contract text: $requiredMemoryText"
    }
}
foreach ($requiredIntentText in @('LesterYu0/feynman-build-workshop', 'four-layer', 'ClassifyIntent', 'intent_classified', 'StartWork', 'intent labels never grant authority')) {
    if ($contents.agentIntentKnowledge -notmatch [regex]::Escape($requiredIntentText)) {
        throw "Agent Intent Recognition System note is missing required contract text: $requiredIntentText"
    }
}
foreach ($requiredLoopText in @('LesterYu0/feynman-build-workshop', 'Plan -> Act -> Observe -> Reflect -> Settle', 'Max iterations', 'Error recovery', 'Context budget', 'Termination')) {
    if ($contents.agentLoopKnowledge -notmatch [regex]::Escape($requiredLoopText)) {
        throw "Agent Loop System note is missing required contract text: $requiredLoopText"
    }
}
foreach ($requiredDocParseText in @('LesterYu0/feynman-build-workshop episode 03', 'Document', 'Chunk', 'Parser routing', 'OCR degradation chain', 'content, structure, performance, and robustness')) {
    if ($contents.agentDocParseKnowledge -notmatch [regex]::Escape($requiredDocParseText)) {
        throw "Agent Document Parse Pipeline note is missing required contract text: $requiredDocParseText"
    }
}
if ($contents.unitPrinciple -notmatch 'Agent-harness terminology refines the same split') {
    throw 'Information/functional unit principle does not classify agent-harness terms.'
}
if ($contents.learningGovernance -notmatch 'Pi agent-harness learning adds a guarded architecture lens') {
    throw 'Learning governance does not constrain Pi agent-harness learning.'
}
if (
    $contents.selfEvolution -notmatch 'executable Agent model' -or
    $contents.selfEvolution -notmatch 'does\s+not\s+create public access' -or
    $contents.selfEvolution -notmatch 'require Pi' -or
    $contents.selfEvolution -notmatch 'load arbitrary extensions' -or
    $contents.selfEvolution -notmatch 'delegation expand authority'
) {
    throw 'Self-evolution routing does not preserve the executable Agent authority boundary.'
}
if ($contents.moduleRegistry -notmatch 'Pi agent-harness learning' -or $contents.moduleRegistry -notmatch 'earendil-works/pi') {
    throw 'Module registry does not record Pi agent-harness evidence.'
}
foreach ($runtimeTerm in @('turn_snapshot_created', 'queue_enqueued', 'pending_write_applied', 'tool_call_started', 'save_point_committed', 'operation_interrupted')) {
    if ($contents.globalExperienceAgentRuntime -notmatch [regex]::Escape($runtimeTerm)) {
        throw "Executable global experience agent runtime is missing durable behavior: $runtimeTerm"
    }
}

$stateJson = & (Join-Path $root 'agent\40-runtime\Get-AgentHarnessState.ps1') -RepositoryRoot $root
$state = $stateJson | ConvertFrom-Json
if ($state.status -ne 'passed') {
    throw "Agent harness state is not complete: $($state.missing_required_surfaces -join ', ')"
}
if ($state.agent_filesystem.model -ne 'agent-filesystem' -or @($state.agent_filesystem.zones).Count -ne 10 -or $state.agent_filesystem.canonical_surfaces.runtime_controller -ne 'agent/40-runtime/Invoke-GlobalExperienceAgent.ps1') {
    throw 'Agent harness state does not expose the physical Agent filesystem.'
}
if ($state.harness.owner -ne 'codex-self-evolution' -or $state.harness.model -ne 'agent-harness') {
    throw 'Agent harness state does not name codex-self-evolution as the harness.'
}
if ($state.harness.installation_policy -notmatch 'do-not-install-runtime-by-default') {
    throw 'Agent harness state does not preserve the Pi runtime installation boundary.'
}
foreach ($requiredEntryScope in @('global experience system', 'learning and external method adoption', 'agent architecture', 'global iteration', 'auto-Git or release synchronization')) {
    if ($requiredEntryScope -notin @($state.global_experience_agent_entry.applies_to)) {
        throw "Agent harness entry route is missing scope: $requiredEntryScope"
    }
}
foreach ($requiredEntryStep in @('load project authority', 'refresh F-codex graph when callable', 'classify Auto intent before operation permission evaluation', 'create bounded task contract', 'select smallest owner/resource set', 'create turn snapshot', 'route gated actions to owners')) {
    if ($requiredEntryStep -notin @($state.global_experience_agent_entry.entry_protocol)) {
        throw "Agent harness entry protocol is missing step: $requiredEntryStep"
    }
}
if ($state.global_experience_agent_entry.transfer_rule -notmatch 'harness resource call') {
    throw 'Agent harness entry transfer rule must route legacy global experience work through the harness.'
}
foreach ($requiredGate in @('git', 'release', 'install', 'credential', 'external', 'global_iteration', 'top_owner_change', 'agent_structure')) {
    if ($requiredGate -notin @($state.tool_gates.name)) {
        throw "Agent harness state is missing tool gate: $requiredGate"
    }
}
foreach ($requiredSurface in @('MCP servers', 'hooks', 'subagent patterns')) {
    if ($requiredSurface -notin @($state.extension_surfaces)) {
        throw "Agent harness state is missing extension surface: $requiredSurface"
    }
}
foreach ($requiredEvent in @('user_goal_received', 'experience_context_loaded', 'agent_resources_selected', 'tool_gate_requested', 'tool_result_recorded', 'save_point_committed')) {
    if ($requiredEvent -notin @($state.agent_loop.event)) {
        throw "Agent system loop is missing event: $requiredEvent"
    }
}
foreach ($requiredExitStep in @('record tool results or error feedback', 'run narrowest proving check', 'accept or reject save point', 'update lifecycle state or candidate records', 'generate current candidate report after complete global iterations')) {
    if ($requiredExitStep -notin @($state.agent_exit_alignment.exit_protocol)) {
        throw "Agent harness exit protocol is missing step: $requiredExitStep"
    }
}
foreach ($requiredOutput in @('global-experience-agent-last-run.json', 'complete iteration proof', 'candidate report', 'publication envelope', 'validated Git commit', 'verified release evidence')) {
    if ($requiredOutput -notin @($state.agent_exit_alignment.save_point_outputs)) {
        throw "Agent harness exit alignment is missing output: $requiredOutput"
    }
}
foreach ($requiredDecision in @('approve', 'edit', 'reject', 'respond')) {
    if ($requiredDecision -notin @($state.human_review_and_evals.review_decisions)) {
        throw "Agent harness human-review decision is missing: $requiredDecision"
    }
}
foreach ($requiredEval in @('topology contract tests', 'harness contract tests', 'global experience agent run test', 'global validation', 'global install validation', 'complete iteration proof')) {
    if ($requiredEval -notin @($state.human_review_and_evals.eval_surfaces)) {
        throw "Agent harness eval surface is missing: $requiredEval"
    }
}
foreach ($requiredLifecycleState in @('requested', 'preflighted', 'authorized', 'executed', 'observed', 'verified', 'captured_or_reported')) {
    if ($requiredLifecycleState -notin @($state.tool_call_lifecycle)) {
        throw "Agent tool-call lifecycle is missing state: $requiredLifecycleState"
    }
}
foreach ($requiredPhase in @('idle', 'turn', 'compaction', 'branch_summary', 'retry')) {
    if ($requiredPhase -notin @($state.harness_phases)) {
        throw "Agent harness phase model is missing phase: $requiredPhase"
    }
}
foreach ($requiredRuntimeUnit in @('active model/provider choice', 'available tool gates', 'selected resources', 'system prompt or project instructions')) {
    if ($requiredRuntimeUnit -notin @($state.runtime_config.latest_config_units)) {
        throw "Agent runtime config is missing unit: $requiredRuntimeUnit"
    }
}
if ($state.runtime_config.setter_rule -notmatch 'next snapshot' -or $state.runtime_config.setter_rule -notmatch 'active evidence') {
    throw 'Agent runtime config does not preserve future-snapshot semantics.'
}
foreach ($requiredSnapshotUnit in @('persisted session evidence', 'resolved resources', 'all available tools', 'active tools', 'derived session id')) {
    if ($requiredSnapshotUnit -notin @($state.turn_snapshot.snapshot_units)) {
        throw "Agent turn snapshot is missing unit: $requiredSnapshotUnit"
    }
}
foreach ($requiredQueueOperation in @('steer', 'followUp', 'nextTurn', 'abort', 'runtime config setters')) {
    if ($requiredQueueOperation -notin @($state.queue_operations.turn_safe_operations)) {
        throw "Agent queue operations are missing turn-safe operation: $requiredQueueOperation"
    }
}
foreach ($requiredStructuralOperation in @('prompt', 'skill', 'promptFromTemplate', 'compact', 'navigateTree')) {
    if ($requiredStructuralOperation -notin @($state.queue_operations.structural_operations)) {
        throw "Agent queue operations are missing structural operation: $requiredStructuralOperation"
    }
}
foreach ($requiredPendingShape in @('pending write enqueue record', 'pending write applied record', 'deterministic target reference')) {
    if ($requiredPendingShape -notin @($state.pending_session_writes.write_shapes)) {
        throw "Agent pending session writes are missing shape: $requiredPendingShape"
    }
}
foreach ($requiredFlushPoint in @('save point', 'operation settlement', 'failure cleanup')) {
    if ($requiredFlushPoint -notin @($state.pending_session_writes.flush_points)) {
        throw "Agent pending session writes are missing flush point: $requiredFlushPoint"
    }
}
foreach ($requiredToolUnit in @('tool gate definitions', 'active tool names', 'idempotency metadata', 'retry-safety metadata', 'provenance')) {
    if ($requiredToolUnit -notin @($state.tool_registry.registry_units)) {
        throw "Agent tool registry is missing unit: $requiredToolUnit"
    }
}
foreach ($requiredModelUnit in @('provider id', 'model id', 'api identifier', 'auth source label', 'last-known model list', 'explicit refresh boundary', 'stream behavior owner')) {
    if ($requiredModelUnit -notin @($state.model_registry.registry_units)) {
        throw "Agent model registry is missing unit: $requiredModelUnit"
    }
}
foreach ($requiredHookUnit in @('typed event', 'observer', 'result-producing handler', 'event-specific reducer', 'cleanup', 'source metadata', 'facade context')) {
    if ($requiredHookUnit -notin @($state.hook_system.event_model)) {
        throw "Agent hook system is missing unit: $requiredHookUnit"
    }
}
foreach ($requiredObservabilityUnit in @('trace id', 'span id', 'parent span id', 'start', 'end', 'error', 'safe event payload')) {
    if ($requiredObservabilityUnit -notin @($state.observability.event_contract)) {
        throw "Agent observability contract is missing unit: $requiredObservabilityUnit"
    }
}
foreach ($requiredObservabilityEvent in @('pi.agent.prompt', 'pi.agent.skill', 'pi.agent.session.append_entry', 'pi.ai.provider.request')) {
    if ($requiredObservabilityEvent -notin @($state.observability.minimal_events)) {
        throw "Agent observability is missing minimal event: $requiredObservabilityEvent"
    }
}
foreach ($requiredResource in @('current user authority', 'project lifecycle files', 'codebase graph when callable', 'owner skills and deterministic scripts')) {
    if ($requiredResource -notin @($state.resource_selector.ladder)) {
        throw "Agent resource selector is missing ladder rung: $requiredResource"
    }
}
if ($state.agent_memory.model -ne 'agent-memory-system' -or $state.agent_memory.backend -ne 'sqlite-fts5') {
    throw 'Agent harness state does not expose the Agent memory system.'
}
foreach ($requiredMemoryOperation in @('StoreMemory', 'SearchMemory', 'ConsolidateMemory', 'RenderMemorySnapshot')) {
    if ($requiredMemoryOperation -notin @($state.agent_memory.operations)) {
        throw "Agent memory state is missing operation: $requiredMemoryOperation"
    }
}
foreach ($requiredMemoryCapability in @('typed-store', 'fts5-search', 'ttl-expiry', 'supersession', 'consolidation', 'frozen-snapshot-rendering', 'search-before-store', 'upsert-or-supersede', 'on-demand-retrieval', 'memory-action-trace-review')) {
    if ($requiredMemoryCapability -notin @($state.agent_memory.capabilities)) {
        throw "Agent memory state is missing capability: $requiredMemoryCapability"
    }
}
foreach ($requiredMemoryDiagnostic in @('write_search_ratio', 'memory_growth_per_step', 'redundant_write_ratio', 'memory_context_ratio', 'delayed_memory_failure_gap')) {
    if ($requiredMemoryDiagnostic -notin @($state.agent_memory.diagnostics)) {
        throw "Agent memory state is missing diagnostic: $requiredMemoryDiagnostic"
    }
}
if ($state.agent_memory.structure_rule -notmatch 'global-control' -or $state.agent_memory.structure_rule -notmatch 'agent_structure') {
    throw 'Agent memory state does not preserve the structural authority boundary.'
}
if ($state.agent_memory.privacy_rule -notmatch 'ignored local state') {
    throw 'Agent memory state does not preserve local-state privacy.'
}
if ($state.agent_intent_recognition.model -ne 'global-experience-agent-intent-policy' -or $state.agent_intent_recognition.operation -ne 'ClassifyIntent') {
    throw 'Agent harness state does not expose the Agent intent recognition system.'
}
foreach ($requiredIntentLayer in @('L0', 'L1', 'L2', 'L3')) {
    if ($requiredIntentLayer -notin @($state.agent_intent_recognition.layers)) {
        throw "Agent intent recognition is missing layer: $requiredIntentLayer"
    }
}
foreach ($requiredIntentRoute in @('CandidateReport', 'CompleteIteration', 'SearchMemory')) {
    if ($requiredIntentRoute -notin @($state.agent_intent_recognition.routes)) {
        throw "Agent intent recognition is missing route: $requiredIntentRoute"
    }
}
if ($state.agent_intent_recognition.no_authority_elevation_rule -notmatch 'never grant authority') {
    throw 'Agent intent recognition does not preserve the authority boundary.'
}
if ($state.agent_loop_policy.model -ne 'global-experience-agent-loop-policy' -or $state.agent_loop_policy.owner -ne 'codex-self-evolution') {
    throw 'Agent harness state does not expose the Agent loop policy.'
}
foreach ($requiredLoopPhase in @('plan', 'act', 'observe', 'reflect', 'settle')) {
    if ($requiredLoopPhase -notin @($state.agent_loop_policy.phases)) {
        throw "Agent loop policy is missing phase: $requiredLoopPhase"
    }
}
if ($state.agent_loop_policy.max_iterations -ne 10 -or @($state.agent_loop_policy.stop_conditions).Count -lt 3) {
    throw 'Agent loop policy does not preserve bounded iteration and multi-condition termination.'
}
if ($state.agent_loop_policy.owner_gate_rule -notmatch 'owner tool gates') {
    throw 'Agent loop policy does not preserve owner tool gates.'
}
$timingTerms = @('TaskStartedAt', 'HostWorkedSeconds', 'New-AgentTiming', 'task_wall_clock_seconds', 'operation_wall_clock_seconds', 'agent_session_wall_clock_seconds', 'not-measured; caller-task-start-required')
foreach ($timingTerm in $timingTerms) {
    if ($contents.globalExperienceAgentRuntime -notmatch [regex]::Escape($timingTerm)) {
        throw "Executable global experience agent runtime is missing layered timing contract: $timingTerm"
    }
}
if ($contents.globalExperienceAgent -notmatch 'TaskStartedAt' -or $contents.globalExperienceAgent -notmatch 'HostWorkedSeconds') {
    throw 'Global experience agent controller does not expose caller task timing inputs.'
}
if ($state.agent_transport_recovery.model -ne 'agent-transport-recovery-policy' -or $state.agent_transport_recovery.classifier -ne 'agent/40-runtime/Get-AgentTransportRecoverySignal.ps1' -or $state.agent_transport_recovery.host_detector -ne 'agent/40-runtime/Get-AgentHostRecoverySignal.ps1') {
    throw 'Agent harness state does not expose the transport recovery classifier.'
}
if ($state.agent_transport_recovery.restart_required_exit -ne 'restart-required' -or $state.agent_transport_recovery.automatic_retry -ne 'disabled_after_classification') {
    throw 'Agent transport recovery does not preserve the restart-required stop boundary.'
}
if ($state.agent_doc_parse_pipeline.model -ne 'agent-doc-parse-pipeline' -or $state.agent_doc_parse_pipeline.owner -ne 'codex-office-cli') {
    throw 'Agent harness state does not expose the owner-routed Agent document parse pipeline.'
}
foreach ($requiredDocParseLayer in @('L1-schema', 'L2-routing', 'L3-pdf-strategy', 'L4-ocr-gated-degradation', 'L5-excel', 'L6-word', 'L7-validation')) {
    if ($requiredDocParseLayer -notin @($state.agent_doc_parse_pipeline.layers)) {
        throw "Agent document parse pipeline is missing layer: $requiredDocParseLayer"
    }
}
foreach ($requiredDocParseCheck in @('content', 'structure', 'performance', 'robustness')) {
    if ($requiredDocParseCheck -notin @($state.agent_doc_parse_pipeline.validation_quadrants)) {
        throw "Agent document parse pipeline is missing validation quadrant: $requiredDocParseCheck"
    }
}
foreach ($requiredBranch in @('current task turn', 'compacted handoff', 'iteration proof', 'release evidence')) {
    if ($requiredBranch -notin @($state.session_tree.branch_units)) {
        throw "Agent session tree is missing branch unit: $requiredBranch"
    }
}
foreach ($requiredSettlement in @('task output exists', 'narrowest proving check passed', 'residual risks are named')) {
    if ($requiredSettlement -notin @($state.completion_contract.settled_when)) {
        throw "Agent completion contract is missing settlement condition: $requiredSettlement"
    }
}
foreach ($requiredStorageUnit in @('tree entry', 'leaf entry', 'compaction checkpoint', 'branch summary', 'tool result evidence')) {
    if ($requiredStorageUnit -notin @($state.durability_model.storage_units)) {
        throw "Agent durability model is missing storage unit: $requiredStorageUnit"
    }
}
foreach ($requiredDurableEntry in @('queue_enqueued', 'queue_consumed', 'pending_write_enqueued', 'pending_write_applied', 'operation_started', 'operation_interrupted', 'error_feedback_recorded', 'restart_prompted', 'restart_recovery_resumed', 'subagent_restart_required', 'turn_started', 'provider_request_started', 'tool_call_started')) {
    if ($requiredDurableEntry -notin @($state.durable_recovery.durable_entries)) {
        throw "Agent durable recovery is missing entry: $requiredDurableEntry"
    }
}
foreach ($requiredEntryType in @('session', 'message', 'model_change', 'thinking_level_change', 'compaction', 'branch_summary', 'custom', 'custom_message', 'label', 'session_info', 'leaf')) {
    if ($requiredEntryType -notin @($state.session_entry_schema.entry_types)) {
        throw "Agent session entry schema is missing type: $requiredEntryType"
    }
}
foreach ($requiredAbortEffect in @('clear steer queue', 'clear followUp queue', 'preserve nextTurn queue', 'preserve pending session writes')) {
    if ($requiredAbortEffect -notin @($state.abort_semantics.effects)) {
        throw "Agent abort semantics are missing effect: $requiredAbortEffect"
    }
}
foreach ($requiredRetryEvent in @('retry_scheduled', 'retry_attempt_start', 'retry_finished')) {
    if ($requiredRetryEvent -notin @($state.compaction_and_branching.retry_events)) {
        throw "Agent compaction/branching is missing retry event: $requiredRetryEvent"
    }
}
foreach ($requiredNonRetryable in @('credential mutation', 'installation', 'publication', 'remote release', 'non-idempotent tool call')) {
    if ($requiredNonRetryable -notin @($state.retry_and_recovery.non_retryable_without_owner_proof)) {
        throw "Agent retry policy is missing non-retryable boundary: $requiredNonRetryable"
    }
}
if ($state.retry_and_recovery.transport_recovery.known_failure_action -notmatch 'restart-required' -or $state.retry_and_recovery.transport_recovery.child_propagation -notmatch 'parent') {
    throw 'Agent retry policy does not propagate restart-required transport failures to the parent.'
}
if ($state.retry_and_recovery.host_watchdog.detector -ne 'agent/40-runtime/Get-AgentHostRecoverySignal.ps1' -or $state.retry_and_recovery.host_watchdog.action -notmatch 'without force-kill') {
    throw 'Agent retry policy does not expose the host watchdog contract.'
}
$topologyJson = & (Join-Path $root 'scripts\Test-AgentSystemTopology.ps1') -RepositoryRoot $root
$topology = $topologyJson | ConvertFrom-Json
if ($topology.status -ne 'passed' -or $topology.model -ne 'agent-system') {
    throw 'Agent system topology contract did not pass.'
}
if ($state.global_experience_agent.controller -ne 'agent\40-runtime\Invoke-GlobalExperienceAgent.ps1') {
    throw 'Agent harness state does not expose the global experience agent controller.'
}
if ($state.owner_network.model -ne 'global-experience-agent-owner-network' -or $state.owner_network.active_owner_count -ne 23) {
    throw 'Agent harness state does not expose all 23 active owner connections.'
}
if ($state.agent_registry.model -ne 'global-experience-agent-registry' -or $state.agent_registry.root_agent.id -ne 'global-experience-agent' -or @($state.agent_registry.concept_agents).Count -lt 1 -or @($state.agent_registry.specialist_agents).Count -ne 23) { throw 'Agent harness state does not expose the root, concept, and specialist Agent registry.' }
if ($state.interface_policy.model -ne 'global-experience-agent-interface-policy' -or $state.interface_policy.default_decision -ne 'deny' -or @($state.interface_policy.interfaces).Count -ne 4 -or $state.interface_policy.structure_change_contract.tool_gate -ne 'agent_structure') { throw 'Agent harness state does not expose the guarded human, LLM, internal, and global-control interfaces.' }
$registryTest = (& (Join-Path $root 'scripts\Test-GlobalExperienceAgentRegistry.ps1') -RepositoryRoot $root) | ConvertFrom-Json
$expectedRegistryChildren = 2 + @($state.agent_registry.child_agent_profiles).Count
if ($registryTest.status -ne 'passed' -or $registryTest.cross_caller_history -lt 4 -or $registryTest.children -ne $expectedRegistryChildren) { throw 'Agent harness caller/model portability and subagent lifecycle did not pass.' }
$ownerConnections = (& (Join-Path $root 'scripts\Test-AgentOwnerConnections.ps1') -RepositoryRoot $root) | ConvertFrom-Json
if ($ownerConnections.status -ne 'passed' -or $ownerConnections.reachable_from_harness -ne 23 -or $ownerConnections.returnable_to_harness -ne 23) {
    throw 'Agent harness owner network is not fully reachable and returnable.'
}
$transportTest = (& (Join-Path $root 'scripts\Test-AgentTransportRecovery.ps1') -RepositoryRoot $root) | ConvertFrom-Json
if ($transportTest.status -ne 'passed' -or $transportTest.fatal_classifier -ne 'restart-required' -or $transportTest.business_classifier -ne 'not-transport-failure' -or $transportTest.child_propagation -ne 'restart-required') {
    throw 'Agent transport recovery classifier or child propagation test did not pass.'
}
$hostTransportTest = (& (Join-Path $root 'scripts\Test-AgentHostTransportRecovery.ps1') -RepositoryRoot $root) | ConvertFrom-Json
if ($hostTransportTest.status -ne 'passed' -or $hostTransportTest.stale_snapshot -ne 'host-stall-suspected' -or $hostTransportTest.transport_snapshot -ne 'transport-disconnect') {
    throw 'Agent host watchdog test did not pass.'
}

[pscustomobject]@{
    status = 'passed'
    source = 'earendil-works/pi'
    required_terms = $requiredTerminology.Count
    checked_files = $paths.Count
} | ConvertTo-Json -Compress
