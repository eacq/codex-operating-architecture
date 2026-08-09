[CmdletBinding()]
param(
    [string]$RepositoryRoot = 'F:\codex',
    [switch]$Apply
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath $RepositoryRoot).Path
$projectPath = Join-Path $root '.codex\project'
$outputDir = Join-Path $projectPath 'timing-analysis'
$ledgerDir = Join-Path $outputDir 'session-timing-ledger'

function Read-Json([string]$Path) {
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { return $null }
    return Get-Content -LiteralPath $Path -Raw -Encoding UTF8 | ConvertFrom-Json
}

function Write-AtomicUtf8NoBom {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Value
    )
    $directory = Split-Path -Parent $Path
    New-Item -ItemType Directory -Force -Path $directory | Out-Null
    $tempPath = Join-Path $directory ('.' + [IO.Path]::GetFileName($Path) + '.' + [guid]::NewGuid().ToString('N') + '.tmp')
    try {
        [IO.File]::WriteAllText($tempPath, $Value, [Text.UTF8Encoding]::new($false))
        if ([IO.File]::Exists($Path)) {
            try { [IO.File]::Replace($tempPath, $Path, $null, $true) }
            catch { Move-Item -LiteralPath $tempPath -Destination $Path -Force }
        } else {
            [IO.File]::Move($tempPath, $Path)
        }
    } finally {
        if ([IO.File]::Exists($tempPath)) { Remove-Item -LiteralPath $tempPath -Force -ErrorAction SilentlyContinue }
    }
}

function Add-Metric {
    param(
        [hashtable]$Map,
        [string]$Operation,
        [double]$Seconds,
        [bool]$Error
    )
    if (-not $Map.ContainsKey($Operation)) {
        $Map[$Operation] = [ordered]@{ count = 0; sum_seconds = 0.0; max_seconds = 0.0; error_count = 0 }
    }
    $row = $Map[$Operation]
    $row.count++
    $row.sum_seconds = [math]::Round([double]$row.sum_seconds + $Seconds, 3)
    $row.max_seconds = [math]::Max([double]$row.max_seconds, $Seconds)
    if ($Error) { $row.error_count++ }
}

$functionalCatalog = Read-Json (Join-Path $root 'agent\30-resources\functional\catalog.json')
$runtimeCatalog = Read-Json (Join-Path $root 'agent\40-runtime\runtime.json')
if (-not $functionalCatalog -or -not $runtimeCatalog) { throw 'Agent functional/runtime catalogs are missing or invalid.' }

$metrics = @{}
$operationRows = New-Object System.Collections.Generic.List[object]
foreach ($ledger in @(Get-ChildItem -LiteralPath $ledgerDir -Filter '*.json' -File -ErrorAction SilentlyContinue)) {
    $record = Read-Json $ledger.FullName
    if (-not $record) { continue }
    foreach ($call in @($record.tool_calls)) {
        $operation = [string]$call.operation
        if ([string]::IsNullOrWhiteSpace($operation)) { continue }
        Add-Metric -Map $metrics -Operation $operation -Seconds ([double]$call.duration_seconds) -Error ([bool]$call.is_error)
    }
}
foreach ($key in @($metrics.Keys)) {
    $row = $metrics[$key]
    $operationRows.Add([pscustomobject][ordered]@{
        operation = $key
        count = [int]$row.count
        sum_seconds = [math]::Round([double]$row.sum_seconds, 3)
        max_seconds = [math]::Round([double]$row.max_seconds, 3)
        error_count = [int]$row.error_count
    })
}
$operationRows = @($operationRows | Sort-Object sum_seconds -Descending)

$runtimeOperations = @($runtimeCatalog.operations | ForEach-Object { [string]$_ })
$catalogUnits = @($functionalCatalog.units | ForEach-Object { [string]$_ })
$derivedUnits = @(
    'scripts/Invoke-CompleteGlobalExperienceIteration.ps1',
    'scripts/Invoke-CodexVerification.ps1',
    'scripts/Invoke-IsolatedGlobalExperienceIteration.ps1',
    'scripts/Invoke-HistoricalTimingAnalysis.ps1',
    'skills/codex-runtime-environments/scripts/Invoke-ScriptResourceRelease.ps1'
)
$allUnits = @($catalogUnits + $derivedUnits | Sort-Object -Unique)

