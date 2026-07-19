[CmdletBinding()]
param(
    [string]$ProjectRoot = (Get-Location).Path,
    [switch]$Apply
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath $ProjectRoot).Path
$timingSources = @('.codex/project/global-experience-iteration.json', '.codex/project/verification-last-run.json')
$measurements = New-Object System.Collections.Generic.List[object]
foreach ($relative in $timingSources) {
    $path = Join-Path $root $relative
    if (-not (Test-Path -LiteralPath $path)) { continue }
    $record = Get-Content -LiteralPath $path -Raw -Encoding UTF8 | ConvertFrom-Json
    foreach ($timing in @($record.step_timings)) {
        if ($null -eq $timing.duration_seconds) { continue }
        [void]$measurements.Add([pscustomobject]@{ source = $relative.Replace('\', '/'); operation = [string]$timing.name; duration_seconds = [double]$timing.duration_seconds })
    }
}

function Get-OptimizationFocus([string]$Operation) {
    if ($Operation -match 'clone|backup|rollback|snapshot') { return 'profile I/O and file enumeration; retain exact hash-verified rollback semantics' }
    if ($Operation -match 'validate') { return 'reuse only equivalent validation evidence; retain the full validation gate' }
    if ($Operation -match 'index|graph') { return 'prefer a fresh health check or incremental index only when coverage remains equivalent' }
    return 'measure repeated deterministic work and isolate the smallest owner-bound optimization'
}

$hotspots = @($measurements | Sort-Object duration_seconds -Descending | Select-Object -First 12 | ForEach-Object {
    [ordered]@{
        operation = $_.operation
        duration_seconds = [math]::Round($_.duration_seconds, 3)
        source = $_.source
        recommended_focus = Get-OptimizationFocus $_.operation
        execution_boundary = 'Auto-apply only an owner-scoped, read-only or local-reversible change with an equivalence check, baseline measurement, and rollback. Otherwise retain as a candidate.'
    }
})
$review = [ordered]@{
    schema_version = 1
    result = 'analyzed'
    asset_class = 'first-class-script-asset'
    peer_artifacts = @('skills', 'knowledge', 'experience', 'workflows')
    language_policy = 'Choose the least-complex installed or project-local runtime that improves measured execution, maintainability, or portability. PowerShell, Python, Node, Shell, Go, Rust, and CSharp are valid options; installing a runtime remains separately authorized.'
    refactor_policy = 'Scripts may be split, merged, or moved within their owner when their trigger, inputs, outputs, validation, rollback, and caller contract remain explicit and tested.'
    automatic_execution_policy = 'Analyze every complete iteration. Apply only measured, function-preserving, owner-scoped read-only or local-reversible optimizations with equivalent verification; never auto-apply external, irreversible, credential, installation, publication, destructive, or runtime-installing changes.'
    measurement_count = $measurements.Count
    hotspots = $hotspots
    generated_at = [DateTime]::UtcNow.ToString('o')
}
if ($Apply) {
    $output = Join-Path $root '.codex\project\script-optimization-review.json'
    $review | ConvertTo-Json -Depth 7 | Set-Content -LiteralPath $output -Encoding UTF8
    $review['output'] = '.codex/project/script-optimization-review.json'
}
$review | ConvertTo-Json -Depth 7
