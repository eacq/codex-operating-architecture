[CmdletBinding()]
param(
    [string]$RepositoryRoot = 'F:\codex'
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath $RepositoryRoot).Path
$manifestPath = Join-Path $root 'config\agent-system.json'
$agentSystemManifest = $null
if (Test-Path -LiteralPath $manifestPath -PathType Leaf) {
    $agentSystemManifest = Get-Content -LiteralPath $manifestPath -Raw -Encoding UTF8 | ConvertFrom-Json
}
$agentFilesystemPath = if ($agentSystemManifest -and $agentSystemManifest.filesystem.manifest) { Join-Path $root ([string]$agentSystemManifest.filesystem.manifest) } else { $null }
$agentFilesystem = if ($agentFilesystemPath -and (Test-Path -LiteralPath $agentFilesystemPath -PathType Leaf)) {
    Get-Content -LiteralPath $agentFilesystemPath -Raw -Encoding UTF8 | ConvertFrom-Json
} else { $null }
$lastAgentRunPath = Join-Path $root '.codex\project\global-experience-agent-last-run.json'
$lastAgentRun = $null
if (Test-Path -LiteralPath $lastAgentRunPath -PathType Leaf) {
    try {
        $lastAgentRun = Get-Content -LiteralPath $lastAgentRunPath -Raw -Encoding UTF8 | ConvertFrom-Json
    } catch {
        $lastAgentRun = $null
    }
}

function Test-RelativeFile([string]$RelativePath) {
    $path = Join-Path $root $RelativePath
    [pscustomobject]@{
        path = $RelativePath
        exists = Test-Path -LiteralPath $path -PathType Leaf
    }
}

$piRoot = Join-Path $root '.runtime\work\network-learning\earendil-works-pi'
$piCommit = $null
$piLocalHead = $null
if (Test-Path -LiteralPath (Join-Path $piRoot '.git') -PathType Container) {
    try {
        $piLocalHead = (& git -C $piRoot rev-parse HEAD 2>$null).Trim()
        $piCommit = (& git -C $piRoot rev-parse origin/main 2>$null).Trim()
        if (-not $piCommit) { $piCommit = $piLocalHead }
    } catch {
        $piCommit = $null
    }
}

$informationUnitPaths = @(
    'config\agent-system.json'
    @($agentSystemManifest.resources.information_units)
) | ForEach-Object { [string]$_ } | Sort-Object -Unique
$informationUnits = @($informationUnitPaths | ForEach-Object { Test-RelativeFile $_ })

$functionalUnitPaths = @(
    @($agentSystemManifest.resources.functional_units)
    @($agentSystemManifest.harness.interfaces)
) | ForEach-Object { [string]$_ } | Sort-Object -Unique
$functionalUnits = @($functionalUnitPaths | ForEach-Object { Test-RelativeFile $_ })

$memoryOperations = @('StoreMemory', 'SearchMemory', 'ConsolidateMemory', 'RenderMemorySnapshot')
$intentPolicyPath = 'config/agent-intent-policy.json'
$intentPolicy = $null
if (Test-Path -LiteralPath (Join-Path $root $intentPolicyPath) -PathType Leaf) {
    $intentPolicy = Get-Content -LiteralPath (Join-Path $root $intentPolicyPath) -Raw -Encoding UTF8 | ConvertFrom-Json
}
$memoryBackendPath = if ($agentFilesystem -and $agentFilesystem.canonical_surfaces.memory_backend) {
    [string]$agentFilesystem.canonical_surfaces.memory_backend
} else {
    'agent/40-runtime/Invoke-AgentMemoryStore.py'
}
$memorySkillPolicyPath = if ($agentFilesystem -and $agentFilesystem.canonical_surfaces.memory_skill_policy) {
    [string]$agentFilesystem.canonical_surfaces.memory_skill_policy
} else {
    'config/agent-memory-skill-policy.json'
}
$memoryKnowledgePath = 'knowledge-vault/30-Knowledge/Agent Memory System.md'
$memoryStatePath = if ($agentFilesystem) {
    $localMemory = @($agentFilesystem.local_state) | Where-Object { $_.id -eq 'agent-memory' } | Select-Object -First 1
    if ($localMemory) { [string]$localMemory.path } else { '.codex/project/agent-memory' }
} else {
    '.codex/project/agent-memory'
}
$agentMemory = [pscustomobject]@{
    model = 'agent-memory-system'
    backend = 'sqlite-fts5'
    backend_path = $memoryBackendPath
    runtime_state_path = $memoryStatePath
    snapshot_path = (Join-Path $memoryStatePath 'frozen-snapshot.md')
    knowledge_note = $memoryKnowledgePath
    skill_policy = $memorySkillPolicyPath
    operations = $memoryOperations
    memory_types = @('preference', 'decision', 'fix', 'workflow', 'context', 'tool-result', 'error', 'candidate', 'scaffold')
    memory_layers = @('working', 'episodic', 'semantic', 'procedural', 'frozen', 'archived')
    capabilities = @('typed-store', 'fts5-search', 'ttl-expiry', 'supersession', 'consolidation', 'frozen-snapshot-rendering', 'search-before-store', 'upsert-or-supersede', 'on-demand-retrieval', 'memory-action-trace-review')
    diagnostics = @('write_search_ratio', 'memory_growth_per_step', 'redundant_write_ratio', 'memory_context_ratio', 'delayed_memory_failure_gap')
    interface_rule = 'human, llm, and internal-functional-unit interfaces may use registered memory operations under current authority'
    structure_rule = 'memory-system structural mutation is denied unless routed through global-control, global-structure authority, and the agent_structure gate'
    privacy_rule = 'runtime database and snapshots remain ignored local state; tracked files contain only backend code, contracts, tests, and knowledge summaries'
}

