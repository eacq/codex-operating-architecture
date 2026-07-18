[CmdletBinding()]
param([string]$ProjectRoot = (Get-Location).Path,[Parameter(Mandatory)][string]$Module,[Parameter(Mandatory)][string]$Component,[Parameter(Mandatory)][string]$Symptom,[string]$ActualResult = '',[string]$RepairAttempt = '',[string]$RepairResult = '',[string]$Verification = '')
$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath $ProjectRoot).Path
$matches = @(Get-ChildItem -LiteralPath (Join-Path $root '.codex\errors') -Recurse -Filter 'report.json' -File -ErrorAction SilentlyContinue | ForEach-Object { $report = Get-Content -LiteralPath $_.FullName -Raw -Encoding UTF8 | ConvertFrom-Json; if ($report.module -eq $Module -and $report.component -eq $Component -and $report.symptom -eq $Symptom) { [pscustomobject]@{ json=$_.FullName; directory=$_.DirectoryName; report=$report } } })
if ($matches.Count -eq 0) { throw 'No matching prior error report was found; create the initial report before reopening a repeated error.' }
$prior = $matches | Sort-Object { $_.report.created_at } | Select-Object -Last 1
$repeatCount = if ($prior.report.repeat_count) { [int]$prior.report.repeat_count + 1 } else { 2 }
$priorRepair = if ($prior.report.repair_result) { [string]$prior.report.repair_result } else { 'No prior repair was recorded; the earlier fallback did not restore the expected behavior.' }
$combinedAttempt = "Repeat #$repeatCount detected. Prior repair/mitigation is treated as failed evidence: $priorRepair`nNew repair: $RepairAttempt"
$updater = Join-Path $root 'skills\codex-error-feedback\scripts\New-ErrorFeedbackReport.ps1'
& $updater -ProjectRoot $root -ReportDirectory $prior.directory -Status observed -RepairAttempt $combinedAttempt -RepairResult $RepairResult -Verification $Verification -ExperienceSystemCausality partial | Out-Null
$updated = Get-Content -LiteralPath $prior.json -Raw -Encoding UTF8 | ConvertFrom-Json
$history = @($updated.repeat_history)
$history += [ordered]@{ detected_at=[DateTime]::UtcNow.ToString('o'); repeat=$repeatCount; prior_repair_treated_as_failed=$priorRepair; actual_result=$ActualResult; new_repair=$RepairAttempt; repair_result=$RepairResult; verification=$Verification }
$updated | Add-Member -NotePropertyName repeat_count -NotePropertyValue $repeatCount -Force
$updated | Add-Member -NotePropertyName repeat_history -NotePropertyValue $history -Force
[IO.File]::WriteAllText($prior.json, (($updated | ConvertTo-Json -Depth 8) + [Environment]::NewLine), [Text.UTF8Encoding]::new($false))
[pscustomobject]@{ result='reopened-repeated-error'; report=$prior.directory; repeat_count=$repeatCount; prior_repair_treated_as_failed=$priorRepair } | ConvertTo-Json -Depth 5
