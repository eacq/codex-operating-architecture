[CmdletBinding()]
param(
    [string]$RepositoryRoot = (Get-Location).Path,
    [ValidateSet('Auto','Fast','Balanced','Full')]
    [string]$Mode = 'Fast',
    [string[]]$ChangedPaths = @(),
    [datetime]$TaskStartedAt = [datetime]::MinValue,
    [Nullable[double]]$HostWorkedSeconds,
    [string]$ClientTimingJson,
    [Nullable[double]]$ExternalElapsedSeconds,
    [Nullable[double]]$ScreenshotCaptureSeconds,
    [switch]$NoRecord
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath $RepositoryRoot).Path
. (Join-Path $root 'scripts\CodexTimingFunctions.ps1')
$controllerStartedAt = [DateTime]::UtcNow
$resourcePolicy = Get-Content -LiteralPath (Join-Path $root 'config\loopx-resource-policy.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$taskTimeAvailable = ($TaskStartedAt -ne [datetime]::MinValue)
$taskStart = if ($taskTimeAvailable) { $TaskStartedAt.ToUniversalTime() } else { $null }
$taskTimeSource = if ($taskTimeAvailable) { 'caller-provided-task-start' } else { 'not-provided' }
$timings = New-Object System.Collections.Generic.List[object]

function Invoke-TimedCheck {
    param([string]$Name, [scriptblock]$Check)
    $started = [DateTime]::UtcNow
    & $Check
    [void]$timings.Add([pscustomobject]@{
        name = $Name
        duration_seconds = [math]::Round(([DateTime]::UtcNow - $started).TotalSeconds, 3)
    })
}

function Get-RepositoryChanges {
    $pathCollector = Join-Path $root 'scripts\Get-CodexGitChangedPaths.ps1'
    @(& $pathCollector -RepositoryRoot $root)
}

$paths = @($ChangedPaths | Where-Object { $_ } | ForEach-Object { $_.Replace('\','/') } | Sort-Object -Unique)
if ($paths.Count -eq 0) { $paths = @(Get-RepositoryChanges) }
$requestedMode = $Mode
$effectiveMode = $Mode
if ($Mode -eq 'Auto') {
    $highRiskPatterns = @($resourcePolicy.verification_profiles.auto.high_risk_path_patterns)
    $highRiskPath = @($paths | Where-Object {
        $candidate = [string]$_
        @($highRiskPatterns | Where-Object { $candidate -match [string]$_ }).Count -gt 0
    }).Count -gt 0
    $effectiveMode = if ($highRiskPath) { [string]$resourcePolicy.verification_profiles.auto.high_risk_fallback } else { [string]$resourcePolicy.verification_profiles.auto.low_risk_default }
}

Invoke-TimedCheck 'codebase-memory-ui-preflight' {
    $starter = Join-Path $root 'scripts\Start-CodebaseMemoryGraphUi.ps1'
    if (-not (Test-Path -LiteralPath $starter)) { throw 'Codebase Memory graph UI starter is missing.' }
    & $starter -RepositoryRoot $root -ProjectName 'F-codex' -Port 9749 | ConvertFrom-Json | Out-Null
}

if ($effectiveMode -in @('Fast','Balanced')) {
    if ($paths.Count -eq 0) { throw 'Fast verification requires changed paths or a non-clean worktree.' }
    Invoke-TimedCheck 'changed-script-syntax' {
        foreach ($relative in $paths) {
            $fullPath = [IO.Path]::GetFullPath((Join-Path $root $relative))
            if (-not $fullPath.StartsWith($root + '\', [StringComparison]::OrdinalIgnoreCase) -or -not (Test-Path -LiteralPath $fullPath -PathType Leaf)) { continue }
            switch -Regex ($relative) {
                '\.ps1$' {
                    $tokens = $null; $errors = $null
                    [void][System.Management.Automation.Language.Parser]::ParseFile($fullPath, [ref]$tokens, [ref]$errors)
                    if ($errors) { throw "PowerShell syntax errors in ${relative}: $($errors | Out-String)" }
                }
                '\.mjs$' {
                    & node --check $fullPath
                    if ($LASTEXITCODE -ne 0) { throw "Node syntax errors in $relative." }
                }
                '\.json$' { Get-Content -LiteralPath $fullPath -Raw -Encoding UTF8 | ConvertFrom-Json | Out-Null }
            }
        }
    }
    if ($effectiveMode -eq 'Balanced') {
        Invoke-TimedCheck 'balanced-encoding-and-interface-checks' {
            & (Join-Path $root 'scripts\Test-RepositoryTextEncoding.ps1') -RepositoryRoot $root | Out-Null
            if ($LASTEXITCODE -ne 0) { throw 'Balanced encoding check failed.' }
            & (Join-Path $root 'scripts\validate-global-install.ps1') | Out-Null
            if ($LASTEXITCODE -ne 0) { throw 'Balanced global interface validation failed.' }
        }
        Invoke-TimedCheck 'diff-whitespace-check' {
            & git -C $root diff --check
            if ($LASTEXITCODE -ne 0) { throw 'Git whitespace check failed.' }
        }
    }
    if (@($paths | Where-Object { $_ -match '(^README|^ARCHITECTURE\.md$|^docs/.*(design-system|provenance)|^scripts/(Render-CodebaseMemoryGraph|capture_codebase_memory_graph_canvas|Test-CodebaseMemoryGraphRenderPolicy))' }).Count -gt 0) {
        Invoke-TimedCheck 'reader-facing-graph-contracts' {
            & (Join-Path $root 'scripts\Test-ReadmeIterationAlignment.ps1') -RepositoryRoot $root | Out-Null
            & (Join-Path $root 'scripts\Test-CodebaseMemoryGraphRenderPolicy.ps1') -RepositoryRoot $root | Out-Null
        }
    }
} else {
    Invoke-TimedCheck 'repository-validation' {
        & (Join-Path $root 'scripts\validate.ps1')
        if ($LASTEXITCODE -ne 0) { throw 'Repository validation failed.' }
    }
    Invoke-TimedCheck 'global-interface-validation' {
        & (Join-Path $root 'scripts\validate-global-install.ps1')
        if ($LASTEXITCODE -ne 0) { throw 'Global interface validation failed.' }
    }
    Invoke-TimedCheck 'diff-whitespace-check' {
        & git -C $root diff --check
        if ($LASTEXITCODE -ne 0) { throw 'Git whitespace check failed.' }
    }
}

$result = [ordered]@{
    schema_version = 1
    mode = $effectiveMode
    resource_version = switch ($effectiveMode) { 'Fast' { 'economy' } 'Balanced' { 'balanced' } 'Full' { 'full' } default { 'unspecified' } }
    completion_boundary = if ($effectiveMode -eq 'Balanced') { 'preliminary-evidence-only; Full required for global closeout' } else { 'profile-complete' }
    requested_mode = $requestedMode
    effective_mode = $effectiveMode
    changed_path_count = $paths.Count
    changed_paths = $paths
    step_timings = @($timings.ToArray())
    timing = [ordered]@{
        task_started_at = if ($taskTimeAvailable) { $taskStart.ToString('o') } else { $null }
        task_completed_at = ''
        task_time_source = $taskTimeSource
        task_time_available = $taskTimeAvailable
        host_reported_worked_seconds = if ($null -ne $HostWorkedSeconds) { [math]::Round([double]$HostWorkedSeconds, 3) } else { $null }
        controller_started_at = $controllerStartedAt.ToString('o')
        completed_at = [DateTime]::UtcNow.ToString('o')
        task_wall_clock_seconds = 0
        operation_wall_clock_seconds = 0
        controller_wall_clock_seconds = 0
        elapsed_wall_clock_seconds = 0
        step_time_sum_seconds = 0
        unaccounted_time_seconds = 0
        primary_metric = [string]$resourcePolicy.speed_quality_contract.primary_metric
        secondary_metrics = @($resourcePolicy.speed_quality_contract.secondary_metrics)
        additional_metrics = @($resourcePolicy.speed_quality_contract.additional_metrics)
    }
    result = 'passed'
    completed_at = [DateTime]::UtcNow.ToString('o')
}
$controllerCompletedAt = [DateTime]::UtcNow
$taskElapsedSeconds = if ($taskTimeAvailable) { [math]::Round(($controllerCompletedAt - $taskStart).TotalSeconds, 3) } else { $null }
$controllerElapsedSeconds = [math]::Round(($controllerCompletedAt - $controllerStartedAt).TotalSeconds, 3)
$timingAssessment = New-CodexTimingAssessment -ClientTimingJson $ClientTimingJson -LifecycleSeconds $taskElapsedSeconds -HostWorkedSeconds $HostWorkedSeconds -ExternalElapsedSeconds $ExternalElapsedSeconds -ScreenshotCaptureSeconds $ScreenshotCaptureSeconds
$stepSeconds = [math]::Round(((@($timings | ForEach-Object { [double]$_.duration_seconds }) | Measure-Object -Sum).Sum), 3)
$result.timing.task_completed_at = if ($taskTimeAvailable) { $controllerCompletedAt.ToString('o') } else { $null }
$result.timing.completed_at = $controllerCompletedAt.ToString('o')
$result.timing.task_wall_clock_seconds = $taskElapsedSeconds
$result.timing.customer_visible_complete_seconds = $timingAssessment.customer_visible_complete_seconds
$result.timing.customer_visible_time_source = $timingAssessment.customer_visible_time_source
$result.timing.client_timing = $timingAssessment.client
$result.timing.external_monotonic_seconds = $timingAssessment.external_monotonic_seconds
$result.timing.screenshot_capture_seconds = $timingAssessment.screenshot_capture_seconds
$result.timing.screenshot_timing_status = $timingAssessment.screenshot_timing_status
$result.timing.cross_validation = $timingAssessment.cross_validation
$result.timing.cross_validation_status = $timingAssessment.cross_validation_status
$result.timing.operation_wall_clock_seconds = $controllerElapsedSeconds
$result.timing.controller_wall_clock_seconds = $controllerElapsedSeconds
$result.timing.elapsed_wall_clock_seconds = $controllerElapsedSeconds
$result.timing.step_time_sum_seconds = $stepSeconds
$result.timing.unaccounted_time_seconds = [math]::Round([math]::Max(0, $controllerElapsedSeconds - $stepSeconds), 3)
$result.timing.operation_time_status = 'measured'
$result.timing.task_time_status = if ($taskTimeAvailable) { 'measured-from-caller-task-start' } else { 'not-measured; caller-task-start-required' }
if (-not $NoRecord) {
    $recordPath = Join-Path $root '.codex\project\verification-last-run.json'
    [System.IO.File]::WriteAllText($recordPath, ($result | ConvertTo-Json -Depth 5), [System.Text.UTF8Encoding]::new($false))
    $result['record'] = '.codex/project/verification-last-run.json'
}
$result | ConvertTo-Json -Depth 5
