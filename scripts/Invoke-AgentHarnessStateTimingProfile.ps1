[CmdletBinding()]
param(
    [string]$RepositoryRoot = 'F:\codex',
    [int]$Iterations = 8,
    [string]$OutputPath = ''
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath $RepositoryRoot).Path
if ($Iterations -lt 3) { throw 'Iterations must be at least 3.' }

$reader = Join-Path $root 'agent\40-runtime\Get-AgentHarnessState.ps1'
$manifestPath = Join-Path $root 'config\agent-system.json'
$filesystemPath = Join-Path $root 'agent\agent-filesystem.json'
$lastRunPath = Join-Path $root '.codex\project\global-experience-agent-last-run.json'
foreach ($path in @($reader, $manifestPath, $filesystemPath)) {
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "Required Agent file is missing: $path" }
}

$analysisRoot = Join-Path $root '.codex\project\timing-analysis'

function Get-Summary($Values) {
    $sorted = @($Values | ForEach-Object { [double]$_ } | Sort-Object)
    [ordered]@{
        count = $sorted.Count
        min_ms = [Math]::Round($sorted[0], 3)
        median_ms = [Math]::Round($sorted[[Math]::Floor(($sorted.Count - 1) / 2)], 3)
        max_ms = [Math]::Round($sorted[$sorted.Count - 1], 3)
        mean_ms = [Math]::Round((($sorted | Measure-Object -Average).Average), 3)
    }
}

