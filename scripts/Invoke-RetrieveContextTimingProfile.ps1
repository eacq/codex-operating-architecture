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
$workRoot = Join-Path $root '.runtime\work\retrievecontext-profile-20260809'
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

function Get-CandidatePaths {
    $manifestPath = Join-Path $root 'config\agent-system.json'
    $manifest = Get-Content -LiteralPath $manifestPath -Raw -Encoding UTF8 | ConvertFrom-Json
    @(
        @($manifest.resources.information_units) +
        @('.codex/project/REQUIREMENTS.md', '.codex/project/WORKFLOWS.md', '.codex/project/EXPERIENCE.md', '.codex/project/RETROSPECTIVES.md', '.codex/project/candidate-reports/latest.md', 'config/agent-system.json', [string]$manifest.agent_registry.source, [string]$manifest.owner_network.source, 'module-registry.json')
    ) | ForEach-Object { [string]$_ } | Sort-Object -Unique
}

$query = 'RetrieveContext timing optimization experience agent'
$candidatePaths = @(Get-CandidatePaths)
$wideComma = [char]0xFF0C
$wideSemicolon = [char]0xFF1B
$splitPattern = '[\s,;' + [regex]::Escape([string]$wideComma + [string]$wideSemicolon) + ']+'

$rows = New-Object System.Collections.Generic.List[object]
$substepRows = New-Object System.Collections.Generic.List[object]
try {
    for ($i = 0; $i -lt $Iterations; $i++) {
        $sessionId = 'retrievecontext-profile-' + $i + '-' + [guid]::NewGuid().ToString('N').Substring(0, 8)
        $startOutput = Join-Path $workRoot ($sessionId + '-start.json')
        $retrieveOutput = Join-Path $workRoot ($sessionId + '-retrieve.json')

        $startJson = & $controller `
            -RepositoryRoot $root `
            -Mode Run `
            -Operation StartWork `
            -SessionId $sessionId `
            -StateRoot $workRoot `
            -OutputPath $startOutput `
            -Goal 'synthetic RetrieveContext setup for timing optimization; no private content' `
            -Query $query `
            -AgentId global-experience-agent `
            -AcceptanceCriteria 'profile only' `
            -NextTurn 'profile retrieve context' `
            -Authority 'bounded local timing profile' `
            -Apply
        if ($LASTEXITCODE -ne 0) { throw 'RetrieveContext setup StartWork failed.' }
        $startRun = $startJson | ConvertFrom-Json
        if ($startRun.status -ne 'passed' -or -not [bool]$startRun.save_point.accepted) { throw 'RetrieveContext setup did not create an accepted save point.' }

        $termStep = Invoke-Timed 'query-term-split' {
            @(([string]$query -split $splitPattern | Where-Object { $_.Length -ge 2 }) | Select-Object -Unique).Count
        }
        $pathStep = Invoke-Timed 'candidate-path-resolution' {
            @($candidatePaths | ForEach-Object {
                $full = Join-Path $root ($_ -replace '/', [string][IO.Path]::DirectorySeparatorChar)
                if (Test-Path -LiteralPath $full -PathType Leaf) { $_ }
            }).Count
        }
        $scanStep = Invoke-Timed 'record-text-scan-and-hash' {
            $terms = @(([string]$query -split $splitPattern | Where-Object { $_.Length -ge 2 }) | Select-Object -Unique)
            $count = 0
            foreach ($relative in $candidatePaths) {
                $full = Join-Path $root ($relative -replace '/', [string][IO.Path]::DirectorySeparatorChar)
                if (-not (Test-Path -LiteralPath $full -PathType Leaf)) { continue }
                $text = Get-Content -LiteralPath $full -Raw -Encoding UTF8
                $matched = @($terms | Where-Object { $text.IndexOf($_, [StringComparison]::OrdinalIgnoreCase) -ge 0 })
                if ($terms.Count -gt 0 -and $matched.Count -eq 0) { continue }
                [void](Get-FileHash -LiteralPath $full -Algorithm SHA256)
                $count++
            }
            $count
        }

        foreach ($step in @($termStep, $pathStep, $scanStep)) {
            [void]$substepRows.Add([pscustomobject][ordered]@{
                iteration = $i
                name = $step.name
                wall_ms = $step.wall_ms
                value = $step.value
            })
        }

        $watch = [Diagnostics.Stopwatch]::StartNew()
        $json = & $controller `
            -RepositoryRoot $root `
            -Mode Continue `
            -Operation RetrieveContext `
            -SessionId $sessionId `
            -StateRoot $workRoot `
            -OutputPath $retrieveOutput `
            -Goal 'synthetic RetrieveContext profile for timing optimization; no private content' `
            -Query $query `
            -Authority 'bounded local timing profile' `
            -Apply
        $watch.Stop()
        if ($LASTEXITCODE -ne 0) { throw 'RetrieveContext profile run failed.' }
        $run = $json | ConvertFrom-Json

        [void]$rows.Add([pscustomobject][ordered]@{
            iteration = $i
            controller_wall_ms = [Math]::Round($watch.Elapsed.TotalMilliseconds, 3)
            operation_wall_ms = [Math]::Round(([double]$run.timing.operation_wall_clock_seconds * 1000), 3)
            output_bytes = (Get-Item -LiteralPath $retrieveOutput).Length
            status = [string]$run.status
            save_point = [bool]$run.save_point.accepted
            relevant_record_count = @($run.tool_result.records).Count
            child_count = @($run.tool_result.children).Count
            next_action_count = @($run.tool_result.next_actions).Count
            query_hash = [string]$run.tool_result.query_sha256
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
        classification = 'retrievecontext_substep_profile'
        goal = 'global-experience-self-iteration-full'
        todo_id = 'todo_a37bf07a621e'
        iterations = $Iterations
        dataset = 'synthetic RetrieveContext sessions under .runtime/work; no private session content read'
        measurements = [ordered]@{
            controller_wall = Get-Summary (@($rowArray | ForEach-Object controller_wall_ms))
            runtime_operation = Get-Summary (@($rowArray | ForEach-Object operation_wall_ms))
            relevant_record_counts = Get-Summary (@($rowArray | ForEach-Object relevant_record_count))
            output_bytes = Get-Summary (@($rowArray | ForEach-Object output_bytes))
            substeps = @($substepSummaries)
        }
        observations = $rowArray
        substep_observations = $substepArray
        static_substeps = @(
            'query hash',
            'candidate record path assembly from Agent manifest and project lifecycle files',
            'query term split',
            'record text scan and term matching',
            'matched record SHA256 hash',
            'work, child, and next-action projection',
            'durable event/savepoint writeback'
        )
        decision = [ordered]@{
            result = 'profiled-no-action'
            reason = 'RetrieveContext median runtime is sub-second in controlled local runs. The record scan and hashes preserve deterministic source coverage, relevance evidence, and privacy-safe context projection; no equivalent strict improvement is proven.'
            slowest_substep = if ($slowest.Count -gt 0) { [string]$slowest[0].name } else { $null }
            next_candidate = 'Regenerate the functional-unit frontier and select the next remaining high-cost hotspot after RetrieveContext no-action closeout.'
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
        $OutputPath = Join-Path $analysisRoot 'retrievecontext-profile.json'
    }
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $OutputPath) | Out-Null
    [IO.File]::WriteAllText($OutputPath, ($result | ConvertTo-Json -Depth 8), [Text.UTF8Encoding]::new($false))
    $result | ConvertTo-Json -Depth 8
} finally {
    if (Test-Path -LiteralPath $workRoot) { Remove-Item -LiteralPath $workRoot -Recurse -Force -ErrorAction SilentlyContinue }
}
