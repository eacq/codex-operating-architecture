[CmdletBinding()]
param(
    [string]$RepositoryRoot = (Get-Location).Path,
    [Parameter(Mandatory = $true)]
    [string]$Version
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath $RepositoryRoot).Path
$currentVersion = (Get-Content -LiteralPath (Join-Path $root 'VERSION') -Raw -Encoding UTF8).Trim()
if ($currentVersion -ne $Version) { throw "Release readiness version mismatch: expected $Version, found $currentVersion." }

$releaseNote = "docs/release-notes/v$Version.md"
if (-not (Test-Path -LiteralPath (Join-Path $root $releaseNote) -PathType Leaf)) {
    throw "Release readiness requires the versioned release note: $releaseNote"
}

$changelogRelative = 'CHANGELOG.md'
$changelogPath = Join-Path $root $changelogRelative
$changelogChanged = @(& git -C $root diff HEAD --name-only -- $changelogRelative | Where-Object { $_ }).Count -gt 0
if (-not $changelogChanged) {
    throw 'Release readiness requires CHANGELOG.md to differ from HEAD before complete validation begins.'
}

$changelog = Get-Content -LiteralPath $changelogPath -Raw -Encoding UTF8
$section = [regex]::Match($changelog, "(?ms)^##\s+$([regex]::Escape($Version))\b.*?(?=^##\s+|\z)").Value
if (-not $section) { throw "Release readiness requires a CHANGELOG.md section for $Version." }
$releaseLine = 'Publish the verified experience-system release metadata, private tag, and release notes for the current version.'
if ($section -notmatch [regex]::Escape($releaseLine)) {
    throw "Release readiness requires the release metadata entry in the CHANGELOG.md section for $Version."
}

[ordered]@{
    result = 'experience-release-readiness-passed'
    version = $Version
    changelog_changed = $true
    release_note = $releaseNote
} | ConvertTo-Json
