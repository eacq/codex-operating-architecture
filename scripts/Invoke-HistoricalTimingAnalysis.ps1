[CmdletBinding()]
param(
    [string]$RepositoryRoot = 'F:\codex',
    [switch]$Apply
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath $RepositoryRoot).Path
$projectPath = Join-Path $root '.codex\project'
$sessionsRoot = Join-Path $projectPath 'agent-sessions'
$outputDir = Join-Path $projectPath 'timing-analysis'

function ConvertTo-IsoUtc([object]$Value) {
    if ($null -eq $Value -or [string]::IsNullOrWhiteSpace([string]$Value)) { return $null }
    try { return [datetime]::Parse([string]$Value, [Globalization.CultureInfo]::InvariantCulture, [Globalization.DateTimeStyles]::AdjustToUniversal) } catch { return $null }
}

function Read-JsonOrNull([string]$Path) {
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { return $null }
    try { return (Get-Content -LiteralPath $Path -Raw -Encoding UTF8 | ConvertFrom-Json) } catch { return $null }
}

function Get-SessionRecord {
    param([string]$StatePath)
    $state = Read-JsonOrNull $StatePath
    if (-not $state) { return $null }
    $dir = Split-Path -Parent $StatePath
    $eventsPath = Join-Path $dir 'events.jsonl'
    $created = ConvertTo-IsoUtc $state.created_at
    $updated = ConvertTo-IsoUtc $state.updated_at
    $sessionSeconds = if ($created -and $updated) { [math]::Max([double]0, ($updated - $created).TotalSeconds) } else { $null }

    $openStack = New-Object System.Collections.Generic.List[object]
    $opSumSeconds = 0.0
    $opCount = 0
    $eventCount = 0
    $turnCount = 0
    $firstEvent = $null
    $lastEvent = $null
    if (Test-Path -LiteralPath $eventsPath -PathType Leaf) {
        foreach ($line in @(Get-Content -LiteralPath $eventsPath -Encoding UTF8 | Where-Object { $_.Trim() })) {
            try { $event = $line | ConvertFrom-Json } catch { continue }
            $eventCount++
            $ts = ConvertTo-IsoUtc $event.timestamp
            if ($ts) {
                if (-not $firstEvent -or $ts -lt $firstEvent) { $firstEvent = $ts }
                if (-not $lastEvent -or $ts -gt $lastEvent) { $lastEvent = $ts }
            }
            $type = [string]$event.type
            if ($type -eq 'turn_started') {
                $turnCount = [int]$event.data.turn
                continue
            }
            if ($type -eq 'operation_started') {
                $openStack.Add([pscustomobject]@{ operation = [string]$event.data.operation; started = $ts })
                continue
            }
            if ($type -eq 'operation_finished') {
                if ($openStack.Count -gt 0) {
                    $lastIndex = $openStack.Count - 1
                    $started = $openStack[$lastIndex].started
                    $openStack.RemoveAt($lastIndex)
                    if ($started -and $ts) {
                        $duration = [math]::Max([double]0, ($ts - $started).TotalSeconds)
                        $opSumSeconds += $duration
                        $opCount++
                    }
                }
            }
        }
    }
    $activeSpanSeconds = if ($firstEvent -and $lastEvent) { [math]::Max([double]0, ($lastEvent - $firstEvent).TotalSeconds) } else { $null }
    $idleSeconds = if ($activeSpanSeconds -ne $null -and $opSumSeconds -ge 0) { [math]::Max([double]0, $activeSpanSeconds - $opSumSeconds) } else { $null }
    $timing = $state.timing
    $hasTimingBlock = ($null -ne $timing)
    $goal = [string]$state.goal
    if ($goal.Length -gt 120) { $goal = $goal.Substring(0, 120) + '...' }

    [pscustomobject]@{
        session_id = [string]$state.session_id
        goal = $goal
        status = [string]$state.status
        phase = [string]$state.phase
        created_at = $state.created_at
        updated_at = $state.updated_at
        session_wall_clock_seconds = $sessionSeconds
        active_span_seconds = $activeSpanSeconds
        operation_sum_seconds = [math]::Round($opSumSeconds, 3)
        operation_count = $opCount
        idle_seconds = $idleSeconds
        event_count = $eventCount
        turn_count = $turnCount
        child_count = @($state.children).Count
        has_timing_block = $hasTimingBlock
        task_time_status = [string]$timing.task_time_status
        task_wall_clock_seconds = if ($timing) { $timing.task_wall_clock_seconds } else { $null }
        host_reported_worked_seconds = if ($timing) { $timing.host_reported_worked_seconds } else { $null }
        operation_wall_clock_seconds = if ($timing) { $timing.operation_wall_clock_seconds } else { $null }
        controller_wall_clock_seconds = if ($timing) { $timing.controller_wall_clock_seconds } else { $null }
    }
}

