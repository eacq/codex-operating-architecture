[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$Query,
    [Parameter(Mandatory = $true)][string]$OutputRoot,
    [string]$ProjectName = 'visual-design-project',
    [string]$SourceRoot = 'F:\codex\.runtime\work\network-learning\ui-ux-pro-max-skill',
    [string]$Page = 'mechanical-research',
    [ValidateRange(1,10)][int]$Variance = 3,
    [ValidateRange(1,10)][int]$Motion = 2,
    [ValidateRange(1,10)][int]$Density = 4,
    [switch]$Force
)
$ErrorActionPreference = 'Stop'
$search = Join-Path $SourceRoot 'src\ui-ux-pro-max\scripts\search.py'
if (-not (Test-Path -LiteralPath $search -PathType Leaf)) {
    throw "UI UX Pro Max source is unavailable: $search. Fetch the requested repository into the configured runtime source first."
}
New-Item -ItemType Directory -Force -Path $OutputRoot | Out-Null
$args = @($search, $Query, '--design-system', '--project-name', $ProjectName, '--format', 'markdown', '--persist', '--output-dir', $OutputRoot, '--page', $Page, '--variance', $Variance, '--motion', $Motion, '--density', $Density)
if ($Force) { $args += '--force' }
& python @args
if ($LASTEXITCODE -ne 0) { throw "UI UX Pro Max design-system generation failed with exit code $LASTEXITCODE." }
$master = Get-ChildItem -LiteralPath (Join-Path $OutputRoot 'design-system') -Filter 'MASTER.md' -Recurse -File | Select-Object -First 1
if (-not $master) { throw 'UI UX Pro Max completed without a persisted MASTER.md.' }
[ordered]@{
    source = 'nextlevelbuilder/ui-ux-pro-max-skill'
    source_root = $SourceRoot
    source_commit = (& git -C $SourceRoot rev-parse HEAD).Trim()
    query = $Query
    project_name = $ProjectName
    page_override = $Page
    master = $master.FullName
    design_dials = [ordered]@{ variance = $Variance; motion = $Motion; density = $Density }
    usage = 'Use the generated design system as a recommendation layer; retain route-specific OfficeCLI, draw.io, scientific-fidelity, and actual-render gates.'
} | ConvertTo-Json -Depth 6