$agentIntentRecognition = [pscustomobject]@{
    model = 'global-experience-agent-intent-policy'
    policy = $intentPolicyPath
    source = if ($intentPolicy) { $intentPolicy.source.repository } else { $null }
    source_path = if ($intentPolicy) { $intentPolicy.source.path } else { $null }
    operation = 'ClassifyIntent'
    auto_route_rule = 'Auto requests are classified before operation permission evaluation; the resolved operation still passes through interface policy'
    layers = if ($intentPolicy) { @($intentPolicy.layers.id) } else { @() }
    routes = if ($intentPolicy) { @($intentPolicy.routes.operation) } else { @() }
    l2_status = if ($intentPolicy) { [string]$intentPolicy.safety.llm_adapter_status } else { $null }
    event = 'intent_classified'
    no_authority_elevation_rule = 'intent labels never grant authority or bypass owner gates'
}

$agentLoopPolicyPath = 'config/agent-loop-policy.json'
$agentLoopPolicy = $null
if (Test-Path -LiteralPath (Join-Path $root $agentLoopPolicyPath) -PathType Leaf) {
    $agentLoopPolicy = Get-Content -LiteralPath (Join-Path $root $agentLoopPolicyPath) -Raw -Encoding UTF8 | ConvertFrom-Json
}
$agentLoopPolicyState = [pscustomobject]@{
    model = if ($agentLoopPolicy) { [string]$agentLoopPolicy.model } else { 'global-experience-agent-loop-policy' }
    owner = if ($agentLoopPolicy) { [string]$agentLoopPolicy.owner } else { 'codex-self-evolution' }
    source = if ($agentLoopPolicy) { $agentLoopPolicy.source } else { $null }
    policy = $agentLoopPolicyPath
    knowledge_note = 'knowledge-vault/30-Knowledge/Agent Loop System.md'
    runtime = if ($agentLoopPolicy) { [string]$agentLoopPolicy.control_plane.local_runtime } else { 'agent/40-runtime/Invoke-GlobalExperienceAgent.ps1' }
    test = if ($agentLoopPolicy) { [string]$agentLoopPolicy.control_plane.test } else { 'scripts/Test-AgentLoopPolicy.ps1' }
    relationship_to_data_plane = if ($agentLoopPolicy) { [string]$agentLoopPolicy.control_plane.relationship_to_c01_c05 } else { $null }
    phases = if ($agentLoopPolicy) { @($agentLoopPolicy.loop_contract.phases) } else { @('plan','act','observe','reflect','settle') }
    phase_mapping = if ($agentLoopPolicy) { $agentLoopPolicy.loop_contract.phase_mapping } else { $null }
    one_step_rule = if ($agentLoopPolicy) { [string]$agentLoopPolicy.loop_contract.one_step_rule } else { 'each operation settles before follow-on work' }
    owner_gate_rule = if ($agentLoopPolicy) { [string]$agentLoopPolicy.loop_contract.owner_rule } else { 'owner tool gates remain authoritative' }
    max_iterations = if ($agentLoopPolicy) { [int]$agentLoopPolicy.control_points.max_iterations.default } else { 10 }
    error_recovery = if ($agentLoopPolicy) { $agentLoopPolicy.control_points.error_recovery } else { $null }
    context_budget = if ($agentLoopPolicy) { $agentLoopPolicy.control_points.context_budget } else { $null }
    stop_conditions = if ($agentLoopPolicy) { @($agentLoopPolicy.control_points.termination.stop_conditions) } else { @('finish_action','final_answer_signal','max_iterations') }
    harness_requirements = if ($agentLoopPolicy) { $agentLoopPolicy.harness_requirements } else { $null }
    gated_candidates = if ($agentLoopPolicy) { @($agentLoopPolicy.authority_boundary.requires_owner_gate) } else { @() }
    privacy_rule = if ($agentLoopPolicy) { [string]$agentLoopPolicy.authority_boundary.privacy_rule } else { 'safe metadata only' }
    evaluation_contract = if ($agentLoopPolicy) { $agentLoopPolicy.evaluation_contract } else { $null }
}

