[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)] [string]$Subject,
    [ValidateSet('relationship','procedure','geometry','quantitative','conceptual','simple')]
    [string]$ProblemType = 'simple',
    [ValidateRange(1, 5)] [int]$Complexity = 1,
    [string[]]$Relationships = @(),
    [string[]]$Labels = @(),
    [switch]$Apply
)

$ErrorActionPreference = 'Stop'
$privatePattern = '(?i)(api[_-]?key|token|secret|password|cookie|auth\.json|[A-Za-z]:\\Users\\|https?://[^/\s]+@)'
$joined = @($Subject) + $Relationships + $Labels -join "`n"
if ($joined -match $privatePattern) {
    throw 'Solution visual-plan input contains private or credential-like content; summarize it before generation.'
}

$relationshipCount = @($Relationships | Where-Object { $_ }).Count
$visualNeeded = $ProblemType -ne 'simple' -and ($Complexity -ge 2 -or $relationshipCount -ge 2)
if (-not $visualNeeded) {
    $format = 'none'
    $action = 'keep-written-solution'
    $visualClass = 'none'
} elseif ($ProblemType -in @('relationship','procedure')) {
    $format = 'mermaid'
    $action = 'embed-reviewable-text-diagram'
    $visualClass = 'text-diagram'
} elseif ($ProblemType -eq 'geometry') {
    $format = 'svg'
    $action = 'render-deterministic-geometry'
    $visualClass = 'editable-vector-diagram'
} elseif ($ProblemType -eq 'quantitative') {
    $format = 'png'
    $action = 'render-lossless-chart-or-comparison'
    $visualClass = 'raster-chart'
} else {
    $format = 'png'
    $action = 'request-sanitized-generated-raster'
    $visualClass = 'generated-explanatory-illustration'
}

$plan = [ordered]@{
    schema_version = 1
    subject = $Subject
    problem_type = $ProblemType
    visual_needed = $visualNeeded
    visual_class = $visualClass
    format = $format
    action = $action
    dimensions = if ($format -eq 'png') { '1600x1000 recommended; inspect at delivery size' } elseif ($format -eq 'none') { 'not applicable' } else { 'responsive source; render only when the delivery surface needs a bitmap' }
    label_language = 'Chinese labels must match the written solution.'
    privacy = 'Use a sanitized problem summary only; do not include private source text, local paths, credentials, sessions, or account data.'
    verification = 'Check every label, edge, value, arrow direction, and stated conclusion against the written reasoning before delivery.'
    fallback = 'If the visual does not reduce reasoning effort or cannot be verified, omit it and retain the written explanation.'
}

if ($Apply) {
    $target = Join-Path (Get-Location) '.codex\project\solution-visual-plan.json'
    $plan | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $target -Encoding UTF8
}

$plan | ConvertTo-Json -Depth 5
