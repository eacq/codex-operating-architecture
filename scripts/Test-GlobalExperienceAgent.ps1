[CmdletBinding()]
param(
    [string]$RepositoryRoot = 'F:\codex'
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath $RepositoryRoot).Path
$outDir = & (Join-Path $root 'scripts\Resolve-CodexRunRoot.ps1') -ArchitectureRoot $root -Kind tmp -ChildPath 'global-experience-agent-test' -IgnoreConfiguredRoot -Create
$stateRoot = Join-Path $outDir 'sessions'

function Read-StrictUtf8NoBom([string]$Path) {
    $bytes = [IO.File]::ReadAllBytes($Path)
    if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
        throw "Agent persistence wrote a UTF-8 BOM: $Path"
    }
    $decoder = [Text.UTF8Encoding]::new($false, $true)
    try { return $decoder.GetString($bytes) }
    catch { throw "Agent persistence is not strict UTF-8: $Path" }
}

$verifyOutput = Join-Path $outDir 'verify.json'
$controller = Join-Path $root 'agent\40-runtime\Invoke-GlobalExperienceAgent.ps1'
if (-not (Test-Path -LiteralPath $controller -PathType Leaf)) { throw 'Canonical Global Experience Agent controller is missing.' }

$verifyJson = & $controller -RepositoryRoot $root -Goal 'test global experience agent canonical verification' -Mode Verify -OutputPath $verifyOutput -Apply
$verify = $verifyJson | ConvertFrom-Json
if ($verify.status -ne 'passed' -or $verify.model -ne 'global-experience-agent') {
    throw 'Global experience agent Verify compatibility mode did not pass.'
}
foreach ($event in @('user_goal_received', 'experience_context_loaded', 'agent_resources_selected', 'tool_gate_requested', 'tool_result_recorded', 'save_point_committed')) {
    if ($event -notin @($verify.events.event)) { throw "Verify compatibility run is missing event: $event" }
}