$sessions = @()
foreach ($statePath in @(Get-ChildItem -LiteralPath $sessionsRoot -Recurse -Filter 'state.json' -File -ErrorAction SilentlyContinue)) {
    $record = Get-SessionRecord -StatePath $statePath.FullName
    if ($record) { $sessions += $record }
}

function Add-LayerStat([System.Collections.Generic.List[object]]$List, [string]$Layer, [string]$Metric, [Nullable[double]]$Seconds, [string]$Source) {
    if ($null -eq $Seconds -or $Seconds -lt 0) { return }
    [void]$List.Add([pscustomobject][ordered]@{ layer=$Layer; metric=$Metric; seconds=[math]::Round([double]$Seconds,3); source=$Source })
}

$layerStats = New-Object System.Collections.Generic.List[object]
foreach ($s in $sessions) {
    Add-LayerStat $layerStats 'agent_session' 'session_wall_clock_seconds' $s.session_wall_clock_seconds ("session:" + $s.session_id)
    Add-LayerStat $layerStats 'agent_session' 'active_span_seconds' $s.active_span_seconds ("session:" + $s.session_id)
    Add-LayerStat $layerStats 'controller_operation' 'operation_sum_seconds' $s.operation_sum_seconds ("session:" + $s.session_id)
    Add-LayerStat $layerStats 'agent_session' 'idle_seconds' $s.idle_seconds ("session:" + $s.session_id)
    Add-LayerStat $layerStats 'user_outcome' 'task_wall_clock_seconds' $s.task_wall_clock_seconds ("session:" + $s.session_id)
    Add-LayerStat $layerStats 'user_outcome' 'host_reported_worked_seconds' $s.host_reported_worked_seconds ("session:" + $s.session_id)
    Add-LayerStat $layerStats 'controller_operation' 'operation_wall_clock_seconds' $s.operation_wall_clock_seconds ("session:" + $s.session_id)
    Add-LayerStat $layerStats 'controller_operation' 'controller_wall_clock_seconds' $s.controller_wall_clock_seconds ("session:" + $s.session_id)
}

$task = Read-JsonOrNull (Join-Path $projectPath 'task-timing-last.json')
if ($task) {
    Add-LayerStat $layerStats 'user_outcome' 'task_wall_clock_seconds' $task.task_wall_clock_seconds 'task-timing-last.json'
    Add-LayerStat $layerStats 'user_outcome' 'host_reported_worked_seconds' $task.host_reported_worked_seconds 'task-timing-last.json'
}
$verification = Read-JsonOrNull (Join-Path $projectPath 'verification-last-run.json')
if ($verification -and $verification.timing) {
    Add-LayerStat $layerStats 'validation_writeback' 'step_time_sum_seconds' $verification.timing.step_time_sum_seconds 'verification-last-run.json'
    Add-LayerStat $layerStats 'controller_operation' 'controller_wall_clock_seconds' $verification.timing.controller_wall_clock_seconds 'verification-last-run.json'
    Add-LayerStat $layerStats 'controller_operation' 'unaccounted_time_seconds' $verification.timing.unaccounted_time_seconds 'verification-last-run.json'
    foreach ($step in @($verification.timing.step_timings)) {
        Add-LayerStat $layerStats 'validation_writeback' ([string]$step.name) $step.duration_seconds 'verification-last-run.json'
    }
}
foreach ($name in @('global-experience-iteration.json','isolated-global-iteration.json')) {
    $iteration = Read-JsonOrNull (Join-Path $projectPath $name)
    if ($iteration) {
        foreach ($step in @($iteration.step_timings)) {
            Add-LayerStat $layerStats 'validation_writeback' ([string]$step.name) $step.duration_seconds $name
        }
    }
}

