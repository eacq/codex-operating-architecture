[CmdletBinding()]
param(
    [string]$RepositoryRoot = (Get-Location).Path,
    [Parameter(Mandatory = $true)] [string]$Version
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath $RepositoryRoot).Path
$auditRelative = "docs/release-readme-audits/v$Version.json"
$auditPath = Join-Path $root $auditRelative
if (-not (Test-Path -LiteralPath $auditPath)) { throw "Release README optimization audit is missing: $auditRelative" }
$audit = Get-Content -LiteralPath $auditPath -Raw -Encoding UTF8 | ConvertFrom-Json
if ($audit.owner -ne 'codex-task-execution/github-readme-presentation') { throw 'Release README optimization owner is invalid.' }
$sourceNames = @($audit.upstream_sources | ForEach-Object { $_.repository })
foreach ($requiredSource in @('oil-oil/beautify-github-readme','rzashakeri/beautify-github-profile')) {
    if ($sourceNames -notcontains $requiredSource) { throw "Release README optimization audit is missing required source: $requiredSource" }
}
foreach ($readme in @('README.md','README.en.md')) {
    $content = Get-Content -LiteralPath (Join-Path $root $readme) -Raw -Encoding UTF8
    if ($content -notmatch '(?s)<!-- BEGIN MANAGED BLOCK: latest-release -->.*?github-readme-presentation.*?<!-- END MANAGED BLOCK: latest-release -->') {
        throw "Release README optimization block is missing from $readme."
    }
}
[ordered]@{ version = $Version; audit = $auditRelative; sources = $sourceNames; result = 'release-readme-optimization-passed' } | ConvertTo-Json -Depth 5
