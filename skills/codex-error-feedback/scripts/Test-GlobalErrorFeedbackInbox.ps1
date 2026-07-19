$ErrorActionPreference = 'Stop'

$root = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
$fixture = & (Join-Path $root 'scripts\Resolve-CodexRunRoot.ps1') -ArchitectureRoot $root -Kind tmp -ChildPath ('codex-global-error-feedback-' + [guid]::NewGuid().ToString('N')) -Create
$sourceProject = Join-Path $fixture 'source-project'
$architectureRoot = Join-Path $fixture 'architecture-root'

New-Item -ItemType Directory -Force -Path $sourceProject | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $architectureRoot 'skills\codex-self-evolution') | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $architectureRoot '.codex\project') | Out-Null

try {
    '{}' | Set-Content -LiteralPath (Join-Path $architectureRoot 'module-registry.json') -Encoding UTF8
    '---' | Set-Content -LiteralPath (Join-Path $architectureRoot 'skills\codex-self-evolution\SKILL.md') -Encoding UTF8

    $userReport = -join @(
        [char]0x5916, [char]0x90E8, [char]0x9879, [char]0x76EE,
        [char]0x8C03, [char]0x7528, [char]0x5168, [char]0x5C40,
        [char]0x7ECF, [char]0x9A8C, [char]0x7CFB, [char]0x7EDF,
        [char]0x540E, [char]0x5931, [char]0x8D25
    )
    $argsForReport = @{
        ProjectRoot = $sourceProject
        ArchitectureRoot = $architectureRoot
        Module = 'codex-experience-capture'
        Component = 'cross-project fixture'
        OriginProjectRoot = $sourceProject
        OriginProjectName = 'fixture-project'
        OriginWorkflow = 'fixture workflow'
        GlobalExperienceFunctions = @('codex-experience-capture', 'codex-error-feedback')
        ExperienceSystemCausality = 'partial'
        MirrorToGlobalExperienceSystem = $true
        UserReport = $userReport
        ExpectedResult = 'Global experience feedback is routed.'
        ActualResult = 'Fixture failure.'
        Severity = 'medium'
    }

    $created = & (Join-Path $root 'skills\codex-error-feedback\scripts\New-ErrorFeedbackReport.ps1') @argsForReport
    $report = Get-Content -LiteralPath $created.metadata -Raw -Encoding UTF8 | ConvertFrom-Json
    if ($report.origin_project.name -ne 'fixture-project') { throw 'Origin project was not recorded in local metadata.' }
    if ($report.experience_system_causality -ne 'partial') { throw 'Experience-system causality was not recorded.' }
    if (@($report.global_experience_functions).Count -ne 2) { throw 'Global experience functions were not recorded.' }
    if (-not $created.global_inbox_updated) { throw 'Global inbox was not reported as updated.' }

    $inbox = Join-Path $architectureRoot '.codex\project\incoming-error-feedback.jsonl'
    if (-not (Test-Path -LiteralPath $inbox)) { throw 'Global incoming error-feedback inbox was not created.' }
    $entries = @(Get-Content -LiteralPath $inbox -Encoding UTF8 | Where-Object { $_.Trim() } | ForEach-Object { $_ | ConvertFrom-Json })
    if ($entries.Count -ne 1) { throw 'Expected one global inbox entry.' }
    if ($entries[0].origin_project -ne 'fixture-project' -or $entries[0].experience_system_causality -ne 'partial') {
        throw 'Global inbox entry did not preserve routing metadata.'
    }
    $reportMetadata = 'fixture-report.json'
    @(
        @{ report_metadata = $reportMetadata; recorded_at = '2026-01-01T00:00:00Z'; severity = 'high'; status = 'observed'; experience_system_causality = 'verified' },
        @{ report_metadata = $reportMetadata; recorded_at = '2026-01-01T00:01:00Z'; severity = 'high'; status = 'fixed'; experience_system_causality = 'verified' }
    ) | ForEach-Object { ($_ | ConvertTo-Json -Compress) | Add-Content -LiteralPath $inbox -Encoding UTF8 }
    $latest = @(Get-Content -LiteralPath $inbox -Encoding UTF8 |
        Where-Object { $_.Trim() } |
        ForEach-Object { $_ | ConvertFrom-Json } |
        Where-Object { $_.report_metadata -eq $reportMetadata } |
        Sort-Object -Property recorded_at |
        Select-Object -Last 1)
    if ($latest[0].status -ne 'fixed') { throw 'Append-only inbox latest status was not selected.' }
    Write-Host 'Global error-feedback inbox test passed.'
}
finally {
    if (Test-Path -LiteralPath $fixture) { Remove-Item -LiteralPath $fixture -Recurse -Force }
}