$loopxRuns = @(Get-ChildItem -LiteralPath (Join-Path $root '.runtime\loopx-trajectory\goals\global-experience-self-iteration-full\runs') -Filter '*.json' -File -ErrorAction SilentlyContinue)
$loopxSummaries = @()
foreach ($run in $loopxRuns) {
    $runData = Read-JsonOrNull $run.FullName
    if ($runData) {
        $loopxSummaries += [pscustomobject]@{
            file = $run.Name
            generated_at = $runData.generated_at
            classification = $runData.classification
            recommended_action = $runData.recommended_action
        }
    }
}

$layerSummaries = @()
foreach ($group in @($layerStats | Group-Object @{ E = { $_.layer + '|' + $_.metric } })) {
    $parts = [string]$group.Name -split '\|'
    $values = @($group.Group | ForEach-Object { [double]$_.seconds })
    $sorted = @($values | Sort-Object)
    $layerSummaries += [pscustomobject]@{
        layer = $parts[0]
        metric = $parts[1]
        count = $values.Count
        sum_seconds = [math]::Round(($values | Measure-Object -Sum).Sum, 1)
        mean_seconds = [math]::Round(($values | Measure-Object -Average).Average, 1)
        median_seconds = [math]::Round($sorted[[int]($sorted.Count / 2)], 1)
        max_seconds = [math]::Round($sorted[-1], 1)
    }
}

$missingTaskTiming = ($sessions | Where-Object { $_.task_time_status -eq 'not-measured; caller-task-start-required' -or [string]::IsNullOrWhiteSpace($_.task_time_status) } | Measure-Object).Count
$withTimingBlock = ($sessions | Where-Object { $_.has_timing_block } | Measure-Object).Count

$topSessions = @($sessions | Sort-Object session_wall_clock_seconds -Descending | Select-Object -First 15 | ForEach-Object {
    [pscustomobject]@{ session_id=$_.session_id; goal=$_.goal; session_seconds=$_.session_wall_clock_seconds; operation_sum_seconds=$_.operation_sum_seconds; operation_count=$_.operation_count; idle_seconds=$_.idle_seconds; turns=$_.turn_count }
})

$iterationRunCount = (Get-ChildItem -LiteralPath (Join-Path $projectPath 'iteration-runs') -File -ErrorAction SilentlyContinue | Measure-Object).Count
$operationTotal = 0
$eventTotal = 0
foreach ($s in $sessions) {
    if ($s.operation_count) { $operationTotal += [int]$s.operation_count }
    if ($s.event_count) { $eventTotal += [int]$s.event_count }
}
$sessionCount = $sessions.Count
$timingBlockCount = $withTimingBlock
$missingCallerTaskTimingCount = $missingTaskTiming
$loopxRunCount = $loopxSummaries.Count
$layerStatCount = $layerStats.Count

