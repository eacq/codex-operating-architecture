[CmdletBinding()]
param(
    [ValidateSet('Private', 'Public')]
    [string]$Mode,
    [Parameter(Mandatory = $true)]
    [string[]]$Paths,
    [string]$RepositoryRoot = (Get-Location).Path,
    [switch]$Apply
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath $RepositoryRoot).Path
$getRepo = { param([string]$remote) $url = (& git -C $root remote get-url $remote).Trim(); $match = [regex]::Match($url, 'github\.com[:/](?<name>[^/]+/[^/.]+)'); if (-not $match.Success) { throw "Cannot derive GitHub repository from '$remote'." }; $match.Groups['name'].Value }
$privateRepository = & $getRepo 'origin'
$publicRepository = & $getRepo 'public'
$current = (Get-Content -LiteralPath (Join-Path $root 'VERSION') -Raw -Encoding UTF8).Trim()
$calculator = Join-Path $PSScriptRoot 'Get-ExperienceVersion.ps1'
$action = if ($Mode -eq 'Private') { 'PrivateRelease' } else { 'PublicRelease' }
$versionPlan = & $calculator -Action $action -CurrentVersion $current -RepositoryRoot $root | ConvertFrom-Json
$releaseTag = if ($Mode -eq 'Private') { "private-$($versionPlan.release_tag)" } else { $versionPlan.release_tag }
$releaseNote = "docs/release-notes/v$($versionPlan.version).md"
$plan = [ordered]@{
    mode = $Mode; current_version = $current; next_version = $versionPlan.version
    release_title = $versionPlan.release_tag; git_tag = $releaseTag; release_note = $releaseNote
    paths = @($Paths)
    apply_requires = @('explicit command phrase', 'scoped paths', 'full validation', 'documentation sync', 'private Git synchronization before public release')
}
if (-not $Apply) { $plan | ConvertTo-Json -Depth 5; exit 0 }

$targetRemote = if ($Mode -eq 'Private') { 'origin' } else { 'public' }
$localTag = (& git -C $root rev-parse -q --verify "refs/tags/$releaseTag" 2>$null)
if ($localTag) { throw "Release tag already exists locally: $releaseTag. Resolve the stale tag or choose a new release before applying." }
$remoteTag = @(& git -C $root ls-remote --tags $targetRemote "refs/tags/$releaseTag" 2>$null)
if ($remoteTag.Count -gt 0) { throw "Release tag already exists on ${targetRemote}: $releaseTag." }
$targetRepository = if ($Mode -eq 'Private') { $privateRepository } else { $publicRepository }
$existingRelease = ''
try {
    $existingRelease = (& gh release view $releaseTag --repo $targetRepository --json tagName 2>$null)
} catch {
    $existingRelease = ''
}
if ($existingRelease) { throw "GitHub Release already exists in $targetRepository for tag: $releaseTag." }

Set-Content -LiteralPath (Join-Path $root 'VERSION') -Value $versionPlan.version -Encoding UTF8
$releaseNotePath = Join-Path $root $releaseNote
if (-not (Test-Path -LiteralPath $releaseNotePath)) {
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $releaseNotePath) | Out-Null
    $chineseHeading = ([char[]]@(0x4E2D, 0x6587) -join '')
    $chineseBody = (([char[]]@(0x5DF2, 0x9A8C, 0x8BC1, 0x7684) -join '') + " $Mode " + ([char[]]@(0x7ECF, 0x9A8C, 0x7CFB, 0x7EDF, 0x53D1, 0x5E03, 0x3002) -join ''))
    @("# v$($versionPlan.version) / $($versionPlan.release_tag)", '', '## English', '', "Verified $Mode experience-system release.", '', "## Chinese / $chineseHeading", '', $chineseBody) | Set-Content -LiteralPath $releaseNotePath -Encoding UTF8
}
$allPaths = @($Paths + 'VERSION' + $releaseNote + 'docs/ITERATION-STATUS.md' + 'CHANGELOG.md' | Sort-Object -Unique)
& (Join-Path $root 'skills\codex-git-operations\scripts\Update-ExperienceChangelog.ps1') -RepositoryRoot $root -Version $versionPlan.version -ChangedPaths $allPaths -ChangeClass Release -Apply | Out-Null
& (Join-Path $root 'scripts\Sync-IterationDocumentation.ps1') -RepositoryRoot $root -ChangedPaths $allPaths -Apply | Out-Null
$allChanged = @(& git -C $root diff --name-only; & git -C $root diff --cached --name-only; & git -C $root ls-files --others --exclude-standard | Sort-Object -Unique)
$unselected = @($allChanged | Where-Object { $_ -notin $allPaths })
if ($unselected.Count -gt 0) { throw "Release retry path set is incomplete after repair; recompute it and include: $($unselected -join ', ')" }
$commitScript = Join-Path $root 'skills\codex-git-operations\scripts\Invoke-VerifiedPrivateCommit.ps1'
& $commitScript -RepositoryRoot $root -Paths $allPaths -Apply -PreserveVersion -Message "release: experience system $($versionPlan.version)"
if ($LASTEXITCODE -ne 0) { throw 'Private release commit/push failed.' }
if ($Mode -eq 'Private') {
    & git -C $root tag -a $releaseTag -m $versionPlan.release_tag
    & git -C $root push origin $releaseTag
    & gh release create $releaseTag --repo $privateRepository --title $versionPlan.release_tag --notes-file $releaseNotePath
} else {
    & (Join-Path $root 'scripts\Test-PublicReleaseSafety.ps1') -RepositoryRoot $root -CandidateRef HEAD -PublicRemote public -PrivateRemote origin | Out-Null
    & git -C $root push public main
    & git -C $root tag -a $releaseTag -m $versionPlan.release_tag
    & git -C $root push public $releaseTag
    & gh release create $releaseTag --repo $publicRepository --title $versionPlan.release_tag --notes-file $releaseNotePath
}
if ($LASTEXITCODE -ne 0) { throw "$Mode GitHub release failed." }
$plan['result'] = 'release-created'
$plan | ConvertTo-Json -Depth 5
