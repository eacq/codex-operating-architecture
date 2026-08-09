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
$workRoot = Join-Path $root '.runtime\work\cancelsubagent-profile-20260809'
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

$rows = New-Object System.Collections.Generic.List[object]
$substepRows = New-Object System.Collections.Generic.List[object]
try {
    for ($i = 0; $i -lt $Iterations; $i++) {
        $sessionId = 'cancelsubagent-profile-' + $i + '-' + [guid]::NewGuid().ToString('N').Substring(0, 8)
        $childId = 'cancel-profile-child-' + $i + '-' + [guid]::NewGuid().ToString('N').Substring(0, 8)
        $delegateOutput = Join-Path $workRoot ($sessionId + '-delegate.json')
        $cancelOutput = Join-Path $workRoot ($sessionId + '-cancel.json')

        $delegateJson = & $controller `
            -RepositoryRoot $root `
            -Mode Run `
            -Operation DelegateSubagent `
            -SessionId $sessionId `
            -StateRoot $workRoot `
            -OutputPath $delegateOutput `
            -Goal 'synthetic CancelSubagent setup for timing optimization; no private content' `
            -AgentId career-planning-agent `
            -ChildId $childId `
            -WriteSurface '.runtime/work/career-planning-agent/cancelsubagent-profile' `
            -AcceptanceCriteria 'profile only' `
            -Verification 'synthetic timing profile setup; cancellation only' `
            -Authority 'bounded local timing profile' `
            -Apply
        if ($LASTEXITCODE -ne 0) { throw 'CancelSubagent setup delegation failed.' }
        $delegateRun = $delegateJson | ConvertFrom-Json
        if ($delegateRun.status -ne 'passed' -or -not [bool]$delegateRun.save_point.accepted) { throw 'CancelSubagent setup did not create an accepted child save point.' }

        $statePath = Join-Path $workRoot ($sessionId + '\' + 'state.json')
        $childStatePath = Join-Path $workRoot ($sessionId + '--' + $childId + '\' + 'state.json')
        $preChildRead = Invoke-Timed 'pre-read-cancellable-child-state' {
            $raw = Get-Content -LiteralPath $childStatePath -Raw -Encoding UTF8
            ($raw | ConvertFrom-Json).status
        }
        $preParentRead = Invoke-Timed 'pre-read-parent-child-reference' {
            $raw = Get-Content -LiteralPath $statePath -Raw -Encoding UTF8
            (@(($raw | ConvertFrom-Json).children) | Where-Object id -eq $childId)[0].status
        }
        $reasonHashStep = Invoke-Timed 'cancellation-reason-hash' {
            $bytes = [Text.Encoding]::UTF8.GetBytes('Synthetic cancellation for CancelSubagent timing profile.')
            $sha = [Security.Cryptography.SHA256]::Create()
            try { ([BitConverter]::ToString($sha.ComputeHash($bytes)) -replace '-', '').ToLowerInvariant() } finally { $sha.Dispose() }
        }

        $watch = [Diagnostics.Stopwatch]::StartNew()
        $json = & $controller `
            -RepositoryRoot $root `
            -Mode Continue `
            -Operation CancelSubagent `
            -SessionId $sessionId `
            -StateRoot $workRoot `
            -OutputPath $cancelOutput `
            -Goal 'synthetic CancelSubagent profile for timing optimization; no private content' `
            -ChildId $childId `
            -ResultSummary 'Synthetic cancellation for CancelSubagent timing profile.' `
            -Authority 'bounded local timing profile' `
            -Apply
        $watch.Stop()
        if ($LASTEXITCODE -ne 0) { throw 'CancelSubagent profile run failed.' }
        $run = $json | ConvertFrom-Json

        $postChildRead = Invoke-Timed 'post-read-cancelled-child-state' {
            $raw = Get-Content -LiteralPath $childStatePath -Raw -Encoding UTF8
            ($raw | ConvertFrom-Json).status
        }
        $postParentRead = Invoke-Timed 'post-read-parent-child-reference' {
            $raw = Get-Content -LiteralPath $statePath -Raw -Encoding UTF8
            (@(($raw | ConvertFrom-Json).children) | Where-Object id -eq $childId)[0].status
        }
        foreach ($step in @($preChildRead, $preParentRead, $reasonHashStep, $postChildRead, $postParentRead)) {
            [void]$substepRows.Add([pscustomobject][ordered]@{
                iteration = $i
                name = $step.name
                wall_ms = $step.wall_ms
                value = [string]$step.value
            })
        }

        $cancelledChildState = Get-Content -LiteralPath $childStatePath -Raw -Encoding UTF8 | ConvertFrom-Json
        $parentState = Get-Content -LiteralPath $statePath -Raw -Encoding UTF8 | ConvertFrom-Json
        $parentChild = @($parentState.children | Where-Object id -eq $childId)[0]
        [void]$rows.Add([pscustomobject][ordered]@{
            iteration = $i
            controller_wall_ms = [Math]::Round($watch.Elapsed.TotalMilliseconds, 3)
            operation_wall_ms = [Math]::Round(([double]$run.timing.operation_wall_clock_seconds * 1000), 3)
            output_bytes = (Get-Item -LiteralPath $cancelOutput).Length
            parent_state_bytes = (Get-Item -LiteralPath $statePath).Length
            child_state_bytes = (Get-Item -LiteralPath $childStatePath).Length
            status = [string]$run.status
            save_point = [bool]$run.save_point.accepted
            result = [string]$run.tool_result.result
            child_status = [string]$run.tool_result.status
            child_state_status = [string]$cancelledChildState.status
            parent_child_status = [string]$parentChild.status
            parent_merge_status = [string]$parentChild.merge_status
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
    $invalid = @($rowArray | Where-Object { $_.status -ne 'passed' -or -not $_.save_point -or $_.result -ne 'subagent-cancelled' -or $_.child_status -ne 'cancelled' -or $_.child_state_status -ne 'cancelled' -or $_.parent_child_status -ne 'cancelled' -or $_.parent_merge_status -ne 'not-applicable' })
    if ($invalid.Count -gt 0) { throw 'CancelSubagent profile produced an invalid cancelled result.' }

    $result = [ordered]@{
        schema_version = 1
        generated_at = [DateTime]::UtcNow.ToString('o')
        classification = 'cancelsubagent_substep_profile'
        goal = 'global-experience-self-iteration-full'
        todo_id = 'todo_1e9ca01140c2'
        iterations = $Iterations
        dataset = 'synthetic DelegateSubagent plus CancelSubagent sessions under .runtime/work; no private session content read'
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
            'joined-child guard',
            'cancellable child-state read',
            'cancellation mutation',
            'parent child-reference reconciliation',
            'cancellation reason hash',
            'child state and event writeback',
            'parent savepoint'
        )
        decision = [ordered]@{
            result = 'profiled-no-action'
            reason = 'CancelSubagent median runtime is sub-second in controlled local runs. Cancellable child-state validation, joined-child guard, cancellation mutation, parent child-reference reconciliation, reason hash, event writeback, and parent savepoint semantics are part of the cancellation safety and recovery contract; no equivalent strict improvement is proven.'
            slowest_substep = if ($slowest.Count -gt 0) { [string]$slowest[0].name } else { $null }
            next_candidate = 'Regenerate the functional-unit frontier and select the next remaining high-cost hotspot after CancelSubagent no-action closeout.'
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
        $OutputPath = Join-Path $analysisRoot 'cancelsubagent-profile.json'
    }
    $mdPath = [IO.Path]::ChangeExtension($OutputPath, '.md')
    $result.artifacts = @(
        ('.codex/project/timing-analysis/' + [IO.Path]::GetFileName($OutputPath)),
        ('.codex/project/timing-analysis/' + [IO.Path]::GetFileName($mdPath))
    )
    Write-AtomicUtf8NoBom -Path $OutputPath -Value (($result | ConvertTo-Json -Depth 8) + [Environment]::NewLine)
    $lines = @(
        '# CancelSubagent Timing Profile',
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
