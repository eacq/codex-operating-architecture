$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
$calculator = Join-Path $root 'skills\codex-git-operations\scripts\Get-ExperienceVersion.ps1'
$private = & $calculator -Action PrivateRelease -RepositoryRoot $root -CurrentVersion '1.1.0.0' -PublicReleaseRows @('v1.1 Latest v1.1 2026-07-18') -PrivateReleaseRows @('v1.1 Latest private-v1.1 2026-07-18') -UseProvidedReleaseRows | ConvertFrom-Json
if ($private.version -ne '1.2.0.0' -or $private.release_tag -ne 'v1.2') { throw 'Private release version did not increment from the existing private release.' }
$firstPrivate = & $calculator -Action PrivateRelease -RepositoryRoot $root -CurrentVersion '1.1.0.0' -PublicReleaseRows @('v1.1 Latest v1.1 2026-07-18') -PrivateReleaseRows @() -UseProvidedReleaseRows | ConvertFrom-Json
if ($firstPrivate.version -ne '1.0.0.0' -or $firstPrivate.release_tag -ne 'v1.0') { throw 'First private release version did not retain the initialized private component.' }
$fixture = & (Join-Path $root 'scripts\Resolve-CodexRunRoot.ps1') -ArchitectureRoot $root -Kind tmp -ChildPath ('experience-changelog-' + [guid]::NewGuid().ToString('N')) -Create
try {
    '1.4.0.0' | Set-Content -LiteralPath (Join-Path $fixture 'VERSION') -Encoding UTF8
    @(
        '# Changelog / Update Log',
        '',
        '## 1.3.0.0 - 2026-07-17',
        '',
        '### English',
        '',
        '- Publish the verified experience-system release metadata, private tag, and release notes for the current version.',
        '',
        '### Chinese / Chinese',
        '',
        '- Existing released version.',
        '',
        '## 1.4.0.0 - 2026-07-18',
        '',
        '### English',
        '',
        '- Existing architecture change.',
        '',
        '### Chinese / Chinese',
        '',
        '- Existing Chinese change.'
    ) | Set-Content -LiteralPath (Join-Path $fixture 'CHANGELOG.md') -Encoding UTF8
    New-Item -ItemType Directory -Force -Path (Join-Path $fixture 'docs\release-notes') | Out-Null
    '# Fixture release note' | Set-Content -LiteralPath (Join-Path $fixture 'docs\release-notes\v1.4.0.0.md') -Encoding UTF8
    & git -C $fixture init -q
    & git -C $fixture config user.email 'fixture@example.invalid'
    & git -C $fixture config user.name 'Fixture'
    & git -C $fixture add .
    & git -C $fixture commit -q -m baseline
    $updater = Join-Path $root 'skills\codex-git-operations\scripts\Update-ExperienceChangelog.ps1'
    & $updater -RepositoryRoot $fixture -Version '1.4.0.0' -ChangedPaths @('scripts/example.ps1') -ChangeClass Release -Apply | Out-Null
    $updated = Get-Content -LiteralPath (Join-Path $fixture 'CHANGELOG.md') -Raw -Encoding UTF8
    $releaseLine = 'Publish the verified experience-system release metadata, private tag, and release notes for the current version.'
    $targetSection = [regex]::Match($updated, '(?ms)^##\s+1\.4\.0\.0\b.*?(?=^##\s+|\z)').Value
    $chineseSection = [regex]::Match($targetSection, '(?ms)### Chinese / Chinese\s*(?<body>.*?)(?=^##\s+|\z)').Groups['body'].Value
    $chineseItems = @($chineseSection -split '\r?\n' | Where-Object { $_ -match '^- ' })
    if ($targetSection -notmatch [regex]::Escape($releaseLine) -or $chineseItems.Count -lt 2) { throw 'Existing release section was not updated with bilingual release metadata.' }
    $firstHash = (Get-FileHash -LiteralPath (Join-Path $fixture 'CHANGELOG.md') -Algorithm SHA256).Hash
    & $updater -RepositoryRoot $fixture -Version '1.4.0.0' -ChangedPaths @('scripts/example.ps1') -ChangeClass Release -Apply | Out-Null
    if ((Get-FileHash -LiteralPath (Join-Path $fixture 'CHANGELOG.md') -Algorithm SHA256).Hash -ne $firstHash) { throw 'Release changelog update is not idempotent.' }
    $readiness = & (Join-Path $root 'skills\codex-git-operations\scripts\Test-ExperienceReleaseReadiness.ps1') -RepositoryRoot $fixture -Version '1.4.0.0' | ConvertFrom-Json
    if ($readiness.result -ne 'experience-release-readiness-passed') { throw 'Release readiness did not accept the updated changelog and release note.' }
    & git -C $fixture add CHANGELOG.md
    & git -C $fixture commit -q -m updated
    $blocked = $false
    try {
        & (Join-Path $root 'skills\codex-git-operations\scripts\Test-ExperienceReleaseReadiness.ps1') -RepositoryRoot $fixture -Version '1.4.0.0' | Out-Null
    } catch {
        $blocked = $_.Exception.Message -match 'CHANGELOG\.md to differ from HEAD'
    }
    if (-not $blocked) { throw 'Release readiness did not fail early when CHANGELOG.md had no release diff.' }

    '2.0.0.0' | Set-Content -LiteralPath (Join-Path $fixture 'VERSION') -Encoding UTF8
    '# Fixture public release note' | Set-Content -LiteralPath (Join-Path $fixture 'docs\release-notes\v2.0.0.0.md') -Encoding UTF8
    & $updater -RepositoryRoot $fixture -Version '2.0.0.0' -ChangedPaths @('scripts/public.ps1') -ChangeClass Release -Apply | Out-Null
    $singlePass = & (Join-Path $root 'skills\codex-git-operations\scripts\Test-ExperienceReleaseReadiness.ps1') -RepositoryRoot $fixture -Version '2.0.0.0' | ConvertFrom-Json
    if ($singlePass.result -ne 'experience-release-readiness-passed') { throw 'A newly generated release section was not ready after one update pass.' }
}
finally {
    if (Test-Path -LiteralPath $fixture) { Remove-Item -LiteralPath $fixture -Recurse -Force }
}
Write-Host 'Experience version test passed.'
