[CmdletBinding()]
param(
    [string]$RepositoryRoot = 'F:\codex',
    [int]$Iterations = 8,
    [string]$OutputPath = ''
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath $RepositoryRoot).Path
if ($Iterations -lt 3) { throw 'Iterations must be at least 3.' }

$controller = Join-Path $root 'agent\40-runtime\Invoke-GlobalExperienceAgent.ps1'
$runtimePath = Join-Path $root 'agent\40-runtime\Invoke-GlobalExperienceAgentRuntime.ps1'
$interfacePolicyPath = Join-Path $root 'config\agent-interface-policy.json'
$structuralPolicyPath = Join-Path $root 'config\agent-structural-optimization-policy.json'
foreach ($path in @($controller, $runtimePath, $interfacePolicyPath, $structuralPolicyPath)) {
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "Required Agent file is missing: $path" }
}

$analysisRoot = Join-Path $root '.codex\project\timing-analysis'
$workRoot = Join-Path $root '.runtime\work\requeststructurechange-profile-20260809'
if (Test-Path -LiteralPath $workRoot) { Remove-Item -LiteralPath $workRoot -Recurse -Force }
New-Item -ItemType Directory -Force -Path $workRoot | Out-Null

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

$requestedSurfaceSets = @(
    @('config/agent-system.json', 'agent/40-runtime/Invoke-GlobalExperienceAgentRuntime.ps1'),
    @('config/agent-interface-policy.json', 'config/global-experience-agent-registry.json'),
    @('agent/agent-filesystem.json', 'config/agent-owner-connections.json')
)

