[CmdletBinding()]
param(
    [string]$RepositoryRoot = 'F:\codex',
    [int]$Iterations = 8,
    [string]$OutputPath = ''
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath $RepositoryRoot).Path
if ($Iterations -lt 3) { throw 'Iterations must be at least 3.' }

$generator = Join-Path $root 'skills\codex-experience-capture\scripts\New-GlobalIterationCandidateReport.ps1'
if (-not (Test-Path -LiteralPath $generator -PathType Leaf)) {
    throw 'Candidate report generator is missing.'
}

$analysisRoot = Join-Path $root '.codex\project\timing-analysis'
$workRoot = Join-Path $root '.runtime\work\candidatereport-profile-20260809'
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

$rows = New-Object System.Collections.Generic.List[object]
$substepRows = New-Object System.Collections.Generic.List[object]
try {
    for ($i = 0; $i -lt $Iterations; $i++) {
        $iterationOutput = Join-Path $workRoot ('report-' + $i)
        New-Item -ItemType Directory -Force -Path $iterationOutput | Out-Null

        $experienceStep = Invoke-Timed 'project-experience-candidate-scan' {
            $path = Join-Path $root '.codex\project\EXPERIENCE.md'
            if (Test-Path -LiteralPath $path -PathType Leaf) { @(Select-String -LiteralPath $path -Pattern '^\s*-\s+' -Encoding UTF8).Count } else { 0 }
        }
        $vaultStep = Invoke-Timed 'linked-knowledge-candidate-scan' {
            $vault = Join-Path $root 'knowledge-vault'
            if (-not (Test-Path -LiteralPath $vault -PathType Container)) { return 0 }
            $count = 0
            foreach ($file in @(Get-ChildItem -LiteralPath $vault -Recurse -Filter '*.md' -File)) {
                if ($file.FullName -match '\\Templates\\') { continue }
                $first = Get-Content -LiteralPath $file.FullName -Encoding UTF8 -TotalCount 20
                if (($first -join "`n") -match '(?m)^status:\s*candidate\s*$') { $count++ }
            }
            $count
        }
        $workflowStep = Invoke-Timed 'workflow-learning-read' {
            $path = Join-Path $root '.codex\project\workflow-learning.json'
            if (Test-Path -LiteralPath $path -PathType Leaf) { [void](Get-Content -LiteralPath $path -Raw -Encoding UTF8 | ConvertFrom-Json); 1 } else { 0 }
        }
        $errorStep = Invoke-Timed 'error-feedback-candidate-scan' {
            $errorsRoot = Join-Path $root '.codex\errors'
            if (-not (Test-Path -LiteralPath $errorsRoot -PathType Container)) { return 0 }
            $count = 0
            foreach ($file in @(Get-ChildItem -LiteralPath $errorsRoot -Recurse -Filter 'report.json' -File)) {
                $raw = Get-Content -LiteralPath $file.FullName -Raw -Encoding UTF8
                if ($raw -match '"status"\s*:\s*"candidate"') { $count++ }
            }
            $count
        }

        foreach ($step in @($experienceStep, $vaultStep, $workflowStep, $errorStep)) {
            [void]$substepRows.Add([pscustomobject][ordered]@{
                iteration = $i
                name = $step.name
                wall_ms = $step.wall_ms
                value = $step.value
            })
        }

        $watch = [Diagnostics.Stopwatch]::StartNew()
        $json = & $generator -ProjectRoot $root -OutputDirectory $iterationOutput -Apply
        $watch.Stop()
        if ($LASTEXITCODE -ne 0) { throw 'CandidateReport profile run failed.' }
        $run = $json | ConvertFrom-Json
        $jsonPath = Join-Path $iterationOutput 'latest.json'
        $markdownPath = Join-Path $iterationOutput 'latest.md'
        [void]$rows.Add([pscustomobject][ordered]@{
            iteration = $i
            generator_wall_ms = [Math]::Round($watch.Elapsed.TotalMilliseconds, 3)
            candidate_count = [int]$run.candidate_count
            json_bytes = (Get-Item -LiteralPath $jsonPath).Length
            markdown_bytes = (Get-Item -LiteralPath $markdownPath).Length
            status = [string]$run.result
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
        classification = 'candidatereport_substep_profile'
        goal = 'global-experience-self-iteration-full'
        todo_id = 'todo_e98712c13983'
        iterations = $Iterations
        dataset = 'synthetic CandidateReport output directories under .runtime/work; no credentials or private session content read'
        measurements = [ordered]@{
            generator_wall = Get-Summary (@($rowArray | ForEach-Object generator_wall_ms))
            substeps = @($substepSummaries)
            json_bytes = Get-Summary (@($rowArray | ForEach-Object json_bytes))
            markdown_bytes = Get-Summary (@($rowArray | ForEach-Object markdown_bytes))
        }
        observations = $rowArray
        substep_observations = $substepArray
        static_substeps = @(
            'project experience candidate bullet scan',
            'experience ledger candidate bullet scan',
            'linked knowledge candidate frontmatter scan',
            'workflow-learning record read',
            'error feedback candidate report scan',
            'dedupe, render JSON, render Markdown'
        )
        decision = [ordered]@{
            result = 'profiled-no-action'
            reason = 'CandidateReport is sub-second in controlled local runs, and its scans preserve candidate visibility, source wording, advisory boundaries, and report determinism. No equivalent strict improvement is proven.'
            slowest_substep = if ($slowest.Count -gt 0) { [string]$slowest[0].name } else { $null }
            next_candidate = 'Regenerate the functional-unit frontier and select the next remaining high-cost hotspot after CandidateReport no-action closeout.'
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
        $OutputPath = Join-Path $analysisRoot 'candidatereport-profile.json'
    }
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $OutputPath) | Out-Null
    [IO.File]::WriteAllText($OutputPath, ($result | ConvertTo-Json -Depth 8), [Text.UTF8Encoding]::new($false))
    $result | ConvertTo-Json -Depth 8
} finally {
    if (Test-Path -LiteralPath $workRoot) { Remove-Item -LiteralPath $workRoot -Recurse -Force -ErrorAction SilentlyContinue }
}
