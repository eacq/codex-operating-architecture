[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)] [string]$ReportDirectory,
    [string]$ProjectRoot = (Get-Location).Path,
    [switch]$Apply
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath $ProjectRoot).Path
$report = Get-Content -LiteralPath (Join-Path $ReportDirectory 'report.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$all = @(Get-ChildItem -LiteralPath (Join-Path $root '.codex\errors') -Recurse -Filter report.json -ErrorAction SilentlyContinue | ForEach-Object { Get-Content $_.FullName -Raw -Encoding UTF8 | ConvertFrom-Json })
$sameOwner = @($all | Where-Object { $_.module -eq $report.module -and $_.component -eq $report.component -and $_.status -in @('fixed','verified') }).Count
$text = "$($report.symptom) $($report.actual_result) $($report.suspected_causes)".ToLowerInvariant()
$recommendation = if ($text -match 'secret|private|privacy|credential') { 'add-publication-preflight-gate' } elseif ($text -match 'false positive|encoding|normalize') { 'reorder-or-normalize-input' } elseif ($text -match 'missing|metadata|precondition') { 'add-preflight-gate' } elseif ($text -match 'redundant|duplicate') { 'remove-or-simplify-step' } else { 'monitor-and-classify-next-occurrence' }
$decision = if ($sameOwner -ge 2 -or $recommendation -eq 'add-publication-preflight-gate') { 'candidate-for-workflow-change' } else { 'candidate-monitor' }
$review = [ordered]@{ report = (Join-Path $ReportDirectory 'report.json'); module = $report.module; component = $report.component; verified_similar_reports = $sameOwner; recommendation = $recommendation; decision = $decision; rule = 'Apply workflow changes only after evidence, then re-run the originating failing check and full validation.' }
if ($Apply) { $review | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath (Join-Path $root '.codex\project\workflow-error-review.json') -Encoding UTF8 }
$review | ConvertTo-Json -Depth 4
