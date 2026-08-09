[CmdletBinding()]
param(
    [string]$RepositoryRoot = 'F:\codex',
    [int]$Iterations = 5,
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
$workRoot = Join-Path $root '.runtime\work\verifyagent-profile-20260809'
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

function Invoke-TimedJsonCommand([string]$Name, [scriptblock]$Command) {
    $watch = [Diagnostics.Stopwatch]::StartNew()
    $json = & $Command
    $watch.Stop()
    if ($LASTEXITCODE -ne 0) { throw "VerifyAgent substep failed: $Name" }
    $parsed = $json | ConvertFrom-Json
    [pscustomobject][ordered]@{
        name = $Name
        wall_ms = [Math]::Round($watch.Elapsed.TotalMilliseconds, 3)
        status = [string]$parsed.status
    }
}

$rows = New-Object System.Collections.Generic.List[object]
$substepRows = New-Object System.Collections.Generic.List[object]
try {
    for ($i = 0; $i -lt $Iterations; $i++) {
        $sessionId = 'verifyagent-profile-' + $i + '-' + [guid]::NewGuid().ToString('N').Substring(0, 8)
        $output = Join-Path $workRoot ($sessionId + '.json')

        $topology = Invoke-TimedJsonCommand 'agent-system-topology' {
            & (Join-Path $root 'scripts\Test-AgentSystemTopology.ps1') -RepositoryRoot $root
        }
        $harness = Invoke-TimedJsonCommand 'agent-harness-contract' {
            & (Join-Path $root 'scripts\Test-AgentHarnessContract.ps1') -RepositoryRoot $root
        }
        $connections = Invoke-TimedJsonCommand 'agent-owner-connections' {
            & (Join-Path $root 'scripts\Test-AgentOwnerConnections.ps1') -RepositoryRoot $root
        }
        $filesystem = Invoke-TimedJsonCommand 'agent-filesystem' {
            & (Join-Path $root 'agent\80-maintenance\Test-AgentFilesystem.ps1') -RepositoryRoot $root
        }
        foreach ($row in @($topology, $harness, $connections, $filesystem)) {
            [void]$substepRows.Add([pscustomobject][ordered]@{
                iteration = $i
                name = $row.name
                wall_ms = $row.wall_ms
                status = $row.status
            })
        }

        $watch = [Diagnostics.Stopwatch]::StartNew()
        $json = & $controller `
            -RepositoryRoot $root `
            -Mode Run `
            -Operation VerifyAgent `
            -SessionId $sessionId `
            -StateRoot $workRoot `
            -OutputPath $output `
            -Goal 'synthetic VerifyAgent profile for timing optimization; no private content' `
            -AgentId global-experience-agent `
            -Authority 'bounded local timing profile' `
            -Apply
        $watch.Stop()
        if ($LASTEXITCODE -ne 0) { throw 'VerifyAgent profile run failed.' }
        $run = $json | ConvertFrom-Json
        [void]$rows.Add([pscustomobject][ordered]@{
            iteration = $i
            controller_wall_ms = [Math]::Round($watch.Elapsed.TotalMilliseconds, 3)
            operation_wall_ms = [Math]::Round(([double]$run.timing.operation_wall_clock_seconds * 1000), 3)
            output_bytes = (Get-Item -LiteralPath $output).Length
            status = [string]$run.status
            save_point = [bool]$run.save_point.accepted
            topology = [string]$run.tool_result.topology
            harness = [string]$run.tool_result.harness
            owner_connections = [string]$run.tool_result.owner_connections
            filesystem = [string]$run.tool_result.filesystem
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
        }
    }

    $slowest = @($substepSummaries | Sort-Object { [double]$_.wall_ms.median_ms } -Descending | Select-Object -First 1)
    $controllerWallSummary = Get-Summary (@($rowArray | ForEach-Object controller_wall_ms))
    $operationWallSummary = Get-Summary (@($rowArray | ForEach-Object operation_wall_ms))

    $result = [ordered]@{
        schema_version = 1
        generated_at = [DateTime]::UtcNow.ToString('o')
        classification = 'verifyagent_substep_profile'
        goal = 'global-experience-self-iteration-full'
        todo_id = 'todo_dcbbf932cb51'
        iterations = $Iterations
        dataset = 'synthetic VerifyAgent sessions and public-safe local validation scripts; no private session content read'
        measurements = [ordered]@{
            controller_wall = $controllerWallSummary
            runtime_operation = $operationWallSummary
            substeps = @($substepSummaries)
            output_bytes = Get-Summary (@($rowArray | ForEach-Object output_bytes))
        }
        observations = $rowArray
        substep_observations = $substepArray
        static_substeps = @(
            'Test-AgentSystemTopology.ps1',
            'Test-AgentHarnessContract.ps1',
            'Test-AgentOwnerConnections.ps1',
            'agent/80-maintenance/Test-AgentFilesystem.ps1',
            'durable event/savepoint writeback'
        )
        decision = [ordered]@{
            result = 'profiled-no-action'
            reason = 'VerifyAgent is a validation aggregator. The measured cost is dominated by required validation scripts, and no equivalent strict improvement is proven without weakening topology, harness, owner-connection, filesystem, or savepoint evidence.'
            slowest_substep = if ($slowest.Count -gt 0) { [string]$slowest[0].name } else { $null }
            next_candidate = 'Regenerate the functional-unit frontier and select the next high-cost hotspot after VerifyAgent no-action closeout.'
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
        $OutputPath = Join-Path $analysisRoot 'verifyagent-profile.json'
    }
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $OutputPath) | Out-Null
    [IO.File]::WriteAllText($OutputPath, ($result | ConvertTo-Json -Depth 8), [Text.UTF8Encoding]::new($false))
    $result | ConvertTo-Json -Depth 8
} finally {
    if (Test-Path -LiteralPath $workRoot) { Remove-Item -LiteralPath $workRoot -Recurse -Force -ErrorAction SilentlyContinue }
}
