$ErrorActionPreference = 'Stop'

$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$fixture = Join-Path ([IO.Path]::GetTempPath()) ('codex-release-readme-visuals-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Force -Path (Join-Path $fixture 'docs\release-notes') | Out-Null

try {
    '# Test README' | Set-Content -LiteralPath (Join-Path $fixture 'README.md') -Encoding UTF8
    '# Test README EN' | Set-Content -LiteralPath (Join-Path $fixture 'README.en.md') -Encoding UTF8
    @(
        '# v1.2.3.4 / v1.2',
        '',
        '## English',
        '',
        'Fixture release.',
        '',
        '## Chinese',
        '',
        'Fixture bilingual placeholder.'
    ) | Set-Content -LiteralPath (Join-Path $fixture 'docs\release-notes\v1.2.3.4.md') -Encoding UTF8

    $result = & (Join-Path $root 'skills\codex-git-operations\scripts\Update-ReleaseReadmeAndVisuals.ps1') `
        -RepositoryRoot $fixture `
        -Version '1.2.3.4' `
        -Mode Private `
        -ReleaseNote 'docs/release-notes/v1.2.3.4.md' `
        -ChangedPaths @('skills/example/SKILL.md','scripts/example.ps1','knowledge/example.md') `
        -Apply | ConvertFrom-Json

    if (-not $result.visual_required) { throw 'Expected visual_required=true for multi-area release fixture.' }
    foreach ($relative in @('README.md','README.en.md','docs/release-notes/v1.2.3.4.md','docs/release-visual-plans/v1.2.3.4.json','docs/assets/release-v1.2.3.4-highlights.mmd')) {
        if (-not (Test-Path -LiteralPath (Join-Path $fixture $relative))) { throw "Expected generated release artifact missing: $relative" }
    }
    $readme = Get-Content -LiteralPath (Join-Path $fixture 'README.md') -Raw -Encoding UTF8
    if ($readme -notmatch 'BEGIN MANAGED BLOCK: latest-release' -or $readme -notmatch 'docs/release-notes/v1\.2\.3\.4\.md') {
        throw 'README latest-release block was not generated correctly.'
    }
    $note = Get-Content -LiteralPath (Join-Path $fixture 'docs\release-notes\v1.2.3.4.md') -Raw -Encoding UTF8
    if ($note -notmatch 'BEGIN MANAGED BLOCK: release-readme-visual-refresh' -or $note -notmatch 'release-v1\.2\.3\.4-highlights\.mmd') {
        throw 'Release note visual-refresh block was not generated correctly.'
    }
    $diagram = Get-Content -LiteralPath (Join-Path $fixture 'docs\assets\release-v1.2.3.4-highlights.mmd') -Raw -Encoding UTF8
    if ($diagram -notmatch 'flowchart LR' -or $diagram -notmatch 'README refresh') {
        throw 'Release Mermaid highlight diagram was not generated correctly.'
    }
    Write-Host 'Release README and visual refresh test passed.'
}
finally {
    if (Test-Path -LiteralPath $fixture) { Remove-Item -LiteralPath $fixture -Recurse -Force }
}
