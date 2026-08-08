$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
$resolver = Join-Path $root 'scripts\Resolve-CodexRunRoot.ps1'
$fixture = & $resolver -ArchitectureRoot $root -Kind tmp -ChildPath ('codex-git-workflow-' + [guid]::NewGuid().ToString('N')) -Create
$workflow = Join-Path $root 'skills\codex-git-operations\scripts\Invoke-CodexGitWorkflow.ps1'

try {
    & git -C $fixture init --quiet
    & git -C $fixture config user.name 'Codex Git Workflow Test'
    & git -C $fixture config user.email 'git-workflow-test@local.invalid'
    Set-Content -LiteralPath (Join-Path $fixture 'first.txt') -Value 'first' -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $fixture 'second.txt') -Value 'second' -Encoding UTF8

    $inspection = & $workflow -RepositoryRoot $fixture -Action Inspect | ConvertFrom-Json
    if ($inspection.result -ne 'inspection-complete' -or $inspection.diff_check -ne 'not-run' -or @($inspection.changed_paths).Count -ne 2) { throw 'Git workflow inspection did not report the fixture changes.' }
    $whitespaceInspection = & $workflow -RepositoryRoot $fixture -Action Inspect -CheckWhitespace | ConvertFrom-Json
    if ($whitespaceInspection.diff_check -ne 'passed') { throw 'Git workflow explicit whitespace check did not pass in the fixture.' }

    $staging = & $workflow -RepositoryRoot $fixture -Action Stage -Paths @('first.txt') -Apply | ConvertFrom-Json
    if ($staging.result -ne 'staged-selected-paths' -or @($staging.staged_paths).Count -ne 1 -or @($staging.staged_paths)[0] -ne 'first.txt') { throw 'Git workflow staging did not preserve the explicit path scope.' }
    if (@(& git -C $fixture diff --cached --name-only) -ne 'first.txt') { throw 'Git workflow staged an unexpected fixture path.' }

    & git -C $fixture commit --quiet -m 'Stage first'
    Set-Content -LiteralPath (Join-Path $fixture 'tracked.txt') -Value 'tracked' -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $fixture 'rename-source.txt') -Value 'rename source' -Encoding UTF8
    & git -C $fixture add tracked.txt rename-source.txt
    & git -C $fixture commit --quiet -m 'Add tracked fixtures'
    Set-Content -LiteralPath (Join-Path $fixture 'tracked.txt') -Value 'tracked modification' -Encoding UTF8
    Move-Item -LiteralPath (Join-Path $fixture 'rename-source.txt') -Destination (Join-Path $fixture 'rename-target.txt')
    & git -C $fixture add -A
    Set-Content -LiteralPath (Join-Path $fixture 'untracked.txt') -Value 'untracked' -Encoding UTF8

    $renamedInspection = & $workflow -RepositoryRoot $fixture -Action Inspect | ConvertFrom-Json
    $renamedPaths = @($renamedInspection.changed_paths)
    if (@($renamedPaths | Where-Object { $_ -in @('tracked.txt', 'rename-target.txt', 'untracked.txt') }).Count -ne 3 -or 'rename-source.txt' -in $renamedPaths) {
        throw 'Git workflow did not correctly parse modified, renamed, and untracked paths.'
    }

    Write-Host 'Codex Git workflow test passed.'
}
finally {
    if (Test-Path -LiteralPath $fixture) { Remove-Item -LiteralPath $fixture -Recurse -Force }
}
