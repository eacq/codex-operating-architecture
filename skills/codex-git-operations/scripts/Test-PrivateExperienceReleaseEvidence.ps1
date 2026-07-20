[CmdletBinding()]
param(
    [string]$RepositoryRoot = (Get-Location).Path,
    [Parameter(Mandatory = $true)] [string]$Version,
    [Parameter(Mandatory = $true)] [string]$Tag,
    [switch]$ForceProxy,
    [switch]$RequireClean,
    [switch]$ApplyLifecycleState,
    [string]$ProvidedOriginMain = '',
    [string]$ProvidedRemoteTagCommit = '',
    [string]$ProvidedReleaseJson = '',
    [string]$ProvidedRepositoryJson = ''
)

$ErrorActionPreference = 'Stop'
$stopwatch = [Diagnostics.Stopwatch]::StartNew()
$root = (Resolve-Path -LiteralPath $RepositoryRoot).Path
$head = (& git -C $root rev-parse HEAD).Trim()
$branch = (& git -C $root branch --show-current).Trim()
$currentVersion = (Get-Content -LiteralPath (Join-Path $root 'VERSION') -Raw -Encoding UTF8).Trim()
if ($currentVersion -ne $Version) { throw "Release evidence version mismatch: expected $Version, found $currentVersion." }
$localTag = (& git -C $root rev-parse "refs/tags/$Tag^{}").Trim()
if (-not $localTag) { throw "Local release tag is missing: $Tag" }
if ($RequireClean -and @(git -C $root status --short).Count -gt 0) { throw 'Release evidence requires a clean worktree.' }

$originUrl = (& git -C $root remote get-url origin).Trim()
$repoMatch = [regex]::Match($originUrl, 'github\.com[:/](?<repo>[^/]+/[^/.]+)')
if (-not $repoMatch.Success) { throw "Cannot derive the private GitHub repository from origin: $originUrl" }
$repository = $repoMatch.Groups['repo'].Value
$provided = @($ProvidedOriginMain, $ProvidedRemoteTagCommit, $ProvidedReleaseJson, $ProvidedRepositoryJson)
$providedCount = @($provided | Where-Object { $_ }).Count
if ($providedCount -notin @(0, 4)) { throw 'Provide all private-release evidence fields together or omit all of them.' }

if ($providedCount -eq 4) {
    $originMain = $ProvidedOriginMain
    $remoteTag = $ProvidedRemoteTagCommit
    $release = $ProvidedReleaseJson | ConvertFrom-Json
    $repositoryEvidence = $ProvidedRepositoryJson | ConvertFrom-Json
} else {
    $github = Join-Path $PSScriptRoot 'Invoke-GitHubNetworkCommand.ps1'
    $originLine = & $github -RepositoryRoot $root -ForceProxy:$ForceProxy -Tool git -C $root ls-remote origin refs/heads/main
    $tagLine = & $github -RepositoryRoot $root -ForceProxy:$ForceProxy -Tool git -C $root ls-remote origin "refs/tags/$Tag^{}"
    $originMain = (([string]$originLine -split '\s+')[0])
    $remoteTag = (([string]$tagLine -split '\s+')[0])
    $release = (& $github -RepositoryRoot $root -ForceProxy:$ForceProxy -Tool gh release view $Tag --repo $repository --json 'tagName,name,isDraft,isPrerelease,publishedAt,url,targetCommitish') | ConvertFrom-Json
    $repositoryEvidence = (& $github -RepositoryRoot $root -ForceProxy:$ForceProxy -Tool gh repo view $repository --json 'isPrivate,nameWithOwner') | ConvertFrom-Json
}

if (@(@($head, $originMain, $localTag, $remoteTag) | Select-Object -Unique).Count -ne 1) {
    throw 'Release evidence mismatch: HEAD, origin/main, local tag, and remote tag do not resolve to one commit.'
}
if (-not $repositoryEvidence.isPrivate -or $repositoryEvidence.nameWithOwner -ne $repository) { throw 'Origin repository is not verified private.' }
if ($release.tagName -ne $Tag -or $release.isDraft -or $release.isPrerelease -or $release.targetCommitish -ne $branch -or -not $release.url) {
    throw 'GitHub Release evidence is incomplete or does not match the current branch and tag.'
}
if ($ApplyLifecycleState) {
    $statePath = Join-Path $root '.codex\project\state.json'
    if (-not (Test-Path -LiteralPath $statePath)) { throw 'Lifecycle state is missing for release evidence writeback.' }
    $state = Get-Content -LiteralPath $statePath -Raw -Encoding UTF8 | ConvertFrom-Json
    $state | Add-Member -NotePropertyName updated_at -NotePropertyValue ([DateTime]::Now.ToString('o')) -Force
    $state | Add-Member -NotePropertyName last_observed_head -NotePropertyValue $head -Force
    $state | Add-Member -NotePropertyName pending_sync -NotePropertyValue $false -Force
    $state | Add-Member -NotePropertyName last_iteration_status -NotePropertyValue 'completed' -Force
    $state | Add-Member -NotePropertyName last_release_tag -NotePropertyValue $Tag -Force
    $state | Add-Member -NotePropertyName last_release_url -NotePropertyValue $release.url -Force
    $state | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $statePath -Encoding UTF8
}
$stopwatch.Stop()

[ordered]@{
    result = 'private-release-evidence-verified'
    repository = $repository
    version = $Version
    tag = $Tag
    commit = $head
    release_url = $release.url
    private = [bool]$repositoryEvidence.isPrivate
    draft = [bool]$release.isDraft
    prerelease = [bool]$release.isPrerelease
    lifecycle_updated = [bool]$ApplyLifecycleState
    scripted_steps = @('head', 'origin-main', 'local-tag', 'remote-tag', 'private-visibility', 'release-status', 'lifecycle-writeback')
    duration_ms = [math]::Round($stopwatch.Elapsed.TotalMilliseconds, 1)
} | ConvertTo-Json -Depth 4
