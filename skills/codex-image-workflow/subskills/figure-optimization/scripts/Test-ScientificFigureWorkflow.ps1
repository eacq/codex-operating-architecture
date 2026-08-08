[CmdletBinding()]
param(
    [string]$RepositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..\..')).Path
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath $RepositoryRoot).Path
$skillPath = Join-Path $root 'skills\codex-image-workflow\subskills\figure-optimization\SKILL.md'
$contractPath = Join-Path $root 'skills\codex-image-workflow\subskills\figure-optimization\references\scientific-figure-contract.md'
$validator = Join-Path $root 'skills\codex-image-workflow\subskills\figure-optimization\scripts\Validate-ScientificFigureSource.ps1'

foreach ($path in @($skillPath, $contractPath, $validator)) {
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        throw "Missing scientific figure workflow artifact: $path"
    }
}

$skill = Get-Content -LiteralPath $skillPath -Raw -Encoding UTF8
foreach ($required in @(
    'Yuan1z0825/nature-skills',
    'scientific-figure-contract.md',
    'Backend',
    'generative image model',
    'legend/statistics alignment',
    'routed skill',
    'ask once instead of guessing'
)) {
    if ($skill -notmatch [regex]::Escape($required)) {
        throw "Figure optimization skill is missing required Nature-derived rule: $required"
    }
}

$contract = Get-Content -LiteralPath $contractPath -Raw -Encoding UTF8
foreach ($required in @(
    'Core conclusion:',
    'Figure archetype:',
    'Evidence hierarchy:',
    'AI-generated images are allowed only for conceptual schematics',
    'run `scripts/Validate-ScientificFigureSource.ps1`',
    'load backend-specific plotting guidance only after the backend is selected',
    'draft plus',
    'provenance and review boundary'
)) {
    if ($contract -notmatch [regex]::Escape($required)) {
        throw "Scientific figure contract is missing required section: $required"
    }
}

$tmp = Join-Path $root '.runtime\tests\scientific-figure-workflow'
New-Item -ItemType Directory -Force -Path $tmp | Out-Null
$good = Join-Path $tmp 'good_figure.py'
$bad = Join-Path $tmp 'bad_cross_backend.py'

@'
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
plt.rcParams["svg.fonttype"] = "none"

# Core conclusion: Treatment improves response.
# n=3 independent biological replicates; width=89 mm; dpi=600.
fig, ax = plt.subplots(figsize=(3.5, 2.2), dpi=600)
ax.plot([0, 1], [0, 1])
fig.savefig("figure.svg")
fig.savefig("figure.pdf")
'@ | Set-Content -LiteralPath $good -Encoding UTF8

@'
import matplotlib.pyplot as plt
library(ggplot2)
fig, ax = plt.subplots()
ax.imshow([[1,2]], cmap="jet")
'@ | Set-Content -LiteralPath $bad -Encoding UTF8

& $validator -Path $good -Strict | Out-Null
if (-not $?) { throw 'Expected good scientific figure fixture to pass strict preflight.' }

$badPassed = $true
& $validator -Path $bad -Strict | Out-Null
if (-not $?) {
    $badPassed = $false
}
if ($badPassed) { throw 'Expected cross-backend fixture to fail strict preflight.' }

Write-Host 'Scientific figure workflow test passed.'
