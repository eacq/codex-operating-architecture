$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
$fixture = & (Join-Path $root 'scripts\Resolve-CodexRunRoot.ps1') -ArchitectureRoot $root -Kind tmp -ChildPath ('git-index-lock-recovery-' + [guid]::NewGuid().ToString('N')) -Create
$repair = Join-Path $root 'skills\codex-git-operations\scripts\Repair-CodexGitIndexLock.ps1'
$repairSource = Get-Content -LiteralPath $repair -Raw -Encoding UTF8
if ($repairSource -match '(?m)^\s*exit\s+0\s*$') { throw 'Git index-lock recovery must return to its parent controller instead of exiting the PowerShell host.' }
if ($repairSource -notmatch 'DeterministicFixture is restricted to the Git index-lock recovery test run root') { throw 'Git index-lock recovery fixture bypass is not constrained to the test run root.' }

try {
    & git -C $fixture init --quiet
    $noLock = & $repair -RepositoryRoot $fixture | ConvertFrom-Json
    if ($noLock.result -ne 'no-lock') { throw 'Git index-lock recovery did not return its no-lock result to the caller.' }
    $lock = Join-Path $fixture '.git\index.lock'
    [IO.File]::WriteAllBytes($lock, [byte[]]@())
    (Get-Item -LiteralPath $lock).LastWriteTime = (Get-Date).AddMinutes(-1)
    $preview = & $repair -RepositoryRoot $fixture -MinimumAgeSeconds 1 -DeterministicFixture | ConvertFrom-Json
    if ($preview.result -ne 'stale-lock-eligible' -or $preview.repaired) { throw 'Stale Git index lock preview was not safe and eligible.' }
    $applied = & $repair -RepositoryRoot $fixture -MinimumAgeSeconds 1 -DeterministicFixture -Apply | ConvertFrom-Json
    if ($applied.result -ne 'stale-lock-removed' -or -not $applied.repaired -or (Test-Path -LiteralPath $lock)) { throw 'Stale Git index lock recovery did not remove the verified fixture lock.' }
    Write-Host 'Git index-lock recovery test passed.'
}
finally {
    if (Test-Path -LiteralPath $fixture) { Remove-Item -LiteralPath $fixture -Recurse -Force }
}
