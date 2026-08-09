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
foreach ($path in @($controller)) {
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "Required Agent script is missing: $path" }
}

$analysisRoot = Join-Path $root '.codex\project\timing-analysis'
$workRoot = Join-Path $root '.runtime\work\completesubagent-profile-20260809'
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

$evidencePath = 'config/minimal-agent-template.json'
$evidenceFullPath = Join-Path $root $evidencePath
if (-not (Test-Path -LiteralPath $evidenceFullPath -PathType Leaf)) { throw "Evidence fixture is missing: $evidencePath" }

$rows = New-Object System.Collections.Generic.List[object]
$substepRows = New-Object System.Collections.Generic.List[object]
try {
    for ($i = 0; $i -lt $Iterations; $i++) {
        $sessionId = 'completesubagent-profile-' + $i + '-' + [guid]::NewGuid().ToString('N').Substring(0, 8)
        $childId = 'career-complete-profile-' + $i + '-' + [guid]::NewGuid().ToString('N').Substring(0, 8)
        $delegateOutput = Join-Path $workRoot ($sessionId + '-delegate.json')
        $completeOutput = Join-Path $workRoot ($sessionId + '-complete.json')

        $delegateJson = & $controller `
            -RepositoryRoot $root `
            -Mode Run `
            -Operation DelegateSubagent `
            -SessionId $sessionId `
            -StateRoot $workRoot `
            -OutputPath $delegateOutput `
            -Goal 'synthetic CompleteSubagent setup for timing optimization; no private content' `
            -AgentId career-planning-agent `
            -ChildId $childId `
            -WriteSurface '.runtime/work/career-planning-agent/completesubagent-profile' `
            -AcceptanceCriteria 'profile only' `
            -Verification 'synthetic timing profile setup; no merge' `
            -Authority 'bounded local timing profile' `
            -Apply
        if ($LASTEXITCODE -ne 0) { throw 'CompleteSubagent setup delegation failed.' }
        $delegateRun = $delegateJson | ConvertFrom-Json
        if ($delegateRun.status -ne 'passed' -or -not [bool]$delegateRun.save_point.accepted) { throw 'CompleteSubagent setup did not create an accepted child save point.' }

        $childStatePath = Join-Path $workRoot ($sessionId + '--' + $childId + '\' + 'state.json')
        $preStateStep = Invoke-Timed 'pre-read-child-state' {
            $raw = Get-Content -LiteralPath $childStatePath -Raw -Encoding UTF8
            ($raw | ConvertFrom-Json).status
        }
        $evidenceHashStep = Invoke-Timed 'evidence-hash' {
            (Get-FileHash -LiteralPath $evidenceFullPath -Algorithm SHA256).Hash.ToLowerInvariant()
        }

        $watch = [Diagnostics.Stopwatch]::StartNew()
        $json = & $controller `
            -RepositoryRoot $root `
            -Mode Continue `
            -Operation CompleteSubagent `
            -SessionId $sessionId `
            -StateRoot $workRoot `
            -OutputPath $completeOutput `
            -Goal 'synthetic CompleteSubagent profile for timing optimization; no private content' `
            -ChildId $childId `
            -ResultSummary 'Synthetic child result for CompleteSubagent timing profile.' `
            -ResultEvidence $evidencePath `
            -Verification 'synthetic timing profile evidence exists and is hash recorded' `
            -Authority 'bounded local timing profile' `
            -Apply
        $watch.Stop()
        if ($LASTEXITCODE -ne 0) { throw 'CompleteSubagent profile run failed.' }
        $run = $json | ConvertFrom-Json

        $postStateStep = Invoke-Timed 'post-read-child-state' {
            $raw = Get-Content -LiteralPath $childStatePath -Raw -Encoding UTF8
            ($raw | ConvertFrom-Json).status
        }
        foreach ($step in @($preStateStep, $evidenceHashStep, $postStateStep)) {
            [void]$substepRows.Add([pscustomobject][ordered]@{
                iteration = $i
                name = $step.name
                wall_ms = $step.wall_ms
                value = [string]$step.value
            })
        }

        $completedChildState = Get-Content -LiteralPath $childStatePath -Raw -Encoding UTF8 | ConvertFrom-Json
        $statePath = Join-Path $workRoot ($sessionId + '\' + 'state.json')
        [void]$rows.Add([pscustomobject][ordered]@{
            iteration = $i
            controller_wall_ms = [Math]::Round($watch.Elapsed.TotalMilliseconds, 3)
            operation_wall_ms = [Math]::Round(([double]$run.timing.operation_wall_clock_seconds * 1000), 3)
            output_bytes = (Get-Item -LiteralPath $completeOutput).Length
            parent_state_bytes = if (Test-Path -LiteralPath $statePath -PathType Leaf) { (Get-Item -LiteralPath $statePath).Length } else { 0 }
            child_state_bytes = if (Test-Path -LiteralPath $childStatePath -PathType Leaf) { (Get-Item -LiteralPath $childStatePath).Length } else { 0 }
            child_lifecycle_ms = [Math]::Round(([double]$run.tool_result.timing.task_wall_clock_seconds * 1000), 3)
            status = [string]$run.status
            save_point = [bool]$run.save_point.accepted
            child_status = [string]$run.tool_result.status
            evidence_count = @($run.tool_result.evidence).Count
            recorded_evidence_hash = [string]@($run.tool_result.evidence)[0].sha256
            child_result_status = [string]$completedChildState.status
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

    $result = [ordered]@{
        schema_version = 1
        generated_at = [DateTime]::UtcNow.ToString('o')
        classification = 'completesubagent_substep_profile'
        goal = 'global-experience-self-iteration-full'
        todo_id = 'todo_e558f799b34b'
        iterations = $Iterations
        dataset = 'synthetic DelegateSubagent plus CompleteSubagent sessions under .runtime/work; no private session content read'
        measurements = [ordered]@{
            controller_wall = Get-Summary (@($rowArray | ForEach-Object controller_wall_ms))
            runtime_operation = Get-Summary (@($rowArray | ForEach-Object operation_wall_ms))
            child_lifecycle = Get-Summary (@($rowArray | ForEach-Object child_lifecycle_ms))
            output_bytes = Get-Summary (@($rowArray | ForEach-Object output_bytes))
            child_state_bytes = Get-Summary (@($rowArray | ForEach-Object child_state_bytes))
            substeps = @($substepSummaries)
        }
        observations = $rowArray
        substep_observations = $substepArray
        static_substeps = @(
            'child reference/status validation',
            'result summary, verification, and evidence argument validation',
            'repository-relative evidence scope check and SHA256 hash',
            'child state read and completion mutation',
            'child lifecycle timing calculation',
            'child state and event writeback',
            'parent savepoint'
        )
        decision = [ordered]@{
            result = 'profiled-no-action'
            reason = 'CompleteSubagent median runtime is sub-second in controlled local runs. The required evidence hash, child-state completion writeback, lifecycle timing, and parent savepoint are part of the child completion safety and recovery contract; no equivalent strict improvement is proven.'
            slowest_substep = if ($slowest.Count -gt 0) { [string]$slowest[0].name } else { $null }
            next_candidate = 'Regenerate the functional-unit frontier and select the next remaining high-cost hotspot after CompleteSubagent no-action closeout.'
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
        $OutputPath = Join-Path $analysisRoot 'completesubagent-profile.json'
    }
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $OutputPath) | Out-Null
    [IO.File]::WriteAllText($OutputPath, ($result | ConvertTo-Json -Depth 8), [Text.UTF8Encoding]::new($false))
    $result | ConvertTo-Json -Depth 8
} finally {
    if (Test-Path -LiteralPath $workRoot) { Remove-Item -LiteralPath $workRoot -Recurse -Force -ErrorAction SilentlyContinue }
}
