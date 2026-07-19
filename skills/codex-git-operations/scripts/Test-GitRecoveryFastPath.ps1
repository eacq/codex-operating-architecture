$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
$fixture = & (Join-Path $root 'scripts\Resolve-CodexRunRoot.ps1') -ArchitectureRoot $root -Kind tmp -ChildPath ('git-recovery-fast-path-' + [guid]::NewGuid().ToString('N')) -Create

try {
    foreach ($name in @('blocked', 'other', 'verified')) {
        New-Item -ItemType Directory -Force -Path (Join-Path $fixture ".codex\errors\$name") | Out-Null
    }
    '{"module":"other-owner","status":"observed"}' | Set-Content -LiteralPath (Join-Path $fixture '.codex\errors\other\report.json') -Encoding UTF8
    '{"module":"codex-git-operations","component":"push","status":"verified"}' | Set-Content -LiteralPath (Join-Path $fixture '.codex\errors\verified\report.json') -Encoding UTF8
    $ready = & (Join-Path $PSScriptRoot 'Test-CodexGitRecoveryPreflight.ps1') -RepositoryRoot $fixture | ConvertFrom-Json
    if ($ready.result -ne 'git-recovery-ready') { throw 'Verified and unrelated reports should not block Git recovery.' }

    '{"module":"codex-git-operations","component":"release","status":"observed"}' | Set-Content -LiteralPath (Join-Path $fixture '.codex\errors\blocked\report.json') -Encoding UTF8
    $blocked = $false
    try {
        & (Join-Path $PSScriptRoot 'Test-CodexGitRecoveryPreflight.ps1') -RepositoryRoot $fixture | Out-Null
    } catch {
        $blocked = $_.Exception.Message -match 'before network, rendering, version, or release work begins'
    }
    if (-not $blocked) { throw 'Unresolved Git reports must fail at the fast preflight boundary.' }

    $release = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'Invoke-ExperienceRelease.ps1') -Raw -Encoding UTF8
    $preflightPosition = $release.IndexOf('Test-CodexGitRecoveryPreflight.ps1')
    $networkPosition = $release.IndexOf('Invoke-GitHubNetworkCommand.ps1')
    $renderPosition = $release.IndexOf('Update-ReleaseReadmeAndVisuals.ps1')
    if ($preflightPosition -lt 0 -or $preflightPosition -gt $networkPosition -or $preflightPosition -gt $renderPosition) {
        throw 'Release recovery preflight must run before network and rendering work.'
    }
    Write-Host 'Git recovery fast-path test passed.'
}
finally {
    if (Test-Path -LiteralPath $fixture) { Remove-Item -LiteralPath $fixture -Recurse -Force }
}
