[CmdletBinding(PositionalBinding = $false)]
param(
    [Parameter(Mandatory = $true)]
    [string]$RepositoryRoot,
    [Parameter(Mandatory = $true)]
    [ValidateSet('Run', 'Continue', 'Resume', 'Abort')]
    [string]$Mode,
    [string]$Goal,
    [ValidateSet('Auto', 'ClassifyIntent', 'VerifyAgent', 'DescribeFilesystem', 'ResolveAgentPath', 'DescribeInterfaces', 'EvaluateAccess', 'RetrieveContext', 'StartWork', 'StoreMemory', 'SearchMemory', 'ConsolidateMemory', 'RenderMemorySnapshot', 'RouteOwner', 'DelegateSubagent', 'CompleteSubagent', 'JoinSubagent', 'CancelSubagent', 'CompleteIteration', 'CandidateReport', 'RequestStructureChange', 'ReviewAgent')]
    [string]$Operation = 'Auto',
    [string]$Owner,
    [string]$SessionId,
    [string]$StateRoot,
    [string]$OutputPath,
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
$controllerStartedAt = [DateTime]::UtcNow
$utf8NoBom = [Text.UTF8Encoding]::new($false)
$manifestPath = Join-Path $root 'config\agent-system.json'
if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) {
    throw 'Global experience agent runtime requires config/agent-system.json.'
}
$manifest = Get-Content -LiteralPath $manifestPath -Raw -Encoding UTF8 | ConvertFrom-Json
$agentRegistryPath = Join-Path $root ([string]$manifest.agent_registry.source)
if (-not (Test-Path -LiteralPath $agentRegistryPath -PathType Leaf)) {
    throw 'Global experience agent runtime requires the canonical agent registry.'
}
$agentRegistry = Get-Content -LiteralPath $agentRegistryPath -Raw -Encoding UTF8 | ConvertFrom-Json
$interfacePolicyPath = Join-Path $root ([string]$agentRegistry.interface_policy.source)
if (-not (Test-Path -LiteralPath $interfacePolicyPath -PathType Leaf)) {
    throw 'Global experience agent runtime requires the canonical interface policy.'
}
$interfacePolicy = Get-Content -LiteralPath $interfacePolicyPath -Raw -Encoding UTF8 | ConvertFrom-Json
$intentPolicyPath = Join-Path $root 'config\agent-intent-policy.json'
if (-not (Test-Path -LiteralPath $intentPolicyPath -PathType Leaf)) {
    throw 'Global experience agent runtime requires config/agent-intent-policy.json.'
}
$intentPolicy = Get-Content -LiteralPath $intentPolicyPath -Raw -Encoding UTF8 | ConvertFrom-Json
$transportRecoveryScriptPath = Join-Path $root 'agent\40-runtime\TransportRecovery.ps1'
if (-not (Test-Path -LiteralPath $transportRecoveryScriptPath -PathType Leaf)) {
    throw "Global experience agent runtime requires transport recovery classifier: $transportRecoveryScriptPath"
}
. $transportRecoveryScriptPath
$transportRecoveryPolicy = Get-AgentTransportRecoveryPolicy -RepositoryRoot $root
$ownerNetworkPath = Join-Path $root ([string]$manifest.owner_network.source)
if (-not (Test-Path -LiteralPath $ownerNetworkPath -PathType Leaf)) {
    throw 'Global experience agent runtime requires the canonical owner network.'
}
$ownerNetwork = Get-Content -LiteralPath $ownerNetworkPath -Raw -Encoding UTF8 | ConvertFrom-Json
if (-not $StateRoot) { $StateRoot = Join-Path $root '.codex\project\agent-sessions' }
if (-not $OutputPath) { $OutputPath = Join-Path $root '.codex\project\global-experience-agent-last-run.json' }

function New-AgentTiming([datetime]$CompletedAt, [string]$SessionStartedAt) {
    $taskAvailable = ($TaskStartedAt -ne [datetime]::MinValue)
    $taskStart = if ($taskAvailable) { $TaskStartedAt.ToUniversalTime() } else { $null }
    $operationSeconds = [math]::Round(($CompletedAt.ToUniversalTime() - $controllerStartedAt).TotalSeconds, 3)
    $taskSeconds = if ($taskAvailable) { [math]::Round(($CompletedAt.ToUniversalTime() - $taskStart).TotalSeconds, 3) } else { $null }
    $sessionSeconds = $null
    if (-not [string]::IsNullOrWhiteSpace($SessionStartedAt)) {
        try { $sessionSeconds = [math]::Round(($CompletedAt.ToUniversalTime() - ([datetime]::Parse($SessionStartedAt).ToUniversalTime())).TotalSeconds, 3) } catch { $sessionSeconds = $null }
    }
    return [ordered]@{
        task_started_at = if ($taskAvailable) { $taskStart.ToString('o') } else { $null }
        task_completed_at = if ($taskAvailable) { $CompletedAt.ToUniversalTime().ToString('o') } else { $null }
        task_time_available = $taskAvailable
        task_time_status = if ($taskAvailable) { 'measured-from-caller-task-start' } else { 'not-measured; caller-task-start-required' }
        task_wall_clock_seconds = $taskSeconds
        host_reported_worked_seconds = if ($null -ne $HostWorkedSeconds) { [math]::Round([double]$HostWorkedSeconds, 3) } else { $null }
        host_worked_status = if ($null -ne $HostWorkedSeconds) { 'host-reported' } else { 'not-provided' }
        operation_started_at = $controllerStartedAt.ToString('o')
        operation_completed_at = $CompletedAt.ToUniversalTime().ToString('o')
        operation_wall_clock_seconds = $operationSeconds
        controller_wall_clock_seconds = $operationSeconds
        agent_session_started_at = $SessionStartedAt
        agent_session_wall_clock_seconds = $sessionSeconds
        timing_layers = @('task-lifecycle', 'host-worked', 'agent-session', 'controller-operation')
    }
}

