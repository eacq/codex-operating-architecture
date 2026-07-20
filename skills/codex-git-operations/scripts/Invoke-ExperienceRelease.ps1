[CmdletBinding()]
param(
    [ValidateSet('Private', 'Public')]
    [string]$Mode,
    [Parameter(Mandatory = $true)]
    [string[]]$Paths,
    [string]$RepositoryRoot = (Get-Location).Path,
    [switch]$PreserveVersion,
    [switch]$ForceProxy,
    [switch]$Apply
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath $RepositoryRoot).Path
if ($Apply) {
    & (Join-Path $PSScriptRoot 'Test-CodexGitRecoveryPreflight.ps1') -RepositoryRoot $root | Out-Null
}
$githubCommand = Join-Path $PSScriptRoot 'Invoke-GitHubNetworkCommand.ps1'
$getRepo = { param([string]$remote) $url = (& git -C $root remote get-url $remote).Trim(); $match = [regex]::Match($url, 'github\.com[:/](?<name>[^/]+/[^/.]+)'); if (-not $match.Success) { throw "Cannot derive GitHub repository from '$remote'." }; $match.Groups['name'].Value }
$privateRepository = & $getRepo 'origin'
$publicRepository = & $getRepo 'public'
$current = (Get-Content -LiteralPath (Join-Path $root 'VERSION') -Raw -Encoding UTF8).Trim()
$calculator = Join-Path $PSScriptRoot 'Get-ExperienceVersion.ps1'
$action = if ($Mode -eq 'Private') { 'PrivateRelease' } else { 'PublicRelease' }
$versionPlan = if ($PreserveVersion) {
    $parts = @($current -split '\.')
    if ($parts.Count -ne 4 -or @($parts | Where-Object { $_ -notmatch '^\d+$' }).Count -gt 0) { throw "Cannot preserve malformed experience version: $current" }
    [pscustomobject]@{ version = $current; release_tag = "v$($parts[0]).$($parts[1])" }
} else {
    & $calculator -Action $action -CurrentVersion $current -RepositoryRoot $root | ConvertFrom-Json
}
$releaseTag = if ($Mode -eq 'Private') { "private-$($versionPlan.release_tag)" } else { $versionPlan.release_tag }
$releaseNote = "docs/release-notes/v$($versionPlan.version).md"
$plan = [ordered]@{
    mode = $Mode; current_version = $current; next_version = $versionPlan.version; preserve_version = [bool]$PreserveVersion; force_proxy = [bool]$ForceProxy
    release_title = $versionPlan.release_tag; git_tag = $releaseTag; release_note = $releaseNote
    paths = @($Paths)
    apply_requires = @('explicit command phrase', 'scoped paths', 'full validation', 'documentation sync', 'private Git synchronization before public release')
}
if (-not $Apply) { $plan | ConvertTo-Json -Depth 5; exit 0 }

$targetRemote = if ($Mode -eq 'Private') { 'origin' } else { 'public' }
$localTag = (& git -C $root rev-parse -q --verify "refs/tags/$releaseTag" 2>$null)
if ($localTag) { throw "Release tag already exists locally: $releaseTag. Resolve the stale tag or choose a new release before applying." }
$remoteTag = @(& $githubCommand -RepositoryRoot $root -ForceProxy:$ForceProxy -Tool git -C $root ls-remote --tags $targetRemote "refs/tags/$releaseTag" 2>$null)
if ($remoteTag.Count -gt 0) { throw "Release tag already exists on ${targetRemote}: $releaseTag." }
$targetRepository = if ($Mode -eq 'Private') { $privateRepository } else { $publicRepository }
$existingRelease = ''
try {
    $existingRelease = (& $githubCommand -RepositoryRoot $root -ForceProxy:$ForceProxy -Tool gh release view $releaseTag --repo $targetRepository --json tagName 2>$null)
} catch {
    $existingRelease = ''
}
if ($existingRelease) { throw "GitHub Release already exists in $targetRepository for tag: $releaseTag." }

