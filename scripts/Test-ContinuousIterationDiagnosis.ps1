$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$fixture = & (Join-Path $root 'scripts\Resolve-CodexRunRoot.ps1') -ArchitectureRoot $root -Kind tmp -ChildPath ('codex-continuous-diagnosis-' + [guid]::NewGuid().ToString('N')) -Create
New-Item -ItemType Directory -Force -Path $fixture | Out-Null
try {
    $probe = Join-Path $fixture 'probe.ps1'
    $repair = Join-Path $fixture 'repair.ps1'
    $evidence = Join-Path $fixture 'evidence.json'
    [IO.File]::WriteAllText($probe, @'
param([string]$RepositoryRoot,[string]$Target)
if (-not (Test-Path -LiteralPath (Join-Path $PSScriptRoot "repaired.marker"))) { throw "Injected $Target failure." }
'@, [Text.UTF8Encoding]::new($false))
    [IO.File]::WriteAllText($repair, @'
param([string]$RepositoryRoot,[string]$Target,[int]$Attempt,[string]$FailureRecordPath)
[IO.File]::WriteAllText((Join-Path $PSScriptRoot "repaired.marker"), "${Target}:$Attempt", [Text.UTF8Encoding]::new($false))
'@, [Text.UTF8Encoding]::new($false))
    $result = & (Join-Path $root 'scripts\Invoke-ContinuousIterationDiagnosis.ps1') -RepositoryRoot $root -Target file-organization -ProbeScript $probe -RepairScript $repair -EvidencePath $evidence -SkipErrorReportForTest -Apply | ConvertFrom-Json
    $record = Get-Content -LiteralPath $evidence -Raw -Encoding UTF8 | ConvertFrom-Json
    if ($result.result -ne 'completed' -or $result.probes -ne 2 -or $result.repairs -ne 1) { throw 'Continuous diagnosis did not repair and retest.' }
    if ($record.status -ne 'completed' -or @($record.attempts).Count -ne 2) { throw 'Continuous diagnosis evidence is incomplete.' }
    if (@($record.attempts)[0].owner -ne 'codex-file-organization') { throw 'Continuous diagnosis owner routing is incorrect.' }
    Remove-Item -LiteralPath (Join-Path $fixture 'repaired.marker') -Force
    $globalEvidence = Join-Path $fixture 'global-evidence.json'
    $globalResult = & (Join-Path $root 'scripts\Invoke-ContinuousIterationDiagnosis.ps1') -RepositoryRoot $root -Target global-iteration -ProbeScript $probe -RepairScript $repair -EvidencePath $globalEvidence -SkipErrorReportForTest -Apply | ConvertFrom-Json
    $globalRecord = Get-Content -LiteralPath $globalEvidence -Raw -Encoding UTF8 | ConvertFrom-Json
    if ($globalResult.result -ne 'completed' -or @($globalRecord.attempts)[0].owner -ne 'codex-self-evolution') { throw 'Global-iteration continuous diagnosis routing is incorrect.' }
    Remove-Item -LiteralPath (Join-Path $fixture 'repaired.marker') -Force
    $reporterDirectory = Join-Path $fixture 'skills\codex-error-feedback\scripts'
    New-Item -ItemType Directory -Force -Path $reporterDirectory | Out-Null
    Copy-Item -LiteralPath (Join-Path $root 'skills\codex-error-feedback\scripts\New-ErrorFeedbackReport.ps1') -Destination $reporterDirectory -Force
    $reportedEvidence = Join-Path $fixture 'reported-evidence.json'
    $reportedResult = & (Join-Path $root 'scripts\Invoke-ContinuousIterationDiagnosis.ps1') -RepositoryRoot $fixture -Target file-organization -ProbeScript $probe -RepairScript $repair -EvidencePath $reportedEvidence -Apply | ConvertFrom-Json
    $formalReport = Get-ChildItem -LiteralPath (Join-Path $fixture '.codex\errors') -Recurse -Filter report.json | Select-Object -First 1 | ForEach-Object { Get-Content -LiteralPath $_.FullName -Raw -Encoding UTF8 | ConvertFrom-Json }
    if ($reportedResult.result -ne 'completed' -or -not $formalReport -or $formalReport.status -ne 'verified') { throw 'Continuous diagnosis did not create and close its formal error report.' }
    Write-Host 'Continuous iteration diagnosis test passed.'
}
finally {
    if (Test-Path -LiteralPath $fixture) { Remove-Item -LiteralPath $fixture -Recurse -Force }
}
