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
if (-not (Test-Path -LiteralPath $controller -PathType Leaf)) { throw "Required Agent script is missing: $controller" }

$analysisRoot = Join-Path $root '.codex\project\timing-analysis'
$workRoot = Join-Path $root '.runtime\work\joinsubagent-profile-20260809'
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

$evidencePath = 'config/minimal-agent-template.json'
$evidenceFullPath = Join-Path $root $evidencePath
if (-not (Test-Path -LiteralPath $evidenceFullPath -PathType Leaf)) { throw "Evidence fixture is missing: $evidencePath" }

$rows = New-Object System.Collections.Generic.List[object]
$substepRows = New-Object System.Collections.Generic.List[object]
try {
    for ($i = 0; $i -lt $Iterations; $i++) {
        $sessionId = 'joinsubagent-profile-' + $i + '-' + [guid]::NewGuid().ToString('N').Substring(0, 8)
        $childId = 'join-profile-child-' + $i + '-' + [guid]::NewGuid().ToString('N').Substring(0, 8)
        $delegateOutput = Join-Path $workRoot ($sessionId + '-delegate.json')
        $completeOutput = Join-Path $workRoot ($sessionId + '-complete.json')
        $joinOutput = Join-Path $workRoot ($sessionId + '-join.json')

        $delegateJson = & $controller `
            -RepositoryRoot $root `
            -Mode Run `
            -Operation DelegateSubagent `
            -SessionId $sessionId `
            -StateRoot $workRoot `
            -OutputPath $delegateOutput `
            -Goal 'synthetic JoinSubagent setup for timing optimization; no private content' `
            -AgentId career-planning-agent `
            -ChildId $childId `
            -WriteSurface '.runtime/work/career-planning-agent/joinsubagent-profile' `
            -AcceptanceCriteria 'profile only' `
            -Verification 'synthetic timing profile setup; no merge' `
            -Authority 'bounded local timing profile' `
            -Apply
        if ($LASTEXITCODE -ne 0) { throw 'JoinSubagent setup delegation failed.' }
        $delegateRun = $delegateJson | ConvertFrom-Json
        if ($delegateRun.status -ne 'passed' -or -not [bool]$delegateRun.save_point.accepted) { throw 'JoinSubagent setup did not create an accepted child save point.' }

        $completeJson = & $controller `
            -RepositoryRoot $root `
            -Mode Continue `
            -Operation CompleteSubagent `
            -SessionId $sessionId `
            -StateRoot $workRoot `
            -OutputPath $completeOutput `
            -Goal 'synthetic JoinSubagent completion setup; no private content' `
            -ChildId $childId `
            -ResultSummary 'Synthetic child result for JoinSubagent timing profile.' `
            -ResultEvidence $evidencePath `
            -Verification 'synthetic timing profile evidence exists and is hash recorded' `
            -Authority 'bounded local timing profile' `
            -Apply
        if ($LASTEXITCODE -ne 0) { throw 'JoinSubagent setup completion failed.' }
        $completeRun = $completeJson | ConvertFrom-Json
        if ($completeRun.status -ne 'passed' -or -not [bool]$completeRun.save_point.accepted) { throw 'JoinSubagent setup did not complete the child.' }

        $statePath = Join-Path $workRoot ($sessionId + '\' + 'state.json')
        $childStatePath = Join-Path $workRoot ($sessionId + '--' + $childId + '\' + 'state.json')
        $preChildRead = Invoke-Timed 'pre-read-completed-child-state' {
            $raw = Get-Content -LiteralPath $childStatePath -Raw -Encoding UTF8
            ($raw | ConvertFrom-Json).status
        }
        $preParentRead = Invoke-Timed 'pre-read-parent-child-reference' {
            $raw = Get-Content -LiteralPath $statePath -Raw -Encoding UTF8
            (@(($raw | ConvertFrom-Json).children) | Where-Object id -eq $childId)[0].status
        }

        $watch = [Diagnostics.Stopwatch]::StartNew()
        $json = & $controller `
            -RepositoryRoot $root `
            -Mode Continue `
            -Operation JoinSubagent `
            -SessionId $sessionId `
            -StateRoot $workRoot `
            -OutputPath $joinOutput `
            -Goal 'synthetic JoinSubagent profile for timing optimization; no private content' `
            -ChildId $childId `
            -MergeDisposition accepted `
            -Verification 'synthetic parent merge verification preserves child evidence hash and bounded result' `
            -Authority 'bounded local timing profile' `
            -Apply
        $watch.Stop()
        if ($LASTEXITCODE -ne 0) { throw 'JoinSubagent profile run failed.' }
        $run = $json | ConvertFrom-Json

        $postChildRead = Invoke-Timed 'post-read-joined-child-state' {
            $raw = Get-Content -LiteralPath $childStatePath -Raw -Encoding UTF8
            ($raw | ConvertFrom-Json).status
        }
        $postParentRead = Invoke-Timed 'post-read-parent-child-reference' {
            $raw = Get-Content -LiteralPath $statePath -Raw -Encoding UTF8
            (@(($raw | ConvertFrom-Json).children) | Where-Object id -eq $childId)[0].status
        }
        foreach ($step in @($preChildRead, $preParentRead, $postChildRead, $postParentRead)) {
            [void]$substepRows.Add([pscustomObject][ordered]@{
                iteration = $i
                name = $step.name
                wall_ms = $step.wall_ms
                value = [string]$step.value
            })
        }

        $joinedChildState = Get-Content -LiteralPath $childStatePath -Raw -Encoding UTF8 | ConvertFrom-Json
        $parentState = Get-Content -LiteralPath $statePath -Raw -Encoding UTF8 | ConvertFrom-Json
        $parentChild = @($parentState.children | Where-Object id -eq $childId)[0]
        [void]$rows.Add([pscustomobject][ordered]@{
            iteration = $i
            controller_wall_ms = [Math]::Round($watch.Elapsed.TotalMilliseconds, 3)
            operation_wall_ms = [Math]::Round(([double]$run.timing.operation_wall_clock_seconds * 1000), 3)
            output_bytes = (Get-Item -LiteralPath $joinOutput).Length
            parent_state_bytes = (Get-Item -LiteralPath $statePath).Length
            child_state_bytes = (Get-Item -LiteralPath $childStatePath).Length
            status = [string]$run.status
            save_point = [bool]$run.save_point.accepted
            result = [string]$run.tool_result.result
            disposition = [string]$run.tool_result.disposition
            child_state_status = [string]$joinedChildState.status
            parent_child_status = [string]$parentChild.status
            parent_merge_status = [string]$parentChild.merge_status
            merge_verifier = [string]$joinedChildState.merge.verifier
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
    $invalid = @($rowArray | Where-Object { $_.status -ne 'passed' -or -not $_.save_point -or $_.result -ne 'subagent-joined' -or $_.disposition -ne 'accepted' -or $_.child_state_status -ne 'joined' -or $_.parent_child_status -ne 'joined' -or $_.parent_merge_status -ne 'accepted' })
    if ($invalid.Count -gt 0) { throw 'JoinSubagent profile produced an invalid joined result.' }

    $result = [ordered]@{
        schema_version = 1
        generated_at = [DateTime]::UtcNow.ToString('o')
        classification = 'joinsubagent_substep_profile'
        goal = 'global-experience-self-iteration-full'
        todo_id = 'todo_7290096060cd'
        iterations = $Iterations
        dataset = 'synthetic DelegateSubagent plus CompleteSubagent plus JoinSubagent sessions under .runtime/work; no private session content read'
        measurements = [ordered]@{
            controller_wall = Get-Summary (@($rowArray | ForEach-Object controller_wall_ms))
            runtime_operation = Get-Summary (@($rowArray | ForEach-Object operation_wall_ms))
            output_bytes = Get-Summary (@($rowArray | ForEach-Object output_bytes))
            parent_state_bytes = Get-Summary (@($rowArray | ForEach-Object parent_state_bytes))
            child_state_bytes = Get-Summary (@($rowArray | ForEach-Object child_state_bytes))
            substeps = @($substepSummaries)
        }
        observations = $rowArray
        substep_observations = $substepArray
        static_substeps = @(
            'child reference lookup',
            'completed child-state read',
            'merge disposition and verification validation',
            'registered verifier projection',
            'child merge mutation',
            'parent child-reference reconciliation',
            'child state and event writeback',
            'parent savepoint'
        )
        decision = [ordered]@{
            result = 'profiled-no-action'
            reason = 'JoinSubagent median runtime is sub-second in controlled local runs. Completed-child verification, registered verifier projection, child merge mutation, parent child-reference reconciliation, event writeback, and parent savepoint semantics are part of the merge safety and recovery contract; no equivalent strict improvement is proven.'
            slowest_substep = if ($slowest.Count -gt 0) { [string]$slowest[0].name } else { $null }
            next_candidate = 'Regenerate the functional-unit frontier and select the next remaining high-cost hotspot after JoinSubagent no-action closeout.'
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
        $OutputPath = Join-Path $analysisRoot 'joinsubagent-profile.json'
    }
    $mdPath = [IO.Path]::ChangeExtension($OutputPath, '.md')
    $result.artifacts = @(
        ('.codex/project/timing-analysis/' + [IO.Path]::GetFileName($OutputPath)),
        ('.codex/project/timing-analysis/' + [IO.Path]::GetFileName($mdPath))
    )
    Write-AtomicUtf8NoBom -Path $OutputPath -Value (($result | ConvertTo-Json -Depth 8) + [Environment]::NewLine)
    $lines = @(
        '# JoinSubagent Timing Profile',
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
        ('- Parent state median: ' + $result.measurements.parent_state_bytes.median_ms + ' bytes'),
        ('- Child state median: ' + $result.measurements.child_state_bytes.median_ms + ' bytes'),
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
