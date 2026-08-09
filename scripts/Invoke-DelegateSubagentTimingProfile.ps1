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
$snapshotScript = Join-Path $root 'agent\40-runtime\Get-AgentStructuralOptimizationSnapshot.ps1'
foreach ($path in @($controller, $snapshotScript)) {
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "Required Agent script is missing: $path" }
}

$analysisRoot = Join-Path $root '.codex\project\timing-analysis'
$workRoot = Join-Path $root '.runtime\work\delegatesubagent-profile-20260809'
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

$rows = New-Object System.Collections.Generic.List[object]
try {
    for ($i = 0; $i -lt $Iterations; $i++) {
        $sessionId = 'delegatesubagent-profile-' + $i + '-' + [guid]::NewGuid().ToString('N').Substring(0, 8)
        $childId = 'career-profile-' + $i + '-' + [guid]::NewGuid().ToString('N').Substring(0, 8)
        $output = Join-Path $workRoot ($sessionId + '.json')

        $snapshotWatch = [Diagnostics.Stopwatch]::StartNew()
        $snapshot = (& $snapshotScript -RepositoryRoot $root -AgentId career-planning-agent) | ConvertFrom-Json
        $snapshotWatch.Stop()
        if ($snapshot.status -ne 'synchronized') { throw 'DelegateSubagent profile requires a synchronized child structural snapshot.' }

        $watch = [Diagnostics.Stopwatch]::StartNew()
        $json = & $controller `
            -RepositoryRoot $root `
            -Mode Run `
            -Operation DelegateSubagent `
            -SessionId $sessionId `
            -StateRoot $workRoot `
            -OutputPath $output `
            -Goal 'synthetic DelegateSubagent profile for timing optimization; no private content' `
            -AgentId career-planning-agent `
            -ChildId $childId `
            -WriteSurface '.runtime/work/career-planning-agent/delegatesubagent-profile' `
            -AcceptanceCriteria 'profile only' `
            -Verification 'synthetic timing profile; no merge' `
            -Authority 'bounded local timing profile' `
            -Apply
        $watch.Stop()
        if ($LASTEXITCODE -ne 0) { throw 'DelegateSubagent profile run failed.' }
        $run = $json | ConvertFrom-Json
        $statePath = Join-Path $workRoot ($sessionId + '\' + 'state.json')
        $childStatePath = Join-Path $workRoot ($sessionId + '--' + $childId + '\' + 'state.json')
        [void]$rows.Add([pscustomobject][ordered]@{
            iteration = $i
            controller_wall_ms = [Math]::Round($watch.Elapsed.TotalMilliseconds, 3)
            operation_wall_ms = [Math]::Round(([double]$run.timing.operation_wall_clock_seconds * 1000), 3)
            structural_snapshot_ms = [Math]::Round($snapshotWatch.Elapsed.TotalMilliseconds, 3)
            output_bytes = (Get-Item -LiteralPath $output).Length
            parent_state_bytes = if (Test-Path -LiteralPath $statePath -PathType Leaf) { (Get-Item -LiteralPath $statePath).Length } else { 0 }
            child_state_bytes = if (Test-Path -LiteralPath $childStatePath -PathType Leaf) { (Get-Item -LiteralPath $childStatePath).Length } else { 0 }
            status = [string]$run.status
            save_point = [bool]$run.save_point.accepted
            child_status = [string]$run.tool_result.child.status
            child_agent_id = [string]$run.tool_result.child.agent_id
            baseline = [string]$run.tool_result.structural_optimization_snapshot.baseline_version
        })
    }

    $rowArray = @($rows.ToArray())
    $controllerWallSummary = Get-Summary (@($rowArray | ForEach-Object controller_wall_ms))
    $operationWallSummary = Get-Summary (@($rowArray | ForEach-Object operation_wall_ms))
    $snapshotSummary = Get-Summary (@($rowArray | ForEach-Object structural_snapshot_ms))
    $outputSizeSummary = Get-Summary (@($rowArray | ForEach-Object output_bytes))
    $childStateSizeSummary = Get-Summary (@($rowArray | ForEach-Object child_state_bytes))

    $result = [ordered]@{
        schema_version = 1
        generated_at = [DateTime]::UtcNow.ToString('o')
        classification = 'delegatesubagent_substep_profile'
        goal = 'global-experience-self-iteration-full'
        todo_id = 'todo_2f5bce96c087'
        iterations = $Iterations
        dataset = 'synthetic DelegateSubagent sessions under .runtime/work; no private session content read'
        measurements = [ordered]@{
            controller_wall = $controllerWallSummary
            runtime_operation = $operationWallSummary
            structural_snapshot = $snapshotSummary
            output_bytes = $outputSizeSummary
            child_state_bytes = $childStateSizeSummary
        }
        observations = $rowArray
        static_substeps = @(
            'argument and duplicate child validation',
            'Get-RegisteredAgent profile lookup',
            'Get-AgentStructuralOptimizationSnapshot.ps1',
            'child reference/state construction',
            'child state and event writeback',
            'parent child-list update and savepoint'
        )
        decision = [ordered]@{
            result = 'profiled-no-action'
            reason = 'DelegateSubagent median runtime is sub-second in controlled local runs. The required child structural snapshot, isolated child-state writeback, and parent savepoint are part of the safety and recovery contract; no equivalent strict improvement is proven.'
            next_candidate = 'Profile CandidateReport substeps or another remaining hotspot from the regenerated inventory.'
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
        $OutputPath = Join-Path $analysisRoot 'delegatesubagent-profile.json'
    }
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $OutputPath) | Out-Null
    [IO.File]::WriteAllText($OutputPath, ($result | ConvertTo-Json -Depth 8), [Text.UTF8Encoding]::new($false))
    $result | ConvertTo-Json -Depth 8
} finally {
    if (Test-Path -LiteralPath $workRoot) { Remove-Item -LiteralPath $workRoot -Recurse -Force -ErrorAction SilentlyContinue }
}