$transportRecoveryPolicyPath = 'config/agent-transport-recovery-policy.json'
$transportRecoveryPolicy = $null
if (Test-Path -LiteralPath (Join-Path $root $transportRecoveryPolicyPath) -PathType Leaf) {
    $transportRecoveryPolicy = Get-Content -LiteralPath (Join-Path $root $transportRecoveryPolicyPath) -Raw -Encoding UTF8 | ConvertFrom-Json
}
$agentTransportRecovery = [pscustomobject]@{
    model = if ($transportRecoveryPolicy) { [string]$transportRecoveryPolicy.model } else { 'agent-transport-recovery-policy' }
    owner = if ($transportRecoveryPolicy) { [string]$transportRecoveryPolicy.owner } else { 'codex-self-evolution' }
    policy = $transportRecoveryPolicyPath
    classifier = if ($transportRecoveryPolicy) { [string]$transportRecoveryPolicy.verification.classifier } else { 'agent/40-runtime/Get-AgentTransportRecoverySignal.ps1' }
    host_detector = if ($transportRecoveryPolicy) { [string]$transportRecoveryPolicy.verification.host_detector } else { 'agent/40-runtime/Get-AgentHostRecoverySignal.ps1' }
    applies_to = if ($transportRecoveryPolicy) { @($transportRecoveryPolicy.applies_to) } else { @('codex','global-experience-agent','child-agent') }
    fatal_pattern_count = if ($transportRecoveryPolicy) { @($transportRecoveryPolicy.detection.fatal_patterns).Count } else { 0 }
    automatic_retry = if ($transportRecoveryPolicy) { [string]$transportRecoveryPolicy.recovery.automatic_retry } else { 'disabled_after_classification' }
    restart_required_exit = if ($transportRecoveryPolicy) { [string]$transportRecoveryPolicy.recovery.exit_type } else { 'restart-required' }
    preserve = if ($transportRecoveryPolicy) { @($transportRecoveryPolicy.recovery.preserve_session, $transportRecoveryPolicy.recovery.preserve_pending_writes) } else { @($true, $true) }
    user_prompt = if ($transportRecoveryPolicy) { [string]$transportRecoveryPolicy.user_prompt.message } else { $null }
    host_watchdog = if ($transportRecoveryPolicy) { $transportRecoveryPolicy.detection.host_watchdog } else { $null }
}

$agentDocParsePipeline = [pscustomobject]@{
    model = 'agent-doc-parse-pipeline'
    owner = 'codex-office-cli'
    source = 'LesterYu0/feynman-build-workshop'
    source_path = 'episodes/03-doc-parse-pipeline'
    knowledge_note = 'knowledge-vault/30-Knowledge/Agent Document Parse Pipeline.md'
    subskill = 'skills/codex-office-cli/subskills/doc-parse-pipeline/SKILL.md'
    runner = 'skills/codex-office-cli/scripts/Invoke-AgentDocParsePipeline.ps1'
    test = 'scripts/Test-AgentDocParsePipeline.ps1'
    layers = @('L1-schema', 'L2-routing', 'L3-pdf-strategy', 'L4-ocr-gated-degradation', 'L5-excel', 'L6-word', 'L7-validation')
    validation_quadrants = @('content', 'structure', 'performance', 'robustness')
    output_schema = @('Document', 'Chunk', 'strategy', 'validation', 'typed-error')
    gate_rule = 'OCR, MinerU, VLM, dependency installation, runtime mutation, and credentialed extraction remain routed through existing owner gates'
    memory_rule = 'parsed documents may enter Agent memory or knowledge only with owner route, strategy, validation result, and unresolved gated capability recorded'
}

$chunkingRetrievalPolicyPath = 'config/agent-chunking-retrieval-policy.json'
$chunkingRetrievalPolicy = $null
if (Test-Path -LiteralPath (Join-Path $root $chunkingRetrievalPolicyPath) -PathType Leaf) {
    $chunkingRetrievalPolicy = Get-Content -LiteralPath (Join-Path $root $chunkingRetrievalPolicyPath) -Raw -Encoding UTF8 | ConvertFrom-Json
}
$agentChunkingRetrieval = [pscustomobject]@{
    model = if ($chunkingRetrievalPolicy) { [string]$chunkingRetrievalPolicy.model } else { 'agent-chunking-retrieval-policy' }
    owner = if ($chunkingRetrievalPolicy) { [string]$chunkingRetrievalPolicy.owner } else { 'codex-information-gathering' }
    source = if ($chunkingRetrievalPolicy) { $chunkingRetrievalPolicy.source } else { $null }
    policy = $chunkingRetrievalPolicyPath
    knowledge_note = 'knowledge-vault/30-Knowledge/Agent Chunking Retrieval System.md'
    subskill = 'skills/codex-information-gathering/subskills/chunking-retrieval/SKILL.md'
    runner = 'skills/codex-information-gathering/scripts/Invoke-AgentChunkingRetrieval.ps1'
    test = 'scripts/Test-AgentChunkingRetrieval.ps1'
    input_contract = if ($chunkingRetrievalPolicy) { $chunkingRetrievalPolicy.input_contract } else { $null }
    layers = if ($chunkingRetrievalPolicy) { @($chunkingRetrievalPolicy.layer_policy | ForEach-Object { [string]$_.layer }) } else { @('L1','L2','L3') }
    local_baseline = if ($chunkingRetrievalPolicy) { [string](@($chunkingRetrievalPolicy.layer_policy | Where-Object { $_.layer -eq 'L1' } | Select-Object -First 1).local_baseline) } else { 'recursive chunking plus BM25-lite lexical retrieval and deterministic rerank' }
    metrics = if ($chunkingRetrievalPolicy) { @($chunkingRetrievalPolicy.evaluation_contract.metrics) } else { @('recall_at_1','recall_at_3','recall_at_5','mrr','answer_accuracy') }
    rerank_calibration = if ($chunkingRetrievalPolicy) { $chunkingRetrievalPolicy.rerank_calibration_contract } else { $null }
    calibration = if ($chunkingRetrievalPolicy) { $chunkingRetrievalPolicy.rerank_calibration_contract.calibration } else { $null }
    gated_candidates = if ($chunkingRetrievalPolicy) { @($chunkingRetrievalPolicy.authority_boundary.requires_owner_gate) } else { @() }
    source_verification_rule = if ($chunkingRetrievalPolicy) { [string]$chunkingRetrievalPolicy.authority_boundary.source_verification_rule } else { 'retrieved chunks route attention; source files, parsed document validation, and tests remain final proof' }
}

