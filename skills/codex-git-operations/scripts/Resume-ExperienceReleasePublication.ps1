[CmdletBinding()]
param(
    [ValidateSet('Private', 'Public')]
    [string]$Mode,
    [Parameter(Mandatory = $true)]
    [string]$Version,
    [Parameter(Mandatory = $true)]
    [string]$Tag,
    [string]$RepositoryRoot = (Get-Location).Path,
    [string]$ReleaseTitle = '',
    [string]$ReleaseNote = '',
    [switch]$AllowPublicHistoryMerge,
    [switch]$SkipRemoteIdentityCheck,
    [switch]$SkipGitHubRelease,
    [switch]$ForceProxy,
    [switch]$Apply
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath $RepositoryRoot).Path
$architectureRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..\..\..')).Path
if (-not $ReleaseTitle) { $ReleaseTitle = $Tag }
if (-not $ReleaseNote) { $ReleaseNote = "docs/release-notes/v$Version.md" }
$releaseNotePath = Join-Path $root $ReleaseNote
if (-not (Test-Path -LiteralPath $releaseNotePath -PathType Leaf)) { throw "Release note is missing: $ReleaseNote" }
$currentVersion = (Get-Content -LiteralPath (Join-Path $root 'VERSION') -Raw -Encoding UTF8).Trim()
if ($currentVersion -ne $Version) { throw "Version mismatch: expected $Version, found $currentVersion." }

function Get-GitHubRepositoryName([string]$Remote) {
    $url = (& git -C $root remote get-url $Remote 2>$null).Trim()
    if (-not $url) { throw "Required remote '$Remote' is unavailable." }
    $match = [regex]::Match($url, 'github\.com[:/](?<name>[^/]+/[^/.]+)')
    if ($match.Success) { return $match.Groups['name'].Value }
    return ''
}

function Invoke-RepositoryGit([string[]]$Arguments) {
    if (-not $Apply) { return }
    $githubCommand = Join-Path $root 'skills\codex-git-operations\scripts\Invoke-GitHubNetworkCommand.ps1'
    $remoteUrl = ''
    $remoteIndex = [Array]::IndexOf($Arguments, 'push')
    if ($remoteIndex -ge 0 -and $Arguments.Count -gt ($remoteIndex + 1)) {
        $remoteUrl = (& git -C $root remote get-url $Arguments[$remoteIndex + 1] 2>$null).Trim()
    }
    if ($remoteUrl -match 'github\.com' -and (Test-Path -LiteralPath $githubCommand -PathType Leaf)) {
        & $githubCommand -RepositoryRoot $root -ForceProxy:$ForceProxy -Tool git @Arguments
    } else {
        & git @Arguments
    }
    if ($LASTEXITCODE -ne 0) { throw "Git command failed: git $($Arguments -join ' ')" }
}

function Invoke-RepositoryGh([string[]]$Arguments) {
    if (-not $Apply -or $SkipGitHubRelease) { return '' }
    $githubCommand = Join-Path $root 'skills\codex-git-operations\scripts\Invoke-GitHubNetworkCommand.ps1'
    if (Test-Path -LiteralPath $githubCommand -PathType Leaf) {
        return (& $githubCommand -RepositoryRoot $root -ForceProxy:$ForceProxy -Tool gh @Arguments)
    }
    return (& gh @Arguments)
}

function Get-RemoteRefCommit([string]$Remote, [string]$Ref) {
    $githubCommand = Join-Path $root 'skills\codex-git-operations\scripts\Invoke-GitHubNetworkCommand.ps1'
    if (Test-Path -LiteralPath $githubCommand -PathType Leaf) {
        $rows = @(& $githubCommand -RepositoryRoot $root -ForceProxy:$ForceProxy -Tool git -C $root ls-remote $Remote $Ref 2>$null | Where-Object { $_ })
    } else {
        $rows = @(& git -C $root ls-remote $Remote $Ref 2>$null | Where-Object { $_ })
    }
    if ($rows.Count -eq 0) { return '' }
    return (($rows[0] -split '\s+')[0]).Trim()
}

