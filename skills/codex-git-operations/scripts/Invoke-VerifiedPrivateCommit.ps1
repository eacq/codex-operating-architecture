[CmdletBinding()]
param(
    [string]$RepositoryRoot = (Get-Location).Path,
    [string[]]$Paths,
    [string]$Message,
    [ValidateSet('Feature', 'Refinement')]
    [string]$ChangeClass = 'Feature',
    [switch]$PreserveVersion,
    [switch]$SkipCompleteIteration,
    [switch]$CommitOnly,
    [switch]$Apply
)

$ErrorActionPreference = 'Stop'
$root = [IO.Path]::GetFullPath((Resolve-Path -LiteralPath $RepositoryRoot).Path).TrimEnd('\\')
$gitRoot = [IO.Path]::GetFullPath(((& git -C $root rev-parse --show-toplevel).Trim() -replace '/', '\\')).TrimEnd('\\')
if ($gitRoot -ne $root) { throw "Repository root mismatch: expected '$root', got '$gitRoot'." }
if ($Apply -and (-not $Paths -or $Paths.Count -eq 0)) { throw 'Apply requires explicit -Paths so unrelated worktree changes cannot be committed.' }
if ($SkipCompleteIteration -and -not $CommitOnly) { throw 'SkipCompleteIteration is allowed only with CommitOnly; normal private auto-Git must retain the complete iteration gate.' }
$allChanged = @(& git -C $root diff --name-only; & git -C $root diff --cached --name-only; & git -C $root ls-files --others --exclude-standard | Sort-Object -Unique)
$selected = if ($Paths -and $Paths.Count -gt 0) { @($Paths) } else { @($allChanged) }
if ($selected.Count -eq 0) { throw 'No changed paths are available for an auto-Git decision.' }
$unexpected = @($selected | Where-Object { $_ -notin $allChanged })
if ($unexpected.Count -gt 0) { throw "Selected paths are not changed or untracked: $($unexpected -join ', ')" }
if ($Apply) {
    $outsideSelected = @($allChanged | Where-Object { $_ -notin $selected })
    if ($outsideSelected.Count -gt 0) { throw "Auto-Git rejects a mixed worktree; unselected changed paths: $($outsideSelected -join ', ')" }
    # Do this before generating version and release artifacts.  Otherwise an
    # unresolved Git-process report can stop the complete-iteration gate only
    # after this command has dirtied the worktree, making the next retry appear
    # to be an unrelated mixed-worktree change.
    $unresolvedGitReports = @(
        Get-ChildItem -LiteralPath (Join-Path $root '.codex/errors') -Filter report.json -Recurse -File |
            ForEach-Object { Get-Content -LiteralPath $_.FullName -Raw -Encoding UTF8 | ConvertFrom-Json } |
            Where-Object { $_.module -eq 'codex-git-operations' -and $_.status -notin @('fixed', 'verified') }
    )
    if ($unresolvedGitReports.Count -gt 0) {
        throw "Git recovery is incomplete: $($unresolvedGitReports.Count) Git-process error report(s) must be fixed or verified before version and release artifacts are generated."
    }
    if (-not $PreserveVersion) {
        $versionAction = if ($ChangeClass -eq 'Feature') { 'AutoFeature' } else { 'AutoFix' }
        $currentVersion = (Get-Content -LiteralPath (Join-Path $root 'VERSION') -Raw -Encoding UTF8).Trim()
        $versionPlan = & (Join-Path $root 'skills\codex-git-operations\scripts\Get-ExperienceVersion.ps1') -Action $versionAction -CurrentVersion $currentVersion | ConvertFrom-Json
        Set-Content -LiteralPath (Join-Path $root 'VERSION') -Value $versionPlan.version -Encoding UTF8
        $autoNote = "docs/release-notes/v$($versionPlan.version).md"
        $autoNotePath = Join-Path $root $autoNote
        if (-not (Test-Path -LiteralPath $autoNotePath)) {
            $chineseHeading = ([char[]]@(0x4E2D, 0x6587) -join '')
            $chineseBody = ([char[]]@(0x5DF2, 0x9A8C, 0x8BC1, 0x7684, 0x81EA, 0x52A8, 0x8FED, 0x4EE3, 0x8FC7, 0x7A0B, 0x3002) -join '')
            @("# v$($versionPlan.version)", '', '## English', '', "Verified automatic $ChangeClass iteration.", '', "## Chinese / $chineseHeading", '', $chineseBody) | Set-Content -LiteralPath $autoNotePath -Encoding UTF8
        }
        $selected = @($selected + 'VERSION' + $autoNote | Sort-Object -Unique)
        & (Join-Path $root 'skills\codex-git-operations\scripts\Update-ExperienceChangelog.ps1') -RepositoryRoot $root -Version $versionPlan.version -ChangedPaths $selected -ChangeClass $ChangeClass -Apply | Out-Null
        $selected = @($selected + 'CHANGELOG.md' | Sort-Object -Unique)
    }
    if (-not $SkipCompleteIteration) {
        $syncScript = Join-Path $root 'scripts\Sync-IterationDocumentation.ps1'
        & $syncScript -RepositoryRoot $root -ChangedPaths $selected -Apply | Out-Null
        $selected = @($selected + 'docs/ITERATION-STATUS.md' | Sort-Object -Unique)
    }
    $presentationVersion = (Get-Content -LiteralPath (Join-Path $root 'VERSION') -Raw -Encoding UTF8).Trim()
    $presentationAudit = & (Join-Path $root 'skills\codex-git-operations\scripts\New-GlobalReadmePresentationAudit.ps1') -RepositoryRoot $root -Version $presentationVersion -ChangedPaths $selected -Apply | ConvertFrom-Json
    if ($presentationAudit.required) {
        $selected = @($selected + $presentationAudit.generated_path | Sort-Object -Unique)
    }
}
$hasImplementation = @($selected | Where-Object { $_ -match '^(skills/|scripts/|config/|codex-provider-switch/|module-registry\.json$)' }).Count -gt 0
$hasDocs = @($selected | Where-Object { $_ -eq 'README.md' -or $_ -match '^(docs/|CHANGELOG\.md$)' }).Count -gt 0
$hasVersion = $selected -contains 'VERSION'
$hasReleaseNote = @($selected | Where-Object { $_ -match '^docs/release-notes/v.+\.md$' }).Count -gt 0
$classification = if ($hasImplementation) { 'minor' } elseif ($hasDocs) { 'patch' } else { 'none' }
$originUrl = (& git -C $root remote get-url origin).Trim()
if (-not $originUrl) { throw 'The private origin remote is missing.' }
$repoMatch = [regex]::Match($originUrl, 'github\.com[:/](?<repo>[^/]+/[^/.]+)')
$githubCommand = Join-Path $PSScriptRoot 'Invoke-GitHubNetworkCommand.ps1'
$privateConfirmed = $false
$privacyReason = 'GitHub CLI or GitHub remote identity is unavailable.'
if ($repoMatch.Success -and (Get-Command gh -ErrorAction SilentlyContinue)) {
    try { $privateConfirmed = ((& $githubCommand -RepositoryRoot $root -Tool gh repo view $repoMatch.Groups['repo'].Value --json isPrivate --jq .isPrivate 2>$null).Trim() -eq 'true'); $privacyReason = if ($privateConfirmed) { 'GitHub CLI confirmed origin is private.' } else { 'GitHub CLI did not confirm origin as private.' } } catch { $privacyReason = 'GitHub CLI could not verify origin visibility.' }
}
$metadataReady = ($selected -contains 'CHANGELOG.md') -and $hasDocs -and ((-not $hasImplementation) -or ($selected -contains 'docs/ITERATION-STATUS.md')) -and ((-not $hasVersion) -or $hasReleaseNote)
$eligible = $classification -ne 'none' -and $metadataReady -and $privateConfirmed
$plan = [ordered]@{ repository_root = $root; branch = (& git -C $root branch --show-current).Trim(); origin = $originUrl; selected_paths = $selected; classification = $classification; recommended_semver_bump = $classification; private_origin_confirmed = $privateConfirmed; privacy_reason = $privacyReason; metadata_ready = $metadataReady; eligible = $eligible; decision = if ($eligible) { 'eligible-for-private-commit' } else { 'needs-human-or-metadata-completion' } }
if (-not $Apply) { $plan | ConvertTo-Json -Depth 5; exit 0 }
if (-not $eligible) { throw ($plan | ConvertTo-Json -Depth 5) }
if (-not $Message) { $Message = "chore: verified $classification architecture update" }
& (Join-Path $root 'skills\codex-file-organization\scripts\Restore-GitTrackedWorkspaceLayout.ps1') -ProjectRoot $root | Out-Null
$pathspecFile = Join-Path ([IO.Path]::GetTempPath()) ("codex-git-pathspec-" + [guid]::NewGuid().ToString('N') + '.txt')
try {
    [IO.File]::WriteAllLines($pathspecFile, @($selected), [Text.UTF8Encoding]::new($false))
    & git -C $root add --pathspec-from-file=$pathspecFile
    if ($LASTEXITCODE -ne 0) { throw 'Git staging failed for the selected pathspec file.' }
}
finally {
    if (Test-Path -LiteralPath $pathspecFile) { Remove-Item -LiteralPath $pathspecFile -Force }
}
if (-not $SkipCompleteIteration) {
    & (Join-Path $root 'scripts\Invoke-CompleteGlobalExperienceIteration.ps1') -RepositoryRoot $root -Staged -Apply | Out-Null
}
& (Join-Path $root 'scripts\Test-ExperienceIterationGate.ps1') -RepositoryRoot $root -Staged -Apply | Out-Null
& (Join-Path $root 'scripts\Test-GitPublicationMetadata.ps1') -RepositoryRoot $root -Staged
if ($LASTEXITCODE -ne 0) { throw 'Publication metadata validation failed.' }
& git -C $root commit -m $Message
if ($LASTEXITCODE -ne 0) { throw 'Git commit failed.' }
$commit = (& git -C $root rev-parse HEAD).Trim()
if (-not $CommitOnly) {
    & $githubCommand -RepositoryRoot $root -Tool git -C $root push origin HEAD
}
& git -C $root config codex.route.repo-root $root
& git -C $root config codex.route.branch $plan.branch
& git -C $root config codex.last.commit $commit
& git -C $root config codex.last.version ((Get-Content -LiteralPath (Join-Path $root 'VERSION') -Raw).Trim())
& git -C $root config codex.last.recorded-at ([DateTime]::UtcNow.ToString('o'))
$plan['commit'] = $commit
$plan['decision'] = if ($CommitOnly) { 'committed-locally-no-push' } else { 'committed-and-pushed-private-origin' }
$plan | ConvertTo-Json -Depth 5