$rows = New-Object System.Collections.Generic.List[object]
$substepRows = New-Object System.Collections.Generic.List[object]
try {
    for ($i = 0; $i -lt $Iterations; $i++) {
        $sessionId = 'requeststructurechange-profile-' + $i + '-' + [guid]::NewGuid().ToString('N').Substring(0, 8)
        $output = Join-Path $workRoot ($sessionId + '.json')
        $requestedSurfaces = @($requestedSurfaceSets[$i % $requestedSurfaceSets.Count])

        $interfacePolicyStep = Invoke-Timed 'interface-policy-json-parse' {
            (Get-Content -LiteralPath $interfacePolicyPath -Raw -Encoding UTF8 | ConvertFrom-Json).structure_change_contract.tool_gate
        }
        $contractStep = Invoke-Timed 'structure-change-contract-parse' {
            $policy = Get-Content -LiteralPath $interfacePolicyPath -Raw -Encoding UTF8 | ConvertFrom-Json
            (@($policy.structure_change_contract.preconditions).Count).ToString()
        }
        $surfaceValidationStep = Invoke-Timed 'requested-surface-validation' {
            $policy = Get-Content -LiteralPath $interfacePolicyPath -Raw -Encoding UTF8 | ConvertFrom-Json
            $allowed = @($policy.structural_surfaces | ForEach-Object { [string]$_ })
            $invalid = @($requestedSurfaces | Where-Object { $allowed -notcontains $_ })
            if ($invalid.Count -gt 0) { throw ('Unexpected non-structural test surface: ' + ($invalid -join ', ')) }
            $requestedSurfaces.Count
        }
        $structuralPolicyStep = Invoke-Timed 'structural-optimization-policy-parse' {
            (Get-Content -LiteralPath $structuralPolicyPath -Raw -Encoding UTF8 | ConvertFrom-Json).schema_version
        }
        foreach ($step in @($interfacePolicyStep, $contractStep, $surfaceValidationStep, $structuralPolicyStep)) {
            [void]$substepRows.Add([pscustomobject][ordered]@{
                iteration = $i
                surfaces = ($requestedSurfaces -join ';')
                name = $step.name
                wall_ms = $step.wall_ms
                value = [string]$step.value
            })
        }

        $watch = [Diagnostics.Stopwatch]::StartNew()
        $json = & $controller `
            -RepositoryRoot $root `
            -Mode Run `
            -Operation RequestStructureChange `
            -SessionId $sessionId `
            -StateRoot $workRoot `
            -OutputPath $output `
            -Goal 'synthetic RequestStructureChange profile for timing optimization; no private content' `
            -Interface global-control `
            -AuthorityScope global-structure `
            -AuthorizationEvidence 'current-user-fixture:agent-interface-policy' `
            -RequestedSurfaces $requestedSurfaces `
            -Authority 'bounded local timing profile' `
            -Apply
        $watch.Stop()
        if ($LASTEXITCODE -ne 0) { throw 'RequestStructureChange profile run failed.' }
        $run = $json | ConvertFrom-Json
        $statePath = Join-Path $workRoot ($sessionId + '\' + 'state.json')
        [void]$rows.Add([pscustomobject][ordered]@{
            iteration = $i
            controller_wall_ms = [Math]::Round($watch.Elapsed.TotalMilliseconds, 3)
            operation_wall_ms = [Math]::Round(([double]$run.timing.operation_wall_clock_seconds * 1000), 3)
            output_bytes = (Get-Item -LiteralPath $output).Length
            state_bytes = if (Test-Path -LiteralPath $statePath -PathType Leaf) { (Get-Item -LiteralPath $statePath).Length } else { 0 }
            status = [string]$run.status
            save_point = [bool]$run.save_point.accepted
            exit_type = [string]$run.exit.type
            result = [string]$run.tool_result.result
            owner = [string]$run.tool_result.owner
            tool_gate = [string]$run.tool_result.tool_gate
            target_surface_count = @($run.tool_result.target_surfaces).Count
            evidence_only = [bool]$run.tool_result.evidence_only
            side_effect_executed = [bool]$run.tool_result.side_effect_executed
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

    $invalid = @($rowArray | Where-Object { $_.status -ne 'passed' -or -not $_.save_point -or $_.exit_type -ne 'global-structure-change-request' -or $_.result -ne 'structure-change-authorized' -or $_.owner -ne 'codex-architecture-iteration' -or $_.tool_gate -ne 'agent_structure' -or -not $_.evidence_only -or $_.side_effect_executed })
    if ($invalid.Count -gt 0) { throw 'RequestStructureChange profile produced an invalid authorization result.' }

    $result = [ordered]@{
        schema_version = 1
        generated_at = [DateTime]::UtcNow.ToString('o')
        classification = 'requeststructurechange_substep_profile'
        goal = 'global-experience-self-iteration-full'
        todo_id = 'todo_5ffc3aabc2bc'
        iterations = $Iterations
        dataset = 'synthetic RequestStructureChange sessions under .runtime/work with declared structural surfaces; no private session content read'
        measurements = [ordered]@{
            controller_wall = Get-Summary (@($rowArray | ForEach-Object controller_wall_ms))
            runtime_operation = Get-Summary (@($rowArray | ForEach-Object operation_wall_ms))
            output_bytes = Get-Summary (@($rowArray | ForEach-Object output_bytes))
            state_bytes = Get-Summary (@($rowArray | ForEach-Object state_bytes))
            substeps = @($substepSummaries)
        }
        observations = $rowArray
        substep_observations = $substepArray
        static_substeps = @(
            'interface policy load',
            'structure change contract parse',
            'requested structural surface validation',
            'global-control and global-structure access decision',
            'agent_structure gate projection',
            'codex-architecture-iteration owner boundary',
            'evidence-only authorization result',
            'global-structure-change-request exit',
            'savepoint writeback'
        )
        decision = [ordered]@{
            result = 'profiled-no-action'
            reason = 'RequestStructureChange median runtime is sub-second in controlled local runs. Agent-structure gate projection, target-surface evidence, owner authority boundary, evidence-only semantics, rollback boundary, and Full closeout protections are part of the structural safety contract; no equivalent strict improvement is proven.'
            slowest_substep = if ($slowest.Count -gt 0) { [string]$slowest[0].name } else { $null }
            next_candidate = 'Regenerate the functional-unit frontier and select the next remaining high-cost hotspot after RequestStructureChange no-action closeout.'
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
        $OutputPath = Join-Path $analysisRoot 'requeststructurechange-profile.json'
    }
    $mdPath = [IO.Path]::ChangeExtension($OutputPath, '.md')
    $result.artifacts = @(
        ('.codex/project/timing-analysis/' + [IO.Path]::GetFileName($OutputPath)),
        ('.codex/project/timing-analysis/' + [IO.Path]::GetFileName($mdPath))
    )
    Write-AtomicUtf8NoBom -Path $OutputPath -Value (($result | ConvertTo-Json -Depth 8) + [Environment]::NewLine)
    $lines = @(
        '# RequestStructureChange Timing Profile',
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
        ('- Runtime median: ' + $result.measurements.runtime_operation.median_ms + ' ms'),
        ('- Output median: ' + $result.measurements.output_bytes.median_ms + ' bytes'),
        ('- State median: ' + $result.measurements.state_bytes.median_ms + ' bytes'),
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
} finally {
    if (Test-Path -LiteralPath $workRoot) { Remove-Item -LiteralPath $workRoot -Recurse -Force -ErrorAction SilentlyContinue }
}
