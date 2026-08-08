[CmdletBinding()]
param(
    [string]$RepositoryRoot = 'F:\codex',
    [switch]$Apply
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath $RepositoryRoot).Path
$policyPath = Join-Path $root 'config\loopx-resource-policy.json'
$policy = Get-Content -LiteralPath $policyPath -Raw -Encoding UTF8 | ConvertFrom-Json
$projectPath = Join-Path $root '.codex\project'
$evidenceDir = Join-Path $projectPath 'timing-evidence'

function Read-JsonOrNull([string]$Path) {
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { return $null }
    try { return (Get-Content -LiteralPath $Path -Raw -Encoding UTF8 | ConvertFrom-Json) } catch { return $null }
}

function Add-Observation([System.Collections.Generic.List[object]]$List, [string]$Source, [string]$Layer, [string]$Metric, [Nullable[double]]$Seconds, [string]$Status, [string]$Evidence) {
    if ($null -eq $Seconds) { return }
    [void]$List.Add([pscustomobject][ordered]@{ source=$Source; layer=$Layer; metric=$Metric; seconds=[math]::Round([double]$Seconds,3); status=$Status; evidence=$Evidence })
}

$observations = New-Object System.Collections.Generic.List[object]
$task = Read-JsonOrNull (Join-Path $projectPath 'task-timing-last.json')
if ($task) {
    Add-Observation $observations 'task-timing-last.json' 'user_outcome' 'task_wall_clock_seconds' $task.task_wall_clock_seconds ([string]$task.timing_status) 'task lifecycle record'
    Add-Observation $observations 'task-timing-last.json' 'user_outcome' 'host_reported_worked_seconds' $task.host_reported_worked_seconds ([string]$task.timing_status) 'Codex host Worked for view'
}
$gea = Read-JsonOrNull (Join-Path $projectPath 'global-experience-agent-last-run.json')
if ($gea -and $gea.timing) {
    Add-Observation $observations 'global-experience-agent-last-run.json' 'agent_session' 'agent_session_wall_clock_seconds' $gea.timing.agent_session_wall_clock_seconds ([string]$gea.timing.task_time_status) 'GEA durable session'
    Add-Observation $observations 'global-experience-agent-last-run.json' 'controller_operation' 'operation_wall_clock_seconds' $gea.timing.operation_wall_clock_seconds ([string]$gea.timing.task_time_status) 'GEA controller operation'
    Add-Observation $observations 'global-experience-agent-last-run.json' 'user_outcome' 'task_wall_clock_seconds' $gea.timing.task_wall_clock_seconds ([string]$gea.timing.task_time_status) 'caller task to GEA save point'
}
$verification = Read-JsonOrNull (Join-Path $projectPath 'verification-last-run.json')
if ($verification -and $verification.timing) {
    Add-Observation $observations 'verification-last-run.json' 'controller_operation' 'controller_wall_clock_seconds' $verification.timing.controller_wall_clock_seconds ([string]$verification.timing.operation_time_status) 'verification controller'
    Add-Observation $observations 'verification-last-run.json' 'validation_writeback' 'step_time_sum_seconds' $verification.timing.step_time_sum_seconds ([string]$verification.timing.operation_time_status) 'verification steps'
    Add-Observation $observations 'verification-last-run.json' 'controller_operation' 'unaccounted_time_seconds' $verification.timing.unaccounted_time_seconds ([string]$verification.timing.operation_time_status) 'controller minus measured steps'
}
foreach ($name in @('global-experience-iteration.json','isolated-global-iteration.json')) {
    $iteration = Read-JsonOrNull (Join-Path $projectPath $name)
    if ($iteration) {
        foreach ($step in @($iteration.step_timings)) {
            Add-Observation $observations $name 'validation_writeback' ([string]$step.name) $step.duration_seconds 'measured' 'iteration step timing'
        }
    }
}
if (Test-Path -LiteralPath $evidenceDir -PathType Container) {
    foreach ($file in Get-ChildItem -LiteralPath $evidenceDir -Filter '*.json' -File) {
        $item = Read-JsonOrNull $file.FullName
        if ($item -and $item.duration_seconds -ne $null) {
            Add-Observation $observations $file.Name ([string]$item.layer) ([string]$item.metric) $item.duration_seconds ([string]$item.status) ([string]$item.evidence)
        }
    }
}

$continuityViews = @($observations | Where-Object { $_.layer -eq 'agent_session' } | Sort-Object seconds -Descending)
$hotspots = @($observations | Where-Object { $_.layer -ne 'agent_session' } | Sort-Object seconds -Descending | Select-Object -First 12)
$recommendations = New-Object System.Collections.Generic.List[object]
foreach ($hotspot in $hotspots) {
    $action = switch ($hotspot.layer) {
        'user_outcome' { 'retain lifecycle and host views in parallel; evidence is insufficient to change user-visible flow' }
        'agent_session' { 'reduce repeated wakeups and idle waits; reuse only within the same save point and evidence boundary' }
        'controller_operation' { 'batch independent read-only checks and reduce repeated controller round trips' }
        'validation_writeback' { 'use equivalent Fast/Auto paths during preliminary work; retain Full for global closeout' }
        default { 'collect comparable evidence for this layer before changing behavior' }
    }
    [void]$recommendations.Add([pscustomobject][ordered]@{ layer=$hotspot.layer; metric=$hotspot.metric; seconds=$hotspot.seconds; action=$action; decision='candidate-until-two-equivalent-observations' })
}
$result = [ordered]@{
    schema_version = 1
    result = 'analyzed'
    generated_at = [DateTime]::UtcNow.ToString('o')
    policy = 'config/loopx-resource-policy.json'
    required_layers = @($policy.timing_optimization_contract.layers)
    observations = @($observations.ToArray())
    continuity_views = $continuityViews
    hotspots = $hotspots
    recommendations = @($recommendations.ToArray())
    preliminary_execution_rule = $policy.timing_optimization_contract.preliminary_routing
    no_regression_gates = @($policy.timing_optimization_contract.no_regression_gates)
    decision = 'baseline-established; apply only function-preserving candidates with equivalent re-verification'
}
if ($Apply) {
    if (-not (Test-Path -LiteralPath $evidenceDir -PathType Container)) { New-Item -ItemType Directory -Path $evidenceDir -Force | Out-Null }
    $json = $result | ConvertTo-Json -Depth 12
    [IO.File]::WriteAllText((Join-Path $projectPath 'timing-optimization-baseline.json'), $json, [Text.UTF8Encoding]::new($false))
    $lines = @('# Preliminary Comprehensive Timing Optimization Baseline','',('Generated: ' + $result.generated_at),'','## Metric Layers','',($result.required_layers -join ', '),'','## Current Hotspots','')
    foreach ($h in $hotspots) { $lines += ('- ' + $h.layer + ' / ' + $h.metric + ': ' + $h.seconds + ' seconds; source: ' + $h.source) }
    $lines += @('','## Preliminary Decision','', 'This pass establishes a baseline and routing rule. A candidate must improve one declared layer across at least two equivalent observations without degrading another required layer. Full validation remains required for global closeout.')
    [IO.File]::WriteAllText((Join-Path $projectPath 'timing-optimization-baseline.md'), ($lines -join "`n"), [Text.UTF8Encoding]::new($false))
    $result['artifacts'] = @('.codex/project/timing-optimization-baseline.json','.codex/project/timing-optimization-baseline.md')
}
$result | ConvertTo-Json -Depth 12
