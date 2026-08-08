[CmdletBinding()]
param(
    [string]$RepositoryRoot = (Get-Location).Path,
    [Parameter(Mandatory = $true)] [string]$Version,
    [Parameter(Mandatory = $true)] [string[]]$ChangedPaths,
    [switch]$Apply
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath $RepositoryRoot).Path
$paths = @($ChangedPaths | Where-Object { $_ } | ForEach-Object { ($_ -replace '\\','/').TrimStart('/') } | Sort-Object -Unique)
$presentationPaths = @($paths | Where-Object {
    $_ -match '^(README(\.en)?\.md|CHANGELOG\.md|docs/.+\.md)$' -and
    $_ -notmatch '^docs/(assets/|release-visual-plans/|readme-presentation-audits/|release-readme-audits/)'
})
if ($presentationPaths.Count -eq 0) {
    [ordered]@{ required = $false; generated_path = $null; reason = 'No main user-facing explanation surface changed.' } | ConvertTo-Json
    return
}

$readmePaths = @($presentationPaths | Where-Object { $_ -match '^README(\.en)?\.md$' })
$headingCount = 0
foreach ($readme in $readmePaths) {
    $path = Join-Path $root $readme
    if (Test-Path -LiteralPath $path) { $headingCount += @((Get-Content -LiteralPath $path -Encoding UTF8 | Where-Object { $_ -match '^#{1,2}\s+' })).Count }
}
$mode = if ($readmePaths.Count -gt 0 -and ($headingCount -ge 6 -or $presentationPaths.Count -ge 3)) { 'README' } else { 'Audit' }
$auditRelative = "docs/readme-presentation-audits/v$Version.json"
$audit = [ordered]@{
    schema_version = 1
    version = $Version
    owner = 'codex-task-execution/github-readme-presentation'
    upstream_sources = @('oil-oil/beautify-github-readme','rzashakeri/beautify-github-profile')
    selected_mode = $mode
    scope = $presentationPaths
    design_system = 'docs/readme-design-system.json'
    required_review = @('project evidence and verified claims','reading order and Markdown hierarchy','approved visual assets and provenance','GitHub-width and narrow-width preview','no decorative widgets, trackers, counters, or unverified metrics')
    complex_readme_threshold = 'whole README, six or more headings, three or more top-level sections changed, or more than one visual changed'
    routing_basis = 'README, changelog, release note, and user-facing docs are reviewed for reader value; machine manifests, generated plans, and raw asset provenance are excluded.'
    result = 'presentation-audit-recorded'
}
if ($Apply) {
    $dir = Join-Path $root 'docs/readme-presentation-audits'
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
    $audit | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath (Join-Path $root $auditRelative) -Encoding UTF8
}
[ordered]@{ required = $true; generated_path = $auditRelative; selected_mode = $mode; scope = $presentationPaths; applied = [bool]$Apply } | ConvertTo-Json -Depth 5