function Invoke-Timed([string]$Name, [scriptblock]$Block) {
    $watch = [Diagnostics.Stopwatch]::StartNew()
    $value = & $Block
    $watch.Stop()
    [pscustomobject][ordered]@{
        name = $Name
        wall_ms = [Math]::Round($watch.Elapsed.TotalMilliseconds, 3)
        value = $value
    }
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

$rows = New-Object System.Collections.Generic.List[object]
$substepRows = New-Object System.Collections.Generic.List[object]
for ($i = 0; $i -lt $Iterations; $i++) {
    $manifestStep = Invoke-Timed 'agent-system-manifest-parse' {
        (Get-Content -LiteralPath $manifestPath -Raw -Encoding UTF8 | ConvertFrom-Json).model
    }
    $filesystemStep = Invoke-Timed 'agent-filesystem-parse' {
        (Get-Content -LiteralPath $filesystemPath -Raw -Encoding UTF8 | ConvertFrom-Json).model
    }
    $lastRunStep = Invoke-Timed 'last-run-state-parse' {
        if (Test-Path -LiteralPath $lastRunPath -PathType Leaf) {
            (Get-Content -LiteralPath $lastRunPath -Raw -Encoding UTF8 | ConvertFrom-Json).status
        } else {
            'missing'
        }
    }
    foreach ($step in @($manifestStep, $filesystemStep, $lastRunStep)) {
        [void]$substepRows.Add([pscustomobject][ordered]@{
            iteration = $i
            name = $step.name
            wall_ms = $step.wall_ms
            value = [string]$step.value
        })
    }

    $watch = [Diagnostics.Stopwatch]::StartNew()
    $json = & $reader -RepositoryRoot $root
    $watch.Stop()
    if ($LASTEXITCODE -ne 0) { throw 'Get-AgentHarnessState profile run failed.' }
    $state = $json | ConvertFrom-Json
    if ($state.status -ne 'passed') { throw 'Get-AgentHarnessState did not return a passed state projection.' }

    [void]$rows.Add([pscustomobject][ordered]@{
        iteration = $i
        controller_wall_ms = [Math]::Round($watch.Elapsed.TotalMilliseconds, 3)
        output_bytes = [Text.Encoding]::UTF8.GetByteCount($json)
        status = [string]$state.status
        schema_version = [int]$state.schema_version
        information_unit_count = @($state.resources.information_units).Count
        functional_unit_count = @($state.resources.functional_units).Count
        tool_gate_count = @($state.tool_gates).Count
        owner_count = [int]$state.owner_network.active_owner_count
        pending_write_model_present = ($null -ne $state.pending_session_writes)
        last_run_present = ($null -ne $state.global_experience_agent.last_run)
    })
}

$rowArray = @($rows.ToArray())
$substepArray = @($substepRows.ToArray())
$substepSummaries = @()
foreach ($name in @($substepArray | ForEach-Object name | Sort-Object -Unique)) {
    $values = @($substepArray | Where-Object name -eq $name | ForEach-Object wall_ms)
    $substepSummaries += [pscustomobject][ordered]@{
        name = $name
        wall_ms = Get-Summary $values
        last_value = @($substepArray | Where-Object name -eq $name | Select-Object -Last 1).value
    }
}
$slowest = @($substepSummaries | Sort-Object { [double]$_.wall_ms.median_ms } -Descending | Select-Object -First 1)
$invalid = @($rowArray | Where-Object { $_.status -ne 'passed' -or $_.schema_version -lt 4 -or $_.information_unit_count -le 0 -or $_.functional_unit_count -le 0 -or $_.tool_gate_count -le 0 -or $_.owner_count -le 0 -or -not $_.pending_write_model_present })
if ($invalid.Count -gt 0) { throw 'Get-AgentHarnessState profile produced an invalid state projection.' }

$result = [ordered]@{
    schema_version = 1
    generated_at = [DateTime]::UtcNow.ToString('o')
    classification = 'agentharnessstate_benchmark_profile'
    goal = 'global-experience-self-iteration-full'
    todo_id = 'todo_9068e7fa3192'
    iterations = $Iterations
    dataset = 'local Get-AgentHarnessState projections; no private session content read'
    measurements = [ordered]@{
        controller_wall = Get-Summary (@($rowArray | ForEach-Object controller_wall_ms))
        output_bytes = Get-Summary (@($rowArray | ForEach-Object output_bytes))
        substeps = @($substepSummaries)
    }
    observations = $rowArray
    substep_observations = $substepArray
    static_substeps = @(
        'agent-system manifest parse',
        'agent filesystem parse',
        'last-run state parse',
        'information and functional unit projection',
        'memory, intent, loop, recovery, retrieval, and codebase-memory policy projection',
        'owner network and registry projection',
        'pending writes, queue, savepoint, and recovery model projection',
        'JSON state output'
    )
    decision = [ordered]@{
        result = 'benchmarked-no-action'
        reason = 'Get-AgentHarnessState is an unobserved runtime functional unit now benchmarked in controlled local runs. It projects broad harness, resource, owner-network, policy, pending-write, recovery, and last-run state for routing and diagnostics; no equivalent strict improvement is proven without narrowing state projection or weakening readiness evidence.'
        slowest_substep = if ($slowest.Count -gt 0) { [string]$slowest[0].name } else { $null }
        next_candidate = 'Regenerate the functional-unit frontier and select the next remaining high-cost hotspot after Get-AgentHarnessState benchmark no-action closeout.'
    }
    safety = [ordered]@{
        code_changed = $false
        credentials_read = $false
        private_session_content_read = $false
        destructive_git = $false
        publication_action = $false
    }
}

if ([string]::IsNullOrWhiteSpace($OutputPath)) {
    $OutputPath = Join-Path $analysisRoot 'agentharnessstate-profile.json'
}
$mdPath = [IO.Path]::ChangeExtension($OutputPath, '.md')
$result.artifacts = @(
    ('.codex/project/timing-analysis/' + [IO.Path]::GetFileName($OutputPath)),
    ('.codex/project/timing-analysis/' + [IO.Path]::GetFileName($mdPath))
)
Write-AtomicUtf8NoBom -Path $OutputPath -Value (($result | ConvertTo-Json -Depth 8) + [Environment]::NewLine)
$lines = @(
    '# Get-AgentHarnessState Timing Profile',
    '',
    ('Generated: ' + $result.generated_at),
    '',
    ('Iterations: ' + $Iterations),
    '',
    '## Decision',
    '',
    $result.decision.reason,
    '',
    ('Slowest measured local substep: ' + $result.decision.slowest_substep),
    '',
    '## Measurements',
    '',
    ('- Controller median: ' + $result.measurements.controller_wall.median_ms + ' ms'),
    ('- Output median: ' + $result.measurements.output_bytes.median_ms + ' bytes'),
    '',
    '## Substeps',
    ''
)
foreach ($step in @($result.measurements.substeps)) {
    $lines += ('- ' + $step.name + ': median=' + $step.wall_ms.median_ms + ' ms; max=' + $step.wall_ms.max_ms + ' ms')
}
$lines += @(
    '',
    '## Next',
    '',
    $result.decision.next_candidate
)
Write-AtomicUtf8NoBom -Path $mdPath -Value (($lines -join "`n") + "`n")
$result | ConvertTo-Json -Depth 8