$codebaseMemoryPolicyPath = 'config/agent-codebase-memory-policy.json'
$codebaseMemoryPolicy = $null
if (Test-Path -LiteralPath (Join-Path $root $codebaseMemoryPolicyPath) -PathType Leaf) {
    $codebaseMemoryPolicy = Get-Content -LiteralPath (Join-Path $root $codebaseMemoryPolicyPath) -Raw -Encoding UTF8 | ConvertFrom-Json
}
$agentCodebaseMemory = [pscustomobject]@{
    model = if ($codebaseMemoryPolicy) { [string]$codebaseMemoryPolicy.model } else { 'agent-codebase-memory-policy' }
    owner = if ($codebaseMemoryPolicy) { [string]$codebaseMemoryPolicy.owner } else { 'codex-information-gathering' }
    entry_owner = if ($codebaseMemoryPolicy) { [string]$codebaseMemoryPolicy.entry_owner } else { 'codex-self-evolution' }
    policy = $codebaseMemoryPolicyPath
    canonical_project = if ($codebaseMemoryPolicy) { $codebaseMemoryPolicy.canonical_project } else { $null }
    callable_discovery = if ($codebaseMemoryPolicy) { $codebaseMemoryPolicy.callable_discovery } else { $null }
    allowed_operations = if ($codebaseMemoryPolicy) { @($codebaseMemoryPolicy.allowed_operations) } else { @() }
    lifecycle = if ($codebaseMemoryPolicy) { @($codebaseMemoryPolicy.agent_use_lifecycle) } else { @() }
    authority_boundary = if ($codebaseMemoryPolicy) { $codebaseMemoryPolicy.authority_boundary } else { $null }
    source_verification_rule = if ($codebaseMemoryPolicy) { [string]$codebaseMemoryPolicy.source_verification_rule } else { 'graph output routes attention; current source files and tests remain final proof' }
    validation = if ($codebaseMemoryPolicy) { $codebaseMemoryPolicy.single_project_validation } else { $null }
}

$ownerNetworkPath = [string]$agentSystemManifest.owner_network.source
$ownerNetwork = $null
if ($ownerNetworkPath -and (Test-Path -LiteralPath (Join-Path $root $ownerNetworkPath) -PathType Leaf)) {
    $ownerNetwork = Get-Content -LiteralPath (Join-Path $root $ownerNetworkPath) -Raw -Encoding UTF8 | ConvertFrom-Json
}
$agentRegistryPath = [string]$agentSystemManifest.agent_registry.source
$agentRegistry = $null
if ($agentRegistryPath -and (Test-Path -LiteralPath (Join-Path $root $agentRegistryPath) -PathType Leaf)) {
    $agentRegistry = Get-Content -LiteralPath (Join-Path $root $agentRegistryPath) -Raw -Encoding UTF8 | ConvertFrom-Json
}
$interfacePolicyPath = [string]$agentSystemManifest.agent_registry.interface_policy
$interfacePolicy = $null
if ($interfacePolicyPath -and (Test-Path -LiteralPath (Join-Path $root $interfacePolicyPath) -PathType Leaf)) {
    $interfacePolicy = Get-Content -LiteralPath (Join-Path $root $interfacePolicyPath) -Raw -Encoding UTF8 | ConvertFrom-Json
}
$structuralOptimizationPolicyPath = 'config/agent-structural-optimization-policy.json'
$structuralOptimizationPolicy = $null
if (Test-Path -LiteralPath (Join-Path $root $structuralOptimizationPolicyPath) -PathType Leaf) {
    $structuralOptimizationPolicy = Get-Content -LiteralPath (Join-Path $root $structuralOptimizationPolicyPath) -Raw -Encoding UTF8 | ConvertFrom-Json
}

$toolGates = @($agentSystemManifest.tool_gates | ForEach-Object {
    [pscustomobject]@{
        name = [string]$_.name
        owner = [string]$_.owner
        lifecycle = @($_.lifecycle)
    }
})

$sessionEvidence = @(
    'conversation-continuity catalog',
    'project lifecycle state',
    'candidate records',
    'error feedback reports',
    'rollback snapshots',
    'publication envelope',
    'release evidence'
)

