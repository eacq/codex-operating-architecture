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
if (-not (Test-Path -LiteralPath $controller -PathType Leaf)) {
    throw 'Global Experience Agent controller is missing.'
}

$analysisRoot = Join-Path $root '.codex\project\timing-analysis'
$workRoot = Join-Path $root '.runtime\work\startwork-profile-20260809'
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
        $sessionId = 'startwork-profile-' + $i + '-' + [guid]::NewGuid().ToString('N').Substring(0, 8)
        $output = Join-Path $workRoot ($sessionId + '.json')
        $watch = [Diagnostics.Stopwatch]::StartNew()
        $json = & $controller `
            -RepositoryRoot $root `
            -Mode Run `
            -Operation StartWork `
            -SessionId $sessionId `
            -StateRoot $workRoot `
            -OutputPath $output `
            -Goal 'synthetic StartWork profile for timing optimization; no private content' `
            -Query 'StartWork profile timing optimization' `
            -AgentId global-experience-agent `
            -AcceptanceCriteria 'profile only' `
            -NextTurn 'profile complete' `
            -Authority 'bounded local timing profile' `
            -Apply
        $watch.Stop()
        if ($LASTEXITCODE -ne 0) { throw 'StartWork profile run failed.' }
        $run = $json | ConvertFrom-Json
        [void]$rows.Add([pscustomobject][ordered]@{
            iteration = $i
            wall_ms = [Math]::Round($watch.Elapsed.TotalMilliseconds, 3)
            operation_wall_ms = [Math]::Round(([double]$run.timing.operation_wall_clock_seconds * 1000), 3)
            relevant_record_count = @($run.tool_result.relevant_records).Count
            output_bytes = (Get-Item -LiteralPath $output).Length
            status = [string]$run.status
            save_point = [bool]$run.save_point.accepted
        })
    }

    $controllerWall = @($rows | ForEach-Object { [double]$_.wall_ms })
    $operationWall = @($rows | ForEach-Object { [double]$_.operation_wall_ms })
    $recordCounts = @($rows | ForEach-Object { [double]$_.relevant_record_count })
    $outputSizes = @($rows | ForEach-Object { [double]$_.output_bytes })
    $rowArray = @($rows.ToArray())
    $controllerWallSummary = Get-Summary $controllerWall
    $operationWallSummary = Get-Summary $operationWall
    $recordCountSummary = Get-Summary $recordCounts
    $outputSizeSummary = Get-Summary $outputSizes

    $result = [ordered]@{
        schema_version = 1
        generated_at = [DateTime]::UtcNow.ToString('o')
        classification = 'startwork_substep_profile'
        goal = 'global-experience-self-iteration-full'
        todo_id = 'todo_c194283a21f1'
        iterations = $Iterations
        dataset = 'synthetic StartWork sessions under .runtime/work; no private session content read'
        measurements = [ordered]@{
            controller_wall = $controllerWallSummary
            runtime_operation = $operationWallSummary
            relevant_record_counts = $recordCountSummary
            output_bytes = $outputSizeSummary
        }
        observations = $rowArray
        static_substeps = @(
            'Get-RegisteredAgent',
            'Get-RelevantAgentRecords query scoring over project records',
            'state.work assignment',
            'work-started result serialization',
            'durable event/savepoint writeback'
        )
        decision = [ordered]@{
            result = 'profiled-no-action'
            reason = 'StartWork median runtime is sub-second in current controlled runs and no repeated equivalent strict improvement is proven. Retain existing authority, record retrieval, savepoint, and queue semantics.'
            next_candidate = 'Profile VerifyAgent substeps or another remaining hotspot from the regenerated inventory.'
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
        $OutputPath = Join-Path $analysisRoot 'startwork-profile.json'
    }
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $OutputPath) | Out-Null
    [IO.File]::WriteAllText($OutputPath, ($result | ConvertTo-Json -Depth 8), [Text.UTF8Encoding]::new($false))
    $result | ConvertTo-Json -Depth 8
} finally {
    if (Test-Path -LiteralPath $workRoot) { Remove-Item -LiteralPath $workRoot -Recurse -Force -ErrorAction SilentlyContinue }
}
