$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
$fixture = & (Join-Path $root 'scripts\Resolve-CodexRunRoot.ps1') -ArchitectureRoot $root -Kind tmp -ChildPath ('private-release-evidence-' + [guid]::NewGuid().ToString('N')) -Create

try {
    New-Item -ItemType Directory -Force -Path (Join-Path $fixture '.codex\project') | Out-Null
    '1.4.0.0' | Set-Content -LiteralPath (Join-Path $fixture 'VERSION') -Encoding UTF8
    '{"schema_version":1,"pending_sync":true}' | Set-Content -LiteralPath (Join-Path $fixture '.codex\project\state.json') -Encoding UTF8
    & git -C $fixture init -q
    & git -C $fixture config user.email 'fixture@example.invalid'
    & git -C $fixture config user.name 'Fixture'
    & git -C $fixture remote add origin 'https://github.com/example/private-repo.git'
    & git -C $fixture add .
    & git -C $fixture commit -q -m release
    & git -C $fixture tag -a private-v1.4 -m v1.4
    $commit = (& git -C $fixture rev-parse HEAD).Trim()
    $branch = (& git -C $fixture branch --show-current).Trim()
    $releaseJson = [ordered]@{ tagName = 'private-v1.4'; name = 'v1.4'; isDraft = $false; isPrerelease = $false; publishedAt = '2026-01-01T00:00:00Z'; url = 'https://github.com/example/private-repo/releases/tag/private-v1.4'; targetCommitish = $branch } | ConvertTo-Json -Compress
    $repoJson = [ordered]@{ isPrivate = $true; nameWithOwner = 'example/private-repo' } | ConvertTo-Json -Compress
    $result = & (Join-Path $PSScriptRoot 'Test-PrivateExperienceReleaseEvidence.ps1') `
        -RepositoryRoot $fixture `
        -Version '1.4.0.0' `
        -Tag 'private-v1.4' `
        -RequireClean `
        -ApplyLifecycleState `
        -ProvidedOriginMain $commit `
        -ProvidedRemoteTagCommit $commit `
        -ProvidedReleaseJson $releaseJson `
        -ProvidedRepositoryJson $repoJson | ConvertFrom-Json
    $state = Get-Content -LiteralPath (Join-Path $fixture '.codex\project\state.json') -Raw -Encoding UTF8 | ConvertFrom-Json
    if ($result.result -ne 'private-release-evidence-verified' -or $result.commit -ne $commit -or $state.pending_sync) {
        throw 'Private release evidence did not verify and write back lifecycle state.'
    }
    if (@($result.scripted_steps).Count -ne 7 -or $result.duration_ms -le 0) { throw 'Private release evidence did not report script telemetry.' }
    $blocked = $false
    try {
        & (Join-Path $PSScriptRoot 'Test-PrivateExperienceReleaseEvidence.ps1') `
            -RepositoryRoot $fixture `
            -Version '1.4.0.0' `
            -Tag 'private-v1.4' `
            -RequireClean `
            -ProvidedOriginMain $commit `
            -ProvidedRemoteTagCommit $commit `
            -ProvidedReleaseJson $releaseJson `
            -ProvidedRepositoryJson $repoJson | Out-Null
    } catch {
        $blocked = $_.Exception.Message -match 'clean worktree'
    }
    if (-not $blocked) { throw 'Private release evidence did not reject a dirty worktree before evidence verification.' }
    Write-Host "Private experience release evidence test passed in $($result.duration_ms)ms."
}
finally {
    if (Test-Path -LiteralPath $fixture) { Remove-Item -LiteralPath $fixture -Recurse -Force }
}
