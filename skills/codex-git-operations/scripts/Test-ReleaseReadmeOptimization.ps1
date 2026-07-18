[CmdletBinding()]
param(
    [string]$RepositoryRoot = (Get-Location).Path,
    [Parameter(Mandatory = $true)] [string]$Version
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath $RepositoryRoot).Path
$readerVisualValidator = Join-Path $root 'scripts\Test-ReaderFacingVisualDelivery.ps1'
if (-not (Test-Path -LiteralPath $readerVisualValidator)) { throw 'Reader-facing visual delivery validator is missing.' }
& $readerVisualValidator -RepositoryRoot $root | Out-Null
$auditRelative = "docs/release-readme-audits/v$Version.json"
$auditPath = Join-Path $root $auditRelative
if (-not (Test-Path -LiteralPath $auditPath)) { throw "Release README optimization audit is missing: $auditRelative" }
$audit = Get-Content -LiteralPath $auditPath -Raw -Encoding UTF8 | ConvertFrom-Json
if ($audit.owner -ne 'codex-task-execution/github-readme-presentation') { throw 'Release README optimization owner is invalid.' }
$sourceNames = @($audit.upstream_sources | ForEach-Object { $_.repository })
foreach ($requiredSource in @('oil-oil/beautify-github-readme','rzashakeri/beautify-github-profile')) {
    if ($sourceNames -notcontains $requiredSource) { throw "Release README optimization audit is missing required source: $requiredSource" }
}
$requiredReadingOrder = @('value proposition', 'first successful action', 'collaboration mechanism', 'architecture visual', 'channels and detailed guarantees', 'release evidence')
if (@($audit.reading_order_contract).Count -ne $requiredReadingOrder.Count -or @($audit.reading_order_contract | Where-Object { $_ -notin $requiredReadingOrder }).Count -gt 0) { throw 'Release README optimization audit has an invalid reading-order contract.' }
if ($audit.visual_decision.action -ne 'use-approved-raster-visual-system' -or $audit.visual_decision.format -ne 'PNG') { throw 'Release README optimization audit has an invalid visual decision.' }
if ([string]::IsNullOrWhiteSpace($audit.visual_decision.reader_delivery_rule) -or [string]::IsNullOrWhiteSpace($audit.visual_decision.text_policy)) { throw 'Release README optimization audit is missing the reader-delivery or in-image-text policy.' }
$designSystemRelative = 'docs/readme-design-system.json'
if ($audit.design_system -ne $designSystemRelative) { throw 'Release README optimization audit does not reference the design system.' }
$designSystemPath = Join-Path $root $designSystemRelative
if (-not (Test-Path -LiteralPath $designSystemPath)) { throw "README design system is missing: $designSystemRelative" }
$designSystem = Get-Content -LiteralPath $designSystemPath -Raw -Encoding UTF8 | ConvertFrom-Json
if ($designSystem.owner -ne 'codex-task-execution/github-readme-presentation' -or $designSystem.visual_assets.collaboration_loop.path -ne 'docs/assets/readme-collaboration-loop.png') { throw 'README design system is incomplete or incompatible with the release audit.' }
if ([string]::IsNullOrWhiteSpace($designSystem.in_image_text.decision_rule) -or @($designSystem.in_image_text.quality_gate).Count -lt 3) { throw 'README design system is missing its in-image-text contract.' }
foreach ($asset in @('docs/assets/readme-collaboration-loop.png','docs/assets/readme-collaboration-loop-labeled.png','docs/assets/readme-architecture-overview-labeled.png','docs/assets/file-organization-architecture-labeled.png')) {
    if (-not (Test-Path -LiteralPath (Join-Path $root $asset))) { throw "Release README visual asset is missing: $asset" }
}
$zhStart = ([char[]]@(0x4ECE,0x8FD9,0x91CC,0x5F00,0x59CB) -join '')
$zhLoop = ([char[]]@(0x534F,0x4F5C,0x95ED,0x73AF) -join '')
$requirements = @{
    'README.md' = @("## $zhStart","## $zhLoop",'docs/assets/readme-collaboration-loop.png','docs/assets/readme-architecture-overview-labeled.png','docs/assets/file-organization-architecture-labeled.png');
    'README.en.md' = @('## Start here','## How it works','docs/assets/readme-collaboration-loop.png','docs/assets/readme-architecture-overview-labeled.png','docs/assets/file-organization-architecture-labeled.png')
}
foreach ($readme in $requirements.Keys) {
    $content = Get-Content -LiteralPath (Join-Path $root $readme) -Raw -Encoding UTF8
    foreach ($requiredText in $requirements[$readme]) {
        if (-not $content.Contains($requiredText)) { throw "Release README layout is missing '$requiredText' from $readme." }
    }
    if ($content -notmatch '(?s)<!-- BEGIN MANAGED BLOCK: latest-release -->.*?github-readme-presentation.*?<!-- END MANAGED BLOCK: latest-release -->') {
        throw "Release README optimization block is missing from $readme."
    }
}
[ordered]@{ version = $Version; audit = $auditRelative; design_system = $designSystemRelative; sources = $sourceNames; result = 'release-readme-optimization-passed' } | ConvertTo-Json -Depth 5
