[CmdletBinding()]
param([string]$RepositoryRoot = 'F:\codex')

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath $RepositoryRoot).Path

function Read-Json([string]$RelativePath) {
    $path = Join-Path $root $RelativePath
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        throw "Required file is missing: $RelativePath"
    }
    Get-Content -LiteralPath $path -Raw -Encoding UTF8 | ConvertFrom-Json
}

$policy = Read-Json 'config\agent-memory-skill-policy.json'
$system = Read-Json 'config\agent-system.json'
$registry = Read-Json 'config\global-experience-agent-registry.json'
$interfacePolicy = Read-Json 'config\agent-interface-policy.json'
$filesystem = Read-Json 'agent\agent-filesystem.json'

if ($policy.model -ne 'agent-memory-as-skill-policy' -or $policy.contract.capability_kind -ne 'registered-functional-unit') {
    throw 'Agent memory skill policy does not describe a registered functional unit.'
}
if ($policy.contract.rule -notmatch 'not a parallel global experience system entrypoint') {
    throw 'Agent memory skill policy must reject a parallel global experience entrypoint.'
}

$requiredOps = @('StoreMemory', 'SearchMemory', 'ConsolidateMemory', 'RenderMemorySnapshot')
foreach ($operation in $requiredOps) {
    if ($operation -notin @($system.agent_runtime.operations)) {
        throw "Agent runtime does not register memory operation: $operation"
    }
    if (-not $policy.operations.PSObject.Properties.Name.Contains($operation)) {
        throw "Agent memory skill policy is missing operation: $operation"
    }
    $requiredPermission = [string]$interfacePolicy.operation_permissions.$operation
    if ($requiredPermission -ne 'functional-unit-use') {
        throw "Memory operation should remain a functional-unit-use route: $operation"
    }
}

foreach ($relativePath in @(
    'config/agent-memory-skill-policy.json',
    'scripts/Test-AgentMemoryAsSkillPolicy.ps1'
)) {
    if ($relativePath -notin @($system.resources.information_units + $system.resources.functional_units)) {
        throw "Agent system resources do not register: $relativePath"
    }
}

if ([string]$filesystem.canonical_surfaces.memory_skill_policy -ne 'config/agent-memory-skill-policy.json') {
    throw 'Agent filesystem does not expose the memory skill policy as a canonical surface.'
}

$experienceMemoryAgent = @($registry.concept_agents | Where-Object id -eq 'experience-memory-agent')
if ($experienceMemoryAgent.Count -ne 1) {
    throw 'experience-memory-agent must remain the single concept Agent for memory capability composition.'
}
if ('config/agent-memory-skill-policy.json' -notin @($experienceMemoryAgent[0].resources)) {
    throw 'experience-memory-agent does not reference the memory skill policy.'
}
if ([string]$experienceMemoryAgent[0].purpose -notmatch 'search-before-store') {
    throw 'experience-memory-agent purpose does not include search-before-store behavior.'
}

foreach ($interfaceId in @('human', 'llm', 'internal-functional-unit')) {
    $entry = $policy.interfaces.$interfaceId
    foreach ($operation in $requiredOps) {
        if ($operation -notin @($entry.allowed)) {
            throw "$interfaceId cannot use registered memory operation $operation"
        }
    }
    if ([string]$entry.structure_mutation -ne 'denied') {
        throw "$interfaceId must not directly mutate Agent memory structure."
    }
}
if ([string]$policy.interfaces.'global-control'.structure_mutation -ne 'only-through-agent_structure-gate') {
    throw 'global-control memory structure mutation must still route through the agent_structure gate.'
}

foreach ($diagnosticId in @('write_search_ratio', 'memory_growth_per_step', 'redundant_write_ratio', 'memory_context_ratio', 'delayed_memory_failure_gap')) {
    if ($diagnosticId -notin @($policy.diagnostics.metrics.id)) {
        throw "Agent memory skill diagnostics are missing: $diagnosticId"
    }
}

$runtime = Join-Path $root 'agent\40-runtime\Invoke-GlobalExperienceAgentRuntime.ps1'
$runtimeText = Get-Content -LiteralPath $runtime -Raw -Encoding UTF8
foreach ($expected in @('agent_memory_stored', 'agent_memory_searched', 'agent_memory_consolidated', 'agent_memory_snapshot_rendered')) {
    if ($runtimeText -notmatch [regex]::Escape($expected)) {
        throw "Runtime does not emit memory action trace event: $expected"
    }
}

[pscustomobject][ordered]@{
    status = 'passed'
    model = 'agent-memory-as-skill-policy'
    operations = $requiredOps.Count
    diagnostics = @($policy.diagnostics.metrics).Count
    structure_gate = 'agent_structure'
} | ConvertTo-Json -Compress