function Get-RemoteTagCommit([string]$Remote, [string]$TagName) {
    $peeled = Get-RemoteRefCommit $Remote "refs/tags/$TagName^{}"
    if ($peeled) { return $peeled }
    return Get-RemoteRefCommit $Remote "refs/tags/$TagName"
}

if ($Apply) { & (Join-Path $PSScriptRoot 'Test-CodexGitRecoveryPreflight.ps1') -RepositoryRoot $root | Out-Null }
$head = (& git -C $root rev-parse HEAD).Trim()
$status = @(& git -C $root status --porcelain)
$nonLifecycleStatus = @($status | Where-Object { $_ -notmatch '^\s*M\s+\.codex/project/state\.json$' })
if ($nonLifecycleStatus.Count -gt 0) { throw 'Release publication resume requires a clean worktree.' }

$privateRepository = Get-GitHubRepositoryName 'origin'
$publicRepository = Get-GitHubRepositoryName 'public'
if ($Mode -eq 'Public' -and -not $SkipRemoteIdentityCheck) {
    & (Join-Path $architectureRoot 'scripts\Test-PublicReleaseSafety.ps1') -RepositoryRoot $root -CandidateRef HEAD -PublicRemote public -PrivateRemote origin | Out-Null
}

$steps = New-Object System.Collections.Generic.List[object]
function Add-Step([string]$Name, [string]$Result, [object]$Details = $null) {
    $steps.Add([ordered]@{ name = $Name; result = $Result; details = $Details }) | Out-Null
}

$originMain = Get-RemoteRefCommit 'origin' 'refs/heads/main'
if ($originMain -ne $head) {
    Invoke-RepositoryGit @('-C', $root, 'push', 'origin', 'HEAD:main')
    $originMain = Get-RemoteRefCommit 'origin' 'refs/heads/main'
    if ($originMain -ne $head) { throw 'origin/main did not advance to HEAD.' }
    Add-Step 'sync-origin-main' 'pushed'
} else {
    Add-Step 'sync-origin-main' 'already-current'
}

if ($Mode -eq 'Public') {
    & git -C $root fetch --quiet public main 2>$null | Out-Null
    if ($LASTEXITCODE -ne 0) { throw 'Could not fetch public/main.' }
    $publicMain = Get-RemoteRefCommit 'public' 'refs/heads/main'
    if ($publicMain -and $publicMain -ne $head) {
        & git -C $root merge-base --is-ancestor $publicMain HEAD
        $remoteAncestor = ($LASTEXITCODE -eq 0)
        if (-not $remoteAncestor) {
            if (-not $AllowPublicHistoryMerge) { throw 'public/main is not an ancestor of HEAD; rerun with -AllowPublicHistoryMerge after review.' }
            if ($Apply) {
                & git -C $root merge --quiet -s ours --no-ff FETCH_HEAD -m "merge: retain public release history for $Tag" | Out-Null
                if ($LASTEXITCODE -ne 0) { throw 'Public history merge failed.' }
                $head = (& git -C $root rev-parse HEAD).Trim()
                if (-not $SkipRemoteIdentityCheck) {
                    & (Join-Path $architectureRoot 'scripts\Test-PublicReleaseSafety.ps1') -RepositoryRoot $root -CandidateRef HEAD -PublicRemote public -PrivateRemote origin | Out-Null
                }
                Invoke-RepositoryGit @('-C', $root, 'push', 'origin', 'HEAD:main')
            }
            Add-Step 'merge-public-history' 'retained-current-tree'
        }
    }
    if ((Get-RemoteRefCommit 'public' 'refs/heads/main') -ne $head) {
        Invoke-RepositoryGit @('-C', $root, 'push', 'public', 'main')
        if ((Get-RemoteRefCommit 'public' 'refs/heads/main') -ne $head) { throw 'public/main did not advance to HEAD.' }
        Add-Step 'sync-public-main' 'pushed'
    } else {
        Add-Step 'sync-public-main' 'already-current'
    }
}