$createdTimes = @($sessions | ForEach-Object { ConvertTo-IsoUtc $_.created_at } | Where-Object { $_ })
$updatedTimes = @($sessions | ForEach-Object { ConvertTo-IsoUtc $_.updated_at } | Where-Object { $_ })
$firstCreated = if ($createdTimes.Count -gt 0) { ($createdTimes | Measure-Object -Minimum).Minimum } else { $null }
$lastUpdated = if ($updatedTimes.Count -gt 0) { ($updatedTimes | Measure-Object -Maximum).Maximum } else { $null }
$systemSpanSeconds = if ($firstCreated -and $lastUpdated) { [math]::Max([double]0, ($lastUpdated - $firstCreated).TotalSeconds) } else { $null }

function Get-LayerSum([object[]]$Rows, [string]$Layer, [string]$Metric) {
    $filtered = @($Rows | Where-Object { $_.layer -eq $Layer -and ($null -eq $Metric -or $_.metric -eq $Metric) })
    if ($filtered.Count -eq 0) { return 0 }
    return [math]::Round((($filtered | ForEach-Object { [double]$_.seconds }) | Measure-Object -Sum).Sum, 1)
}
$totalSessionWallSeconds = Get-LayerSum $layerStats 'agent_session' 'session_wall_clock_seconds'
$totalActiveSpanSeconds = Get-LayerSum $layerStats 'agent_session' 'active_span_seconds'
$totalOperationSeconds = Get-LayerSum $layerStats 'controller_operation' 'operation_sum_seconds'
$totalIdleSeconds = Get-LayerSum $layerStats 'agent_session' 'idle_seconds'
$totalValidationSeconds = [math]::Round((($layerStats | Where-Object { $_.layer -eq 'validation_writeback' } | ForEach-Object { [double]$_.seconds }) | Measure-Object -Sum).Sum, 1)
$totalTaskWallSeconds = Get-LayerSum $layerStats 'user_outcome' 'task_wall_clock_seconds'
$totalHostWorkedSeconds = Get-LayerSum $layerStats 'user_outcome' 'host_reported_worked_seconds'
$codexMeasuredTaskCount = ($sessions | Where-Object { $_.task_time_status -eq 'measured-from-caller-task-start' } | Measure-Object).Count
$codexHostWorkedRecordCount = ($sessions | Where-Object { $_.host_reported_worked_seconds -ne $null } | Measure-Object).Count