$savePoints = @(
    'verified rollback snapshot',
    'complete iteration proof',
    'publication envelope',
    'validated Git commit',
    'verified release evidence'
)

$extensionSurfaces = @(
    'imported upstream packages',
    'MCP servers',
    'hooks',
    'project-local executable resources',
    'runtime plugins',
    'subagent patterns'
)

$agentEntry = [pscustomobject]@{
    default_route = 'every Codex project entry starts or resumes Global Experience Agent durable work through agent/40-runtime/Invoke-GlobalExperienceAgent.ps1 after codex-self-evolution project entry unless the user explicitly authorizes a turn-level skip'
    startup_policy = [pscustomobject]@{
        default = 'auto-start-or-resume'
        skip_requires = 'explicit user authorization for this turn'
        startup_operations = @(
            'Run StartWork',
            'Resume',
            'Continue'
        )
        skip_does_not_bypass = @(
            'codex-self-evolution lifecycle entry',
            'Codebase Memory F-codex startup and indexing when applicable',
            'safety, privacy, rollback, and validation gates',
            'owner routing',
            'permission checks'
        )
        authority_boundary = 'automatic Agent startup records durable work and retrieves relevant records only; it does not authorize Git, release, installation, credential, publication, destructive cleanup, top-owner, or Agent-structure mutation'
    }
    applies_to = @(
        'all Codex project entries by default unless explicit user-authorized skip',
        'global experience system',
        'experience capture',
        'learning and external method adoption',
        'owner or skill structure',
        'information and functional unit topology',
        'agent architecture',
        'global iteration',
        'auto-Git or release synchronization'
    )
    entry_protocol = @(
        'load project authority',
        'refresh F-codex graph when callable',
        'retrieve relevant Agent memory when useful',
        'classify Auto intent before operation permission evaluation',
        'create bounded task contract',
        'select smallest owner/resource set',
        'create turn snapshot',
        'route gated actions to owners'
    )
    transfer_rule = 'legacy skill-first global experience work is treated as a harness resource call; the skill remains the owner, but the harness owns entry state, resource selection, tool gates, and closeout'
}

$agentLoop = @(
    [pscustomobject]@{
        phase = 'intake'
        event = 'user_goal_received'
        owner = 'codex-self-evolution'
        output = 'bounded task contract with authority and quality floor'
    }
    [pscustomobject]@{
        phase = 'orient'
        event = 'experience_context_loaded'
        owner = 'codex-self-evolution'
        output = 'project authority, verified experience, graph evidence, and required skills'
    }
    [pscustomobject]@{
        phase = 'select'
        event = 'agent_resources_selected'
        owner = 'codex-self-evolution'
        output = 'smallest accountable owner set and progressive-disclosure files'
    }
    [pscustomobject]@{
        phase = 'act'
        event = 'tool_gate_requested'
        owner = 'specialist owner'
        output = 'approved, denied, deferred, or evidence-only action'
    }
    [pscustomobject]@{
        phase = 'observe'
        event = 'tool_result_recorded'
        owner = 'executing owner'
        output = 'current-task evidence, failure report, or next bounded step'
    }
    [pscustomobject]@{
        phase = 'settle'
        event = 'save_point_committed'
        owner = 'verification owner'
        output = 'validated state, rollback boundary, and closeout evidence'
    }
)

$agentExitAlignment = $agentSystemManifest.agent_exit_alignment

$humanReviewAndEvals = [pscustomobject]@{
    review_decisions = @(
        'approve',
        'edit',
        'reject',
        'respond'
    )
    review_rule = 'human review pauses at authority boundaries, preserves durable state, and resumes only from an accepted decision or a clarified response'
    eval_surfaces = @(
        'topology contract tests',
        'harness contract tests',
        'global experience agent run test',
        'architecture diagram test',
        'global validation',
        'global install validation',
        'candidate report',
        'complete iteration proof'
    )
    eval_rule = 'agent behavior changes must have repeatable tests or dataset-like fixtures before they are treated as implemented functionality'
}

$resourceSelector = [pscustomobject]@{
    ladder = @(
        'current user authority',
        'project lifecycle files',
        'verified project experience',
        'knowledge and learning indexes',
        'codebase graph when callable',
        'owner skills and deterministic scripts',
        'targeted fresh external evidence'
    )
    selection_rule = 'load the smallest resource set that can decide the next bounded action'
    no_regression_rule = 'never conserve context by skipping safety, privacy, authority, rollback, or validation gates'
}

$sessionTree = [pscustomobject]@{
    branch_units = @(
        'current task turn',
        'compacted handoff',
        'project lifecycle state',
        'error feedback report',
        'candidate record',
        'iteration proof',
        'release evidence'
    )
    persistence_policy = 'persist metadata, decisions, evidence paths, and verification results; do not persist raw private sessions or secrets in Git'
    merge_policy = 'a branch can affect future routing only after a named verifier accepts its save point'
}

$toolCallLifecycle = @(
    'requested',
    'preflighted',
    'authorized',
    'executed',
    'observed',
    'verified',
    'captured_or_reported'
)

$harnessPhases = @(
    'idle',
    'turn',
    'compaction',
    'branch_summary',
    'retry'
)

