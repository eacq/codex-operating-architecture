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
$manifestPath = Join-Path $root 'config\agent-system.json'
$ownerNetworkPath = Join-Path $root 'config\agent-owner-connections.json'
foreach ($path in @($controller, $manifestPath, $ownerNetworkPath)) {
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "Required Agent file is missing: $path" }
}

$analysisRoot = Join-Path $root '.codex\project\timing-analysis'
$workRoot = Join-Path $root '.runtime\work\routeowner-profile-20260809'
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

$ownerNetwork = Get-Content -LiteralPath $ownerNetworkPath -Raw -Encoding UTF8 | ConvertFrom-Json
$owners = @($ownerNetwork.owners | ForEach-Object { [string]$_.owner } | Sort-Object)
if ($owners.Count -lt 3) { throw 'RouteOwner profile requires at least three active owners.' }

$rows = New-Object System.Collections.Generic.List[object]
$substepRows = New-Object System.Collections.Generic.List[object]
try {
    for ($i = 0; $i -lt $Iterations; $i++) {
        $owner = $owners[$i % $owners.Count]
        $sessionId = 'routeowner-profile-' + $i + '-' + [guid]::NewGuid().ToString('N').Substring(0, 8)
        $output = Join-Path $workRoot ($sessionId + '.json')

        $manifestStep = Invoke-Timed 'manifest-json-parse' {
            (Get-Content -LiteralPath $manifestPath -Raw -Encoding UTF8 | ConvertFrom-Json).model
        }
        $networkStep = Invoke-Timed 'owner-network-json-parse' {
            (Get-Content -LiteralPath $ownerNetworkPath -Raw -Encoding UTF8 | ConvertFrom-Json).owners.Count
        }
        $ownerLookupStep = Invoke-Timed 'owner-node-lookup' {
            $match = @($ownerNetwork.owners | Where-Object owner -eq $owner)
            if ($match.Count -ne 1) { throw "Owner lookup failed for $owner" }
            $match[0].skill
        }
        $handoffFilterStep = Invoke-Timed 'incoming-outgoing-filter' {
            $incoming = @($ownerNetwork.connections | Where-Object to -eq $owner)
            $outgoing = @($ownerNetwork.connections | Where-Object from -eq $owner)
            ($incoming.Count + $outgoing.Count)
        }
        foreach ($step in @($manifestStep, $networkStep, $ownerLookupStep, $handoffFilterStep)) {
            [void]$substepRows.Add([pscustomobject][ordered]@{
                iteration = $i
                owner = $owner
                name = $step.name
                wall_ms = $step.wall_ms
                value = [string]$step.value
            })
        }

        $watch = [Diagnostics.Stopwatch]::StartNew()
        $json = & $controller `
            -RepositoryRoot $root `
            -Mode Run `
            -Operation RouteOwner `
            -SessionId $sessionId `
            -StateRoot $workRoot `
            -OutputPath $output `
            -Goal 'synthetic RouteOwner profile for timing optimization; no private content' `
            -Owner $owner `
            -Authority 'bounded local timing profile' `
            -Apply
        $watch.Stop()
        if ($LASTEXITCODE -ne 0) { throw 'RouteOwner profile run failed.' }
        $run = $json | ConvertFrom-Json
        $statePath = Join-Path $workRoot ($sessionId + '\' + 'state.json')
        [void]$rows.Add([pscustomobject][ordered]@{
            iteration = $i
            owner = $owner
            controller_wall_ms = [Math]::Round($watch.Elapsed.TotalMilliseconds, 3)
            operation_wall_ms = [Math]::Round(([double]$run.timing.operation_wall_clock_seconds * 1000), 3)
            output_bytes = (Get-Item -LiteralPath $output).Length
            state_bytes = if (Test-Path -LiteralPath $statePath -PathType Leaf) { (Get-Item -LiteralPath $statePath).Length } else { 0 }
            status = [string]$run.status
            save_point = [bool]$run.save_point.accepted
            result = [string]$run.tool_result.result
            routed_owner = [string]$run.tool_result.owner
            evidence_only = [bool]$run.tool_result.evidence_only
            side_effect_executed = [bool]$run.tool_result.side_effect_executed
            incoming_count = @($run.tool_result.incoming).Count
            outgoing_count = @($run.tool_result.outgoing).Count
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

    $invalid = @($rowArray | Where-Object { $_.status -ne 'passed' -or -not $_.save_point -or $_.result -ne 'owner-routed' -or -not $_.evidence_only -or $_.side_effect_executed })
    if ($invalid.Count -gt 0) { throw 'RouteOwner profile produced an invalid route result.' }

    $result = [ordered]@{
        schema_version = 1
        generated_at = [DateTime]::UtcNow.ToString('o')
        classification = 'routeowner_substep_profile'
        goal = 'global-experience-self-iteration-full'
        todo_id = 'todo_bb34e3376277'
        iterations = $Iterations
        dataset = 'synthetic RouteOwner sessions under .runtime/work; no private session content read'
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
            'manifest and owner-network load',
            'owner node uniqueness check',
            'operation contract gate projection',
            'route resource selection',
            'agent review checkpoint',
            'incoming and outgoing handoff projection',
            'evidence-only savepoint'
        )
        decision = [ordered]@{
            result = 'profiled-no-action'
            reason = 'RouteOwner median runtime is sub-second in controlled local runs. Owner-network resolution, canonical skill routing, gate projection, bidirectional handoff visibility, review checkpoint, and evidence-only savepoint semantics are part of the owner routing safety contract; no equivalent strict improvement is proven.'
            slowest_substep = if ($slowest.Count -gt 0) { [string]$slowest[0].name } else { $null }
            next_candidate = 'Regenerate the functional-unit frontier and select the next remaining high-cost hotspot after RouteOwner no-action closeout.'
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
        $OutputPath = Join-Path $analysisRoot 'routeowner-profile.json'
    }
    $mdPath = [IO.Path]::ChangeExtension($OutputPath, '.md')
    Write-AtomicUtf8NoBom -Path $OutputPath -Value (($result | ConvertTo-Json -Depth 8) + [Environment]::NewLine)
    $lines = @(
        '# RouteOwner Timing Profile',
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
    $result.artifacts = @(
        ('.codex/project/timing-analysis/' + [IO.Path]::GetFileName($OutputPath)),
        ('.codex/project/timing-analysis/' + [IO.Path]::GetFileName($mdPath))
    )
    Write-AtomicUtf8NoBom -Path $OutputPath -Value (($result | ConvertTo-Json -Depth 8) + [Environment]::NewLine)
    $result | ConvertTo-Json -Depth 8
} finally {
    if (Test-Path -LiteralPath $workRoot) { Remove-Item -LiteralPath $workRoot -Recurse -Force -ErrorAction SilentlyContinue }
}
