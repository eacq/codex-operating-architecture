[CmdletBinding()]
param(
    [string]$RepositoryRoot = (Get-Location).Path,
    [ValidateSet('Inspect','Stage','Commit','PrivateRelease','PublicRelease')]
    [string]$Action = 'Inspect',
    [string[]]$Paths = @(),
    [string]$Message,
    [ValidateSet('Feature','Refinement')]
    [string]$ChangeClass = 'Feature',
    [switch]$CheckWhitespace,
    [switch]$Push,
    [switch]$ForceProxy,
    [switch]$Apply
)

$ErrorActionPreference = 'Stop'
$root = [IO.Path]::GetFullPath((Resolve-Path -LiteralPath $RepositoryRoot).Path).TrimEnd('\')
$gitRoot = [IO.Path]::GetFullPath(((& git -C $root rev-parse --show-toplevel).Trim() -replace '/', '\')).TrimEnd('\')
if ($gitRoot -ne $root) { throw "Repository root mismatch: expected '$root', got '$gitRoot'." }
if ($Push -and $Action -ne 'Commit') { throw 'Push is valid only for the Commit action.' }
if ($Action -ne 'Inspect' -and -not $Apply) { throw "$Action changes Git or remote state; rerun with -Apply after reviewing the plan." }
if ($Action -in @('Stage','Commit','PrivateRelease','PublicRelease') -and $Paths.Count -eq 0) { throw "$Action requires explicit -Paths so unrelated changes stay untouched." }

function Normalize-RepositoryPath([string]$Path) {
    $value = $Path.Trim().Trim('"').Replace('\','/').TrimStart('/')
    if (-not $value -or [IO.Path]::IsPathRooted($Path) -or $value -match '(^|/)\.\.(/|$)') { throw "Invalid repository-relative path: $Path" }
    return $value
}

function Get-ChangedPaths {
    $pathCollector = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..\scripts\Get-CodexGitChangedPaths.ps1')).Path
    return @(& $pathCollector -RepositoryRoot $root | ForEach-Object { Normalize-RepositoryPath $_ })
}

function Get-Checkpoint {
    $keys = @('codex.route.repo-root','codex.route.branch','codex.last.commit','codex.last.version','codex.last.recorded-at')
    $values = @{}
    foreach ($line in @(& git -C $root config --local --get-regexp '^codex\.(route|last)\.' 2>$null | Where-Object { $_ })) {
        $match = [regex]::Match([string]$line, '^(?<key>\S+)\s+(?<value>.*)$')
        if ($match.Success) { $values[$match.Groups['key'].Value] = $match.Groups['value'].Value.Trim() }
    }
    $checkpoint = [ordered]@{}
    foreach ($key in $keys) {
        $value = if ($values.ContainsKey($key)) { $values[$key] } else { '' }
        if ($value) { $checkpoint[$key] = $value }
    }
    return $checkpoint
}

function Get-RemoteSummary {
    $summary = @()
    foreach ($line in @(& git -C $root config --local --get-regexp '^remote\..*\.url$' 2>$null | Where-Object { $_ })) {
        $match = [regex]::Match([string]$line, '^remote\.(?<name>[^.]+)\.url\s+(?<url>.*)$')
        if (-not $match.Success) { continue }
        $remote = $match.Groups['name'].Value
        $url = $match.Groups['url'].Value.Trim()
        $safeUrl = $url -replace '://[^/@]+@', '://***@'
        $summary += [pscustomobject]@{ name = $remote; url = $safeUrl }
    }
    return $summary
}

$changed = @(Get-ChangedPaths)
$selected = @($Paths | ForEach-Object { Normalize-RepositoryPath $_ } | Sort-Object -Unique)
$branch = ([string](& git -C $root branch --show-current)).Trim()
$status = @(& git -C $root status --short --branch)
$diffCheck = 'not-run'
if ($CheckWhitespace) {
    & git -C $root diff --check
    $diffCheck = if ($LASTEXITCODE -eq 0) { 'passed' } else { 'failed' }
}
$basePlan = [ordered]@{
    repository_root = $root
    action = $Action
    branch = $branch
    status = $status
    changed_paths = $changed
    selected_paths = $selected
    remotes = @(Get-RemoteSummary)
    checkpoint = Get-Checkpoint
    diff_check = $diffCheck
    force_proxy = [bool]$ForceProxy
    apply_required = $Action -ne 'Inspect'
}

if ($Action -eq 'Inspect') {
    $basePlan.result = 'inspection-complete'
    $basePlan | ConvertTo-Json -Depth 6
    exit 0
}

$unknown = @($selected | Where-Object { $_ -notin $changed })
if ($unknown.Count -gt 0) { throw "Selected paths are not changed or untracked: $($unknown -join ', ')" }

if ($Action -eq 'Stage') {
    $indexLockRepair = Join-Path $PSScriptRoot 'Repair-CodexGitIndexLock.ps1'
    $indexLockResult = & $indexLockRepair -RepositoryRoot $root -Apply | ConvertFrom-Json
    if ($indexLockResult.result -eq 'lock-retained') {
        throw "Git staging is blocked by index lock: $($indexLockResult.retained_reason)."
    }
    $runRootResolver = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..\scripts\Resolve-CodexRunRoot.ps1')).Path
    $runRoot = & $runRootResolver -ArchitectureRoot $root -Kind tmp -Create
    $pathspec = Join-Path $runRoot ('codex-stage-' + [guid]::NewGuid().ToString('N') + '.txt')
    try {
        [IO.File]::WriteAllLines($pathspec, $selected, [Text.UTF8Encoding]::new($false))
        & git -C $root add --pathspec-from-file=$pathspec
        if ($LASTEXITCODE -ne 0) { throw 'Git staging failed.' }
    }
    finally {
        if (Test-Path -LiteralPath $pathspec) { Remove-Item -LiteralPath $pathspec -Force }
    }
    $basePlan.staged_paths = @(& git -C $root diff --cached --name-only | Where-Object { $_ } | Sort-Object -Unique)
    $basePlan.index_lock_recovery = $indexLockResult
    $basePlan.result = 'staged-selected-paths'
    $basePlan | ConvertTo-Json -Depth 6
    exit 0
}

if ($Action -eq 'Commit') {
    $commitScript = Join-Path $PSScriptRoot 'Invoke-VerifiedPrivateCommit.ps1'
    $arguments = @{ RepositoryRoot = $root; Paths = $selected; ChangeClass = $ChangeClass; Apply = $true }
    if ($Message) { $arguments.Message = $Message }
    if (-not $Push) { $arguments.CommitOnly = $true }
    if ($ForceProxy) { $arguments.ForceProxy = $true }
    $result = & $commitScript @arguments | ConvertFrom-Json
    $basePlan.controller_result = $result
    $basePlan.result = $result.decision
    $basePlan | ConvertTo-Json -Depth 8
    exit 0
}

$releaseScript = Join-Path $PSScriptRoot 'Invoke-ExperienceRelease.ps1'
$releaseMode = if ($Action -eq 'PrivateRelease') { 'Private' } else { 'Public' }
$releaseResult = & $releaseScript -RepositoryRoot $root -Mode $releaseMode -Paths $selected -ForceProxy:$ForceProxy -Apply | ConvertFrom-Json
$basePlan.controller_result = $releaseResult
$basePlan.result = $releaseResult.result
$basePlan | ConvertTo-Json -Depth 8
