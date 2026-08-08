[CmdletBinding(PositionalBinding = $false)]
param(
    [string]$RepositoryRoot = 'F:\codex',
    [string]$Goal = 'global experience agent structural verification',
    [ValidateSet('Inspect', 'Verify', 'Run', 'Continue', 'Resume', 'Abort')]
    [string]$Mode = 'Verify',
    [string]$OutputPath,
    [ValidateSet('Auto', 'ClassifyIntent', 'VerifyAgent', 'DescribeFilesystem', 'ResolveAgentPath', 'DescribeInterfaces', 'EvaluateAccess', 'RetrieveContext', 'StartWork', 'StoreMemory', 'SearchMemory', 'ConsolidateMemory', 'RenderMemorySnapshot', 'RouteOwner', 'DelegateSubagent', 'CompleteSubagent', 'JoinSubagent', 'CancelSubagent', 'CompleteIteration', 'CandidateReport', 'RequestStructureChange', 'ReviewAgent')]
    [string]$Operation = 'Auto',
    [string]$Owner,
    [string]$SessionId,
    [string]$StateRoot,
    [string]$CallerId = 'authorized-local-user',
    [string]$ModelProvider = 'host-managed',
    [string]$ModelId = 'unspecified',
    [string]$HostId = 'compatible-agent-host',
    [datetime]$TaskStartedAt = [datetime]::MinValue,
    [Nullable[double]]$HostWorkedSeconds,
    [string]$AgentId = 'global-experience-agent',
    [string]$ChildId,
    [string]$Query,
    [string]$FilesystemId,
    [string[]]$WriteSurface = @(),
    [string[]]$AcceptanceCriteria = @(),
    [string]$Verification,
    [string]$ResultSummary,
    [string[]]$ResultEvidence = @(),
    [string]$MergeDisposition,
    [string[]]$Steer = @(),
    [string[]]$FollowUp = @(),
    [string[]]$NextTurn = @(),
    [string[]]$PendingWrite = @(),
    [ValidateSet('human', 'llm', 'internal-functional-unit', 'global-control')]
    [string]$Interface = 'human',
    [ValidateSet('none', 'functional', 'gated', 'global-structure')]
    [string]$AuthorityScope = 'functional',
    [string]$AuthorizationEvidence,
    [string]$RequestedOperation,
    [string[]]$RequestedSurfaces = @(),
    [string]$MemoryType = 'context',
    [string]$MemoryLayer = 'episodic',
    [int]$TtlDays = 0,
    [int]$Priority = 5,
    [string]$Authority = 'current user authorized the bounded global experience agent operation',
    [switch]$Apply
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath $RepositoryRoot).Path
if (-not $OutputPath) { $OutputPath = Join-Path $root '.codex\project\global-experience-agent-last-run.json' }

if ($Mode -in @('Run', 'Continue', 'Resume', 'Abort')) {
    $runtime = Join-Path $root 'agent\40-runtime\Invoke-GlobalExperienceAgentRuntime.ps1'
    if (-not (Test-Path -LiteralPath $runtime -PathType Leaf)) {
        throw 'Global experience agent runtime is missing.'
    }
    & $runtime -RepositoryRoot $root -Mode $Mode -Goal $Goal -Operation $Operation -Owner $Owner -SessionId $SessionId -StateRoot $StateRoot -OutputPath $OutputPath -CallerId $CallerId -ModelProvider $ModelProvider -ModelId $ModelId -HostId $HostId -TaskStartedAt $TaskStartedAt -HostWorkedSeconds $HostWorkedSeconds -AgentId $AgentId -ChildId $ChildId -Query $Query -FilesystemId $FilesystemId -WriteSurface $WriteSurface -AcceptanceCriteria $AcceptanceCriteria -Verification $Verification -ResultSummary $ResultSummary -ResultEvidence $ResultEvidence -MergeDisposition $MergeDisposition -Steer $Steer -FollowUp $FollowUp -NextTurn $NextTurn -PendingWrite $PendingWrite -Interface $Interface -AuthorityScope $AuthorityScope -AuthorizationEvidence $AuthorizationEvidence -RequestedOperation $RequestedOperation -RequestedSurfaces $RequestedSurfaces -MemoryType $MemoryType -MemoryLayer $MemoryLayer -TtlDays $TtlDays -Priority $Priority -Authority $Authority -Apply:$Apply
    return
}

