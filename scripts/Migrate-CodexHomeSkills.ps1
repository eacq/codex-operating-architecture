[CmdletBinding(SupportsShouldProcess)]
param(
    [string]$RepositoryRoot = (Split-Path $PSScriptRoot -Parent),
    [string]$CodexHome = (Join-Path $HOME '.codex'),
    [switch]$Apply
)

$ErrorActionPreference = 'Stop'
$RepositoryRoot = (Resolve-Path -LiteralPath $RepositoryRoot).Path
$manifestPath = Join-Path $RepositoryRoot 'config\local-skill-consolidation.json'
$manifest = Get-Content -LiteralPath $manifestPath -Raw -Encoding UTF8 | ConvertFrom-Json
$sourceRoot = Join-Path $CodexHome 'skills'
if (-not (Test-Path -LiteralPath $sourceRoot -PathType Container)) { throw "Codex skills root is missing: $sourceRoot" }

function Test-ExcludedPath {
    param([System.IO.FileInfo]$File)
    $relativeParts = $File.FullName.Substring($script:sourceRoot.Length).TrimStart('\').Split([IO.Path]::DirectorySeparatorChar)
    if ($relativeParts | Where-Object { $manifest.exclusions.directories -contains $_ }) { return $true }
    if ($manifest.exclusions.files -contains $File.Name) { return $true }
    if ($manifest.exclusions.extensions -contains $File.Extension) { return $true }
    return $false
}

$packages = @($manifest.packages.psobject.Properties | ForEach-Object {
    [pscustomobject]@{ Name = $_.Name; Owner = [string]$_.Value; Source = Join-Path $sourceRoot $_.Name }
}) | Sort-Object Name
$missing = @($packages | Where-Object { -not (Test-Path -LiteralPath $_.Source -PathType Container) })
if ($missing.Count) { throw "Mapped source packages are missing: $($missing.Name -join ', ')" }
$unexpected = @(Get-ChildItem -LiteralPath $sourceRoot -Directory -Force | Where-Object {
    (Test-Path -LiteralPath (Join-Path $_.FullName 'SKILL.md') -PathType Leaf) -and -not $_.LinkType -and -not ($manifest.excluded_roots -contains $_.Name) -and -not ($manifest.packages.psobject.Properties.Name -contains $_.Name)
})
if ($unexpected.Count) { throw "Unmapped direct Codex Home skills require an explicit owner decision: $($unexpected.Name -join ', ')" }

$preview = foreach ($package in $packages) {
    $destination = Join-Path $RepositoryRoot (Join-Path 'skills' (Join-Path $package.Owner (Join-Path 'subskills' (Join-Path 'imported-codex-home' $package.Name))))
    $fileCount = @(Get-ChildItem -LiteralPath $package.Source -File -Force -Recurse -ErrorAction Stop | Where-Object { -not (Test-ExcludedPath $_) }).Count
    [pscustomobject]@{ source = $package.Name; owner = $package.Owner; destination = $destination; eligible_files = $fileCount }
}
if (-not $Apply) {
    $preview | ConvertTo-Json -Depth 4
    Write-Host 'Preview only. Re-run with -Apply after reviewing the owner map.'
    return
}

$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$backupRoot = Join-Path $CodexHome (Join-Path 'skill-migration-backups' "global-experience-$stamp")
$profileRoot = Join-Path $CodexHome 'private-skill-config'
$profilePath = Join-Path $profileRoot 'global-experience-skill-migration.json'
New-Item -ItemType Directory -Path $backupRoot, $profileRoot -Force | Out-Null
$results = @()
foreach ($package in $packages) {
    $destination = Join-Path $RepositoryRoot (Join-Path 'skills' (Join-Path $package.Owner (Join-Path 'subskills' (Join-Path 'imported-codex-home' $package.Name))))
    $upstream = Join-Path $destination 'upstream'
    if (Test-Path -LiteralPath $destination) { throw "Refusing to overwrite an existing imported package: $destination" }
    New-Item -ItemType Directory -Path $upstream -Force | Out-Null
    $allFiles = Get-ChildItem -LiteralPath $package.Source -File -Force -Recurse -ErrorAction Stop
    $eligible = @($allFiles | Where-Object { -not (Test-ExcludedPath $_) })
    foreach ($file in $eligible) {
        $relative = $file.FullName.Substring($package.Source.Length).TrimStart('\\')
        $target = Join-Path $upstream $relative
        New-Item -ItemType Directory -Path (Split-Path $target -Parent) -Force | Out-Null
        Copy-Item -LiteralPath $file.FullName -Destination $target -Force
    }
    $copiedFiles = @(Get-ChildItem -LiteralPath $upstream -File -Force -Recurse).Count
    if ($copiedFiles -ne $eligible.Count) { throw "Copy verification failed for $($package.Name): expected $($eligible.Count), copied $copiedFiles" }
    $configFiles = @($eligible | Where-Object { $_.Name -match '(^|\.)(config|settings|env)(\.|$)' -or $_.Extension -in '.toml','.ini','.yaml','.yml','.json' } | ForEach-Object { $_.FullName.Substring($package.Source.Length).TrimStart('\\') })
    $wrapper = @"
---
name: imported-$($package.Name)
description: Internal compatibility package for the migrated Codex Home skill '$($package.Name)'. Route through $($package.Owner); this package is not a top-level discovery interface.
---

# Imported Codex Home Package: $($package.Name)

**Owner:** `$($package.Owner)`  
**Invocation:** owner-routed internal subskill; do not register this package as a new global entry point.  
**Imported source:** `upstream/` (portable workflow and non-secret assets only).

## Contract

1. Reuse the upstream material only when the parent owner selects this mode.
2. Follow the parent owner's authority, privacy, validation, and handoff rules.
3. Local provider, account, path, runtime, and credential choices remain in the private migration profile; never reconstruct them from the imported content.
4. Before changing this package, compare its trigger, artifacts, and safety boundary with the parent owner and promote only with verified reuse evidence.
"@
    Set-Content -LiteralPath (Join-Path $destination 'SKILL.md') -Value $wrapper -Encoding UTF8
    $backup = Join-Path $backupRoot $package.Name
    Move-Item -LiteralPath $package.Source -Destination $backup
    $results += [pscustomobject]@{ source = $package.Name; owner = $package.Owner; destination = $destination.Substring($RepositoryRoot.Length).TrimStart('\\'); backup = $backup; copied_files = $copiedFiles; portable_config_files = $configFiles; status = 'migrated' }
}
$profile = [pscustomobject]@{
    schema_version = 1
    created_at = (Get-Date).ToUniversalTime().ToString('o')
    purpose = 'Non-secret local migration record for canonical global skill consolidation.'
    backup_root = $backupRoot
    entries = $results | Select-Object source, owner, destination, backup, portable_config_files, status
    excluded = $manifest.exclusions
    secret_policy = 'No values from credentials, tokens, cookies, .env files, certificates, or private endpoints are copied or recorded.'
}
$profile | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $profilePath -Encoding UTF8
Write-Host "Migrated $($results.Count) direct Codex Home skills into canonical owner subskills. Backup: $backupRoot"
Write-Host "Wrote non-secret local configuration migration profile: $profilePath"
