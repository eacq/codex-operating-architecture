[CmdletBinding()]
param(
    [string]$RepositoryRoot = (Get-Location).Path,
    [switch]$Staged
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath $RepositoryRoot).Path
$arguments = if ($Staged) { @('diff', '--cached', '--name-only') } else { @('diff', '--name-only') }
$changed = @(& git -C $root @arguments | Where-Object { $_ })
if ($changed.Count -eq 0) { throw 'No changed paths available for publication metadata validation.' }
$gate = Join-Path $root '.codex\project\git-iteration-gate.json'
if (-not (Test-Path -LiteralPath $gate)) { throw 'Complete Test-ExperienceIterationGate.ps1 before any Git commit or update.' }
$globalIteration = Join-Path $root '.codex\project\global-experience-iteration.json'
if (-not (Test-Path -LiteralPath $globalIteration)) { throw 'Complete Invoke-CompleteGlobalExperienceIteration.ps1 before any Git commit or update.' }
$expectedHash = ((Get-Content $gate -Raw -Encoding UTF8 | ConvertFrom-Json).staged_paths_sha256)
$sha = [Security.Cryptography.SHA256]::Create()
$actualHash = ([BitConverter]::ToString($sha.ComputeHash([Text.Encoding]::UTF8.GetBytes(($changed | Sort-Object) -join "`n"))) -replace '-','').ToLowerInvariant()
$sha.Dispose()
if ($expectedHash -ne $actualHash) { throw 'Git changes differ from the completed experience-iteration gate; rerun it before Git.' }
$globalRecord = Get-Content -LiteralPath $globalIteration -Raw -Encoding UTF8 | ConvertFrom-Json
if ($globalRecord.result -ne 'passed' -or $globalRecord.head_at_start -ne ((& git -C $root rev-parse HEAD).Trim()) -or $globalRecord.staged_paths_sha256 -ne $actualHash) {
    throw 'Git changes are not covered by a current completed global experience iteration.'
}

if ($changed -notcontains 'CHANGELOG.md') {
    throw 'Update CHANGELOG.md for every non-merge commit before push.'
}

$publicWorkflowChange = $changed | Where-Object {
    $_ -match '^(skills/|scripts/|config/|codex-provider-switch/|VERSION$|README\.md$)'
}
$descriptionChange = $changed | Where-Object { $_ -eq 'README.md' -or $_ -like 'docs/*' }
if ($publicWorkflowChange -and -not $descriptionChange) {
    throw 'Public workflow changes require README.md or a matching docs/ description update.'
}
if ($publicWorkflowChange -and -not (Test-Path -LiteralPath (Join-Path $root 'docs/ITERATION-STATUS.md'))) {
    throw 'Implementation changes require generated iteration-status documentation.'
}

$chineseCounterpart = ([char]0x4E2D).ToString() + ([char]0x6587).ToString() + ([char]0x5BF9).ToString() + ([char]0x7167).ToString()
$chineseDescription = ([char]0x4E2D).ToString() + ([char]0x6587).ToString() + ([char]0x8BF4).ToString() + ([char]0x660E).ToString()
$chinese = ([char]0x4E2D).ToString() + ([char]0x6587).ToString()
$githubDocs = @($changed | Where-Object { $_ -eq 'README.md' -or $_ -like 'docs/*.md' })
$deleted = @(& git -C $root diff --cached --diff-filter=D --name-only | Where-Object { $_ })
$githubDocs = @($githubDocs | Where-Object { $_ -notin $deleted })
foreach ($path in $githubDocs) {
    if ($path -eq 'README.md') {
        if ($changed -notcontains 'README.en.md') { throw 'A changed Chinese README requires the staged English counterpart README.en.md.' }
        continue
    }
    $content = (& git -C $root show ":$path") -join "`n"
    if (-not $content.Contains($chineseCounterpart) -and -not $content.Contains($chineseDescription) -and -not $content.Contains($chinese)) {
        throw "GitHub-facing document requires an in-file Chinese counterpart: $path"
    }
}

if ($changed -contains 'VERSION') {
    $version = (Get-Content -LiteralPath (Join-Path $root 'VERSION') -Raw -Encoding UTF8).Trim()
    $releaseNote = "docs/release-notes/v$version.md"
    if ($changed -notcontains $releaseNote) {
        throw "Version change requires staged release note: $releaseNote"
    }
}

Write-Output "Git publication metadata and bilingual GitHub documentation validated for $($changed.Count) changed paths."