function ConvertTo-RelativePath([string]$Path) {
    return (($Path.Substring($root.Length)).TrimStart('\', '/') -replace '\\', '/')
}

function Test-AgentFile([string]$RelativePath) {
    $path = Join-Path $root $RelativePath
    [pscustomobject]@{
        path = $RelativePath
        exists = Test-Path -LiteralPath $path -PathType Leaf
    }
}

function New-AgentEvent([string]$Phase, [string]$Event, [string]$Owner, [string]$Status, [object]$Evidence) {
    [pscustomobject][ordered]@{
        phase = $Phase
        event = $Event
        owner = $Owner
        status = $Status
        evidence = $Evidence
        timestamp = [DateTime]::UtcNow.ToString('o')
    }
}

$manifestPath = Join-Path $root 'config\agent-system.json'
if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) {
    throw 'Global experience agent cannot start without config/agent-system.json.'
}
$manifest = Get-Content -LiteralPath $manifestPath -Raw -Encoding UTF8 | ConvertFrom-Json
if ($manifest.model -ne 'agent-system' -or $manifest.harness.owner -ne 'codex-self-evolution') {
    throw 'Global experience agent manifest does not expose the codex-self-evolution harness.'
}
$interfacePolicyPath = Join-Path $root ([string]$manifest.agent_registry.interface_policy)
if (-not (Test-Path -LiteralPath $interfacePolicyPath -PathType Leaf)) {
    throw 'Global experience agent cannot start without config/agent-interface-policy.json.'
}
$interfacePolicy = Get-Content -LiteralPath $interfacePolicyPath -Raw -Encoding UTF8 | ConvertFrom-Json
$interfaceEntry = @($interfacePolicy.interfaces | Where-Object id -eq $Interface)
if ($interfaceEntry.Count -ne 1 -or 'observe' -notin @($interfaceEntry[0].permissions)) {
    throw "Agent interface cannot inspect or verify the system: $Interface"
}
$authorizationDecision = [ordered]@{
    decision = 'allow'
    reason = 'registered interface observe permission permits topology inspection or verification'
    interface = $Interface
    operation = $Mode
    required_permission = 'observe'
    authority_scope = $AuthorityScope
    labels_grant_authority = $false
    next_authority_boundary = 'registered read-only verification or a separately authorized runtime operation'
}

$events = New-Object System.Collections.Generic.List[object]

$events.Add((New-AgentEvent 'intake' 'user_goal_received' 'codex-self-evolution' 'accepted' ([ordered]@{
    goal = $Goal
    mode = $Mode
    authority = $Authority
    interface = $Interface
    authority_scope = $AuthorityScope
})))

$authorityFiles = @(
    '.codex/project/state.json',
    '.codex/project/REQUIREMENTS.md',
    '.codex/project/WORKFLOWS.md',
    '.codex/project/EXPERIENCE.md',
    'config/agent-system.json',
    'config/agent-interface-policy.json',
    'module-registry.json'
)
$authorityEvidence = @($authorityFiles | ForEach-Object { Test-AgentFile $_ })
if (@($authorityEvidence | Where-Object { -not $_.exists }).Count -gt 0) {
    throw "Global experience agent missing authority files: $((@($authorityEvidence | Where-Object { -not $_.exists }) | ForEach-Object path) -join ', ')"
}
$events.Add((New-AgentEvent 'orient' 'experience_context_loaded' 'codex-self-evolution' 'loaded' ([ordered]@{
    authority_files = $authorityEvidence
    manifest_source = $manifest.template.source
    manifest_commit = $manifest.template.source_commit
})))

$resourceFiles = @(
    @($manifest.resources.information_units) +
    @($manifest.resources.functional_units) +
    @($manifest.harness.interfaces)
) | ForEach-Object { [string]$_ } | Sort-Object -Unique
$resourceEvidence = @($resourceFiles | ForEach-Object { Test-AgentFile $_ })
if (@($resourceEvidence | Where-Object { -not $_.exists }).Count -gt 0) {
    throw "Global experience agent missing resource files: $((@($resourceEvidence | Where-Object { -not $_.exists }) | ForEach-Object path) -join ', ')"
}
$events.Add((New-AgentEvent 'select' 'agent_resources_selected' 'codex-self-evolution' 'selected' ([ordered]@{
    resource_count = @($resourceEvidence).Count
    selection_policy = $manifest.resources.selection_policy
})))

$gateEvidence = @()
foreach ($gate in @($manifest.tool_gates)) {
    $ownerSkill = Join-Path $root ("skills\{0}\SKILL.md" -f $gate.owner)
    $lifecycle = @($gate.lifecycle)
    $missingLifecycle = @('requested', 'preflighted', 'authorized', 'executed', 'observed', 'verified', 'captured_or_reported' | Where-Object { $_ -notin $lifecycle })
    $gateEvidence += [pscustomobject]@{
        name = $gate.name
        owner = $gate.owner
        owner_exists = Test-Path -LiteralPath $ownerSkill -PathType Leaf
        lifecycle_complete = $missingLifecycle.Count -eq 0
        missing_lifecycle = $missingLifecycle
    }
}
if (@($gateEvidence | Where-Object { -not $_.owner_exists -or -not $_.lifecycle_complete }).Count -gt 0) {
    throw 'Global experience agent tool-gate topology is incomplete.'
}
$events.Add((New-AgentEvent 'act' 'tool_gate_requested' 'specialist owner' 'preflighted' ([ordered]@{
    tool_gates = $gateEvidence
    action_policy = 'no gated side effect is executed by topology verification'
})))

$checks = New-Object System.Collections.Generic.List[object]
if ($Mode -eq 'Verify') {
    $topologyJson = & (Join-Path $root 'scripts\Test-AgentSystemTopology.ps1') -RepositoryRoot $root
    $topology = $topologyJson | ConvertFrom-Json
    $checks.Add([pscustomobject]@{ name = 'agent-system-topology'; status = $topology.status; detail = $topology })

    $contractJson = & (Join-Path $root 'scripts\Test-AgentHarnessContract.ps1') -RepositoryRoot $root
    $contract = $contractJson | ConvertFrom-Json
    $checks.Add([pscustomobject]@{ name = 'agent-harness-contract'; status = $contract.status; detail = $contract })

    $ownerConnectionsJson = & (Join-Path $root 'scripts\Test-AgentOwnerConnections.ps1') -RepositoryRoot $root
    $ownerConnections = $ownerConnectionsJson | ConvertFrom-Json
    $checks.Add([pscustomobject]@{ name = 'agent-owner-connections'; status = $ownerConnections.status; detail = $ownerConnections })

    $interfacePolicyJson = & (Join-Path $root 'scripts\Test-AgentInterfacePolicy.ps1') -RepositoryRoot $root
    $interfacePolicyCheck = $interfacePolicyJson | ConvertFrom-Json
    $checks.Add([pscustomobject]@{ name = 'agent-interface-policy'; status = $interfacePolicyCheck.status; detail = $interfacePolicyCheck })
}
$failedChecks = @($checks | Where-Object { $_.status -ne 'passed' })
if ($failedChecks.Count -gt 0) {
    throw "Global experience agent verification failed: $((@($failedChecks) | ForEach-Object name) -join ', ')"
}
$events.Add((New-AgentEvent 'observe' 'tool_result_recorded' 'verification owner' 'verified' ([ordered]@{
    checks = @($checks.ToArray())
    mode = $Mode
})))

$result = [ordered]@{
    schema_version = 3
    status = 'passed'
    model = 'global-experience-agent'
    manifest = 'config/agent-system.json'
    interface_policy = 'config/agent-interface-policy.json'
    interface = $Interface
    authorization_decision = $authorizationDecision
    goal = $Goal
    mode = $Mode
    source = $manifest.template.source
    source_commit = $manifest.template.source_commit
    events = @($events.ToArray())
    save_point = [ordered]@{
        type = 'global-experience-agent-run'
        accepted = $true
        output = ConvertTo-RelativePath $OutputPath
    }
    exit = [ordered]@{
        type = 'evidence'
        status = 'passed'
        audience = $Interface
        authority_decision = $authorizationDecision
        next_authority_boundary = $authorizationDecision.next_authority_boundary
    }
    completed_at = [DateTime]::UtcNow.ToString('o')
}

$events.Add((New-AgentEvent 'settle' 'save_point_committed' 'verification owner' 'settled' ([ordered]@{
    output = ConvertTo-RelativePath $OutputPath
    write_requested = [bool]$Apply
})))
$result.events = @($events.ToArray())

if ($Apply) {
    $parent = Split-Path -Parent $OutputPath
    New-Item -ItemType Directory -Force -Path $parent | Out-Null
    $json = ($result | ConvertTo-Json -Depth 10) + [Environment]::NewLine
    [IO.File]::WriteAllText($OutputPath, $json, [Text.UTF8Encoding]::new($false))
}

$result | ConvertTo-Json -Depth 10
