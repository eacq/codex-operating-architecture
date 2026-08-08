[CmdletBinding()]
param([string]$RepositoryRoot = (Get-Location).Path)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath $RepositoryRoot).Path
$registryPath = Join-Path $root 'config\global-experience-agent-registry.json'
$manifestPath = Join-Path $root 'config\agent-system.json'
$ownerNetworkPath = Join-Path $root 'config\agent-owner-connections.json'
$controllerPath = Join-Path $root 'agent\40-runtime\Invoke-GlobalExperienceAgent.ps1'
$runtimePath = Join-Path $root 'agent\40-runtime\Invoke-GlobalExperienceAgentRuntime.ps1'
foreach ($path in @($registryPath, $manifestPath, $ownerNetworkPath, $controllerPath, $runtimePath)) {
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "Agent registry test requires: $path" }
}
$positionalBindingPattern = '\[CmdletBinding\(PositionalBinding\s*=\s*\$false\)\]'
foreach ($path in @($controllerPath, $runtimePath)) {
    $source = Get-Content -LiteralPath $path -Raw -Encoding UTF8
    if ($source -notmatch $positionalBindingPattern) {
        throw "Agent command surface permits accidental positional binding: $path"
    }
}
$registry = Get-Content -LiteralPath $registryPath -Raw -Encoding UTF8 | ConvertFrom-Json
$manifest = Get-Content -LiteralPath $manifestPath -Raw -Encoding UTF8 | ConvertFrom-Json
$network = Get-Content -LiteralPath $ownerNetworkPath -Raw -Encoding UTF8 | ConvertFrom-Json
if ($registry.model -ne 'global-experience-agent-registry' -or $registry.root_agent.id -ne 'global-experience-agent') { throw 'Canonical root Agent is not registered.' }
if ($manifest.agent_registry.source -ne 'config/global-experience-agent-registry.json') { throw 'Agent manifest does not point to the canonical registry.' }
$requiredFeynmanUnits = @('memory_system','intent_recognition','doc_parse_pipeline','chunking_retrieval','rerank_calibration','agent_loop','memory_as_skill')
if ($registry.dynamic_subagents.template_inheritance -notmatch 'feynman-build-workshop') { throw 'Dynamic child Agent policy does not inherit the feynman structural scaffold.' }
foreach ($childProfile in @($registry.child_agent_profiles)) {
    foreach ($unit in $requiredFeynmanUnits) {
        $entry = @($childProfile.feynman_structural_scaffold.units | Where-Object { $_.id -eq $unit })
        if ($entry.Count -ne 1 -or [string]::IsNullOrWhiteSpace($entry[0].application)) {
            throw "Child Agent profile $($childProfile.id) is missing feynman structural scaffold unit: $unit"
        }
    }
}
foreach ($capability in @('describe-filesystem','resolve-agent-path','retrieve-context','start-work','continue-work','delegate-subagent','join-subagent','cancel-subagent','resume')) {
    if ($capability -notin @($registry.root_agent.capabilities)) { throw "Root Agent capability is missing: $capability" }
}
$activeOwners = @($network.owners.owner | Sort-Object -Unique)
$conceptOwners = @($registry.concept_agents.owners | ForEach-Object { $_ } | Sort-Object -Unique)
$invalidConceptOwners = @($conceptOwners | Where-Object { $_ -notin $activeOwners })
$unrepresentedOwners = @($activeOwners | Where-Object { $_ -notin $conceptOwners })
if ($invalidConceptOwners.Count -gt 0 -or $unrepresentedOwners.Count -gt 0) { throw "Concept Agent owner coverage failed. Invalid: $($invalidConceptOwners -join ', '); missing: $($unrepresentedOwners -join ', ')" }
foreach ($requiredOperation in @('DescribeFilesystem','ResolveAgentPath','DescribeInterfaces','EvaluateAccess','RetrieveContext','StartWork','StoreMemory','SearchMemory','ConsolidateMemory','RenderMemorySnapshot','DelegateSubagent','CompleteSubagent','JoinSubagent','CancelSubagent','RequestStructureChange')) {
    if ($requiredOperation -notin @($manifest.agent_runtime.operations)) { throw "Agent runtime operation is missing: $requiredOperation" }
}
if ('Continue' -notin @($manifest.agent_runtime.modes) -or $manifest.subagents.policy -ne 'executable-under-current-authority') { throw 'Continuation or executable subagent policy is inactive.' }

