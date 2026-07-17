$ErrorActionPreference = 'Stop'

$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$fixture = Join-Path ([IO.Path]::GetTempPath()) ('codex-release-pathset-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Force -Path $fixture | Out-Null

try {
    & git -C $fixture init | Out-Null
    & git -C $fixture config user.email test@example.invalid
    & git -C $fixture config user.name 'Codex Test'
    'base' | Set-Content -LiteralPath (Join-Path $fixture 'selected.md') -Encoding UTF8
    'base' | Set-Content -LiteralPath (Join-Path $fixture 'generated.md') -Encoding UTF8
    & git -C $fixture add selected.md generated.md | Out-Null
    & git -C $fixture commit -m init | Out-Null

    'changed' | Set-Content -LiteralPath (Join-Path $fixture 'selected.md') -Encoding UTF8
    'generated changed' | Set-Content -LiteralPath (Join-Path $fixture 'generated.md') -Encoding UTF8
    'unexpected' | Set-Content -LiteralPath (Join-Path $fixture 'unexpected.md') -Encoding UTF8

    $result = & (Join-Path $root 'skills\codex-git-operations\scripts\Resolve-ExperienceReleasePathSet.ps1') `
        -RepositoryRoot $fixture `
        -Paths @('selected.md') `
        -GeneratedPaths @('generated.md') | ConvertFrom-Json

    if ($result.complete) { throw 'Expected incomplete path set when an unselected dirty path exists.' }
    if (@($result.unselected_paths) -notcontains 'unexpected.md') { throw 'Expected unexpected.md to be reported as unselected.' }
    if (@($result.commit_paths) -notcontains 'selected.md' -or @($result.commit_paths) -notcontains 'generated.md') {
        throw 'Expected selected and generated changed paths to be commit candidates.'
    }

    $result2 = & (Join-Path $root 'skills\codex-git-operations\scripts\Resolve-ExperienceReleasePathSet.ps1') `
        -RepositoryRoot $fixture `
        -Paths @('selected.md','unexpected.md') `
        -GeneratedPaths @('generated.md') | ConvertFrom-Json

    if (-not $result2.complete) { throw 'Expected complete path set after including the unexpected dirty path.' }
    if (@($result2.commit_paths).Count -ne 3) { throw 'Expected exactly three commit paths in the complete path set.' }

    Write-Host 'Experience release path-set test passed.'
}
finally {
    if (Test-Path -LiteralPath $fixture) { Remove-Item -LiteralPath $fixture -Recurse -Force }
}
