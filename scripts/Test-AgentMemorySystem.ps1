[CmdletBinding()]
param([string]$RepositoryRoot = 'F:\codex')

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath $RepositoryRoot).Path
$controller = Join-Path $root 'agent\40-runtime\Invoke-GlobalExperienceAgent.ps1'
$stateRoot = & (Join-Path $root 'scripts\Resolve-CodexRunRoot.ps1') -ArchitectureRoot $root -Kind tmp -ChildPath ('agent-memory-test-' + [guid]::NewGuid().ToString('N')) -Create
$memoryDb = Join-Path $stateRoot 'memory\memory.db'
$previousMemoryDb = $env:CODEX_AGENT_MEMORY_DB
$previousPythonEnvironment = @{
    PYTHONUTF8 = $env:PYTHONUTF8
    PYTHONIOENCODING = $env:PYTHONIOENCODING
    PYTHONNOUSERSITE = $env:PYTHONNOUSERSITE
}
try {
    $env:CODEX_AGENT_MEMORY_DB = $memoryDb
    $env:PYTHONUTF8 = '0'
    $env:PYTHONIOENCODING = 'utf-8:strict'
    $env:PYTHONNOUSERSITE = '0'
    $sessionId = 'agent-memory-fixture'
    $stored = & $controller -RepositoryRoot $root -Mode Run -Operation StoreMemory -SessionId $sessionId -StateRoot $stateRoot -Interface llm -AuthorityScope functional -AgentId 'experience-memory-agent' -Goal 'Store a verified memory about the Feynman-style Agent memory system.' -ResultSummary 'Feynman memory pattern maps to typed Agent memory with SQLite FTS5, TTL, supersession, consolidation, and frozen snapshots.' -MemoryType decision -MemoryLayer semantic -Priority 9 -Steer 'feynman-build-workshop' -ResultEvidence 'agent/40-runtime/Invoke-AgentMemoryStore.py' -Authority 'fixture bounded local authority' -Apply | ConvertFrom-Json
    if ($stored.status -ne 'passed' -or $stored.tool_result.result -ne 'memory-stored' -or -not (Test-Path -LiteralPath $memoryDb -PathType Leaf)) {
        throw 'StoreMemory did not persist a local SQLite memory.'
    }

    $procedureStored = & $controller -RepositoryRoot $root -Mode Continue -Operation StoreMemory -SessionId $sessionId -StateRoot $stateRoot -Interface llm -AuthorityScope functional -AgentId 'experience-memory-agent' -Goal 'Store a procedural workflow alias.' -ResultSummary 'A procedural memory type alias must persist as the canonical workflow type.' -MemoryType procedure -MemoryLayer procedural -Priority 8 -Authority 'fixture bounded local authority' -Apply | ConvertFrom-Json
    if ($procedureStored.tool_result.memory.type -ne 'workflow' -or $procedureStored.tool_result.memory.layer -ne 'procedural') {
        throw 'Procedure memory type did not normalize to canonical workflow/procedural storage.'
    }

    $found = & $controller -RepositoryRoot $root -Mode Continue -Operation SearchMemory -SessionId $sessionId -StateRoot $stateRoot -Interface human -AuthorityScope functional -Query 'SQLite FTS5 frozen snapshots' -Authority 'fixture bounded local authority' -Apply | ConvertFrom-Json
    if ($found.tool_result.result -ne 'memory-search-results' -or $found.tool_result.count -lt 1 -or ($found.tool_result.records[0].content -notmatch 'SQLite FTS5')) {
        throw 'SearchMemory did not retrieve the stored Agent memory.'
    }

    $consolidated = & $controller -RepositoryRoot $root -Mode Continue -Operation ConsolidateMemory -SessionId $sessionId -StateRoot $stateRoot -Interface internal-functional-unit -AuthorityScope functional -ResultSummary 'fixture consolidation' -Authority 'fixture bounded local authority' -Apply | ConvertFrom-Json
    if ($consolidated.tool_result.result -ne 'memory-consolidated') {
        throw 'ConsolidateMemory did not complete.'
    }

    $snapshot = & $controller -RepositoryRoot $root -Mode Continue -Operation RenderMemorySnapshot -SessionId $sessionId -StateRoot $stateRoot -Interface llm -AuthorityScope functional -Authority 'fixture bounded local authority' -Apply | ConvertFrom-Json
    $snapshotPath = Join-Path $root ([string]$snapshot.tool_result.output)
    if (-not (Test-Path -LiteralPath $snapshotPath -PathType Leaf)) {
        $snapshotPath = Join-Path $stateRoot 'memory\frozen-snapshot.md'
    }
    if ($snapshot.tool_result.result -ne 'memory-snapshot-rendered' -or $snapshot.tool_result.count -lt 1 -or -not (Test-Path -LiteralPath $snapshotPath -PathType Leaf)) {
        throw 'RenderMemorySnapshot did not create a stable snapshot.'
    }

    $denied = & $controller -RepositoryRoot $root -Mode Run -Operation RequestStructureChange -SessionId 'agent-memory-denied' -StateRoot $stateRoot -Interface llm -AuthorityScope functional -RequestedSurfaces 'agent/40-runtime/Invoke-AgentMemoryStore.py' -Authority 'fixture bounded local authority' -Apply | ConvertFrom-Json
    if ($denied.status -ne 'blocked' -or $denied.exit.type -ne 'authorization-required') {
        throw 'LLM interface must not directly mutate Agent memory structure.'
    }
    if ($env:PYTHONUTF8 -ne '0' -or $env:PYTHONIOENCODING -ne 'utf-8:strict' -or $env:PYTHONNOUSERSITE -ne '0') {
        throw 'Agent memory invocation did not restore the caller Python environment.'
    }

    [pscustomobject][ordered]@{
        status = 'passed'
        model = 'global-experience-agent-memory'
        backend = 'sqlite-fts5'
        operations = 4
        denied_structure_mutation = $true
    } | ConvertTo-Json -Compress
} finally {
    if ($null -eq $previousMemoryDb) { Remove-Item Env:\CODEX_AGENT_MEMORY_DB -ErrorAction SilentlyContinue } else { $env:CODEX_AGENT_MEMORY_DB = $previousMemoryDb }
    foreach ($name in $previousPythonEnvironment.Keys) {
        if ($null -eq $previousPythonEnvironment[$name]) { Remove-Item -LiteralPath "Env:$name" -ErrorAction SilentlyContinue }
        else { Set-Item -LiteralPath "Env:$name" -Value $previousPythonEnvironment[$name] }
    }
    $resolvedStateRoot = [IO.Path]::GetFullPath($stateRoot)
    $allowedRoot = [IO.Path]::GetFullPath('F:\.codex-codex-tmp').TrimEnd('\') + '\'
    if ($resolvedStateRoot.StartsWith($allowedRoot, [StringComparison]::OrdinalIgnoreCase) -and (Test-Path -LiteralPath $resolvedStateRoot)) {
        Remove-Item -LiteralPath $resolvedStateRoot -Recurse -Force
    }
}