$stateRoot = & (Join-Path $root 'scripts\Resolve-CodexRunRoot.ps1') -ArchitectureRoot $root -Kind tmp -ChildPath ('agent-registry-test-' + [guid]::NewGuid().ToString('N')) -Create
$sessionId = 'portable-agent-test'
$controller = $controllerPath
try {
    $started = & $controller -RepositoryRoot $root -Mode Run -Operation StartWork -SessionId $sessionId -StateRoot $stateRoot -Goal 'Continue verified global Agent work from durable experience.' -Query 'experience Agent' -AgentId 'work-orchestration-agent' -CallerId 'user-a' -ModelProvider 'provider-a' -ModelId 'model-a' -HostId 'host-a' -AcceptanceCriteria 'durable work is retrievable' -NextTurn 'retrieve current records' -Authority 'fixture bounded local authority' -Apply | ConvertFrom-Json
    if ($started.status -ne 'passed' -or $started.tool_result.result -ne 'work-started' -or @($started.tool_result.relevant_records).Count -eq 0) { throw 'Root Agent did not start durable work with relevant records.' }

    $context = & $controller -RepositoryRoot $root -Mode Continue -Operation RetrieveContext -SessionId $sessionId -StateRoot $stateRoot -Goal 'Continue from another caller and model.' -Query 'experience Agent' -CallerId 'user-b' -ModelProvider 'provider-b' -ModelId 'model-b' -HostId 'host-b' -Authority 'fixture bounded local authority' -Apply | ConvertFrom-Json
    if ($context.tool_result.result -ne 'context-retrieved' -or @($context.tool_result.records).Count -eq 0 -or $context.caller_context.caller_id -ne 'user-b') { throw 'Cross-caller context retrieval did not succeed.' }

    $delegated = & $controller -RepositoryRoot $root -Mode Continue -Operation DelegateSubagent -SessionId $sessionId -StateRoot $stateRoot -Goal 'Classify the durable Agent experience contract.' -AgentId 'experience-memory-agent' -ChildId 'experience-child' -WriteSurface '.codex/project/agent-test-surface' -AcceptanceCriteria 'return evidence-backed classification' -Verification 'parent merge verifier checks repository-relative evidence' -CallerId 'user-b' -ModelProvider 'provider-b' -ModelId 'model-b' -HostId 'host-b' -Authority 'fixture bounded local authority' -Apply | ConvertFrom-Json
    if ($delegated.tool_result.result -ne 'subagent-delegated' -or $delegated.tool_result.child.status -ne 'delegated') { throw 'Subagent delegation did not create durable child state.' }

    $completed = & $controller -RepositoryRoot $root -Mode Continue -Operation CompleteSubagent -SessionId $sessionId -StateRoot $stateRoot -Goal 'Record child result.' -ChildId 'experience-child' -ResultSummary 'Agent experience contract classified.' -ResultEvidence 'config/agent-system.json' -Verification 'manifest exists and is hash recorded' -CallerId 'user-c' -ModelProvider 'provider-c' -ModelId 'model-c' -HostId 'host-c' -Authority 'fixture bounded local authority' -Apply | ConvertFrom-Json
    if ($completed.tool_result.result -ne 'subagent-completed' -or @($completed.tool_result.evidence).Count -ne 1) { throw 'Subagent completion lacks evidence.' }

    $joined = & $controller -RepositoryRoot $root -Mode Continue -Operation JoinSubagent -SessionId $sessionId -StateRoot $stateRoot -Goal 'Verify and join child result.' -ChildId 'experience-child' -MergeDisposition accepted -Verification 'codex-task-execution verified the child evidence hash and bounded result' -CallerId 'user-c' -ModelProvider 'provider-c' -ModelId 'model-c' -HostId 'host-c' -Authority 'fixture bounded local authority' -Apply | ConvertFrom-Json
    if ($joined.tool_result.result -ne 'subagent-joined' -or $joined.tool_result.disposition -ne 'accepted') { throw 'Subagent merge verification did not settle.' }

    $pptDelegated = & $controller -RepositoryRoot $root -Mode Continue -Operation DelegateSubagent -SessionId $sessionId -StateRoot $stateRoot -Goal 'Plan and validate a visual-design child Agent handoff.' -AgentId 'visual-design-agent' -ChildId 'visual-child' -WriteSurface '.runtime/work/visual-design-agent/registry-test' -AcceptanceCriteria 'return visual route plan, design template, selected asset, and validation evidence' -Verification 'selected specialist delivery gate plus parent evidence hash check' -CallerId 'user-c' -ModelProvider 'provider-c' -ModelId 'model-c' -HostId 'host-c' -Authority 'fixture bounded local authority' -Apply | ConvertFrom-Json
    if ($pptDelegated.tool_result.result -ne 'subagent-delegated' -or $pptDelegated.tool_result.child.agent_id -ne 'visual-design-agent' -or 'codex-image-workflow' -notin @($pptDelegated.tool_result.owners)) { throw 'Visual-design child profile was not delegated through the Agent registry.' }

    $pptCompleted = & $controller -RepositoryRoot $root -Mode Continue -Operation CompleteSubagent -SessionId $sessionId -StateRoot $stateRoot -Goal 'Record visual-design child route evidence.' -ChildId 'visual-child' -ResultSummary 'Visual-design child profile resolved and returned route-contract and template evidence.' -ResultEvidence 'skills/codex-image-workflow/subskills/visual-design-agent/SKILL.md' -Verification 'profile evidence exists and is hash recorded' -CallerId 'user-c' -ModelProvider 'provider-c' -ModelId 'model-c' -HostId 'host-c' -Authority 'fixture bounded local authority' -Apply | ConvertFrom-Json
    if ($pptCompleted.tool_result.result -ne 'subagent-completed') { throw 'PPT child completion did not settle.' }

    $pptJoined = & $controller -RepositoryRoot $root -Mode Continue -Operation JoinSubagent -SessionId $sessionId -StateRoot $stateRoot -Goal 'Join visual-design child profile evidence.' -ChildId 'visual-child' -MergeDisposition accepted -Verification 'selected specialist owner verified the profile contract evidence for parent merge' -CallerId 'user-c' -ModelProvider 'provider-c' -ModelId 'model-c' -HostId 'host-c' -Authority 'fixture bounded local authority' -Apply | ConvertFrom-Json
    if ($pptJoined.tool_result.result -ne 'subagent-joined' -or $pptJoined.tool_result.disposition -ne 'accepted') { throw 'PPT child join did not settle.' }

    $careerDelegated = & $controller -RepositoryRoot $root -Mode Continue -Operation DelegateSubagent -SessionId $sessionId -StateRoot $stateRoot -Goal 'Plan and validate a career planning child Agent handoff.' -AgentId 'career-planning-agent' -ChildId 'career-child' -WriteSurface '.runtime/work/career-planning-agent/registry-test' -AcceptanceCriteria 'return route plan, onboarding status, grounded draft, validation evidence, and human-review boundary when used for real career planning' -Verification 'codex-requirement-authoring contract gate plus parent evidence hash check' -CallerId 'user-c' -ModelProvider 'provider-c' -ModelId 'model-c' -HostId 'host-c' -Authority 'fixture bounded local authority' -Apply | ConvertFrom-Json
    if ($careerDelegated.tool_result.result -ne 'subagent-delegated' -or $careerDelegated.tool_result.child.agent_id -ne 'career-planning-agent' -or 'codex-requirement-authoring' -notin @($careerDelegated.tool_result.owners)) { throw 'Career planning child profile was not delegated through the Agent registry.' }

    $careerCompleted = & $controller -RepositoryRoot $root -Mode Continue -Operation CompleteSubagent -SessionId $sessionId -StateRoot $stateRoot -Goal 'Record career planning child route evidence.' -ChildId 'career-child' -ResultSummary 'Career planning child profile resolved and returned route-contract evidence.' -ResultEvidence 'skills/codex-requirement-authoring/subskills/career-planning-agent/SKILL.md' -Verification 'profile evidence exists and is hash recorded' -CallerId 'user-c' -ModelProvider 'provider-c' -ModelId 'model-c' -HostId 'host-c' -Authority 'fixture bounded local authority' -Apply | ConvertFrom-Json
    if ($careerCompleted.tool_result.result -ne 'subagent-completed') { throw 'Career planning child completion did not settle.' }

    $careerJoined = & $controller -RepositoryRoot $root -Mode Continue -Operation JoinSubagent -SessionId $sessionId -StateRoot $stateRoot -Goal 'Join career planning child profile evidence.' -ChildId 'career-child' -MergeDisposition accepted -Verification 'codex-requirement-authoring verified the profile contract evidence for parent merge' -CallerId 'user-c' -ModelProvider 'provider-c' -ModelId 'model-c' -HostId 'host-c' -Authority 'fixture bounded local authority' -Apply | ConvertFrom-Json
    if ($careerJoined.tool_result.result -ne 'subagent-joined' -or $careerJoined.tool_result.disposition -ne 'accepted') { throw 'Career planning child join did not settle.' }

    $trajectoryProfiles = @(
        @{ AgentId = 'issue-fix-agent'; ChildId = 'issue-fix-child'; Surface = '.runtime/work/issue-fix-agent/registry-test'; Skill = 'skills/codex-git-operations/subskills/loopx-issue-fix/SKILL.md'; Goal = 'Validate issue-fix trajectory child profile.' },
        @{ AgentId = 'auto-ml-experiment-agent'; ChildId = 'auto-ml-child'; Surface = '.runtime/work/auto-ml-agent/registry-test'; Skill = 'skills/codex-task-execution/subskills/loopx-auto-ml-experiment/SKILL.md'; Goal = 'Validate auto-ML trajectory child profile.' },
        @{ AgentId = 'auto-research-agent'; ChildId = 'auto-research-child'; Surface = '.runtime/work/auto-research-agent/registry-test'; Skill = 'skills/codex-information-gathering/subskills/loopx-auto-research/SKILL.md'; Goal = 'Validate auto-research trajectory child profile.' }
    )
    foreach ($trajectory in $trajectoryProfiles) {
        $trajectoryDelegated = & $controller -RepositoryRoot $root -Mode Continue -Operation DelegateSubagent -SessionId $sessionId -StateRoot $stateRoot -Goal $trajectory.Goal -AgentId $trajectory.AgentId -ChildId $trajectory.ChildId -WriteSurface $trajectory.Surface -AcceptanceCriteria 'return route, bounded evidence, verification, and recovery boundary' -Verification 'trajectory owner gate plus parent evidence hash check' -CallerId 'user-c' -ModelProvider 'provider-c' -ModelId 'model-c' -HostId 'host-c' -Authority 'fixture bounded local authority' -Apply | ConvertFrom-Json
        if ($trajectoryDelegated.tool_result.result -ne 'subagent-delegated' -or $trajectoryDelegated.tool_result.child.agent_id -ne $trajectory.AgentId) { throw "Trajectory child profile was not delegated: $($trajectory.AgentId)" }
        $trajectoryCompleted = & $controller -RepositoryRoot $root -Mode Continue -Operation CompleteSubagent -SessionId $sessionId -StateRoot $stateRoot -Goal "Record $($trajectory.AgentId) evidence." -ChildId $trajectory.ChildId -ResultSummary "$($trajectory.AgentId) returned route-contract evidence." -ResultEvidence $trajectory.Skill -Verification 'profile evidence exists and is hash recorded' -CallerId 'user-c' -ModelProvider 'provider-c' -ModelId 'model-c' -HostId 'host-c' -Authority 'fixture bounded local authority' -Apply | ConvertFrom-Json
        if ($trajectoryCompleted.tool_result.result -ne 'subagent-completed') { throw "Trajectory child completion did not settle: $($trajectory.AgentId)" }
        $trajectoryJoined = & $controller -RepositoryRoot $root -Mode Continue -Operation JoinSubagent -SessionId $sessionId -StateRoot $stateRoot -Goal "Join $($trajectory.AgentId) evidence." -ChildId $trajectory.ChildId -MergeDisposition accepted -Verification 'trajectory owner verified profile contract evidence for parent merge' -CallerId 'user-c' -ModelProvider 'provider-c' -ModelId 'model-c' -HostId 'host-c' -Authority 'fixture bounded local authority' -Apply | ConvertFrom-Json
        if ($trajectoryJoined.tool_result.result -ne 'subagent-joined' -or $trajectoryJoined.tool_result.disposition -ne 'accepted') { throw "Trajectory child join did not settle: $($trajectory.AgentId)" }
    }

    $null = & $controller -RepositoryRoot $root -Mode Continue -Operation DelegateSubagent -SessionId $sessionId -StateRoot $stateRoot -Goal 'Disposable child.' -AgentId 'codex-information-gathering' -ChildId 'cancel-child' -WriteSurface '.codex/project/agent-test-surface-2' -AcceptanceCriteria 'bounded inspection' -Verification 'parent decides whether to merge' -CallerId 'user-c' -ModelProvider 'provider-c' -ModelId 'model-c' -HostId 'host-c' -Authority 'fixture bounded local authority' -Apply | ConvertFrom-Json
    $cancelled = & $controller -RepositoryRoot $root -Mode Continue -Operation CancelSubagent -SessionId $sessionId -StateRoot $stateRoot -Goal 'Cancel disposable child.' -ChildId 'cancel-child' -ResultSummary 'No longer required.' -CallerId 'user-c' -ModelProvider 'provider-c' -ModelId 'model-c' -HostId 'host-c' -Authority 'fixture bounded local authority' -Apply | ConvertFrom-Json
    if ($cancelled.tool_result.result -ne 'subagent-cancelled') { throw 'Subagent cancellation did not settle.' }

    $resumed = & $controller -RepositoryRoot $root -Mode Resume -SessionId $sessionId -StateRoot $stateRoot -Query 'Agent experience' -CallerId 'user-d' -ModelProvider 'provider-d' -ModelId 'model-d' -HostId 'host-d' -Authority 'fixture bounded local authority' -Apply | ConvertFrom-Json
    $expectedChildren = 2 + @($registry.child_agent_profiles).Count
    if ($resumed.status -ne 'passed' -or $resumed.caller_context.caller_id -ne 'user-d' -or @($resumed.caller_history).Count -lt 4 -or @($resumed.model_history).Count -lt 4 -or @($resumed.children).Count -ne $expectedChildren -or @($resumed.relevant_records).Count -eq 0) { throw 'Cross-caller/model Resume did not return durable work, records, and child state.' }
    $stateText = Get-Content -LiteralPath (Join-Path $stateRoot "$sessionId\state.json") -Raw -Encoding UTF8
    if ($stateText -match '(?i)OPENAI_API_KEY|Bearer\s+[A-Za-z0-9._-]+|cookie\s*=|raw private conversation') { throw 'Durable Agent state contains forbidden secret or raw-session material.' }

    [pscustomobject][ordered]@{status='passed';model=$registry.model;root_agent=$registry.root_agent.id;specialist_agents=$activeOwners.Count;concept_agents=@($registry.concept_agents).Count;operations=@($manifest.agent_runtime.operations).Count;cross_caller_history=@($resumed.caller_history).Count;cross_model_history=@($resumed.model_history).Count;children=@($resumed.children).Count} | ConvertTo-Json -Depth 8
} finally {
    $resolvedStateRoot = [IO.Path]::GetFullPath($stateRoot)
    $allowedRoot = [IO.Path]::GetFullPath('F:\.codex-codex-tmp').TrimEnd('\') + '\'
    if ($resolvedStateRoot.StartsWith($allowedRoot, [StringComparison]::OrdinalIgnoreCase) -and (Test-Path -LiteralPath $resolvedStateRoot)) { Remove-Item -LiteralPath $resolvedStateRoot -Recurse -Force }
}
