$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
$fixture = & (Join-Path $root 'scripts\Resolve-CodexRunRoot.ps1') -ArchitectureRoot $root -Kind tmp -ChildPath ('error-feedback-closeout-' + [guid]::NewGuid().ToString('N')) -Create
$source = Join-Path $fixture 'source'
$architecture = Join-Path $fixture 'architecture'

try {
    New-Item -ItemType Directory -Force -Path (Join-Path $source '.codex\project') | Out-Null
    New-Item -ItemType Directory -Force -Path (Join-Path $architecture 'skills\codex-self-evolution') | Out-Null
    New-Item -ItemType Directory -Force -Path (Join-Path $architecture '.codex\project') | Out-Null
    '{}' | Set-Content -LiteralPath (Join-Path $architecture 'module-registry.json') -Encoding UTF8
    '---' | Set-Content -LiteralPath (Join-Path $architecture 'skills\codex-self-evolution\SKILL.md') -Encoding UTF8
    $created = & (Join-Path $PSScriptRoot 'New-ErrorFeedbackReport.ps1') `
        -ProjectRoot $source `
        -ArchitectureRoot $architecture `
        -Module 'codex-git-operations' `
        -Component 'fixture' `
        -UserReport 'Fixture release failure.' `
        -ExpectedResult 'Fixture succeeds.' `
        -ActualResult 'Fixture failed.' `
        -Severity high `
        -ExperienceSystemCausality primary
    $result = & (Join-Path $PSScriptRoot 'Complete-ErrorFeedbackRepair.ps1') `
        -ProjectRoot $source `
        -ArchitectureRoot $architecture `
        -ReportDirectory (Split-Path -Parent $created.metadata) `
        -Status verified `
        -RepairAttempt 'Fixture repair.' `
        -RepairResult 'Fixture result.' `
        -Verification 'Fixture verification.' `
        -Apply | ConvertFrom-Json
    if ($result.result -ne 'error-feedback-closed' -or $result.status -ne 'verified' -or -not $result.global_inbox_updated) {
        throw 'Error-feedback closeout did not update the report and global inbox.'
    }
    if ($result.blocking_incoming_count -ne 0 -or $result.workflow_review.report -notmatch 'report\.json$') {
        throw "Error-feedback closeout did not complete workflow review and blocking-inbox audit: $($result | ConvertTo-Json -Depth 6 -Compress)"
    }
    if (@($result.scripted_steps).Count -ne 3 -or $result.duration_ms -le 0) { throw 'Error-feedback closeout did not report script telemetry.' }
    Write-Host "Error-feedback closeout test passed in $($result.duration_ms)ms."
}
finally {
    if (Test-Path -LiteralPath $fixture) { Remove-Item -LiteralPath $fixture -Recurse -Force }
}