$operationToUnits = @{
    CompleteIteration = @('scripts/Invoke-CompleteGlobalExperienceIteration.ps1')
    VerifyAgent = @('agent/40-runtime/Invoke-GlobalExperienceAgentRuntime.ps1', 'scripts/Test-AgentSystemTopology.ps1', 'scripts/Test-AgentHarnessContract.ps1', 'scripts/Test-AgentOwnerConnections.ps1', 'agent/80-maintenance/Test-AgentFilesystem.ps1')
    StoreMemory = @('agent/40-runtime/Invoke-AgentMemoryStore.py')
    SearchMemory = @('agent/40-runtime/Invoke-AgentMemoryStore.py')
    ConsolidateMemory = @('agent/40-runtime/Invoke-AgentMemoryStore.py')
    RenderMemorySnapshot = @('agent/40-runtime/Invoke-AgentMemoryStore.py')
    StartWork = @('agent/40-runtime/Invoke-GlobalExperienceAgentRuntime.ps1')
    RetrieveContext = @('agent/40-runtime/Invoke-GlobalExperienceAgentRuntime.ps1')
    CandidateReport = @('skills/codex-experience-capture/scripts/New-GlobalIterationCandidateReport.ps1')
    RouteOwner = @('config/agent-owner-connections.json')
    DelegateSubagent = @('agent/40-runtime/Invoke-GlobalExperienceAgentRuntime.ps1')
    CompleteSubagent = @('agent/40-runtime/Invoke-GlobalExperienceAgentRuntime.ps1')
    JoinSubagent = @('agent/40-runtime/Invoke-GlobalExperienceAgentRuntime.ps1')
    Abort = @('agent/40-runtime/Invoke-GlobalExperienceAgentRuntime.ps1')
    RequestStructureChange = @('agent/40-runtime/Invoke-GlobalExperienceAgentRuntime.ps1', 'config/agent-interface-policy.json', 'config/agent-structural-optimization-policy.json')
    EvaluateAccess = @('agent/40-runtime/Invoke-GlobalExperienceAgentRuntime.ps1', 'config/agent-interface-policy.json')
    DescribeInterfaces = @('agent/40-runtime/Invoke-GlobalExperienceAgentRuntime.ps1', 'config/agent-interface-policy.json')
    ResolveAgentPath = @('agent/40-runtime/Invoke-GlobalExperienceAgentRuntime.ps1', 'agent/agent-filesystem.json')
    DescribeFilesystem = @('agent/40-runtime/Invoke-GlobalExperienceAgentRuntime.ps1', 'agent/agent-filesystem.json')
    ClassifyIntent = @('agent/40-runtime/Invoke-GlobalExperienceAgentRuntime.ps1', 'config/agent-intent-policy.json')
    CancelSubagent = @('agent/40-runtime/Invoke-GlobalExperienceAgentRuntime.ps1')
    ReviewAgent = @('agent/40-runtime/Invoke-GlobalExperienceAgentRuntime.ps1', 'config/agent-review-lenses.json')
}