$registry = Get-Content -LiteralPath (Join-Path $root 'module-registry.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$activeOwners = @($registry.modules | Where-Object status -eq 'active' | ForEach-Object { [string]$_.name })
foreach ($owner in $activeOwners) {
    $previewJson = & $controller `
        -RepositoryRoot $root `
        -Goal "preview canonical Agent route for $owner" `
        -Mode Run `
        -Operation RouteOwner `
        -Owner $owner `
        -SessionId ("preview-" + $owner) `
        -StateRoot $stateRoot
    $preview = $previewJson | ConvertFrom-Json
    if ($preview.status -ne 'preview' -or $preview.operation -ne 'RouteOwner' -or $preview.owner -ne $owner) {
        throw "Agent runtime did not resolve active owner route: $owner"
    }
}

$routeSessionId = 'route-' + [guid]::NewGuid().ToString('N')
$routeOutput = Join-Path $outDir 'route-owner.json'
$routeJson = & $controller `
    -RepositoryRoot $root `
    -Goal 'route architecture work through its canonical Agent owner without executing a gated side effect' `
    -Mode Run `
    -Operation RouteOwner `
    -Owner 'codex-architecture-iteration' `
    -SessionId $routeSessionId `
    -StateRoot $stateRoot `
    -OutputPath $routeOutput `
    -Authority 'test fixture authority' `
    -Apply
$route = $routeJson | ConvertFrom-Json
if ($route.status -ne 'passed' -or $route.tool_result.result -ne 'owner-routed' -or -not $route.tool_result.evidence_only -or $route.tool_result.side_effect_executed) {
    throw 'Agent RouteOwner did not settle as an evidence-only owner handoff.'
}
if (@($route.tool_result.incoming).Count -eq 0 -or @($route.tool_result.outgoing).Count -eq 0 -or -not $route.save_point.accepted) {
    throw 'Agent RouteOwner did not preserve bidirectional handoffs and save-point settlement.'
}

$intentSessionId = 'intent-' + [guid]::NewGuid().ToString('N')
$intentJson = & $controller `
    -RepositoryRoot $root `
    -Goal 'please generate the current candidate report' `
    -Mode Run `
    -Operation ClassifyIntent `
    -SessionId $intentSessionId `
    -StateRoot $stateRoot `
    -OutputPath (Join-Path $outDir 'intent.json') `
    -Interface llm `
    -AuthorityScope functional `
    -Apply
$intent = $intentJson | ConvertFrom-Json
if ($intent.status -ne 'passed' -or $intent.tool_result.decision.layer -ne 'L1' -or $intent.tool_result.decision.operation -ne 'CandidateReport' -or $intent.tool_result.side_effect_executed) {
    throw 'Agent ClassifyIntent did not return an evidence-only intent route.'
}

$externalStateRoot = Join-Path ([System.IO.Directory]::GetParent($root).FullName) ('codex-agent-external-state-' + [guid]::NewGuid().ToString('N'))
$externalSessionId = 'external-' + [guid]::NewGuid().ToString('N')
$externalRunJson = & $controller `
    -RepositoryRoot $root `
    -Goal 'external project session must not run the global complete iteration gate' `
    -Mode Run `
    -Operation StartWork `
    -SessionId $externalSessionId `
    -StateRoot $externalStateRoot `
    -Authority 'test fixture authority' `
    -Apply
$externalRun = $externalRunJson | ConvertFrom-Json
if ($externalRun.status -ne 'passed' -or $externalRun.durable_state.phase -ne 'idle') {
    throw 'External project fixture session did not start from an idle save point.'
}
$blockedCompleteIteration = $false
try {
    & $controller `
        -RepositoryRoot $root `
        -Goal 'external project session must not run the global complete iteration gate' `
        -Mode Continue `
        -Operation CompleteIteration `
        -SessionId $externalSessionId `
        -StateRoot $externalStateRoot `
        -AuthorityScope gated `
        -Authority 'test fixture authority' `
        -AuthorizationEvidence 'test fixture bounded gated authority' `
        -Apply | Out-Null
} catch {
    $blockedCompleteIteration = ($_.Exception.Message -match 'project-local StateRoot')
}
if (-not $blockedCompleteIteration) {
    throw 'Project-local StateRoot was not blocked from running CompleteIteration.'
}
$externalStatePath = Join-Path $externalStateRoot "$externalSessionId\state.json"
$externalState = Get-Content -LiteralPath $externalStatePath -Raw -Encoding UTF8 | ConvertFrom-Json
if ($externalState.phase -ne 'idle' -or $externalState.active_operation) {
    throw 'Blocked project-local CompleteIteration left an active operation.'
}
if (Test-Path -LiteralPath $externalStateRoot) {
    Remove-Item -LiteralPath $externalStateRoot -Recurse -Force
}

$sessionId = 'test-' + [guid]::NewGuid().ToString('N')
$runOutput = Join-Path $outDir 'run.json'
$multilingualGoal = ([char]0x9A8C) + ([char]0x8BC1) + ' Agent ' + ([char]0x4E2D) + ([char]0x6587) + ([char]0x7F16) + ([char]0x7801) + ([char]0x5F80) + ([char]0x8FD4)
$runJson = & $controller `
    -RepositoryRoot $root `
    -Goal $multilingualGoal `
    -Mode Run `
    -Operation VerifyAgent `
    -SessionId $sessionId `
    -StateRoot $stateRoot `
    -OutputPath $runOutput `
    -Steer 'retain verification floor' `
    -FollowUp 'record closeout evidence' `
    -NextTurn 'preserve for the next user turn' `
    -PendingWrite 'durable extension metadata' `
    -Authority 'test fixture authority' `
    -Apply
$run = $runJson | ConvertFrom-Json
if ($run.status -ne 'passed' -or $run.mode -ne 'Run' -or $run.operation -ne 'VerifyAgent') {
    throw 'Executable global experience agent Run mode did not pass.'
}
if ($run.task_contract.goal -ne $multilingualGoal) {
    throw 'Executable agent did not preserve the multilingual goal in memory.'
}
if (-not $run.turn_snapshot.immutable -or $run.turn_snapshot.session_id -ne $sessionId) {
    throw 'Executable agent did not create an immutable session-bound turn snapshot.'
}
if (-not $run.save_point.accepted -or $run.durable_state.phase -ne 'idle') {
    throw 'Executable agent did not settle at an accepted idle save point.'
}

$sessionDir = Join-Path $stateRoot $sessionId
$statePath = Join-Path $sessionDir 'state.json'
$eventPath = Join-Path $sessionDir 'events.jsonl'
foreach ($path in @($statePath, $eventPath, $runOutput)) {
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "Executable agent did not persist: $path" }
    [void](Read-StrictUtf8NoBom $path)
}
$persistedRun = Read-StrictUtf8NoBom $runOutput | ConvertFrom-Json
if ($persistedRun.task_contract.goal -ne $multilingualGoal) {
    throw 'Executable agent did not preserve the multilingual goal on disk.'
}
$entries = @(Get-Content -LiteralPath $eventPath -Encoding UTF8 | Where-Object { $_ } | ForEach-Object { $_ | ConvertFrom-Json })
foreach ($entryType in @('session', 'operation_started', 'turn_started', 'queue_enqueued', 'pending_write_enqueued', 'turn_snapshot_created', 'agent_resources_selected', 'tool_gate_requested', 'tool_call_started', 'tool_call_finished', 'pending_write_applied', 'queue_consumed', 'turn_finished', 'save_point_committed', 'operation_finished')) {
    if ($entryType -notin @($entries.type)) { throw "Executable agent event log is missing: $entryType" }
}

$resumeOutput = Join-Path $outDir 'resume.json'
$resumeJson = & $controller -RepositoryRoot $root -Mode Resume -SessionId $sessionId -StateRoot $stateRoot -OutputPath $resumeOutput -Apply
$resume = $resumeJson | ConvertFrom-Json
if ($resume.status -ne 'passed' -or $resume.phase -ne 'idle' -or $resume.recovered_interrupted_operation) {
    throw 'Agent Resume did not reconstruct the settled durable boundary.'
}
if (@($resume.queues.nextTurn).Count -ne 1) {
    throw 'Agent Resume did not preserve nextTurn queue state.'
}

$abortOutput = Join-Path $outDir 'abort.json'
$abortJson = & $controller -RepositoryRoot $root -Mode Abort -SessionId $sessionId -StateRoot $stateRoot -OutputPath $abortOutput -Apply
$abort = $abortJson | ConvertFrom-Json
if ($abort.status -ne 'passed' -or -not $abort.abort.settled) {
    throw 'Agent Abort did not settle.'
}
if ($abort.abort.steer_count -ne 0 -or $abort.abort.follow_up_count -ne 0 -or $abort.abort.next_turn_count -ne 1) {
    throw 'Agent Abort did not clear steer/followUp while preserving nextTurn.'
}
foreach ($path in @($verifyOutput, $routeOutput, $runOutput, $resumeOutput, $abortOutput, $statePath, $eventPath)) {
    [void](Read-StrictUtf8NoBom $path)
}

[pscustomobject]@{
    status = 'passed'
    model = $run.model
    compatibility_events = @($verify.events).Count
    durable_entries = $entries.Count
    session_id = $sessionId
    save_point = $run.save_point.id
    resume = 'settled-boundary-reconstructed'
    abort = 'queue-semantics-verified'
    owner_routes = $activeOwners.Count
    routed_owner = $route.tool_result.owner
    routed_owner_save_point = $route.save_point.id
    intent_operation = $intent.tool_result.decision.operation
    external_complete_iteration_guard = 'project-local-state-root-blocked'
} | ConvertTo-Json -Compress