function Test-AgentPathIsInsideRoot([string]$Path, [string]$RootPath) {
    if ([string]::IsNullOrWhiteSpace($Path) -or [string]::IsNullOrWhiteSpace($RootPath)) { return $false }
    $fullPath = [IO.Path]::GetFullPath($Path).TrimEnd('\', '/')
    $fullRoot = [IO.Path]::GetFullPath($RootPath).TrimEnd('\', '/')
    return ($fullPath -eq $fullRoot -or $fullPath.StartsWith($fullRoot + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase))
}

function Get-AgentSha256([string]$Value) {
    $sha = [Security.Cryptography.SHA256]::Create()
    try {
        $bytes = [Text.Encoding]::UTF8.GetBytes($Value)
        return ([BitConverter]::ToString($sha.ComputeHash($bytes))).Replace('-', '').ToLowerInvariant()
    } finally {
        $sha.Dispose()
    }
}

function ConvertTo-AgentPath([string]$Path) {
    $full = [IO.Path]::GetFullPath($Path)
    if ($full.StartsWith($root, [StringComparison]::OrdinalIgnoreCase)) {
        return (($full.Substring($root.Length)).TrimStart('\', '/') -replace '\\', '/')
    }
    return $full
}

function Write-AgentJsonAtomic([string]$Path, [object]$Value) {
    $parent = Split-Path -Parent $Path
    if (-not (Test-Path -LiteralPath $parent -PathType Container)) {
        New-Item -ItemType Directory -Force -Path $parent | Out-Null
    }
    $temporary = "$Path.$([guid]::NewGuid().ToString('N')).tmp"
    $json = ($Value | ConvertTo-Json -Depth 20) + [Environment]::NewLine
    [IO.File]::WriteAllText($temporary, $json, $script:utf8NoBom)
    if (Test-Path -LiteralPath $Path -PathType Leaf) {
        Remove-Item -LiteralPath $Path -Force -ErrorAction SilentlyContinue
    }
    Move-Item -LiteralPath $temporary -Destination $Path -Force
}

function Add-AgentUtf8Line([string]$Path, [string]$Value) {
    $parent = Split-Path -Parent $Path
    if (-not (Test-Path -LiteralPath $parent -PathType Container)) {
        New-Item -ItemType Directory -Force -Path $parent | Out-Null
    }
    [IO.File]::AppendAllText($Path, $Value + [Environment]::NewLine, $script:utf8NoBom)
}

function New-AgentId([string]$Prefix) {
    return "$Prefix-$([guid]::NewGuid().ToString('N'))"
}

function Add-DurableEntry([string]$Type, [object]$Data) {
    $entry = [ordered]@{
        schema_version = 1
        id = New-AgentId 'entry'
        parentId = $script:state.leaf_id
        timestamp = [DateTime]::UtcNow.ToString('o')
        type = $Type
        data = $Data
    }
    Add-AgentUtf8Line -Path $script:eventLogPath -Value ($entry | ConvertTo-Json -Depth 15 -Compress)
    $script:state.leaf_id = $entry.id
    $script:state.updated_at = $entry.timestamp
    return [pscustomobject]$entry
}

function Save-AgentState {
    $persistedTiming = New-AgentTiming -CompletedAt ([DateTime]::UtcNow) -SessionStartedAt ([string]$script:state.created_at)
    if ($script:state -is [System.Collections.IDictionary]) {
        $script:state['timing'] = $persistedTiming
    } elseif ($script:state.PSObject.Properties.Name -contains 'timing') {
        $script:state.timing = $persistedTiming
    } else {
        $script:state | Add-Member -NotePropertyName timing -NotePropertyValue $persistedTiming
    }
    Write-AgentJsonAtomic -Path $script:statePath -Value $script:state
}

function Read-AgentState([string]$Path, [switch]$RepairMalformedJson) {
    $raw = [IO.File]::ReadAllText($Path)
    try {
        return ($raw | ConvertFrom-Json)
    } catch {
        if (-not $RepairMalformedJson) { throw }
        $characters = New-Object System.Text.StringBuilder
        $insideString = $false
        $escaped = $false
        foreach ($character in $raw.ToCharArray()) {
            if ($insideString) {
                if ($escaped) {
                    [void]$characters.Append($character)
                    $escaped = $false
                    continue
                }
                if ($character -eq [char]'\') {
                    [void]$characters.Append($character)
                    $escaped = $true
                    continue
                }
                if ($character -eq [char]'"') {
                    [void]$characters.Append($character)
                    $insideString = $false
                    continue
                }
                if ($character -eq [char]13) {
                    [void]$characters.Append('\r')
                    continue
                }
                if ($character -eq [char]10) {
                    [void]$characters.Append('\n')
                    continue
                }
                [void]$characters.Append($character)
                continue
            }
            if ($character -eq [char]'"') { $insideString = $true }
            [void]$characters.Append($character)
        }
        if ($insideString) { throw 'Agent state repair refused: input ended inside a JSON string.' }
        $repairedText = $characters.ToString()
        try { $repairedState = $repairedText | ConvertFrom-Json } catch { throw "Agent state repair refused: repaired JSON is invalid. $($_.Exception.Message)" }
        $backup = "$Path.corrupt-$(Get-Date -Format 'yyyyMMddTHHmmssZ').bak"
        Copy-Item -LiteralPath $Path -Destination $backup -Force
        $temporary = "$Path.$([guid]::NewGuid().ToString('N')).tmp"
        [IO.File]::WriteAllText($temporary, $repairedText + [Environment]::NewLine, $script:utf8NoBom)
        Move-Item -LiteralPath $temporary -Destination $Path -Force
        return $repairedState
    }
}

function Add-QueueValues([string]$QueueName, [string[]]$Values) {
    $clean = @($Values | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
    if ($clean.Count -eq 0) { return }
    $existing = @($script:state.queues.$QueueName)
    $script:state.queues.$QueueName = @($existing + $clean)
    Add-DurableEntry 'queue_enqueued' ([ordered]@{
        queue = $QueueName
        count = $clean.Count
        values_sha256 = @( $clean | ForEach-Object { Get-AgentSha256 $_ } )
    }) | Out-Null
}

function Get-AgentOwnerNode([string]$RequestedOwner) {
    if ([string]::IsNullOrWhiteSpace($RequestedOwner)) { return $null }
    $matches = @($ownerNetwork.owners | Where-Object owner -eq $RequestedOwner)
    if ($matches.Count -ne 1) {
        throw "Agent owner is not an active canonical owner: $RequestedOwner"
    }
    return $matches[0]
}

function Assert-AgentLabel([string]$Name, [string]$Value) {
    if ([string]::IsNullOrWhiteSpace($Value) -or $Value.Length -gt 120 -or $Value -match '[\r\n]') {
        throw "$Name must be a non-empty single-line label of at most 120 characters."
    }
}

function Get-RegisteredAgent([string]$RequestedAgentId) {
    if ([string]::IsNullOrWhiteSpace($RequestedAgentId) -or $RequestedAgentId -eq $agentRegistry.root_agent.id) {
        return [pscustomobject][ordered]@{ id=$agentRegistry.root_agent.id; kind='root'; owners=@('codex-self-evolution'); resources=@($manifest.resources.information_units) }
    }
    $concept = @($agentRegistry.concept_agents | Where-Object id -eq $RequestedAgentId)
    if ($concept.Count -eq 1) { return $concept[0] }
    $childProfile = @($agentRegistry.child_agent_profiles | Where-Object id -eq $RequestedAgentId)
    if ($childProfile.Count -eq 1) {
        return [pscustomobject][ordered]@{
            id = [string]$childProfile[0].id
            kind = [string]$childProfile[0].kind
            owners = @($childProfile[0].owners)
            resources = @($childProfile[0].resources)
            parent_concept = [string]$childProfile[0].parent_concept
            allowed_operations = @($childProfile[0].allowed_operations)
            denied_operations = @($childProfile[0].denied_operations)
            required_write_surface = [string]$childProfile[0].required_write_surface
             required_evidence = @($childProfile[0].required_evidence)
             merge_verifier = [string]$childProfile[0].merge_verifier
             authority_boundary = [string]$childProfile[0].authority_boundary
             document_capability = $childProfile[0].document_capability
             structural_optimization_inheritance = $childProfile[0].structural_optimization_inheritance
        }
    }
    $owner = Get-AgentOwnerNode $RequestedAgentId
    if ($owner) {
        return [pscustomobject][ordered]@{ id=[string]$owner.owner; kind='specialist'; owners=@([string]$owner.owner); resources=@([string]$owner.skill); tool_gate=$owner.tool_gate }
    }
    throw "Agent is not registered: $RequestedAgentId"
}

function Get-RelevantAgentRecords([string]$RequestedQuery) {
    $candidatePaths = @(
        @($manifest.resources.information_units) +
        @('.codex/project/REQUIREMENTS.md', '.codex/project/WORKFLOWS.md', '.codex/project/EXPERIENCE.md', '.codex/project/RETROSPECTIVES.md', '.codex/project/candidate-reports/latest.md', 'config/agent-system.json', [string]$manifest.agent_registry.source, [string]$manifest.owner_network.source, 'module-registry.json')
    ) | ForEach-Object { [string]$_ } | Sort-Object -Unique
    $wideComma = [char]0xFF0C
    $wideSemicolon = [char]0xFF1B
    $splitPattern = '[\s,;' + [regex]::Escape([string]$wideComma + [string]$wideSemicolon) + ']+'
    $terms = @(([string]$RequestedQuery -split $splitPattern | Where-Object { $_.Length -ge 2 }) | Select-Object -Unique)
    $records = New-Object System.Collections.Generic.List[object]
    foreach ($relative in $candidatePaths) {
        $full = Join-Path $root ($relative -replace '/', [string][IO.Path]::DirectorySeparatorChar)
        if (-not (Test-Path -LiteralPath $full -PathType Leaf)) { continue }
        $text = Get-Content -LiteralPath $full -Raw -Encoding UTF8
        $matched = @($terms | Where-Object { $text.IndexOf($_, [StringComparison]::OrdinalIgnoreCase) -ge 0 })
        if ($terms.Count -gt 0 -and $matched.Count -eq 0) { continue }
        $records.Add([pscustomobject][ordered]@{
            path = $relative
            sha256 = (Get-FileHash -LiteralPath $full -Algorithm SHA256).Hash.ToLowerInvariant()
            matched_terms = $matched
            score = $matched.Count
            bytes = (Get-Item -LiteralPath $full).Length
        })
    }
    return @($records | Sort-Object @{Expression='score';Descending=$true}, path | Select-Object -First 25)
}

function Get-AgentMemoryDbPath {
    if (-not [string]::IsNullOrWhiteSpace($env:CODEX_AGENT_MEMORY_DB)) {
        return [IO.Path]::GetFullPath($env:CODEX_AGENT_MEMORY_DB)
    }
    $memoryRoot = Join-Path $root '.codex\project\agent-memory'
    return Join-Path $memoryRoot 'memory.db'
}

function Resolve-AgentPython {
    $runtimeConfig = Join-Path $root '.codex\project\validation-runtime.json'
    $configuredPython = if (Test-Path -LiteralPath $runtimeConfig -PathType Leaf) {
        try { [string](Get-Content -LiteralPath $runtimeConfig -Raw -Encoding UTF8 | ConvertFrom-Json).python_path } catch { '' }
    } else { '' }
    $candidates = @(
        $env:CODEX_PYTHON,
        $configuredPython,
        (Join-Path $root '.codex\runtime\env\python.exe'),
        (Join-Path $root '.runtime\envs\codex-foundation\python.exe'),
        'python'
    ) | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Select-Object -Unique
    foreach ($candidate in $candidates) {
        if ([IO.Path]::IsPathRooted($candidate) -and -not (Test-Path -LiteralPath $candidate -PathType Leaf)) { continue }
        $previousErrorAction = $ErrorActionPreference
        $ErrorActionPreference = 'Continue'
        & $candidate -s -c "import sys" 2>$null
        $exitCode = $LASTEXITCODE
        $ErrorActionPreference = $previousErrorAction
        if ($exitCode -eq 0) { return $candidate }
    }
    throw 'Agent memory backend requires a usable project Python runtime.'
}

function Invoke-AgentMemoryStore([string[]]$Arguments) {
    $scriptPath = Join-Path $root 'agent\40-runtime\Invoke-AgentMemoryStore.py'
    if (-not (Test-Path -LiteralPath $scriptPath -PathType Leaf)) { throw "Agent memory backend is missing: $scriptPath" }
    $dbPath = Get-AgentMemoryDbPath
    $python = Resolve-AgentPython
    $previousEnvironment = @{
        PYTHONUTF8 = $env:PYTHONUTF8
        PYTHONIOENCODING = $env:PYTHONIOENCODING
        PYTHONNOUSERSITE = $env:PYTHONNOUSERSITE
    }
    try {
        $env:PYTHONUTF8 = '1'
        $env:PYTHONIOENCODING = 'utf-8'
        $env:PYTHONNOUSERSITE = '1'
        $raw = & $python -s $scriptPath --db $dbPath @Arguments 2>&1
        $exitCode = $LASTEXITCODE
    }
    finally {
        foreach ($name in $previousEnvironment.Keys) {
            if ($null -eq $previousEnvironment[$name]) { Remove-Item -LiteralPath "Env:$name" -ErrorAction SilentlyContinue }
            else { Set-Item -LiteralPath "Env:$name" -Value $previousEnvironment[$name] }
        }
    }
    $jsonLine = @($raw | Where-Object { $_ -match '^\s*\{' } | Select-Object -Last 1)
    if (-not $jsonLine) { throw "Agent memory backend returned no JSON: $($raw -join "`n")" }
    $result = $jsonLine | ConvertFrom-Json
    if ($exitCode -ne 0 -or $result.result -eq 'memory-error') { throw "Agent memory backend failed: $($raw -join "`n")" }
    return $result
}

function ConvertTo-AgentIntentText([string]$Value) {
    if ([string]::IsNullOrWhiteSpace($Value)) { return '' }
    return (($Value.ToLowerInvariant() -replace '[\r\n\t]+', ' ') -replace '\s+', ' ').Trim()
}

function Get-AgentIntentRouteScore([string]$Text, [object]$Route) {
    $score = 0.0
    $matches = New-Object System.Collections.Generic.List[string]
    foreach ($utterance in @($Route.utterances)) {
        $needle = ConvertTo-AgentIntentText ([string]$utterance)
        if ($needle.Length -eq 0) { continue }
        if ($Text -eq $needle) {
            $score += 0.75
            $matches.Add([string]$utterance)
        } elseif ($Text.Contains($needle)) {
            $score += 0.35
            $matches.Add([string]$utterance)
        }
    }
    foreach ($keyword in @($Route.keywords)) {
        $needle = ConvertTo-AgentIntentText ([string]$keyword)
        if ($needle.Length -eq 0) { continue }
        if ($Text.Contains($needle)) {
            $score += 0.15
            $matches.Add([string]$keyword)
        }
    }
    if ($score -gt 0.95) { $score = 0.95 }
    return [pscustomobject][ordered]@{
        score = [math]::Round($score, 3)
        matches = @($matches | Select-Object -Unique)
    }
}

function Invoke-AgentIntentRouter([string]$Requested, [string]$RequestedGoal, [string]$RequestedOwner, [string]$RequestedQuery) {
    $stopwatch = [Diagnostics.Stopwatch]::StartNew()
    $text = ConvertTo-AgentIntentText $(if (-not [string]::IsNullOrWhiteSpace($RequestedQuery)) { $RequestedQuery } else { $RequestedGoal })
    if (-not [string]::IsNullOrWhiteSpace($RequestedOwner)) {
        $stopwatch.Stop()
        return [ordered]@{
            result = 'intent-classified'
            intent = 'explicit-owner-route'
            operation = 'RouteOwner'
            confidence = 1.0
            layer = 'L0'
            matched_rule = 'explicit-owner'
            slots = [ordered]@{ owner = $RequestedOwner }
            fallback_needed = $false
            llm_called = $false
            latency_ms = [math]::Round($stopwatch.Elapsed.TotalMilliseconds, 3)
            policy = ConvertTo-AgentPath $intentPolicyPath
        }
    }
    if ($Requested -ne 'Auto') {
        $stopwatch.Stop()
        return [ordered]@{
            result = 'intent-classified'
            intent = 'explicit-operation'
            operation = $Requested
            confidence = 1.0
            layer = 'L0'
            matched_rule = 'explicit-operation'
            slots = [ordered]@{}
            fallback_needed = $false
            llm_called = $false
            latency_ms = [math]::Round($stopwatch.Elapsed.TotalMilliseconds, 3)
            policy = ConvertTo-AgentPath $intentPolicyPath
        }
    }
    foreach ($rule in @($intentPolicy.l0_rules)) {
        if ($text -match [string]$rule.pattern) {
            $stopwatch.Stop()
            return [ordered]@{
                result = 'intent-classified'
                intent = [string]$rule.intent
                operation = [string]$rule.operation
                confidence = [double]$rule.confidence
                layer = 'L0'
                matched_rule = [string]$rule.id
                slots = [ordered]@{}
                fallback_needed = $false
                llm_called = $false
                latency_ms = [math]::Round($stopwatch.Elapsed.TotalMilliseconds, 3)
                policy = ConvertTo-AgentPath $intentPolicyPath
            }
        }
    }
    $bestRoute = $null
    $bestScore = $null
    foreach ($route in @($intentPolicy.routes)) {
        $routeScore = Get-AgentIntentRouteScore -Text $text -Route $route
        if ($null -eq $bestScore -or $routeScore.score -gt $bestScore.score) {
            $bestRoute = $route
            $bestScore = $routeScore
        }
    }
    if ($bestRoute -and $bestScore.score -ge [double]$bestRoute.threshold) {
        $stopwatch.Stop()
        return [ordered]@{
            result = 'intent-classified'
            intent = [string]$bestRoute.intent
            operation = [string]$bestRoute.operation
            confidence = [double]$bestScore.score
            layer = 'L1'
            matched_rule = [string]$bestRoute.intent
            matched_terms = @($bestScore.matches)
            slots = [ordered]@{}
            fallback_needed = $bestScore.score -lt [double]$intentPolicy.confidence_bands.direct_execute
            llm_called = $false
            l2_status = [string]$intentPolicy.safety.llm_adapter_status
            latency_ms = [math]::Round($stopwatch.Elapsed.TotalMilliseconds, 3)
            policy = ConvertTo-AgentPath $intentPolicyPath
        }
    }
    $stopwatch.Stop()
    return [ordered]@{
        result = 'intent-classified'
        intent = [string]$intentPolicy.fallback.intent
        operation = [string]$intentPolicy.fallback.operation
        confidence = [double]$intentPolicy.fallback.confidence
        layer = 'L3'
        matched_rule = 'fallback-safe-work-start'
        matched_terms = @()
        slots = [ordered]@{}
        fallback_needed = $true
        llm_called = $false
        l2_status = [string]$intentPolicy.safety.llm_adapter_status
        latency_ms = [math]::Round($stopwatch.Elapsed.TotalMilliseconds, 3)
        policy = ConvertTo-AgentPath $intentPolicyPath
    }
}

function Get-ChildReference([string]$RequestedChildId) {
    if ([string]::IsNullOrWhiteSpace($RequestedChildId)) { throw 'A child operation requires -ChildId.' }
    $matches = @($script:state.children | Where-Object id -eq $RequestedChildId)
    if ($matches.Count -ne 1) { throw "Child agent is not registered in this session: $RequestedChildId" }
    return $matches[0]
}

function Get-ChildStatePath([object]$ChildReference) {
    return Join-Path $StateRoot ([string]$ChildReference.session_id + '\state.json')
}

function Read-ChildState([object]$ChildReference) {
    $path = Get-ChildStatePath $ChildReference
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "Child agent state is missing: $($ChildReference.session_id)" }
    return Get-Content -LiteralPath $path -Raw -Encoding UTF8 | ConvertFrom-Json
}

function Write-ChildState([object]$ChildReference, [object]$ChildState, [string]$EventType, [object]$EventData) {
    $childDirectory = Join-Path $StateRoot ([string]$ChildReference.session_id)
    $childStatePath = Join-Path $childDirectory 'state.json'
    $childEventPath = Join-Path $childDirectory 'events.jsonl'
    if (-not (Test-Path -LiteralPath $childDirectory -PathType Container)) { New-Item -ItemType Directory -Force -Path $childDirectory | Out-Null }
    Write-AgentJsonAtomic -Path $childStatePath -Value $ChildState
    $childEvent = [ordered]@{schema_version=1;timestamp=[DateTime]::UtcNow.ToString('o');type=$EventType;data=$EventData} | ConvertTo-Json -Depth 12 -Compress
    Add-AgentUtf8Line -Path $childEventPath -Value $childEvent
}


function Invoke-AgentReviewCheckpoint([string]$ResolvedOperation, [object]$OperationContract) {
    $lensesPath = Join-Path $root 'config\agent-review-lenses.json'
    if (-not (Test-Path -LiteralPath $lensesPath -PathType Leaf)) {
        return [ordered]@{ status = 'skipped'; reason = 'no-review-lenses-config'; risk_level = 'low'; lenses_applied = 0; checklist = @() }
    }
    try { $lensesCfg = Get-Content -LiteralPath $lensesPath -Raw -Encoding UTF8 | ConvertFrom-Json } catch { }
    if (-not $lensesCfg -or @($lensesCfg.lenses).Count -eq 0) {
        return [ordered]@{ status = 'skipped'; reason = 'no-lenses-defined'; risk_level = 'low'; lenses_applied = 0; checklist = @() }
    }
    $allLenses = @($lensesCfg.lenses)
    $checklist = @()
    $riskLevel = 'low'
    if ($ResolvedOperation -eq 'ReviewAgent') {
        $riskLevel = 'medium'
    } elseif ($ResolvedOperation -eq 'RequestStructureChange' -or $OperationContract.gate_required) {
        if ($ResolvedOperation -eq 'RequestStructureChange') { $riskLevel = 'critical' }
        elseif ($ResolvedOperation -eq 'CompleteIteration') { $riskLevel = 'high' }
        else { $riskLevel = 'medium' }
    }
    $toolGate = '' + $OperationContract.tool_gate
    foreach ($lens in $allLenses) {
        $applyTo = @($lens.apply_to)
        if ($ResolvedOperation -eq 'ReviewAgent' -or $applyTo -contains $toolGate -or $applyTo -contains $ResolvedOperation) {
            $checklist += [ordered]@{ lens = '' + $lens.id; books = [int]$lens.books; six_hats_role = '' + $lens.six_hats_role; description = '' + $lens.description; behavior = '' + $lens.behavior }
        }
    }
    if ($riskLevel -in @('critical', 'high')) {
        foreach ($cl in $allLenses) {
            if ([int]$cl.books -ge 7) {
                $found = @($checklist | Where-Object { $_.lens -eq ('' + $cl.id) })
                if ($found.Count -eq 0) {
                    $checklist += [ordered]@{ lens = '' + $cl.id; books = [int]$cl.books; six_hats_role = '' + $cl.six_hats_role; description = '' + $cl.description; behavior = '' + $cl.behavior }
                }
            }
        }
    }
    $result = [ordered]@{ status = 'reviewed'; risk_level = $riskLevel; operation = $ResolvedOperation; tool_gate = $toolGate; lenses_applied = $checklist.Count; checklist = $checklist; timestamp = [DateTime]::UtcNow.ToString('o') }
    Add-DurableEntry 'agent_review_checkpoint' $result | Out-Null
    return $result
}
function Resolve-AgentOperation([string]$Requested, [string]$RequestedGoal, [string]$RequestedOwner) {
    $script:lastIntentDecision = Invoke-AgentIntentRouter -Requested $Requested -RequestedGoal $RequestedGoal -RequestedOwner $RequestedOwner -RequestedQuery $Query
    return [string]$script:lastIntentDecision.operation
}

function Get-AgentInterfaceEntry([string]$InterfaceId) {
    $entry = @($interfacePolicy.interfaces | Where-Object { $_.id -eq $InterfaceId })
    if ($entry.Count -ne 1) { throw "Agent interface is not registered: $InterfaceId" }
    return $entry[0]
}

function Get-AgentOperationPermission([string]$ResolvedOperation) {
    $property = $interfacePolicy.operation_permissions.PSObject.Properties[$ResolvedOperation]
    if ($null -eq $property -or [string]::IsNullOrWhiteSpace([string]$property.Value)) {
        return $null
    }
    return [string]$property.Value
}

function Test-AgentInterfaceAccess([string]$ResolvedOperation, [string[]]$TargetSurfaces = @()) {
    $entry = Get-AgentInterfaceEntry $Interface
    $requiredPermission = Get-AgentOperationPermission $ResolvedOperation
    $decision = 'allow'
    $reason = 'registered interface permission and authority scope permit this operation'
    $nextBoundary = 'registered functional unit or named owner gate'

    if ([string]::IsNullOrWhiteSpace($requiredPermission)) {
        $decision = 'deny'
        $reason = 'operation has no registered permission mapping'
        $nextBoundary = 'codex-architecture-iteration must register the operation'
    } elseif ($requiredPermission -notin @($entry.permissions)) {
        $decision = 'deny'
        $reason = "interface '$Interface' does not hold permission '$requiredPermission'"
        $nextBoundary = if ($requiredPermission -eq 'agent-structure') { 'use global-control with explicit global-structure authority' } else { 'obtain a compatible interface or route through an authorized owner' }
    } elseif ($requiredPermission -eq 'gated-action' -and $AuthorityScope -notin @('gated', 'global-structure')) {
        $decision = 'deny'
        $reason = 'gated action requires gated or global-structure authority scope'
        $nextBoundary = 'obtain current gated authority and invoke the named owner gate'
    } elseif ($requiredPermission -eq 'agent-structure') {
        if ($Interface -ne 'global-control') {
            $decision = 'deny'
            $reason = 'Agent structure is writable only through global-control'
        } elseif ($AuthorityScope -ne 'global-structure') {
            $decision = 'deny'
            $reason = 'global-control requires global-structure authority scope for Agent structure'
        } elseif ([string]::IsNullOrWhiteSpace($AuthorizationEvidence)) {
            $decision = 'deny'
            $reason = 'global-control requires current non-secret authorization evidence'
        } elseif (@($TargetSurfaces | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }).Count -eq 0) {
            $decision = 'deny'
            $reason = 'global-control requires at least one declared target surface'
        }
        $nextBoundary = if ($decision -eq 'allow') { 'codex-architecture-iteration through the agent_structure gate' } else { 'provide explicit current global-structure authority through global-control' }
    }

    return [ordered]@{
        decision = $decision
        reason = $reason
        interface = $Interface
        audience = [string]$entry.audience
        operation = $ResolvedOperation
        required_permission = $requiredPermission
        authority_scope = $AuthorityScope
        authorization_evidence_sha256 = if ([string]::IsNullOrWhiteSpace($AuthorizationEvidence)) { $null } else { Get-AgentSha256 $AuthorizationEvidence }
        target_surfaces = @($TargetSurfaces | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
        labels_grant_authority = $false
        next_authority_boundary = $nextBoundary
    }
}

function New-AgentExit([string]$Type, [string]$Status, [object]$AuthorityDecision, [string]$NextBoundary) {
    return [ordered]@{
        type = $Type
        status = $Status
        audience = $Interface
        authority_decision = $AuthorityDecision
        next_authority_boundary = $NextBoundary
    }
}

function New-AgentRestartRequiredResult([object]$RecoverySignal, [string]$ResolvedOperation, [string]$Source) {
    $now = [DateTime]::UtcNow.ToString('o')
    $recovery = [ordered]@{
        status = 'restart-required'
        source = if ([string]::IsNullOrWhiteSpace($Source)) { 'global-experience-agent' } else { $Source }
        classification = [string]$RecoverySignal.classification
        component = [string]$RecoverySignal.component
        matched_pattern_ids = @($RecoverySignal.matched_pattern_ids)
        error_sha256 = [string]$RecoverySignal.error_sha256
        detected_at = $now
        restart_required = $true
        automatic_retry = 'disabled_after_classification'
        preserved_state = @('durable session state', 'pending writes', 'child lineage')
        preserve_pending_writes = $true
        user_message = [string]$RecoverySignal.user_message
        next_action = [string]$RecoverySignal.next_action
    }
    $script:state.recovery = $recovery
    $script:state.status = 'blocked-restart-required'
    $script:state.phase = 'idle'
    $script:state.active_operation = $null
    Add-DurableEntry 'error_feedback_recorded' ([ordered]@{
        operation = $ResolvedOperation
        classification = $recovery.classification
        component = $recovery.component
        error_sha256 = $recovery.error_sha256
        restart_required = $true
    }) | Out-Null
    Add-DurableEntry 'restart_prompted' ([ordered]@{
        operation = $ResolvedOperation
        classification = $recovery.classification
        preserved_state = $recovery.preserved_state
        next_action = $recovery.next_action
    }) | Out-Null
    Save-AgentState
    return [ordered]@{
        schema_version = 4
        status = 'blocked'
        model = 'global-experience-agent'
        mode = $Mode
        operation = $ResolvedOperation
        session_id = $SessionId
        caller_context = $callerContext
        interface = $Interface
        authorization_decision = $authorizationDecision
        recovery = $recovery
        durable_state = [ordered]@{
            state = ConvertTo-AgentPath $script:statePath
            events = ConvertTo-AgentPath $script:eventLogPath
            phase = $script:state.phase
            status = $script:state.status
            pending_write_count = @($script:state.pending_writes).Count
            child_count = @($script:state.children).Count
        }
        exit = New-AgentExit -Type 'restart-required' -Status 'blocked' -AuthorityDecision $authorizationDecision -NextBoundary ([string]$RecoverySignal.next_action)
        timing = New-AgentTiming -CompletedAt ([DateTime]::UtcNow) -SessionStartedAt $null
        completed_at = $now
    }
}

function Get-OperationContract([string]$ResolvedOperation, [object]$SelectedOwnerNode) {
    switch ($ResolvedOperation) {
        'VerifyAgent' {
            return [ordered]@{
                owner = 'codex-self-evolution'
                tool_gate = 'internal_validation'
                gate_required = $false
                retry_safe = $true
                idempotent = $true
            }
        }
        'ClassifyIntent' {
            return [ordered]@{ owner='codex-self-evolution'; tool_gate='intent_router'; gate_required=$false; retry_safe=$true; idempotent=$true }
        }
        'DescribeInterfaces' {
            return [ordered]@{ owner='codex-architecture-iteration'; tool_gate='interface_policy'; gate_required=$false; retry_safe=$true; idempotent=$true }
        }
        'DescribeFilesystem' {
            return [ordered]@{ owner='codex-file-organization'; tool_gate='agent_filesystem'; gate_required=$false; retry_safe=$true; idempotent=$true }
        }
        'ResolveAgentPath' {
            return [ordered]@{ owner='codex-file-organization'; tool_gate='agent_filesystem'; gate_required=$false; retry_safe=$true; idempotent=$true }
        }
        'EvaluateAccess' {
            return [ordered]@{ owner='codex-architecture-iteration'; tool_gate='interface_policy'; gate_required=$false; retry_safe=$true; idempotent=$true }
        }
        'RetrieveContext' {
            return [ordered]@{ owner='codex-conversation-continuity'; tool_gate='record_retrieval'; gate_required=$false; retry_safe=$true; idempotent=$true }
        }
        'StartWork' {
            return [ordered]@{ owner='codex-requirement-authoring'; tool_gate='work_contract'; gate_required=$false; retry_safe=$true; idempotent=$true }
        }
        'StoreMemory' {
            return [ordered]@{ owner='codex-experience-capture'; tool_gate='agent_memory'; gate_required=$false; retry_safe=$true; idempotent=$true }
        }
        'SearchMemory' {
            return [ordered]@{ owner='codex-conversation-continuity'; tool_gate='agent_memory'; gate_required=$false; retry_safe=$true; idempotent=$true }
        }
        'ConsolidateMemory' {
            return [ordered]@{ owner='codex-experience-capture'; tool_gate='agent_memory'; gate_required=$false; retry_safe=$true; idempotent=$true }
        }
        'RenderMemorySnapshot' {
            return [ordered]@{ owner='codex-knowledge-system'; tool_gate='agent_memory'; gate_required=$false; retry_safe=$true; idempotent=$true }
        }
        'CandidateReport' {
            return [ordered]@{
                owner = 'codex-experience-capture'
                tool_gate = 'candidate_report'
                gate_required = $false
                retry_safe = $true
                idempotent = $true
            }
        }
        'RouteOwner' {
            if ($null -eq $SelectedOwnerNode) { throw 'RouteOwner requires -Owner.' }
            $registeredGate = if ($null -ne $SelectedOwnerNode.tool_gate -and -not [string]::IsNullOrWhiteSpace([string]$SelectedOwnerNode.tool_gate)) {
                [string]$SelectedOwnerNode.tool_gate
            } else {
                'owner_route'
            }
            return [ordered]@{
                owner = [string]$SelectedOwnerNode.owner
                tool_gate = $registeredGate
                gate_required = $false
                evidence_only = $true
                retry_safe = $true
                idempotent = $true
            }
        }
        'DelegateSubagent' {
            return [ordered]@{ owner='codex-task-execution'; tool_gate='subagent_lifecycle'; gate_required=$false; retry_safe=$false; idempotent=$false }
        }
        'CompleteSubagent' {
            return [ordered]@{ owner='codex-task-execution'; tool_gate='subagent_lifecycle'; gate_required=$false; retry_safe=$true; idempotent=$true }
        }
        'JoinSubagent' {
            return [ordered]@{ owner='codex-task-execution'; tool_gate='subagent_merge'; gate_required=$false; retry_safe=$true; idempotent=$true }
        }
        'CancelSubagent' {
            return [ordered]@{ owner='codex-task-execution'; tool_gate='subagent_lifecycle'; gate_required=$false; retry_safe=$true; idempotent=$true }
        }
        'CompleteIteration' {
            return [ordered]@{
                owner = 'codex-self-evolution'
                tool_gate = 'global_iteration'
                gate_required = $true
                retry_safe = $false
                idempotent = $false
            }
        }
        'RequestStructureChange' {
            return [ordered]@{
                owner = 'codex-architecture-iteration'
                tool_gate = 'agent_structure'
                gate_required = $true
                evidence_only = $true
                retry_safe = $true
                idempotent = $true
            }
        }
        'ReviewAgent' {
            return [ordered]@{ owner='codex-experience-capture'; tool_gate='agent_review'; gate_required=$false; retry_safe=$true; idempotent=$true }
        }
        default { throw "Unsupported global experience agent operation: $ResolvedOperation" }
    }
}

function Invoke-AgentOperation([string]$ResolvedOperation, [object]$SelectedOwnerNode) {
    switch ($ResolvedOperation) {
        'VerifyAgent' {
            $topology = (& (Join-Path $root 'scripts\Test-AgentSystemTopology.ps1') -RepositoryRoot $root) | ConvertFrom-Json
            $harness = (& (Join-Path $root 'scripts\Test-AgentHarnessContract.ps1') -RepositoryRoot $root) | ConvertFrom-Json
            $connections = (& (Join-Path $root 'scripts\Test-AgentOwnerConnections.ps1') -RepositoryRoot $root) | ConvertFrom-Json
            $filesystem = (& (Join-Path $root 'agent\80-maintenance\Test-AgentFilesystem.ps1') -RepositoryRoot $root) | ConvertFrom-Json
            return [ordered]@{
                result = 'verified'
                topology = $topology.status
                harness = $harness.status
                owner_connections = $connections.status
                filesystem = $filesystem.status
                active_owner_coverage = $connections.active_owner_coverage
            }
        }
        'ClassifyIntent' {
            $decision = Invoke-AgentIntentRouter -Requested 'Auto' -RequestedGoal $Goal -RequestedOwner $Owner -RequestedQuery $Query
            Add-DurableEntry 'intent_classified' $decision | Out-Null
            return [ordered]@{
                result = 'intent-classified'
                decision = $decision
                evidence_only = $true
                side_effect_executed = $false
            }
        }
        'DescribeFilesystem' {
            $layoutPath = Join-Path $root 'agent\agent-filesystem.json'
            $layout = Get-Content -LiteralPath $layoutPath -Raw -Encoding UTF8 | ConvertFrom-Json
            $itemsJson = & (Join-Path $root 'agent\80-maintenance\Resolve-AgentFilesystemPath.ps1') -RepositoryRoot $root -List
            $items = $itemsJson | ConvertFrom-Json
            return [ordered]@{
                result = 'filesystem-described'
                manifest = 'agent/agent-filesystem.json'
                root = $layout.root
                zones = @($layout.zones)
                projection_count = @($items).Count
                canonical_surfaces = $layout.canonical_surfaces
                local_state = @($layout.local_state)
                compatibility_adapters = @($layout.compatibility_adapters)
                evidence_only = $true
                side_effect_executed = $false
            }
        }
        'ResolveAgentPath' {
            if ([string]::IsNullOrWhiteSpace($FilesystemId)) { throw 'ResolveAgentPath requires -FilesystemId.' }
            $resolvedJson = & (Join-Path $root 'agent\80-maintenance\Resolve-AgentFilesystemPath.ps1') -RepositoryRoot $root -Id $FilesystemId
            return [ordered]@{
                result = 'agent-path-resolved'
                resolution = ($resolvedJson | ConvertFrom-Json)
                evidence_only = $true
                side_effect_executed = $false
            }
        }
        'DescribeInterfaces' {
            return [ordered]@{
                result = 'interfaces-described'
                policy = ConvertTo-AgentPath $interfacePolicyPath
                default_decision = [string]$interfacePolicy.default_decision
                interfaces = @($interfacePolicy.interfaces)
                exits = @($interfacePolicy.exits)
            }
        }
        'EvaluateAccess' {
            if ([string]::IsNullOrWhiteSpace($RequestedOperation)) { throw 'EvaluateAccess requires -RequestedOperation.' }
            return [ordered]@{
                result = 'access-evaluated'
                evaluation = Test-AgentInterfaceAccess -ResolvedOperation $RequestedOperation -TargetSurfaces $RequestedSurfaces
                evidence_only = $true
                side_effect_executed = $false
            }
        }
        'RetrieveContext' {
            $records = @(Get-RelevantAgentRecords $Query)
            return [ordered]@{
                result = 'context-retrieved'
                query_sha256 = Get-AgentSha256 ([string]$Query)
                records = $records
                work = $script:state.work
                children = @($script:state.children)
                next_actions = @($script:state.queues.nextTurn)
            }
        }
        'StartWork' {
            $definition = Get-RegisteredAgent $AgentId
            $records = @(Get-RelevantAgentRecords $(if ($Query) { $Query } else { $Goal }))
            $script:state.work = [ordered]@{
                status = 'ready'
                agent_id = [string]$definition.id
                agent_kind = [string]$definition.kind
                owners = @($definition.owners)
                goal_sha256 = Get-AgentSha256 $Goal
                acceptance_criteria = @($AcceptanceCriteria)
                relevant_records = @($records.path)
                next_actions = @($NextTurn)
                updated_at = [DateTime]::UtcNow.ToString('o')
            }
            return [ordered]@{ result='work-started'; agent_id=$definition.id; agent_kind=$definition.kind; owners=@($definition.owners); relevant_records=$records; next_actions=@($NextTurn); continuation='use Mode Continue with the same SessionId from any compatible authorized host' }
        }
        'StoreMemory' {
            $definition = Get-RegisteredAgent $AgentId
            $content = if (-not [string]::IsNullOrWhiteSpace($ResultSummary)) { $ResultSummary } else { $Goal }
            if ([string]::IsNullOrWhiteSpace($content)) { throw 'StoreMemory requires -ResultSummary or -Goal as memory content.' }
            $arguments = @(
                'store',
                '--agent-id', [string]$definition.id,
                '--session-id', $SessionId,
                '--type', $MemoryType,
                '--layer', $MemoryLayer,
                '--content', $content,
                '--source', "agent-runtime:$SessionId",
                '--confidence', '0.8',
                '--priority', ([string]$Priority),
                '--ttl-days', ([string]$TtlDays)
            )
            foreach ($tag in @($Steer + $FollowUp | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })) { $arguments += @('--tag', [string]$tag) }
            foreach ($evidence in @($ResultEvidence | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })) { $arguments += @('--evidence', [string]$evidence) }
            $stored = Invoke-AgentMemoryStore $arguments
            Add-DurableEntry 'agent_memory_stored' ([ordered]@{ id=$stored.id; type=$stored.type; layer=$stored.layer; content_sha256=$stored.content_sha256 }) | Out-Null
            return [ordered]@{
                result = 'memory-stored'
                memory = $stored
                db = ConvertTo-AgentPath (Get-AgentMemoryDbPath)
                local_state = $true
                continuation = 'later authorized callers or model hosts may use SearchMemory or RetrieveContext with this session id'
            }
        }
        'SearchMemory' {
            $searchQuery = if (-not [string]::IsNullOrWhiteSpace($Query)) { $Query } else { $Goal }
            if ([string]::IsNullOrWhiteSpace($searchQuery)) { throw 'SearchMemory requires -Query or -Goal.' }
            $found = Invoke-AgentMemoryStore @('search', '--query', $searchQuery, '--limit', '10')
            Add-DurableEntry 'agent_memory_searched' ([ordered]@{ query_sha256=$found.query_sha256; count=$found.count }) | Out-Null
            return [ordered]@{
                result = 'memory-search-results'
                query_sha256 = $found.query_sha256
                count = $found.count
                records = @($found.records)
                db = ConvertTo-AgentPath (Get-AgentMemoryDbPath)
                local_state = $true
            }
        }
        'ConsolidateMemory' {
            $notes = if (-not [string]::IsNullOrWhiteSpace($ResultSummary)) { $ResultSummary } else { 'manual Agent memory consolidation' }
            $consolidated = Invoke-AgentMemoryStore @('consolidate', '--notes', $notes)
            Add-DurableEntry 'agent_memory_consolidated' $consolidated | Out-Null
            return [ordered]@{
                result = 'memory-consolidated'
                consolidation = $consolidated
                db = ConvertTo-AgentPath (Get-AgentMemoryDbPath)
                local_state = $true
            }
        }
        'RenderMemorySnapshot' {
            $memoryRoot = if (-not [string]::IsNullOrWhiteSpace($env:CODEX_AGENT_MEMORY_DB)) { Split-Path -Parent (Get-AgentMemoryDbPath) } else { Join-Path $root '.codex\project\agent-memory' }
            $snapshotPath = Join-Path $memoryRoot 'frozen-snapshot.md'
            $snapshot = Invoke-AgentMemoryStore @('snapshot', '--limit', '50', '--output', $snapshotPath)
            Add-DurableEntry 'agent_memory_snapshot_rendered' ([ordered]@{ count=$snapshot.count; output=ConvertTo-AgentPath $snapshotPath }) | Out-Null
            return [ordered]@{
                result = 'memory-snapshot-rendered'
                count = $snapshot.count
                output = ConvertTo-AgentPath $snapshotPath
                local_state = $true
                prompt_rule = 'use this stable snapshot as a prefix block; append dynamic task context after it'
            }
        }
        'CandidateReport' {
            $report = (& (Join-Path $root 'skills\codex-experience-capture\scripts\New-GlobalIterationCandidateReport.ps1') -ProjectRoot $root -Apply) | ConvertFrom-Json
            return [ordered]@{
                result = $report.result
                candidate_count = $report.candidate_count
                output = $report.output
            }
        }
        'ReviewAgent' {
            $contract = Get-OperationContract -ResolvedOperation $ResolvedOperation -SelectedOwnerNode $SelectedOwnerNode
            $review = Invoke-AgentReviewCheckpoint -ResolvedOperation $ResolvedOperation -OperationContract $contract
            return [ordered]@{
                result = 'agent-reviewed'
                review = $review
                evidence_only = $true
                side_effect_executed = $false
            }
        }
        'RouteOwner' {
            if ($null -eq $SelectedOwnerNode) { throw 'RouteOwner requires a resolved owner node.' }
            $incoming = @($ownerNetwork.connections | Where-Object to -eq $SelectedOwnerNode.owner)
            $outgoing = @($ownerNetwork.connections | Where-Object from -eq $SelectedOwnerNode.owner)
            return [ordered]@{
                result = 'owner-routed'
                evidence_only = $true
                owner = [string]$SelectedOwnerNode.owner
                plane = [string]$SelectedOwnerNode.plane
                stage = [string]$SelectedOwnerNode.stage
                skill = [string]$SelectedOwnerNode.skill
                triggers = @($SelectedOwnerNode.triggers)
                consumes = @($SelectedOwnerNode.consumes)
                produces = @($SelectedOwnerNode.produces)
                verification = [string]$SelectedOwnerNode.verification
                tool_gate = $SelectedOwnerNode.tool_gate
                incoming = $incoming
                outgoing = $outgoing
                side_effect_executed = $false
            }
        }
        'DelegateSubagent' {
            if ([string]::IsNullOrWhiteSpace($ChildId) -or $ChildId -notmatch '^[A-Za-z0-9][A-Za-z0-9._-]{0,80}$') { throw 'DelegateSubagent requires a safe -ChildId.' }
            if (@($script:state.children | Where-Object id -eq $ChildId).Count -gt 0) { throw "Child agent already exists: $ChildId" }
            if (@($AcceptanceCriteria).Count -eq 0 -or [string]::IsNullOrWhiteSpace($Verification)) { throw 'DelegateSubagent requires acceptance criteria and a merge verification rule.' }
            $definition = Get-RegisteredAgent $AgentId
            $optimizationSnapshot = & (Join-Path $root 'agent\40-runtime\Get-AgentStructuralOptimizationSnapshot.ps1') -RepositoryRoot $root -AgentId ([string]$definition.id) | ConvertFrom-Json
            if ($optimizationSnapshot.status -ne 'synchronized') { throw "Subagent structural optimization baseline is not synchronized: $($definition.id)" }
            $childSessionId = "$SessionId--$ChildId"
            $childReference = [pscustomobject][ordered]@{ id=$ChildId; session_id=$childSessionId; agent_id=[string]$definition.id; kind=[string]$definition.kind; status='delegated'; merge_status='pending'; structural_optimization_baseline=[string]$optimizationSnapshot.baseline_version; created_at=[DateTime]::UtcNow.ToString('o') }
            $childState = [ordered]@{
                schema_version = 2
                model = 'global-experience-subagent'
                agent_id = [string]$definition.id
                kind = [string]$definition.kind
                session_id = $childSessionId
                parent_session_id = $SessionId
                status = 'delegated'
                goal = $Goal
                goal_sha256 = Get-AgentSha256 $Goal
                authority_sha256 = $script:state.authority_sha256
                caller_context = $script:state.caller_context
                owners = @($definition.owners)
                resources = @($definition.resources)
                parent_concept = $definition.parent_concept
                allowed_operations = @($definition.allowed_operations)
                denied_operations = @($definition.denied_operations)
                required_write_surface = $definition.required_write_surface
                required_evidence = @($definition.required_evidence)
                merge_verifier = $definition.merge_verifier
                authority_boundary = $definition.authority_boundary
                document_capability = $definition.document_capability
                structural_optimization_snapshot = $optimizationSnapshot
                write_surfaces = @($WriteSurface)
                acceptance_criteria = @($AcceptanceCriteria)
                merge_verification = $Verification
                result = $null
                merge = $null
                recovery = [ordered]@{
                    status = 'armed'
                    policy = ConvertTo-AgentPath (Join-Path $root 'config\agent-transport-recovery-policy.json')
                    restart_required = $false
                    parent_session_id = $SessionId
                }
                created_at = $childReference.created_at
                updated_at = $childReference.created_at
            }
            Write-ChildState $childReference $childState 'subagent_delegated' ([ordered]@{parent_session_id=$SessionId;agent_id=$definition.id;goal_sha256=$childState.goal_sha256;write_surfaces=@($WriteSurface);structural_optimization_baseline=$optimizationSnapshot.baseline_version;structural_optimization_policy_sha256=$optimizationSnapshot.policy_sha256})
            $script:state.children = @($script:state.children) + @($childReference)
            return [ordered]@{result='subagent-delegated';child=$childReference;state=ConvertTo-AgentPath (Get-ChildStatePath $childReference);owners=@($definition.owners);write_surfaces=@($WriteSurface);structural_optimization_snapshot=$optimizationSnapshot}
        }
        'CompleteSubagent' {
            $childReference = Get-ChildReference $ChildId
            if ($childReference.status -in @('cancelled','joined')) { throw "Child agent cannot complete from status: $($childReference.status)" }
            if ([string]::IsNullOrWhiteSpace($ResultSummary) -or [string]::IsNullOrWhiteSpace($Verification) -or @($ResultEvidence).Count -eq 0) { throw 'CompleteSubagent requires result summary, verification, and result evidence.' }
            $verifiedEvidence = @()
            foreach ($relativeEvidence in @($ResultEvidence)) {
                if ([IO.Path]::IsPathRooted($relativeEvidence)) { throw "Subagent evidence must be repository-relative: $relativeEvidence" }
                $fullEvidence = [IO.Path]::GetFullPath((Join-Path $root $relativeEvidence))
                if (-not $fullEvidence.StartsWith($root.TrimEnd('\') + '\', [StringComparison]::OrdinalIgnoreCase) -or -not (Test-Path -LiteralPath $fullEvidence -PathType Leaf)) { throw "Subagent evidence is missing or out of scope: $relativeEvidence" }
                $verifiedEvidence += [ordered]@{path=$relativeEvidence;sha256=(Get-FileHash -LiteralPath $fullEvidence -Algorithm SHA256).Hash.ToLowerInvariant()}
            }
            $childState = Read-ChildState $childReference
            $childState.status = 'completed'
            $childCompletedAt = [DateTime]::UtcNow
            $childStartedAt = [datetime]::Parse([string]$childState.created_at).ToUniversalTime()
            $childLifecycleSeconds = [math]::Round(($childCompletedAt.ToUniversalTime() - $childStartedAt).TotalSeconds, 3)
            $childTiming = [ordered]@{
                task_started_at = $childStartedAt.ToString('o')
                task_completed_at = $childCompletedAt.ToUniversalTime().ToString('o')
                task_time_status = 'measured-from-child-delegation-to-completion'
                task_wall_clock_seconds = $childLifecycleSeconds
                host_reported_worked_seconds = $null
                host_worked_status = 'not-provided'
                operation_wall_clock_seconds = $null
                controller_wall_clock_seconds = $null
                note = 'Child Agent host Worked for is not inferred by the parent; provide it explicitly when the child host exposes it.'
            }
            $childState.result = [ordered]@{summary=$ResultSummary;verification=$Verification;evidence=$verifiedEvidence;timing=$childTiming;completed_at=$childCompletedAt.ToString('o')}
            $childState.updated_at = $childState.result.completed_at
            $childReference.status = 'completed'
            Write-ChildState $childReference $childState 'subagent_completed' $childState.result
            return [ordered]@{result='subagent-completed';child_id=$ChildId;status=$childReference.status;evidence=$verifiedEvidence;timing=$childTiming}
        }
        'JoinSubagent' {
            $childReference = Get-ChildReference $ChildId
            $childState = Read-ChildState $childReference
            if ($childState.recovery -and [string]$childState.recovery.status -eq 'restart-required') {
                $childReference.status = 'restart-required'
                $childReference.merge_status = 'blocked'
                Add-DurableEntry 'subagent_restart_required' ([ordered]@{
                    child_id = $ChildId
                    classification = [string]$childState.recovery.classification
                    error_sha256 = [string]$childState.recovery.error_sha256
                    user_message = [string]$childState.recovery.user_message
                }) | Out-Null
                Save-AgentState
                return [ordered]@{
                    result = 'subagent-restart-required'
                    restart_required = $true
                    child_id = $ChildId
                    child_status = 'restart-required'
                    recovery = $childState.recovery
                    user_message = [string]$childState.recovery.user_message
                    next_action = [string]$childState.recovery.next_action
                }
            }
            if ($childReference.status -ne 'completed') { throw "JoinSubagent requires completed child state; got $($childReference.status)." }
            if ($MergeDisposition -notin @('accepted','rejected') -or [string]::IsNullOrWhiteSpace($Verification)) { throw 'JoinSubagent requires -MergeDisposition accepted|rejected and -Verification.' }
            $childState.status = 'joined'
            $registeredVerifier = if ([string]::IsNullOrWhiteSpace([string]$childState.merge_verifier)) { 'codex-task-execution parent merge gate' } else { [string]$childState.merge_verifier }
            $childState.merge = [ordered]@{disposition=$MergeDisposition;verification=$Verification;verifier=$registeredVerifier;joined_at=[DateTime]::UtcNow.ToString('o')}
            $childState.updated_at = $childState.merge.joined_at
            $childReference.status = 'joined'
            $childReference.merge_status = $MergeDisposition
            Write-ChildState $childReference $childState 'subagent_joined' $childState.merge
            return [ordered]@{result='subagent-joined';child_id=$ChildId;disposition=$MergeDisposition;verification=$Verification}
        }
        'CancelSubagent' {
            $childReference = Get-ChildReference $ChildId
            if ($childReference.status -eq 'joined') { throw 'A joined child agent cannot be cancelled.' }
            $childState = Read-ChildState $childReference
            $cancelledAt = [DateTime]::UtcNow.ToString('o')
            $childState.status = 'cancelled'
            $childState.updated_at = $cancelledAt
            $childReference.status = 'cancelled'
            $childReference.merge_status = 'not-applicable'
            Write-ChildState $childReference $childState 'subagent_cancelled' ([ordered]@{cancelled_at=$cancelledAt;reason_sha256=Get-AgentSha256 ([string]$ResultSummary)})
            return [ordered]@{result='subagent-cancelled';child_id=$ChildId;status='cancelled'}
        }
        'CompleteIteration' {
            & (Join-Path $root 'scripts\Invoke-CompleteGlobalExperienceIteration.ps1') -RepositoryRoot $root -Apply | Out-Null
            $proofPath = Join-Path $root '.codex\project\global-experience-iteration.json'
            if (-not (Test-Path -LiteralPath $proofPath -PathType Leaf)) {
                throw 'Complete global iteration did not write its proof.'
            }
            $proof = Get-Content -LiteralPath $proofPath -Raw -Encoding UTF8 | ConvertFrom-Json
            if ($proof.result -ne 'passed') {
                throw 'Complete global iteration proof did not pass.'
            }
            return [ordered]@{
                result = $proof.result
                mode = $proof.mode
                proof = ConvertTo-AgentPath $proofPath
                rollback_ready = [bool]$proof.sources.file_organization.rollback_ready
                post_replacement_validated = [bool]$proof.sources.file_organization.post_replacement_validated
                lifecycle_written_back = [bool]$proof.sources.file_organization.lifecycle_written_back
            }
        }
        'RequestStructureChange' {
            return [ordered]@{
                result = 'structure-change-authorized'
                evidence_only = $true
                side_effect_executed = $false
                owner = 'codex-architecture-iteration'
                tool_gate = 'agent_structure'
                target_surfaces = @($RequestedSurfaces)
                required_alignment = @($interfacePolicy.structure_change_contract.preconditions)
                execution_rule = [string]$interfacePolicy.structure_change_contract.execution_rule
            }
        }
    }
}

if ($SessionId -and $SessionId -notmatch '^[A-Za-z0-9][A-Za-z0-9._-]{0,100}$') {
    throw 'SessionId contains unsupported characters.'
}
Assert-AgentLabel 'CallerId' $CallerId
Assert-AgentLabel 'ModelProvider' $ModelProvider
Assert-AgentLabel 'ModelId' $ModelId
Assert-AgentLabel 'HostId' $HostId

$accessOperation = if ($Mode -in @('Run', 'Continue')) {
    Resolve-AgentOperation -Requested $Operation -RequestedGoal $Goal -RequestedOwner $Owner
} else {
    $Mode
}
$accessSurfaces = if ($accessOperation -eq 'RequestStructureChange') { @($RequestedSurfaces) } else { @() }
$authorizationDecision = Test-AgentInterfaceAccess -ResolvedOperation $accessOperation -TargetSurfaces $accessSurfaces
if ($authorizationDecision.decision -ne 'allow') {
    $blocked = [ordered]@{
        schema_version = 3
        status = 'blocked'
        model = 'global-experience-agent'
        mode = $Mode
        operation = $accessOperation
        session_id = $SessionId
        interface = $Interface
        authorization_decision = $authorizationDecision
        durable_session_mutated = $false
        exit = New-AgentExit -Type 'authorization-required' -Status 'blocked' -AuthorityDecision $authorizationDecision -NextBoundary $authorizationDecision.next_authority_boundary
        completed_at = [DateTime]::UtcNow.ToString('o')
    }
    Write-AgentJsonAtomic -Path $OutputPath -Value $blocked
    $blocked | ConvertTo-Json -Depth 20
    return
}

if ($Mode -eq 'Run' -and -not $SessionId) {
    $SessionId = 'global-experience-' + [DateTime]::UtcNow.ToString('yyyyMMddTHHmmssZ') + '-' + [guid]::NewGuid().ToString('N').Substring(0, 8)
}
if (-not $SessionId) { throw "$Mode requires SessionId." }

$sessionDirectory = Join-Path $StateRoot $SessionId
$script:statePath = Join-Path $sessionDirectory 'state.json'
$script:eventLogPath = Join-Path $sessionDirectory 'events.jsonl'

if ($Mode -in @('Run', 'Continue') -and -not $Apply) {
    $previewOperation = Resolve-AgentOperation -Requested $Operation -RequestedGoal $Goal -RequestedOwner $Owner
    $previewOwnerNode = Get-AgentOwnerNode $Owner
    if ($previewOperation -eq 'RouteOwner' -and $null -eq $previewOwnerNode) { throw 'RouteOwner requires -Owner.' }
    [pscustomobject][ordered]@{
        schema_version = 2
        status = 'preview'
        model = 'global-experience-agent'
        mode = $Mode
        operation = $previewOperation
        owner = if ($previewOwnerNode) { [string]$previewOwnerNode.owner } else { $null }
        owner_network = ConvertTo-AgentPath $ownerNetworkPath
        agent_registry = ConvertTo-AgentPath $agentRegistryPath
        interface_policy = ConvertTo-AgentPath $interfacePolicyPath
        interface = $Interface
        authorization_decision = $authorizationDecision
        caller_context = [ordered]@{ caller_id=$CallerId; model_provider=$ModelProvider; model_id=$ModelId; host_id=$HostId }
        session_id = $SessionId
        state_root = ConvertTo-AgentPath $StateRoot
        apply_required = $true
        exit = New-AgentExit -Type 'evidence' -Status 'preview' -AuthorityDecision $authorizationDecision -NextBoundary 'rerun with -Apply to create or continue durable state'
    } | ConvertTo-Json -Depth 10
    return
}

if (-not $Apply) { throw "$Mode requires -Apply because it changes durable agent state." }

if ($Mode -in @('Run', 'Continue')) {
    $callerContext = [ordered]@{ caller_id=$CallerId; model_provider=$ModelProvider; model_id=$ModelId; host_id=$HostId }
    if ($Mode -eq 'Run') {
        if (Test-Path -LiteralPath $script:statePath -PathType Leaf) {
            throw "Global experience agent session already exists: $SessionId"
        }
        New-Item -ItemType Directory -Force -Path $sessionDirectory | Out-Null
        $now = [DateTime]::UtcNow.ToString('o')
        $script:state = [ordered]@{
            schema_version = 3
            model = 'global-experience-agent'
            agent_id = 'global-experience-agent'
            registry = ConvertTo-AgentPath $agentRegistryPath
            session_id = $SessionId
            status = 'running'
            phase = 'turn'
            created_at = $now
            updated_at = $now
            leaf_id = $null
            turn_count = 1
            goal = $Goal
            goal_sha256 = Get-AgentSha256 $Goal
            authority = $Authority
            authority_sha256 = Get-AgentSha256 $Authority
            interface = $Interface
            authority_scope = $AuthorityScope
            authorization_evidence_sha256 = $authorizationDecision.authorization_evidence_sha256
            caller_context = $callerContext
            caller_history = @($CallerId)
            model_history = @("$ModelProvider/$ModelId")
            queues = [ordered]@{ steer = @(); followUp = @(); nextTurn = @() }
            pending_writes = @()
            children = @()
            work = $null
            active_operation = $null
            last_save_point = $null
            recovery = [ordered]@{
                status = 'armed'
                policy = ConvertTo-AgentPath (Join-Path $root 'config\agent-transport-recovery-policy.json')
                restart_required = $false
            }
            timing = $null
        }
        Add-DurableEntry 'session' ([ordered]@{session_id=$SessionId;agent_id='global-experience-agent';model='global-experience-agent';manifest='config/agent-system.json';registry=ConvertTo-AgentPath $agentRegistryPath;source_commit=$manifest.template.source_commit;caller_context=$callerContext}) | Out-Null
    } else {
        if (-not (Test-Path -LiteralPath $script:statePath -PathType Leaf) -or -not (Test-Path -LiteralPath $script:eventLogPath -PathType Leaf)) { throw "Global experience agent session was not found: $SessionId" }
        $script:state = Get-Content -LiteralPath $script:statePath -Raw -Encoding UTF8 | ConvertFrom-Json
        if ($script:state.phase -ne 'idle' -or $script:state.status -eq 'running') { throw 'Continue requires an idle durable save-point boundary; use Resume after interruption.' }
        if ($script:state.status -eq 'aborted') { throw 'Continue cannot run an aborted session; inspect or start a new session.' }
        if ($script:state.status -eq 'blocked-restart-required') { throw 'Continue is blocked after a transport failure; restart Codex or the affected host, then use Resume before Continue.' }
        if (-not ($script:state.PSObject.Properties.Name -contains 'children')) { $script:state | Add-Member -NotePropertyName children -NotePropertyValue @() }
        if (-not ($script:state.PSObject.Properties.Name -contains 'caller_history')) { $script:state | Add-Member -NotePropertyName caller_history -NotePropertyValue @() }
        if (-not ($script:state.PSObject.Properties.Name -contains 'model_history')) { $script:state | Add-Member -NotePropertyName model_history -NotePropertyValue @() }
        if (-not ($script:state.PSObject.Properties.Name -contains 'work')) { $script:state | Add-Member -NotePropertyName work -NotePropertyValue $null }
        if (-not ($script:state.PSObject.Properties.Name -contains 'recovery')) {
            $script:state | Add-Member -NotePropertyName recovery -NotePropertyValue ([ordered]@{ status='armed'; policy=ConvertTo-AgentPath (Join-Path $root 'config\agent-transport-recovery-policy.json'); restart_required=$false })
        }
        if (-not ($script:state.PSObject.Properties.Name -contains 'caller_context')) { $script:state | Add-Member -NotePropertyName caller_context -NotePropertyValue $callerContext }
        if (-not ($script:state.PSObject.Properties.Name -contains 'agent_id')) { $script:state | Add-Member -NotePropertyName agent_id -NotePropertyValue 'global-experience-agent' }
        if (-not ($script:state.PSObject.Properties.Name -contains 'registry')) { $script:state | Add-Member -NotePropertyName registry -NotePropertyValue (ConvertTo-AgentPath $agentRegistryPath) }
        $script:state.turn_count = [int]$script:state.turn_count + 1
        $script:state.status = 'running'
        $script:state.phase = 'turn'
        $script:state.goal = $Goal
        $script:state.goal_sha256 = Get-AgentSha256 $Goal
        $script:state.authority = $Authority
        $script:state.authority_sha256 = Get-AgentSha256 $Authority
        if (-not ($script:state.PSObject.Properties.Name -contains 'interface')) { $script:state | Add-Member -NotePropertyName interface -NotePropertyValue $Interface } else { $script:state.interface = $Interface }
        if (-not ($script:state.PSObject.Properties.Name -contains 'authority_scope')) { $script:state | Add-Member -NotePropertyName authority_scope -NotePropertyValue $AuthorityScope } else { $script:state.authority_scope = $AuthorityScope }
        if (-not ($script:state.PSObject.Properties.Name -contains 'authorization_evidence_sha256')) { $script:state | Add-Member -NotePropertyName authorization_evidence_sha256 -NotePropertyValue $authorizationDecision.authorization_evidence_sha256 } else { $script:state.authorization_evidence_sha256 = $authorizationDecision.authorization_evidence_sha256 }
        $script:state.caller_context = $callerContext
        $script:state.caller_history = @($script:state.caller_history + $CallerId | Select-Object -Unique)
        $script:state.model_history = @($script:state.model_history + "$ModelProvider/$ModelId" | Select-Object -Unique)
        Add-DurableEntry 'caller_context_changed' ([ordered]@{caller_context=$callerContext;turn=$script:state.turn_count}) | Out-Null
    }

    Add-DurableEntry 'operation_started' ([ordered]@{ operation = 'agent_turn'; phase = 'turn'; mode=$Mode }) | Out-Null
    Add-DurableEntry 'turn_started' ([ordered]@{ turn = $script:state.turn_count; goal_sha256 = $script:state.goal_sha256; caller_context=$callerContext }) | Out-Null
    Add-QueueValues -QueueName 'steer' -Values $Steer
    Add-QueueValues -QueueName 'followUp' -Values $FollowUp
    Add-QueueValues -QueueName 'nextTurn' -Values $NextTurn
    foreach ($write in @($PendingWrite | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })) {
        $script:state.pending_writes = @($script:state.pending_writes) + @([ordered]@{
            id = New-AgentId 'pending'
            value = $write
            value_sha256 = Get-AgentSha256 $write
        })
        Add-DurableEntry 'pending_write_enqueued' ([ordered]@{ value_sha256 = Get-AgentSha256 $write }) | Out-Null
    }

    $resolvedOperation = Resolve-AgentOperation -Requested $Operation -RequestedGoal $Goal -RequestedOwner $Owner
    if ($script:lastIntentDecision) {
        Add-DurableEntry 'intent_classified' $script:lastIntentDecision | Out-Null
    }
    $selectedOwnerNode = Get-AgentOwnerNode $Owner
    if ($resolvedOperation -eq 'RouteOwner' -and $null -eq $selectedOwnerNode) { throw 'RouteOwner requires -Owner.' }
    $operationContract = Get-OperationContract -ResolvedOperation $resolvedOperation -SelectedOwnerNode $selectedOwnerNode
    if ($resolvedOperation -eq 'CompleteIteration' -and -not (Test-AgentPathIsInsideRoot -Path $StateRoot -RootPath $root)) {
        throw 'CompleteIteration is a global F:\codex iteration gate and cannot be run from a project-local StateRoot. Use project lifecycle records for project-local closeout, or start a canonical F:\codex session for a real global iteration.'
    }
    if ($operationContract.gate_required) {
        $gate = @($manifest.tool_gates | Where-Object { $_.name -eq $operationContract.tool_gate })
        if ($gate.Count -ne 1) { throw "Agent tool gate is not registered: $($operationContract.tool_gate)" }
        if ([string]::IsNullOrWhiteSpace($Authority)) { throw 'A gated agent operation requires an authority record.' }
    }

    $resourceFiles = if ($resolvedOperation -eq 'RouteOwner') {
        @(
            @($manifest.resources.information_units) +
            @($manifest.harness.interfaces) +
            @([string]$manifest.owner_network.source) +
            @([string]$selectedOwnerNode.skill)
        ) | ForEach-Object { [string]$_ } | Sort-Object -Unique
    } else {
        @(
            @($manifest.resources.information_units) +
            @($manifest.resources.functional_units) +
            @($manifest.harness.interfaces)
        ) | ForEach-Object { [string]$_ } | Sort-Object -Unique
    }
    $gitHead = (& git -C $root rev-parse HEAD).Trim()
    $snapshot = [ordered]@{
        id = New-AgentId 'snapshot'
        immutable = $true
        session_id = $SessionId
        turn = $script:state.turn_count
        created_at = [DateTime]::UtcNow.ToString('o')
        goal_sha256 = $script:state.goal_sha256
        authority_sha256 = $script:state.authority_sha256
        git_head = $gitHead
        resources = $resourceFiles
        active_tools = @($operationContract.tool_gate)
        operation = $resolvedOperation
        selected_owner = if ($selectedOwnerNode) { [string]$selectedOwnerNode.owner } else { $operationContract.owner }
        owner_network = [string]$manifest.owner_network.source
        agent_registry = [string]$manifest.agent_registry.source
        interface_policy = ConvertTo-AgentPath $interfacePolicyPath
        interface = $Interface
        authority_scope = $AuthorityScope
        authorization_decision = $authorizationDecision
        agent_id = $AgentId
        caller_context = $callerContext
        execution_options = [ordered]@{ apply = $true; retry_safe = $operationContract.retry_safe; idempotent = $operationContract.idempotent }
    }
    Add-DurableEntry 'turn_snapshot_created' $snapshot | Out-Null
    Add-DurableEntry 'agent_resources_selected' ([ordered]@{ resources = $resourceFiles; count = $resourceFiles.Count }) | Out-Null
    Add-DurableEntry 'tool_gate_requested' ([ordered]@{
        name = $operationContract.tool_gate
        owner = $operationContract.owner
        required = $operationContract.gate_required
        authority_sha256 = $script:state.authority_sha256
        decision = if ($operationContract.evidence_only) { 'evidence-only' } else { 'authorized' }
    }) | Out-Null

    # Book-shelf-learning: run deliberation review checkpoint before gated actions
    $reviewCheckpoint = Invoke-AgentReviewCheckpoint -ResolvedOperation $resolvedOperation -OperationContract $operationContract
    Add-DurableEntry 'agent_review_checkpoint_result' ([ordered]@{ status = [string]$reviewCheckpoint.status; risk_level = [string]$reviewCheckpoint.risk_level; lenses_applied = [int]$reviewCheckpoint.lenses_applied }) | Out-Null
    Add-DurableEntry 'interface_access_authorized' $authorizationDecision | Out-Null
    $script:state.active_operation = [ordered]@{
        name = $resolvedOperation
        started_at = [DateTime]::UtcNow.ToString('o')
        retry_safe = $operationContract.retry_safe
        idempotent = $operationContract.idempotent
        snapshot_id = $snapshot.id
    }
    Save-AgentState

    try {
        Add-DurableEntry 'tool_call_started' ([ordered]@{ operation = $resolvedOperation; tool_gate = $operationContract.tool_gate }) | Out-Null
        $toolResult = Invoke-AgentOperation -ResolvedOperation $resolvedOperation -SelectedOwnerNode $selectedOwnerNode
        if ($toolResult -and $toolResult.restart_required -eq $true) {
            Add-DurableEntry 'tool_call_finished' ([ordered]@{ operation = $resolvedOperation; result = $toolResult; is_error = $true; restart_required = $true }) | Out-Null
            $restartResult = New-AgentRestartRequiredResult -RecoverySignal $toolResult.recovery -ResolvedOperation $resolvedOperation -Source 'child-agent'
            Write-AgentJsonAtomic -Path $OutputPath -Value $restartResult
            $restartResult | ConvertTo-Json -Depth 20
            return
        }
        Add-DurableEntry 'tool_call_finished' ([ordered]@{ operation = $resolvedOperation; result = $toolResult; is_error = $false }) | Out-Null
        Add-DurableEntry 'tool_result_recorded' ([ordered]@{ operation = $resolvedOperation; result = $toolResult }) | Out-Null

        foreach ($pending in @($script:state.pending_writes)) {
            Add-DurableEntry 'pending_write_applied' ([ordered]@{ id = $pending.id; value_sha256 = $pending.value_sha256 }) | Out-Null
        }
        $script:state.pending_writes = @()
        foreach ($queueName in @('steer', 'followUp')) {
            $queued = @($script:state.queues.$queueName)
            if ($queued.Count -gt 0) {
                Add-DurableEntry 'queue_consumed' ([ordered]@{ queue = $queueName; count = $queued.Count }) | Out-Null
                $script:state.queues.$queueName = @()
            }
        }

        Add-DurableEntry 'turn_finished' ([ordered]@{ turn = $script:state.turn_count; operation = $resolvedOperation; status = 'passed' }) | Out-Null
        $savePoint = [ordered]@{
            id = New-AgentId 'savepoint'
            accepted = $true
            operation = $resolvedOperation
            snapshot_id = $snapshot.id
            git_head = $gitHead
            result = $toolResult
            created_at = [DateTime]::UtcNow.ToString('o')
        }
        Add-DurableEntry 'save_point_committed' $savePoint | Out-Null
        Add-DurableEntry 'operation_finished' ([ordered]@{ operation = 'agent_turn'; status = 'settled' }) | Out-Null
        $script:state.last_save_point = $savePoint
        $script:state.active_operation = $null
        $script:state.phase = 'idle'
        $script:state.status = 'settled'
        Save-AgentState

        $exitType = if ($resolvedOperation -eq 'RequestStructureChange') {
            'global-structure-change-request'
        } elseif ($resolvedOperation -eq 'ReviewAgent') {
            'agent-reviewed'
        } elseif ($operationContract.gate_required) {
            'gated-action-request'
        } elseif ($resolvedOperation -eq 'RouteOwner') {
            'handoff'
        } else {
            'save-point'
        }
        $result = [ordered]@{
            schema_version = 3
            status = 'passed'
            model = 'global-experience-agent'
            mode = $Mode
            session_id = $SessionId
            operation = $resolvedOperation
            task_contract = [ordered]@{
                goal = $Goal
                authority = $Authority
                owner = $operationContract.owner
                verification = 'tool result plus accepted durable save point'
            }
            caller_context = $callerContext
            agent_registry = ConvertTo-AgentPath $agentRegistryPath
            interface_policy = ConvertTo-AgentPath $interfacePolicyPath
            interface = $Interface
            authorization_decision = $authorizationDecision
            turn_snapshot = $snapshot
            tool_result = $toolResult
            save_point = $savePoint
            durable_state = [ordered]@{
                state = ConvertTo-AgentPath $script:statePath
                events = ConvertTo-AgentPath $script:eventLogPath
                phase = $script:state.phase
                next_turn_count = @($script:state.queues.nextTurn).Count
                child_count = @($script:state.children).Count
                work_status = if ($script:state.work) { $script:state.work.status } else { $null }
            }
            exit = New-AgentExit -Type $exitType -Status 'passed' -AuthorityDecision $authorizationDecision -NextBoundary $authorizationDecision.next_authority_boundary
            timing = New-AgentTiming -CompletedAt ([DateTime]::UtcNow) -SessionStartedAt ([string]$script:state.created_at)
            completed_at = [DateTime]::UtcNow.ToString('o')
        }
        Write-AgentJsonAtomic -Path $OutputPath -Value $result
        $result | ConvertTo-Json -Depth 20
    } catch {
        $failure = $_.Exception.Message
        $recoverySignal = Get-AgentTransportRecoverySignal -Policy $transportRecoveryPolicy -ErrorText $failure -Component "global-experience-agent/$resolvedOperation" -BeforeCompletion
        if ($recoverySignal.restart_required -eq $true) {
            $restartResult = New-AgentRestartRequiredResult -RecoverySignal $recoverySignal -ResolvedOperation $resolvedOperation -Source 'global-experience-agent'
            Write-AgentJsonAtomic -Path $OutputPath -Value $restartResult
            $restartResult | ConvertTo-Json -Depth 20
            return
        }
        try {
            Add-DurableEntry 'operation_interrupted' ([ordered]@{ operation = $resolvedOperation; error = $failure }) | Out-Null
            $script:state.status = 'interrupted'
            $script:state.phase = 'idle'
            $script:state.active_operation = $null
            Save-AgentState
        } catch {
            # Preserve the original operation error when failure cleanup cannot write.
        }
        throw
    }
    return
}

if (-not (Test-Path -LiteralPath $script:statePath -PathType Leaf)) {
    throw "Global experience agent session was not found: $SessionId"
}
$script:state = Read-AgentState -Path $script:statePath -RepairMalformedJson:($Mode -eq 'Resume')
if (-not (Test-Path -LiteralPath $script:eventLogPath -PathType Leaf)) {
    throw "Global experience agent event log was not found: $SessionId"
}
if (-not ($script:state.PSObject.Properties.Name -contains 'children')) { $script:state | Add-Member -NotePropertyName children -NotePropertyValue @() }
if (-not ($script:state.PSObject.Properties.Name -contains 'caller_history')) { $script:state | Add-Member -NotePropertyName caller_history -NotePropertyValue @() }
if (-not ($script:state.PSObject.Properties.Name -contains 'model_history')) { $script:state | Add-Member -NotePropertyName model_history -NotePropertyValue @() }
if (-not ($script:state.PSObject.Properties.Name -contains 'work')) { $script:state | Add-Member -NotePropertyName work -NotePropertyValue $null }
if (-not ($script:state.PSObject.Properties.Name -contains 'caller_context')) { $script:state | Add-Member -NotePropertyName caller_context -NotePropertyValue ([ordered]@{caller_id='legacy-caller';model_provider='legacy-host';model_id='unknown';host_id='legacy-host'}) }

if ($Mode -eq 'Resume') {
    foreach ($name in @('children','caller_history','model_history','work')) {
        if (-not ($script:state.PSObject.Properties.Name -contains $name)) {
            $defaultValue = if ($name -eq 'work') { $null } else { @() }
            $script:state | Add-Member -NotePropertyName $name -NotePropertyValue $defaultValue
        }
    }
    if (-not ($script:state.PSObject.Properties.Name -contains 'recovery')) {
        $script:state | Add-Member -NotePropertyName recovery -NotePropertyValue ([ordered]@{ status='armed'; policy=ConvertTo-AgentPath (Join-Path $root 'config\agent-transport-recovery-policy.json'); restart_required=$false })
    }
    $restartRecovery = $null
    if ($script:state.status -eq 'blocked-restart-required' -and $script:state.recovery) {
        $restartRecovery = $script:state.recovery
        $script:state.recovery = [ordered]@{
            status = 'armed'
            policy = ConvertTo-AgentPath (Join-Path $root 'config\agent-transport-recovery-policy.json')
            restart_required = $false
            resumed_from = 'restart-required'
            previous_classification = [string]$restartRecovery.classification
            resumed_at = [DateTime]::UtcNow.ToString('o')
        }
        Add-DurableEntry 'restart_recovery_resumed' ([ordered]@{
            previous_classification = [string]$restartRecovery.classification
            previous_error_sha256 = [string]$restartRecovery.error_sha256
            resume_boundary = 'post-restart durable session'
        }) | Out-Null
    }
    $recoveredInterrupted = $false
    if ($script:state.phase -ne 'idle' -or $script:state.status -eq 'running') {
        Add-DurableEntry 'operation_interrupted' ([ordered]@{
            operation = if ($script:state.active_operation) { $script:state.active_operation.name } else { 'unknown' }
            reason = 'host recovery found an unfinished operation'
        }) | Out-Null
        $script:state.phase = 'idle'
        $script:state.status = 'interrupted'
        $script:state.active_operation = $null
        $recoveredInterrupted = $true
    }
    Add-QueueValues -QueueName 'steer' -Values $Steer
    Add-QueueValues -QueueName 'followUp' -Values $FollowUp
    Add-QueueValues -QueueName 'nextTurn' -Values $NextTurn
    $resumeCallerContext = [ordered]@{caller_id=$CallerId;model_provider=$ModelProvider;model_id=$ModelId;host_id=$HostId}
    $script:state.caller_context = $resumeCallerContext
    $script:state.caller_history = @($script:state.caller_history + $CallerId | Select-Object -Unique)
    $script:state.model_history = @($script:state.model_history + "$ModelProvider/$ModelId" | Select-Object -Unique)
    Add-DurableEntry 'caller_context_changed' ([ordered]@{caller_context=$resumeCallerContext;mode='Resume'}) | Out-Null
    Add-DurableEntry 'recovery_completed' ([ordered]@{
        interrupted_operation_marked = $recoveredInterrupted
        resume_boundary = 'durable save point or conservative interruption'
    }) | Out-Null
    if ($script:state.status -ne 'aborted') { $script:state.status = 'settled' }
    Save-AgentState
    $result = [ordered]@{
        schema_version = 3
        status = 'passed'
        model = 'global-experience-agent'
        mode = $Mode
        session_id = $SessionId
        recovered_interrupted_operation = $recoveredInterrupted
        phase = $script:state.phase
        last_save_point = $script:state.last_save_point
        queues = $script:state.queues
        caller_context = $resumeCallerContext
        interface = $Interface
        authorization_decision = $authorizationDecision
        caller_history = @($script:state.caller_history)
        model_history = @($script:state.model_history)
        work = $script:state.work
        children = @($script:state.children)
        timing = New-AgentTiming -CompletedAt ([DateTime]::UtcNow) -SessionStartedAt ([string]$script:state.created_at)
        relevant_records = @(Get-RelevantAgentRecords $Query)
        pending_write_count = @($script:state.pending_writes).Count
        durable_state = [ordered]@{ state = ConvertTo-AgentPath $script:statePath; events = ConvertTo-AgentPath $script:eventLogPath }
        exit = New-AgentExit -Type 'save-point' -Status 'passed' -AuthorityDecision $authorizationDecision -NextBoundary 'continue from the restored idle save point'
    }
    Write-AgentJsonAtomic -Path $OutputPath -Value $result
    $result | ConvertTo-Json -Depth 20
    return
}

if ($Mode -eq 'Abort') {
    Add-DurableEntry 'abort_requested' ([ordered]@{
        previous_phase = $script:state.phase
        clear = @('steer', 'followUp')
        preserve = @('nextTurn', 'pending_writes')
    }) | Out-Null
    $script:state.queues.steer = @()
    $script:state.queues.followUp = @()
    $script:state.phase = 'idle'
    $script:state.status = 'aborted'
    $script:state.active_operation = $null
    $script:state.caller_context = [ordered]@{caller_id=$CallerId;model_provider=$ModelProvider;model_id=$ModelId;host_id=$HostId}
    Add-DurableEntry 'operation_finished' ([ordered]@{ operation = 'abort'; status = 'settled' }) | Out-Null
    Save-AgentState
    $result = [ordered]@{
        schema_version = 3
        status = 'passed'
        model = 'global-experience-agent'
        mode = $Mode
        session_id = $SessionId
        phase = $script:state.phase
        caller_context = $script:state.caller_context
        interface = $Interface
        authorization_decision = $authorizationDecision
        abort = [ordered]@{
            settled = $true
            steer_count = @($script:state.queues.steer).Count
            follow_up_count = @($script:state.queues.followUp).Count
            next_turn_count = @($script:state.queues.nextTurn).Count
            pending_write_count = @($script:state.pending_writes).Count
        }
        timing = New-AgentTiming -CompletedAt ([DateTime]::UtcNow) -SessionStartedAt ([string]$script:state.created_at)
        durable_state = [ordered]@{ state = ConvertTo-AgentPath $script:statePath; events = ConvertTo-AgentPath $script:eventLogPath }
        exit = New-AgentExit -Type 'save-point' -Status 'passed' -AuthorityDecision $authorizationDecision -NextBoundary 'start a new session or inspect the aborted durable state'
    }
    Write-AgentJsonAtomic -Path $OutputPath -Value $result
    $result | ConvertTo-Json -Depth 20
}
