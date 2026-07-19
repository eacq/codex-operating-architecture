$ErrorActionPreference = 'Stop'

$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$releaseControllerPath = Join-Path $root 'skills\codex-git-operations\scripts\Update-ReleaseReadmeAndVisuals.ps1'
$releaseController = Get-Content -LiteralPath $releaseControllerPath -Raw -Encoding UTF8
if ($releaseController -notmatch '&\s+powershell\.exe\s+-NoProfile\s+-NonInteractive\s+-File\s+\$graphRenderer') {
    throw 'Release README refresh must isolate the graph renderer in a child PowerShell process.'
}
if ($releaseController -match '&\s+\$graphRenderer') {
    throw 'Release README refresh still invokes the graph renderer in its parent process.'
}
$fixture = & (Join-Path $root 'scripts\Resolve-CodexRunRoot.ps1') -ArchitectureRoot $root -Kind tmp -ChildPath ('codex-release-readme-visuals-' + [guid]::NewGuid().ToString('N')) -Create
New-Item -ItemType Directory -Force -Path (Join-Path $fixture 'docs\release-notes') | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $fixture 'scripts') | Out-Null

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
    @'
[pscustomobject]@{
    url = 'http://127.0.0.1:9750/'
    project_name = 'F-codex'
} | ConvertTo-Json
'@ | Set-Content -LiteralPath (Join-Path $fixture 'scripts\Start-CodebaseMemoryGraphUi.ps1') -Encoding UTF8
    @'
param(
    [string]$OutputPath,
    [string]$UiUrl,
    [string]$ProjectName,
    [switch]$PngOnly
)
New-Item -ItemType File -Path $OutputPath -Force | Out-Null
exit 0
'@ | Set-Content -LiteralPath (Join-Path $fixture 'scripts\Render-CodebaseMemoryGraph.ps1') -Encoding UTF8

    $result = & $releaseControllerPath `
        -RepositoryRoot $fixture `
        -Version '1.2.3.4' `
        -Mode Private `
        -ReleaseNote 'docs/release-notes/v1.2.3.4.md' `
        -ChangedPaths @('skills/example/SKILL.md','scripts/example.ps1','knowledge/example.md') `
        -Apply | ConvertFrom-Json

    if (-not $result.visual_required) { throw 'Expected visual_required=true for multi-area release fixture.' }
    foreach ($relative in @('README.md','README.en.md','docs/assets/codebase-memory-mcp-graph.png','docs/release-notes/v1.2.3.4.md','docs/release-visual-plans/v1.2.3.4.json','docs/release-readme-audits/v1.2.3.4.json')) {
        if (-not (Test-Path -LiteralPath (Join-Path $fixture $relative))) { throw "Expected generated release artifact missing: $relative" }
    }
    if (@($result.generated_paths) -notcontains 'docs/assets/codebase-memory-mcp-graph.png') {
        throw 'Release README refresh did not include the rendered graph PNG in generated_paths.'
    }
    $readme = Get-Content -LiteralPath (Join-Path $fixture 'README.md') -Raw -Encoding UTF8
    if ($readme -notmatch 'BEGIN MANAGED BLOCK: latest-release' -or $readme -notmatch 'docs/release-notes/v1\.2\.3\.4\.md') {
        throw 'README latest-release block was not generated correctly.'
    }
    $note = Get-Content -LiteralPath (Join-Path $fixture 'docs\release-notes\v1.2.3.4.md') -Raw -Encoding UTF8
    if ($note -notmatch 'BEGIN MANAGED BLOCK: release-readme-visual-refresh' -or $note -notmatch "## What's new /" -or $note -notmatch '## Verification /') {
        throw 'Release note reader-facing change summary was not generated correctly.'
    }
    if ($note -match 'release-visual-highlights-labeled\.png|README And Visual Refresh|README optimization audit:') {
        throw 'Release note must not lead readers through visual-generation mechanics.'
    }
    if ($note -match '\.(mmd|svg)') {
        throw 'Release note must not link a Mermaid or SVG reader-facing visual.'
    }
    Write-Host 'Release README and visual refresh test passed.'
}
finally {
    if (Test-Path -LiteralPath $fixture) { Remove-Item -LiteralPath $fixture -Recurse -Force }
}
