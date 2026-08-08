[CmdletBinding()]
param([switch]$Integration)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
$resumeScript = Join-Path $root 'skills\codex-git-operations\scripts\Resume-ExperienceReleasePublication.ps1'

if (-not $Integration) {
    $source = Get-Content -LiteralPath $resumeScript -Raw -Encoding UTF8
    foreach ($required in @(
        'Release publication resume requires a clean worktree',
        'sync-origin-main',
        'merge-public-history',
        'sync-public-main',
        'create-local-tag',
        'sync-release-tag',
        'github-release',
        'SkipGitHubRelease',
        'pending_sync',
        'release-publication-resumed'
    )) {
        if ($source -notmatch [regex]::Escape($required)) { throw "Publication resume contract is missing: $required" }
    }
    if ($source -notmatch 'AllowPublicHistoryMerge') { throw 'Publication resume does not expose the public history review gate.' }
    if ($source -notmatch 'tag .* exists but does not point to HEAD') { throw 'Publication resume does not reject mismatched tags.' }
    if ($source -notmatch 'Invoke-GitHubNetworkCommand\.ps1') { throw 'Publication resume does not route GitHub network commands through the scoped helper.' }
    if ($source -notmatch 'Get-RemoteRefCommit[\s\S]+Invoke-GitHubNetworkCommand\.ps1[\s\S]+ls-remote') { throw 'Publication resume remote-ref probes do not use the scoped GitHub network helper.' }
    Write-Host 'Experience release publication resume contract test passed.'
    return
}

$runRoot = & (Join-Path $root 'scripts\Resolve-CodexRunRoot.ps1') -ArchitectureRoot $root -Kind tmp -ChildPath ('release-publication-resume-' + [guid]::NewGuid().ToString('N')) -Create
$work = Join-Path $runRoot 'work'
$publicWork = Join-Path $runRoot 'public-work'
$origin = Join-Path $runRoot 'origin.git'
$public = Join-Path $runRoot 'public.git'

try {
    & git init --bare $origin | Out-Null
    & git init --bare $public | Out-Null
    & git init $work | Out-Null
    & git -C $work config user.email 'fixture@example.invalid'
    & git -C $work config user.name 'Fixture'
    & git -C $work remote add origin $origin
    & git -C $work remote add public $public
    New-Item -ItemType Directory -Force -Path (Join-Path $work 'docs\release-notes') | Out-Null
    New-Item -ItemType Directory -Force -Path (Join-Path $work '.codex\project') | Out-Null
    '2.0.0.0' | Set-Content -LiteralPath (Join-Path $work 'VERSION') -Encoding UTF8
    '# v2.0.0.0' | Set-Content -LiteralPath (Join-Path $work 'docs\release-notes\v2.0.0.0.md') -Encoding UTF8
    '{"schema_version":1,"pending_sync":true}' | Set-Content -LiteralPath (Join-Path $work '.codex\project\state.json') -Encoding UTF8
    'public base' | Set-Content -LiteralPath (Join-Path $work 'README.md') -Encoding UTF8
    & git -C $work add .
    & git -C $work commit -q -m base
    & git -C $work branch -M main
    & git -C $work push origin HEAD:main | Out-Null
    & git -C $work push public HEAD:main | Out-Null

    & git clone $public $publicWork | Out-Null
    & git -C $publicWork checkout main | Out-Null
    if ($LASTEXITCODE -ne 0) { throw 'Could not check out public fixture main branch.' }
    & git -C $publicWork config user.email 'fixture@example.invalid'
    & git -C $publicWork config user.name 'Fixture'
    'public-only' | Set-Content -LiteralPath (Join-Path $publicWork 'PUBLIC.md') -Encoding UTF8
    & git -C $publicWork add PUBLIC.md
    & git -C $publicWork commit -q -m public-only
    & git -C $publicWork push origin HEAD:main | Out-Null
    if ($LASTEXITCODE -ne 0) { throw 'Could not push public-only fixture commit.' }

    'release tree' | Set-Content -LiteralPath (Join-Path $work 'README.md') -Encoding UTF8
    & git -C $work add README.md
    & git -C $work commit -q -m release
    $releaseCommit = (& git -C $work rev-parse HEAD).Trim()

    $resume = & $resumeScript `
        -RepositoryRoot $work `
        -Mode Public `
        -Version '2.0.0.0' `
        -Tag 'v2.0' `
        -ReleaseTitle 'v2.0' `
        -AllowPublicHistoryMerge `
        -SkipRemoteIdentityCheck `
        -SkipGitHubRelease `
        -Apply | ConvertFrom-Json
    if ($resume.result -ne 'release-publication-resumed') { throw 'Publication resume did not complete.' }
    $head = (& git -C $work rev-parse HEAD).Trim()
    if ($head -eq $releaseCommit) { throw 'Publication resume did not retain public history with a merge commit.' }
    $originHead = ((& git -C $work ls-remote origin refs/heads/main) -split '\s+')[0]
    $publicHead = ((& git -C $work ls-remote public refs/heads/main) -split '\s+')[0]
    $publicTag = ((& git -C $work ls-remote public 'refs/tags/v2.0^{}') -split '\s+')[0]
    if ($originHead -ne $head -or $publicHead -ne $head -or $publicTag -ne $head) { throw 'Publication resume did not align origin, public, and tag to HEAD.' }
    $readme = (Get-Content -LiteralPath (Join-Path $work 'README.md') -Raw -Encoding UTF8).Trim()
    if ($readme -ne 'release tree') { throw 'Publication resume changed the reviewed release tree.' }
    $state = Get-Content -LiteralPath (Join-Path $work '.codex\project\state.json') -Raw -Encoding UTF8 | ConvertFrom-Json
    if ($state.pending_sync -or $state.last_release_tag -ne 'v2.0') { throw 'Publication resume did not update lifecycle state.' }

    $again = & $resumeScript `
        -RepositoryRoot $work `
        -Mode Public `
        -Version '2.0.0.0' `
        -Tag 'v2.0' `
        -ReleaseTitle 'v2.0' `
        -AllowPublicHistoryMerge `
        -SkipRemoteIdentityCheck `
        -SkipGitHubRelease `
        -Apply | ConvertFrom-Json
    if (@($again.steps | Where-Object { $_.result -eq 'pushed' }).Count -ne 0) { throw 'Publication resume is not idempotent.' }
}
finally {
    if (Test-Path -LiteralPath $runRoot) { Remove-Item -LiteralPath $runRoot -Recurse -Force }
}

Write-Host 'Experience release publication resume integration test passed.'