$runtimeConfig = [pscustomobject]@{
    latest_config_units = @(
        'active model/provider choice',
        'thinking or reasoning level',
        'available tool gates',
        'active tool-gate subset',
        'selected resources',
        'stream or execution options',
        'system prompt or project instructions'
    )
    getter_rule = 'reads return the latest harness configuration for future routing, not the in-flight proof snapshot'
    setter_rule = 'runtime-like changes made during a turn update the next snapshot at a save point and never rewrite the active evidence request'
}

$turnSnapshot = [pscustomobject]@{
    snapshot_units = @(
        'persisted session evidence',
        'resolved resources',
        'resolved project instructions',
        'model/provider metadata',
        'thinking level',
        'all available tools',
        'active tools',
        'execution options',
        'derived session id'
    )
    creation_rule = 'create one immutable decision snapshot for each bounded task turn or verification proof'
    save_point_refresh_rule = 'after assistant/tool-result completion, refresh future context/model/tool/resource state before another provider-like step'
}

$queueOperations = [pscustomobject]@{
    turn_safe_operations = @(
        'steer',
        'followUp',
        'nextTurn',
        'abort',
        'runtime config setters'
    )
    structural_operations = @(
        'prompt',
        'skill',
        'promptFromTemplate',
        'compact',
        'navigateTree'
    )
    busy_rule = 'structural operations are rejected while busy; queue operations are accepted only at documented safe points'
    drain_rule = 'queue drains are ordered and evidence-bearing; failed queue notifications roll back or route to error feedback'
}

$pendingSessionWrites = [pscustomobject]@{
    write_shapes = @(
        'candidate session entry without generated id',
        'pending write enqueue record',
        'pending write applied record',
        'deterministic target reference'
    )
    persistence_rule = 'accepted pending writes are durable before public success is reported'
    flush_points = @(
        'save point',
        'operation settlement',
        'failure cleanup'
    )
    ordering_rule = 'agent-emitted messages and tool results are persisted before queued extension or lifecycle writes for that turn'
}

$toolRegistry = [pscustomobject]@{
    registry_units = @(
        'tool gate definitions',
        'tool owner',
        'active tool names',
        'idempotency metadata',
        'retry-safety metadata',
        'provenance'
    )
    read_update_semantics = 'tool reads expose current registry state; active-tool updates validate uniqueness, existence, owner, and authority before commit'
    persistence_rule = 'active tool changes are branch-scoped durable configuration when they affect future routing'
    rejection_rule = 'duplicate tool names, duplicate active names, invalid active tools, and ungated side effects are rejected'
}

$modelRegistry = [pscustomobject]@{
    registry_units = @(
        'provider id',
        'model id',
        'api identifier',
        'auth source label',
        'last-known model list',
        'explicit refresh boundary',
        'stream behavior owner'
    )
    provider_rule = 'providers own metadata, auth, model listing, and stream behavior; the harness selects models through a registry facade'
    refresh_rule = 'model reads use last-known state; dynamic refresh is explicit, side-effect-free discovery'
    auth_rule = 'auth failures remain visible and redacted; silent fallback after stored-credential failure is not allowed'
}

$hookSystem = [pscustomobject]@{
    event_model = @(
        'typed event',
        'observer',
        'result-producing handler',
        'event-specific reducer',
        'cleanup',
        'source metadata',
        'facade context'
    )
    observer_rule = 'observers are passive and their returns are ignored'
    handler_rule = 'result-producing handlers reduce by event-specific semantics such as transform chaining, patch accumulation, first cancel, or early block'
    context_rule = 'hooks receive stable facades rather than raw internals or unordered session writes'
    error_rule = 'hook failures after commit do not roll back committed state; they route through normalized harness or error-feedback handling'
}

$observability = [pscustomobject]@{
    event_contract = @(
        'trace id',
        'span id',
        'parent span id',
        'start',
        'end',
        'error',
        'safe event payload'
    )
    minimal_events = @(
        'pi.agent.prompt',
        'pi.agent.skill',
        'pi.agent.compaction',
        'pi.agent.branch_navigation',
        'pi.agent.session.append_entry',
        'pi.ai.provider.request'
    )
    adapter_rule = 'core lifecycle emits stable safe events; runtime adapters decide whether to bridge them to logs, OpenTelemetry, Sentry, or local reports'
    redaction_rule = 'prompts, completions, tool args, tool results, shell output, file contents, headers, and secrets are unsafe by default'
}

$durabilityModel = [pscustomobject]@{
    storage_units = @(
        'metadata header',
        'tree entry',
        'leaf entry',
        'compaction checkpoint',
        'branch summary',
        'custom extension entry',
        'tool result evidence'
    )
    local_mapping = @(
        'metadata-only conversation catalog',
        'project lifecycle state',
        'error feedback report',
        'candidate record',
        'iteration proof',
        'release evidence'
    )
    recovery_rule = 'resume only from durable save points; known transport failures before completion are marked restart-required, prompt the user, and preserve state instead of retrying indefinitely'
}

