[CmdletBinding()]
param(
    [string]$CodexHome = (Join-Path $HOME '.codex')
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$sourceSkills = Join-Path $root 'skills'
$globalSkills = Join-Path $CodexHome 'skills'
$guidanceSource = Join-Path $root 'config\global-AGENTS.md'
$guidanceTarget = Join-Path $CodexHome 'AGENTS.md'
$override = Join-Path $CodexHome 'AGENTS.override.md'

if (Test-Path -LiteralPath $override) {
    $overrideContent = Get-Content -LiteralPath $override -Raw -Encoding UTF8
    if ($overrideContent.Trim()) { throw "Global guidance is masked by $override" }
}
if (-not (Test-Path -LiteralPath $guidanceTarget)) { throw "Global guidance is missing: $guidanceTarget" }

$guidanceItem = Get-Item -LiteralPath $guidanceTarget -Force
if ($guidanceItem.LinkType -eq 'SymbolicLink') {
    if (([string]$guidanceItem.Target).TrimEnd('\') -ine $guidanceSource.TrimEnd('\')) {
        throw "Global guidance points to an unexpected source: $($guidanceItem.Target)"
    }
} elseif ((Get-FileHash $guidanceSource -Algorithm SHA256).Hash -ne (Get-FileHash $guidanceTarget -Algorithm SHA256).Hash) {
    throw 'Managed global guidance differs from the canonical repository source.'
}

$guidance = Get-Content -LiteralPath $guidanceTarget -Raw -Encoding UTF8
if (-not $guidance.Contains('$codex-self-evolution')) { throw 'Global guidance does not route codex-self-evolution.' }

$invalid = @()
$sourceSkillDirectories = @(Get-ChildItem -LiteralPath $sourceSkills -Directory | Where-Object { Test-Path -LiteralPath (Join-Path $_.FullName 'SKILL.md') -PathType Leaf })
$sourceSkillNames = @($sourceSkillDirectories | ForEach-Object Name)
$stale = @()
Get-ChildItem -LiteralPath $globalSkills -Directory -Force | ForEach-Object {
    if ($_.LinkType -eq 'Junction' -and $sourceSkillNames -notcontains $_.Name) {
        $stale += $_.Name
    }
}
if ($stale.Count) { throw "Stale global skill interfaces: $($stale -join ', ')" }

$sourceSkillDirectories | ForEach-Object {
    $global = Get-Item -LiteralPath (Join-Path $globalSkills $_.Name) -Force -ErrorAction SilentlyContinue
    if (-not $global -or $global.LinkType -ne 'Junction' -or ([string]$global.Target).TrimEnd('\') -ine $_.FullName.TrimEnd('\')) {
        $invalid += $_.Name
    }
}
if ($invalid.Count) { throw "Invalid global skill interfaces: $($invalid -join ', ')" }

$controller = Get-Content -LiteralPath (Join-Path $sourceSkills 'codex-self-evolution\SKILL.md') -Raw -Encoding UTF8
if (-not $controller.Contains('Use at the start of work in any project')) {
    throw 'Self-evolution trigger does not cover entry to any project.'
}

Write-Host "Validated global guidance and $($sourceSkillDirectories.Count) architecture-root skill interfaces."
