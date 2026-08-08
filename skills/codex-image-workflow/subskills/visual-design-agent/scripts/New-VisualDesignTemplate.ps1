[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$ProjectPath,
    [Parameter(Mandatory = $true)][string]$Category,
    [Parameter(Mandatory = $true)][string]$Route,
    [string]$TemplateName = 'approved-design-template',
    [string[]]$ValidationChecks = @(),
    [switch]$Apply,
    [switch]$Json
)
$ErrorActionPreference = 'Stop'
$templateRoot = Join-Path (Resolve-Path -LiteralPath $ProjectPath).Path 'templates'
$record = [ordered]@{ schema_version=1; kind='visual-design-template'; name=$TemplateName; category=$Category; route=$Route; reusable_fields=@('reader intent','information hierarchy','semantic topology','layout grammar','palette','typography','component rules','connector rules','format and editability','content-to-layout mapping','container/node/edge safe-area rules','final-render correction loop','quality checks'); layout_policy=[ordered]@{policy='content-driven';topology='layout follows actual semantic content and relationships';safe_area='all elements remain within intended regions and connectors attach to intended ports';overflow_action=@('resize','reflow','regroup','remove structure');template_mutability='template may be changed after final content placement';format_scope=@('raster','presentation','drawio','architecture','scientific-figure','infographic','card-series')}; privacy_rule='exclude raw private inputs, credentials, account/session data, and unlicensed assets'; validation_checks=@($ValidationChecks); created_at=[DateTimeOffset]::UtcNow.ToString('o') }
if ($Apply) { New-Item -ItemType Directory -Path $templateRoot -Force | Out-Null; $jsonPath=Join-Path $templateRoot 'design-template.json'; $mdPath=Join-Path $templateRoot 'design-template.md'; $record | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $jsonPath -Encoding UTF8; @("# $TemplateName",'',"- Category: $Category","- Route: $Route",'- Reuse only when factual boundary, layout topology, and provenance fit.','- Do not store private inputs, credentials, sessions, or unlicensed assets.') | Set-Content -LiteralPath $mdPath -Encoding UTF8 }
if ($Json) { $record | ConvertTo-Json -Depth 6 } else { $record }