$durableRecovery = [pscustomobject]@{
    durable_entries = @(
        'queue_enqueued',
        'queue_consumed',
        'pending_write_enqueued',
        'pending_write_applied',
        'operation_started',
        'operation_finished',
        'operation_interrupted',
        'error_feedback_recorded',
        'restart_prompted',
        'restart_recovery_resumed',
        'subagent_restart_required',
        'turn_started',
        'turn_finished',
        'provider_request_started',
        'provider_request_finished',
        'tool_call_started',
        'tool_call_finished'
    )
    host_restore_rule = 'the host recreates models, tools, resources, hooks, auth providers, and extension handlers before reducing durable state'
    default_policy = 'mark unfinished provider requests and unsafe tool calls interrupted; retry only from durable boundaries or with owner-proven idempotency'
}

$sessionEntrySchema = [pscustomobject]@{
    version = 'pi-jsonl-tree-v3-aligned'
    entry_types = @(
        'session',
        'message',
        'model_change',
        'thinking_level_change',
        'compaction',
        'branch_summary',
        'custom',
        'custom_message',
        'label',
        'session_info',
        'leaf'
    )
    tree_rule = 'entries form a branchable tree through id, parentId, and durable leaf movement'
    context_rule = 'compaction entries may carry retainedTail so newer checkpoints can rebuild context without walking stale raw history'
}

$abortSemantics = [pscustomobject]@{
    allowed_phase = 'turn'
    effects = @(
        'signal cancellation',
        'clear steer queue',
        'clear followUp queue',
        'preserve nextTurn queue',
        'preserve pending session writes',
        'flush durable writes at save point, settlement, or failure cleanup'
    )
    barrier_rule = 'abort waits for safe settlement and never discards accepted durable writes'
}

$compactionAndBranching = [pscustomobject]@{
    structural_rule = 'compaction and tree navigation are idle-only structural mutations'
    branch_summary_rule = 'branch summaries capture abandoned-branch context before navigation affects future turns'
    retry_events = @(
        'retry_scheduled',
        'retry_attempt_start',
        'retry_finished'
    )
    auto_compaction_rule = 'auto-compaction remains a candidate until a deterministic decision point and no-regression tests exist'
}

$retryAndRecovery = [pscustomobject]@{
    retryable_operations = @(
        'graph preflight',
        'source refresh',
        'compaction or summarization',
        'read-only validation'
    )
    non_retryable_without_owner_proof = @(
        'credential mutation',
        'installation',
        'destructive cleanup',
        'publication',
        'remote release',
        'non-idempotent tool call'
    )
    failure_route = 'structured error feedback before promotion or repeated repair'
    transport_recovery = [pscustomobject]@{
        policy = 'config/agent-transport-recovery-policy.json'
        classifier = 'agent/40-runtime/Get-AgentTransportRecoverySignal.ps1'
        known_failure_action = 'stop automatic retry, persist state, return restart-required prompt'
        resume = 'restart Codex or affected host, then Resume before Continue'
        child_propagation = 'JoinSubagent returns restart-required to the parent'
    }
    host_watchdog = [pscustomobject]@{
        detector = 'agent/40-runtime/Get-AgentHostRecoverySignal.ps1'
        threshold_seconds = if ($transportRecoveryPolicy) { [int]$transportRecoveryPolicy.detection.host_watchdog.stall_threshold_seconds } else { 180 }
        stale_condition = 'active inProgress turn with no assistant/tool marker, or with a stale inProgress tool marker'
        action = 'persist host-recovery marker and return restart-required prompt without force-kill'
        snapshot_source = 'codex_app__list_threads plus codex_app__wait_threads'
    }
}

$completionContract = [pscustomobject]@{
    settled_when = @(
        'task output exists',
        'narrowest proving check passed',
        'state changes are scoped and reviewable',
        'residual risks are named',
        'reusable lessons are captured or consciously left as candidates'
    )
    blocked_when = @(
        'required user authority is missing',
        'source evidence cannot be refreshed and local evidence is insufficient',
        'verification fails outside the authorized repair scope',
        'rollback boundary is unclear',
        'known transport failure occurred before a completion marker'
    )
}

$missing = @(
    $informationUnits + $functionalUnits |
        Where-Object { -not $_.exists } |
        ForEach-Object { $_.path }
)