$result = [ordered]@{
    schema_version = 1
    result = 'analyzed'
    generated_at = [DateTime]::UtcNow.ToString('o')
    scope = 'all-past-tasks'
    session_count = $sessionCount
    session_timing_block_count = $timingBlockCount
    session_missing_caller_task_timing = $missingCallerTaskTimingCount
    operation_total_count = $operationTotal
    event_total_count = $eventTotal
    iteration_run_files = $iterationRunCount
    loopx_run_count = $loopxRunCount
    system_total = [ordered]@{
        first_session_created_at = if ($firstCreated) { $firstCreated.ToString('o') } else { $null }
        last_session_updated_at = if ($lastUpdated) { $lastUpdated.ToString('o') } else { $null }
        system_span_seconds = $systemSpanSeconds
        total_session_wall_clock_seconds = $totalSessionWallSeconds
        total_active_span_seconds = $totalActiveSpanSeconds
        total_controller_operation_seconds = $totalOperationSeconds
        total_idle_seconds = $totalIdleSeconds
        total_validation_writeback_seconds = $totalValidationSeconds
        total_task_wall_clock_seconds = $totalTaskWallSeconds
        total_host_reported_worked_seconds = $totalHostWorkedSeconds
        codex_measured_task_count = $codexMeasuredTaskCount
        codex_task_wall_clock_total_seconds = $totalTaskWallSeconds
        codex_host_worked_record_count = $codexHostWorkedRecordCount
        codex_host_worked_total_seconds = $totalHostWorkedSeconds
    }
    codex_runtime = [ordered]@{
        measured_task_record_count = $codexMeasuredTaskCount
        task_wall_clock_total_seconds = $totalTaskWallSeconds
        host_reported_worked_record_count = $codexHostWorkedRecordCount
        host_reported_worked_total_seconds = $totalHostWorkedSeconds
        definition = 'Codex actual run time per task = wall clock from task acceptance (or save-point resume anchor) to the accepted save point; host-reported worked time is captured when the host exposes it'
        optimization_target = 'Record Codex actual runtime on every task and reduce it via batched tool calls, local-evidence reuse, bounded context, and avoiding repeated full validation; Full validation stays for global closeout'
    }
    layer_summaries = $layerSummaries
    top_sessions_by_wall_clock = $topSessions
    loopx_runs = $loopxSummaries
    observations_count = $layerStatCount
    decision = 'baseline-captured; apply only function-preserving candidates with two equivalent observations per declared layer'
}
if ($Apply) {
    New-Item -ItemType Directory -Force -Path $outputDir | Out-Null
    $jsonPath = Join-Path $outputDir 'historical-timing-analysis.json'
    $mdPath = Join-Path $outputDir 'historical-timing-analysis.md'
    [IO.File]::WriteAllText($jsonPath, (($result | ConvertTo-Json -Depth 10) + [Environment]::NewLine), [Text.UTF8Encoding]::new($false))
    $lines = @('# Historical Timing Analysis','',('Generated: ' + $result.generated_at),'',('Sessions: ' + $result.session_count + '; timing blocks: ' + $result.session_timing_block_count + '; missing caller task timing: ' + $result.session_missing_caller_task_timing),'','## Layer Summaries','')
    foreach ($l in $layerSummaries) {
        $lines += ('- ' + $l.layer + ' / ' + $l.metric + ': count=' + $l.count + ' sum=' + $l.sum_seconds + 's mean=' + $l.mean_seconds + 's median=' + $l.median_seconds + 's max=' + $l.max_seconds + 's')
    }
    $system = $result.system_total
    $lines += @('','## System Total Time','')
    $lines += ('- System span (first session created to last session updated): ' + [math]::Round([double]$system.system_span_seconds, 0) + 's (' + [math]::Round([double]$system.system_span_seconds / 86400, 2) + ' days)')
    $lines += ('- Total session wall clock: ' + $system.total_session_wall_clock_seconds + 's')
    $lines += ('- Total active span: ' + $system.total_active_span_seconds + 's; total controller operation time: ' + $system.total_controller_operation_seconds + 's; total idle: ' + $system.total_idle_seconds + 's')
    $lines += ('- Total validation/writeback time: ' + $system.total_validation_writeback_seconds + 's')
    $lines += ('- Total task wall clock: ' + $system.total_task_wall_clock_seconds + 's; total host reported worked time: ' + $system.total_host_reported_worked_seconds + 's')
    $lines += @('','## Codex Actual Runtime (optimization target)','')
    $lines += ('- Measured task records (caller task start supplied): ' + $system.codex_measured_task_count)
    $lines += ('- Codex task wall clock total: ' + $system.codex_task_wall_clock_total_seconds + 's; host-reported worked records: ' + $system.codex_host_worked_record_count + ' (' + $system.codex_host_worked_total_seconds + 's)')
    $lines += ('- Target: ' + $result.codex_runtime.optimization_target)
    $lines += @('','## Top Sessions by Wall Clock','')
    foreach ($t in $topSessions) {
        $lines += ('- ' + $t.session_id + ' (' + $t.goal + '): session=' + $t.session_seconds + 's ops=' + $t.operation_sum_seconds + 's (' + $t.operation_count + ') idle=' + $t.idle_seconds + 's turns=' + $t.turns)
    }
    $lines += @('','## Decision','','Baseline captured across all past tasks. Optimizations require function-preserving candidates with two equivalent observations per declared layer; Full validation remains for global closeout.')
    [IO.File]::WriteAllText($mdPath, ($lines -join "`n"), [Text.UTF8Encoding]::new($false))
    $result['artifacts'] = @('.codex/project/timing-analysis/historical-timing-analysis.json','.codex/project/timing-analysis/historical-timing-analysis.md')
}
$result | ConvertTo-Json -Depth 10
