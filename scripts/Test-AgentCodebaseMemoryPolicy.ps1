[CmdletBinding()]
param(
    [string]$RepositoryRoot = 'F:\codex'
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath $RepositoryRoot).Path

function Read-JsonFile([string]$RelativePath) {
    $path = Join-Path $root $RelativePath
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        throw "Required file is missing: $RelativePath"
    }
    Get-Content -LiteralPath $path -Raw -Encoding UTF8 | ConvertFrom-Json
}

$policy = Read-JsonFile 'config\agent-codebase-memory-policy.json'
if ($policy.model -ne 'agent-codebase-memory-policy') { throw 'Codebase Memory policy model mismatch.' }
if ($policy.owner -ne 'codex-information-gathering') { throw 'Codebase Memory policy must be owned by codex-information-gathering.' }
if ($policy.entry_owner -ne 'codex-self-evolution') { throw 'Codebase Memory entry owner must be codex-self-evolution.' }
if ($policy.canonical_project.name -ne 'F-codex') { throw 'Canonical Codebase Memory project must be F-codex.' }
if ($policy.canonical_project.root_normalized -ne 'F:/codex') { throw 'Canonical Codebase Memory root must normalize to F:/codex.' }
if ($policy.canonical_project.default_mode -ne 'fast') { throw 'Canonical Codebase Memory default mode must be fast.' }
if (-not $policy.callable_discovery.registry_first) { throw 'Codebase Memory policy must require callable registry discovery first.' }
if ($policy.automatic_indexing.auto_index_setting -ne $false) { throw 'Codebase Memory auto-indexing must be disabled.' }
if (@($policy.automatic_indexing.automatic_projects).Count -ne 1 -or $policy.automatic_indexing.automatic_projects[0].name -ne 'F-codex') { throw 'Automatic Codebase Memory indexing must be limited to F-codex.' }
if ($policy.automatic_indexing.explicit_c_drive_rule -notmatch 'temporary task-scoped project') { throw 'C-drive inspection must require a temporary task-scoped project.' }

$operationNames = @($policy.allowed_operations | ForEach-Object { [string]$_.name })
foreach ($requiredOperation in @('index_repository','get_graph_schema','get_architecture','search_code','trace_path')) {
    if ($operationNames -notcontains $requiredOperation) {
        throw "Codebase Memory policy is missing required operation: $requiredOperation"
    }
}
$indexOperation = @($policy.allowed_operations | Where-Object { $_.name -eq 'index_repository' } | Select-Object -First 1)
if (-not $indexOperation) { throw 'index_repository operation is missing.' }
if ($indexOperation.required_arguments.name -ne 'F-codex') { throw 'index_repository must target F-codex.' }
if ($indexOperation.required_arguments.repo_path -ne 'F:\codex') { throw 'index_repository must target F:\codex.' }
if ($indexOperation.required_arguments.mode -ne 'fast') { throw 'index_repository must use fast mode by default.' }
if (-not $indexOperation.required_arguments.persistence) { throw 'index_repository must request persistent artifact generation.' }

foreach ($phase in @('entry_refresh','coverage_inspection','route_evidence','source_verify','save_point_record')) {
    if (@($policy.agent_use_lifecycle | ForEach-Object { [string]$_.phase }) -notcontains $phase) {
        throw "Codebase Memory lifecycle is missing phase: $phase"
    }
}

$neverAllowed = @($policy.authority_boundary.never_allowed | ForEach-Object { [string]$_ })
foreach ($phrase in @('creating aliases for F:\codex','treating graph misses as absence proof without source verification','using graph evidence to bypass owner tool gates','automatically indexing Codex installation')) {
    if (-not ($neverAllowed | Where-Object { $_ -like "*$phrase*" })) {
        throw "Codebase Memory authority boundary is missing: $phrase"
    }
}
if ($policy.source_verification_rule -notmatch 'source files and tests') {
    throw 'Codebase Memory source verification rule must keep source files and tests as final proof.'
}
if ($policy.single_project_validation.script -ne 'scripts/Test-CodebaseMemoryProjectScope.ps1') {
    throw 'Codebase Memory single-project validation must use Test-CodebaseMemoryProjectScope.ps1.'
}

$agentSystem = Read-JsonFile 'config\agent-system.json'
$informationUnits = @($agentSystem.resources.information_units | ForEach-Object { [string]$_ })
$functionalUnits = @($agentSystem.resources.functional_units | ForEach-Object { [string]$_ })
foreach ($requiredInfo in @('config/agent-codebase-memory-policy.json','knowledge-vault/30-Knowledge/Codebase Memory MCP.md','knowledge-vault/20-Workflows/Codebase Graph Evidence Workflow.md')) {
    if ($informationUnits -notcontains $requiredInfo) { throw "Agent system information units do not include $requiredInfo." }
}
foreach ($requiredFunction in @('config/agent-codebase-memory-policy.json','scripts/Test-AgentCodebaseMemoryPolicy.ps1')) {
    if ($functionalUnits -notcontains $requiredFunction) { throw "Agent system functional units do not include $requiredFunction." }
}

$stateReader = Join-Path $root 'agent\40-runtime\Get-AgentHarnessState.ps1'
$state = (& $stateReader -RepositoryRoot $root) | ConvertFrom-Json
if (-not $state.agent_codebase_memory) { throw 'Agent harness state does not expose agent_codebase_memory.' }
if ($state.agent_codebase_memory.canonical_project.name -ne 'F-codex') {
    throw 'Agent harness state exposes the wrong Codebase Memory project.'
}
if (@($state.agent_codebase_memory.allowed_operations | ForEach-Object { [string]$_.name }) -notcontains 'index_repository') {
    throw 'Agent harness state does not expose index_repository as an allowed Codebase Memory operation.'
}

[pscustomobject]@{
    result = 'agent-codebase-memory-policy-passed'
    canonical_project = $policy.canonical_project.name
    owner = $policy.owner
    operations = $operationNames
} | ConvertTo-Json -Depth 6