[pscustomObject]@{
    schema_version = 4
    status = if ($missing.Count -eq 0) { 'passed' } else { 'missing-required-surfaces' }
    harness = [pscustomobject]@{
        owner = 'codex-self-evolution'
        model = 'agent-harness'
        source = 'https://github.com/earendil-works/pi'
        source_commit = $piCommit
        local_clone_head = $piLocalHead
        installation_policy = 'learn-as-method-system; do-not-install-runtime-by-default'
    }
    resources = [pscustomobject]@{
        information_units = $informationUnits
        functional_units = $functionalUnits
        selection_policy = 'experience-first progressive disclosure with graph evidence when available'
    }
    agent_memory = $agentMemory
    agent_intent_recognition = $agentIntentRecognition
    agent_loop_policy = $agentLoopPolicyState
    agent_transport_recovery = $agentTransportRecovery
    agent_doc_parse_pipeline = $agentDocParsePipeline
    agent_chunking_retrieval = $agentChunkingRetrieval
    agent_codebase_memory = $agentCodebaseMemory
    tool_gates = $toolGates
    session_evidence = $sessionEvidence
    save_points = $savePoints
    extension_surfaces = $extensionSurfaces
    global_experience_agent_entry = $agentEntry
    agent_system_manifest = $agentSystemManifest
    agent_filesystem = [pscustomobject]@{
        source = if ($agentSystemManifest) { $agentSystemManifest.filesystem.manifest } else { $null }
        model = if ($agentFilesystem) { $agentFilesystem.model } else { $null }
        root = if ($agentFilesystem) { $agentFilesystem.root } else { $null }
        zones = if ($agentFilesystem) { @($agentFilesystem.zones) } else { @() }
        canonical_surfaces = if ($agentFilesystem) { $agentFilesystem.canonical_surfaces } else { $null }
        compatibility_adapters = if ($agentFilesystem) { @($agentFilesystem.compatibility_adapters) } else { @() }
    }
    owner_network = [pscustomobject]@{
        source = $ownerNetworkPath
        model = if ($ownerNetwork) { $ownerNetwork.model } else { $null }
        owners = if ($ownerNetwork) { @($ownerNetwork.owners) } else { @() }
        connections = if ($ownerNetwork) { @($ownerNetwork.connections) } else { @() }
        active_owner_count = if ($ownerNetwork) { @($ownerNetwork.owners).Count } else { 0 }
    }
    agent_registry = [pscustomobject]@{
        source = $agentRegistryPath
        model = if ($agentRegistry) { $agentRegistry.model } else { $null }
        root_agent = if ($agentRegistry) { $agentRegistry.root_agent } else { $null }
        concept_agents = if ($agentRegistry) { @($agentRegistry.concept_agents) } else { @() }
        child_agent_profiles = if ($agentRegistry) { @($agentRegistry.child_agent_profiles) } else { @() }
        specialist_agents = if ($ownerNetwork) { @($ownerNetwork.owners) } else { @() }
        dynamic_subagents = if ($agentRegistry) { $agentRegistry.dynamic_subagents } else { $null }
        continuation = if ($agentRegistry) { $agentRegistry.continuation } else { $null }
    }
    interface_policy = [pscustomobject]@{
        source = $interfacePolicyPath
        model = if ($interfacePolicy) { $interfacePolicy.model } else { $null }
        default_decision = if ($interfacePolicy) { $interfacePolicy.default_decision } else { $null }
        interfaces = if ($interfacePolicy) { @($interfacePolicy.interfaces) } else { @() }
        exits = if ($interfacePolicy) { @($interfacePolicy.exits) } else { @() }
        structure_change_contract = if ($interfacePolicy) { $interfacePolicy.structure_change_contract } else { $null }
    }
    structural_optimization_policy = [pscustomobject]@{
        source = $structuralOptimizationPolicyPath
        model = if ($structuralOptimizationPolicy) { $structuralOptimizationPolicy.model } else { $null }
        baseline_id = if ($structuralOptimizationPolicy) { $structuralOptimizationPolicy.baseline_id } else { $null }
        baseline_version = if ($structuralOptimizationPolicy) { $structuralOptimizationPolicy.baseline_version } else { $null }
        required_optimizations = if ($structuralOptimizationPolicy) { @($structuralOptimizationPolicy.required_optimizations) } else { @() }
        synchronization_controller = if ($structuralOptimizationPolicy) { $structuralOptimizationPolicy.synchronization_controller } else { $null }
        runtime_snapshot_provider = if ($structuralOptimizationPolicy) { $structuralOptimizationPolicy.runtime_snapshot_provider } else { $null }
    }
    global_experience_agent = [pscustomobject]@{
        controller = 'agent\40-runtime\Invoke-GlobalExperienceAgent.ps1'
        runtime = 'agent\40-runtime\Invoke-GlobalExperienceAgentRuntime.ps1'
        test = 'scripts\Test-GlobalExperienceAgent.ps1'
        execution_contract = $agentSystemManifest.agent_runtime
        last_run = $lastAgentRun
    }
    agent_loop = $agentLoop
    agent_exit_alignment = $agentExitAlignment
    human_review_and_evals = $humanReviewAndEvals
    harness_phases = $harnessPhases
    runtime_config = $runtimeConfig
    turn_snapshot = $turnSnapshot
    queue_operations = $queueOperations
    pending_session_writes = $pendingSessionWrites
    tool_registry = $toolRegistry
    model_registry = $modelRegistry
    hook_system = $hookSystem
    observability = $observability
    resource_selector = $resourceSelector
    session_tree = $sessionTree
    tool_call_lifecycle = $toolCallLifecycle
    durability_model = $durabilityModel
    durable_recovery = $durableRecovery
    session_entry_schema = $sessionEntrySchema
    abort_semantics = $abortSemantics
    compaction_and_branching = $compactionAndBranching
    retry_and_recovery = $retryAndRecovery
    completion_contract = $completionContract
    subagent_policy = 'executable only through registered specialist, concept, or named child profiles with current authority, isolated write surfaces, a synchronized structural optimization snapshot, evidence-bearing completion, and merge verification'
    missing_required_surfaces = $missing
} | ConvertTo-Json -Depth 8