$targetRemote = if ($Mode -eq 'Private') { 'origin' } else { 'public' }
$targetRepository = if ($Mode -eq 'Private') { $privateRepository } else { $publicRepository }
$remoteTag = Get-RemoteTagCommit $targetRemote $Tag
if ($remoteTag -and $remoteTag -ne $head) { throw "$targetRemote tag $Tag exists but does not point to HEAD." }
$localTagCommit = ([string]@(& git -C $root rev-parse -q --verify "refs/tags/$Tag^{commit}" 2>$null)[0]).Trim()
if ($localTagCommit -and $localTagCommit -ne $head) { throw "Local tag $Tag exists but does not point to HEAD." }
if (-not $localTagCommit -and $Apply) {
    & git -C $root tag -a $Tag -m $ReleaseTitle
    if ($LASTEXITCODE -ne 0) { throw "Could not create local tag $Tag." }
    Add-Step 'create-local-tag' 'created'
} else {
    Add-Step 'create-local-tag' 'already-current'
}
if (-not $remoteTag) {
    Invoke-RepositoryGit @('-C', $root, 'push', $targetRemote, $Tag)
    $remoteTag = Get-RemoteTagCommit $targetRemote $Tag
    if ($remoteTag -ne $head) { throw "$targetRemote tag $Tag did not advance to HEAD." }
    Add-Step 'sync-release-tag' 'pushed'
} else {
    Add-Step 'sync-release-tag' 'already-current'
}

$releaseUrl = ''
if (-not $SkipGitHubRelease) {
    $existingRelease = ''
    try {
        $existingRelease = Invoke-RepositoryGh @('release', 'view', $Tag, '--repo', $targetRepository, '--json', 'tagName,isDraft,isPrerelease,url,targetCommitish')
    } catch {
        $existingRelease = ''
    }
    if (-not $existingRelease) {
        $created = Invoke-RepositoryGh @('release', 'create', $Tag, '--repo', $targetRepository, '--title', $ReleaseTitle, '--notes-file', $releaseNotePath, '--latest')
        $releaseUrl = (($created | Select-Object -Last 1) -as [string]).Trim()
        Add-Step 'github-release' 'created' $releaseUrl
    } else {
        $release = $existingRelease | ConvertFrom-Json
        if ($release.isDraft -or $release.isPrerelease) { throw "GitHub Release $Tag is draft or prerelease." }
        $releaseUrl = $release.url
        Add-Step 'github-release' 'already-current' $releaseUrl
    }
}

if ($Apply) {
    $statePath = Join-Path $root '.codex\project\state.json'
    if (Test-Path -LiteralPath $statePath -PathType Leaf) {
        $state = Get-Content -LiteralPath $statePath -Raw -Encoding UTF8 | ConvertFrom-Json
        $state | Add-Member -NotePropertyName last_observed_head -NotePropertyValue $head -Force
        $state | Add-Member -NotePropertyName pending_sync -NotePropertyValue $false -Force
        $state | Add-Member -NotePropertyName last_iteration_status -NotePropertyValue 'completed' -Force
        $state | Add-Member -NotePropertyName last_release_tag -NotePropertyValue $Tag -Force
        if ($releaseUrl) { $state | Add-Member -NotePropertyName last_release_url -NotePropertyValue $releaseUrl -Force }
        $state | Add-Member -NotePropertyName updated_at -NotePropertyValue (Get-Date).ToString('o') -Force
        $state | ConvertTo-Json | Set-Content -LiteralPath $statePath -Encoding UTF8
    }
}

[ordered]@{
    result = 'release-publication-resumed'
    mode = $Mode
    version = $Version
    tag = $Tag
    commit = $head
    target_remote = $targetRemote
    release_url = $releaseUrl
    steps = $steps.ToArray()
} | ConvertTo-Json -Depth 6
