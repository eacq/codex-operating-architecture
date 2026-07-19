[CmdletBinding()]
param([string]$RepositoryRoot = (Split-Path -Parent $PSScriptRoot))

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath $RepositoryRoot).Path
$skillsRoot = Join-Path $root 'skills'
$policyPath = Join-Path $root 'config\skill-name-migrations.json'
$policy = Get-Content -LiteralPath $policyPath -Raw -Encoding UTF8 | ConvertFrom-Json

if ($policy.policy.top_owner_rename_authority.enabled) {
    $registry = Get-Content -LiteralPath (Join-Path $root 'module-registry.json') -Raw -Encoding UTF8 | ConvertFrom-Json
    $invalidOwners = @($registry.modules | Where-Object { $_.status -eq 'active' -and $_.name -notmatch '^codex-[a-z0-9-]+$' })
    if ($invalidOwners.Count -gt 0) { throw "Active owner names must use the codex-* theme: $($invalidOwners.name -join ', ')" }
}

foreach ($migration in @($policy.migrations)) {
    $canonicalRoot = Join-Path $root (($migration.canonical_path -replace '/', '\'))
    $legacyRoot = Join-Path $skillsRoot $migration.from
    if (-not (Test-Path -LiteralPath $canonicalRoot -PathType Container)) { throw "Canonical skill is missing: $($migration.to)" }
    if (-not (Test-Path -LiteralPath $legacyRoot -PathType Container)) { throw "Compatibility skill is missing: $($migration.from)" }
    $canonicalSkill = Get-Content -LiteralPath (Join-Path $canonicalRoot 'SKILL.md') -Raw -Encoding UTF8
    $legacySkill = Get-Content -LiteralPath (Join-Path $legacyRoot 'SKILL.md') -Raw -Encoding UTF8
    if ($canonicalSkill -notmatch "(?m)^name:\s*$([regex]::Escape([string]$migration.to))\s*$") { throw "Canonical SKILL.md name does not match $($migration.to)" }
    if ($legacySkill -notmatch [regex]::Escape('$' + [string]$migration.to)) { throw "Compatibility skill does not route to $($migration.to)" }
}

Write-Host "Validated $(@($policy.migrations).Count) skill-name migration(s)."