if (-not $PreserveVersion) { Set-Content -LiteralPath (Join-Path $root 'VERSION') -Value $versionPlan.version -Encoding UTF8 }
$releaseNotePath = Join-Path $root $releaseNote
if (-not (Test-Path -LiteralPath $releaseNotePath)) {
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $releaseNotePath) | Out-Null
    $chineseHeading = ([char[]]@(0x4E2D, 0x6587) -join '')
    $chineseBody = (([char[]]@(0x5DF2, 0x9A8C, 0x8BC1, 0x7684) -join '') + " $Mode " + ([char[]]@(0x7ECF, 0x9A8C, 0x7CFB, 0x7EDF, 0x53D1, 0x5E03, 0x3002) -join ''))
    @("# v$($versionPlan.version) / $($versionPlan.release_tag)", '', '## English', '', "Verified $Mode experience-system release.", '', "## Chinese / $chineseHeading", '', $chineseBody) | Set-Content -LiteralPath $releaseNotePath -Encoding UTF8
}
$releaseReadmeVisuals = & (Join-Path $root 'skills\codex-git-operations\scripts\Update-ReleaseReadmeAndVisuals.ps1') -RepositoryRoot $root -Version $versionPlan.version -Mode $Mode -ReleaseNote $releaseNote -ChangedPaths $Paths -Apply | ConvertFrom-Json
$readmeOptimizationCheck = & (Join-Path $root 'skills\codex-git-operations\scripts\Test-ReleaseReadmeOptimization.ps1') -RepositoryRoot $root -Version $versionPlan.version | ConvertFrom-Json
if ($readmeOptimizationCheck.result -ne 'release-readme-optimization-passed') { throw 'Release README presentation optimization did not pass.' }
$presentationAuditPath = "docs/readme-presentation-audits/v$($versionPlan.version).json"
$generatedPaths = @($releaseReadmeVisuals.generated_paths) + @('VERSION', $releaseNote, 'docs/ITERATION-STATUS.md', 'CHANGELOG.md', $presentationAuditPath)
$allPaths = @($Paths + $generatedPaths | Sort-Object -Unique)
& (Join-Path $root 'skills\codex-git-operations\scripts\Update-ExperienceChangelog.ps1') -RepositoryRoot $root -Version $versionPlan.version -ChangedPaths $allPaths -ChangeClass Release -Apply | Out-Null
& (Join-Path $root 'scripts\Sync-IterationDocumentation.ps1') -RepositoryRoot $root -ChangedPaths $allPaths -Apply | Out-Null
& (Join-Path $root 'skills\codex-git-operations\scripts\Test-ExperienceReleaseReadiness.ps1') -RepositoryRoot $root -Version $versionPlan.version | Out-Null
$pathSet = & (Join-Path $root 'skills\codex-git-operations\scripts\Resolve-ExperienceReleasePathSet.ps1') -RepositoryRoot $root -Paths $Paths -GeneratedPaths $generatedPaths | ConvertFrom-Json
$allPaths = @($pathSet.all_paths)
$unselected = @($pathSet.unselected_paths)
if ($unselected.Count -gt 0) { throw "Release retry path set is incomplete after repair; recompute it and include: $($unselected -join ', ')" }
$commitPaths = @($pathSet.commit_paths)
if ($commitPaths.Count -eq 0) { throw 'Release produced no changed or untracked paths to commit.' }
$commitScript = Join-Path $root 'skills\codex-git-operations\scripts\Invoke-VerifiedPrivateCommit.ps1'
& $commitScript -RepositoryRoot $root -Paths $commitPaths -Apply -PreserveVersion -ForceProxy:$ForceProxy -Message "release: experience system $($versionPlan.version)"
if ($LASTEXITCODE -ne 0) { throw 'Private release commit/push failed.' }
if ($Mode -eq 'Private') {
    & git -C $root tag -a $releaseTag -m $versionPlan.release_tag
    & $githubCommand -RepositoryRoot $root -ForceProxy:$ForceProxy -Tool git -C $root push origin $releaseTag
    & $githubCommand -RepositoryRoot $root -ForceProxy:$ForceProxy -Tool gh release create $releaseTag --repo $privateRepository --title $versionPlan.release_tag --notes-file $releaseNotePath
} else {
    & (Join-Path $root 'scripts\Test-PublicReleaseSafety.ps1') -RepositoryRoot $root -CandidateRef HEAD -PublicRemote public -PrivateRemote origin | Out-Null
    & $githubCommand -RepositoryRoot $root -ForceProxy:$ForceProxy -Tool git -C $root push public main
    & git -C $root tag -a $releaseTag -m $versionPlan.release_tag
    & $githubCommand -RepositoryRoot $root -ForceProxy:$ForceProxy -Tool git -C $root push public $releaseTag
    & $githubCommand -RepositoryRoot $root -ForceProxy:$ForceProxy -Tool gh release create $releaseTag --repo $publicRepository --title $versionPlan.release_tag --notes-file $releaseNotePath
}
if ($LASTEXITCODE -ne 0) { throw "$Mode GitHub release failed." }
$releaseEvidence = if ($Mode -eq 'Private') {
    & (Join-Path $root 'skills\codex-git-operations\scripts\Test-PrivateExperienceReleaseEvidence.ps1') `
        -RepositoryRoot $root `
        -Version $versionPlan.version `
        -Tag $releaseTag `
        -ForceProxy:$ForceProxy `
        -RequireClean `
        -ApplyLifecycleState | ConvertFrom-Json
} else {
    $null
}
$plan['result'] = 'release-created'
$plan['readme_optimization'] = $readmeOptimizationCheck
$plan['release_evidence'] = $releaseEvidence
$plan | ConvertTo-Json -Depth 5