$unitRows = New-Object System.Collections.Generic.List[object]
foreach ($unit in $allUnits) {
    $matched = @($operationToUnits.GetEnumerator() | Where-Object { $_.Value -contains $unit } | ForEach-Object Key)
    $observations = @($operationRows | Where-Object { $_.operation -in $matched })
    $sum = if ($observations.Count) { [math]::Round((($observations | ForEach-Object sum_seconds) | Measure-Object -Sum).Sum, 3) } else { 0 }
    $max = if ($observations.Count) { [math]::Round((($observations | ForEach-Object max_seconds) | Measure-Object -Maximum).Maximum, 3) } else { 0 }
    $class = if ($unit -match 'Invoke-CompleteGlobalExperienceIteration|Invoke-IsolatedGlobalExperienceIteration|Invoke-CodexVerification|validate') { 'validation_or_writeback' } elseif ($unit -match 'Memory|memory') { 'memory' } elseif ($unit -match 'Index|Graph|Chunk|Retrieve|Parse') { 'retrieval_or_index' } elseif ($unit -match 'Resource|Cleanup|Release|Transport') { 'resource_or_recovery' } else { 'runtime_or_owner' }
    $decision = if ($unit -match 'Invoke-CompleteGlobalExperienceIteration|Invoke-IsolatedGlobalExperienceIteration|Invoke-CodexVerification') { 'preserve-full-proof; optimize only preliminary or duplicated work' } elseif ($sum -gt 10) { 'candidate-for-batched-or-cached-execution' } elseif ($sum -gt 0) { 'measure-before-change' } else { 'unobserved; benchmark before change' }
    $unitRows.Add([pscustomobject][ordered]@{
        path = $unit
        class = $class
        observed = ($observations.Count -gt 0)
        observed_operations = $matched
        observed_count = [int](($observations | ForEach-Object count | Measure-Object -Sum).Sum)
        observed_sum_seconds = $sum
        observed_max_seconds = $max
        decision = $decision
    })
}
$unitRows = @($unitRows | Sort-Object @{ Expression = 'observed_sum_seconds'; Descending = $true }, @{ Expression = 'path'; Descending = $false })
$hotspots = @($operationRows | Select-Object -First 12 | ForEach-Object {
    $operation = $_.operation
    [pscustomobject][ordered]@{
        functional_unit = $operation
        count = $_.count
        sum_seconds = $_.sum_seconds
        max_seconds = $_.max_seconds
        error_count = $_.error_count
        mapped_paths = @($operationToUnits[$operation])
        recommendation = if ($operation -eq 'CompleteIteration') { 'Keep Full closeout; optimize isolation, caching, and preliminary duplicate validation only.' } elseif ($operation -match 'Memory') { 'Benchmark process-start and SQLite round trips; consider bounded batch API.' } else { 'Profile substeps before changing behavior.' }
    }
})

$result = [ordered]@{
    schema_version = 1
    result = 'analyzed'
    generated_at = [DateTime]::UtcNow.ToString('o')
    scope = 'all-registered-experience-agent-functional-units'
    source_catalogs = @('agent/30-resources/functional/catalog.json','agent/40-runtime/runtime.json')
    catalog_functional_unit_count = $catalogUnits.Count
    analyzed_functional_unit_count = $allUnits.Count
    registered_runtime_operation_count = $runtimeOperations.Count
    observed_operation_count = $operationRows.Count
    unobserved_functional_unit_count = @($unitRows | Where-Object { -not $_.observed }).Count
    functional_units = $unitRows
    observed_operations = $operationRows
    observed_operation_hotspots = $hotspots
    decision = 'inventory-complete; optimize only with function-preserving validation and keep Full closeout proof'
}

if ($Apply) {
    New-Item -ItemType Directory -Force -Path $outputDir | Out-Null
    $jsonPath = Join-Path $outputDir 'experience-agent-functional-unit-inventory.json'
    $mdPath = Join-Path $outputDir 'experience-agent-functional-unit-inventory.md'
    Write-AtomicUtf8NoBom -Path $jsonPath -Value (($result | ConvertTo-Json -Depth 10) + [Environment]::NewLine)
    $lines = @('# Experience Agent Functional Unit Inventory','',('Generated: ' + $result.generated_at),'',('Catalog functional units: ' + $result.catalog_functional_unit_count + '; analyzed units including derived hotspots: ' + $result.analyzed_functional_unit_count + '; runtime operations: ' + $result.registered_runtime_operation_count + '; observed operations: ' + $result.observed_operation_count),'', '## Observed Hotspots','')
    foreach ($hotspot in $hotspots) { $lines += ('- ' + $hotspot.functional_unit + ': count=' + $hotspot.count + ' sum=' + $hotspot.sum_seconds + 's max=' + $hotspot.max_seconds + 's; ' + $hotspot.recommendation) }
    $lines += @('','## Registered Units','')
    foreach ($unit in $unitRows) { $lines += ('- ' + $unit.path + ': class=' + $unit.class + '; observed=' + $unit.observed + '; sum=' + $unit.observed_sum_seconds + 's; decision=' + $unit.decision) }
    Write-AtomicUtf8NoBom -Path $mdPath -Value (($lines -join "`n") + "`n")
    $result.artifacts = @('.codex/project/timing-analysis/experience-agent-functional-unit-inventory.json','.codex/project/timing-analysis/experience-agent-functional-unit-inventory.md')
}
$result | ConvertTo-Json -Depth 10
