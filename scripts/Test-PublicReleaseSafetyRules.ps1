[CmdletBinding()]
param(
    [string]$RepositoryRoot = (Get-Location).Path
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath $RepositoryRoot).Path
$runRootScript = Join-Path $root 'scripts\Resolve-CodexRunRoot.ps1'
$runRoot = if (Test-Path -LiteralPath $runRootScript -PathType Leaf) {
    (& $runRootScript -ArchitectureRoot $root -Kind work -ChildPath 'public-release-safety-test' -Create)
} else {
    Join-Path $root '.runtime\work\public-release-safety-test'
}
$fixture = Join-Path $runRoot ([guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Force -Path $fixture | Out-Null
try {
    & git -C $fixture init --quiet
    & git -C $fixture config user.email 'codex@example.invalid'
    & git -C $fixture config user.name 'Codex Test'
    New-Item -ItemType Directory -Force -Path (Join-Path $fixture 'config') | Out-Null
    Set-Content -LiteralPath (Join-Path $fixture 'config\.env.example') -Value 'TOKEN=' -Encoding UTF8
    & git -C $fixture add config/.env.example
    & git -C $fixture commit --quiet -m 'test env example'
    & (Join-Path $root 'scripts\Test-PublicReleaseSafety.ps1') -RepositoryRoot $fixture -CandidateRef HEAD -SkipRemoteIdentityCheck | Out-Null

    Set-Content -LiteralPath (Join-Path $fixture 'config\.env.local') -Value 'TOKEN=secret-shaped' -Encoding UTF8
    & git -C $fixture add config/.env.local
    & git -C $fixture commit --quiet -m 'test real env'
    $blocked = $false
    try {
        & (Join-Path $root 'scripts\Test-PublicReleaseSafety.ps1') -RepositoryRoot $fixture -CandidateRef HEAD -SkipRemoteIdentityCheck | Out-Null
    } catch {
        if ($_.Exception.Message -match 'forbidden private-state path') { $blocked = $true } else { throw }
    }
    if (-not $blocked) { throw 'Public release safety rules did not reject .env.local.' }
} finally {
    if (Test-Path -LiteralPath $fixture) { Remove-Item -LiteralPath $fixture -Recurse -Force }
}

'Public release safety rules test passed.'
