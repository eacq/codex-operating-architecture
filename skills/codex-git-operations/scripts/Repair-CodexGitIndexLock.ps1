[CmdletBinding()]
param(
    [string]$RepositoryRoot = (Get-Location).Path,
    [ValidateRange(1, 3600)][int]$MinimumAgeSeconds = 15,
    [switch]$DeterministicFixture,
    [switch]$Apply
)

$ErrorActionPreference = 'Stop'
$root = [IO.Path]::GetFullPath((Resolve-Path -LiteralPath $RepositoryRoot).Path).TrimEnd('\')
$gitRoot = [IO.Path]::GetFullPath(((& git -C $root rev-parse --show-toplevel).Trim() -replace '/', '\')).TrimEnd('\')
if ($gitRoot -ne $root) { throw "Repository root mismatch: expected '$root', got '$gitRoot'." }

$gitDirectory = Join-Path $root '.git'
if (-not (Test-Path -LiteralPath $gitDirectory -PathType Container)) {
    throw 'Git index-lock recovery supports only repositories with a local .git directory.'
}

$lockPath = Join-Path $gitDirectory 'index.lock'
if (-not (Test-Path -LiteralPath $lockPath -PathType Leaf)) {
    [pscustomobject]@{ result = 'no-lock'; repository_root = $root; lock_path = $lockPath; repaired = $false } | ConvertTo-Json
    return
}

$lock = Get-Item -LiteralPath $lockPath
$ageSeconds = [math]::Floor(((Get-Date) - $lock.LastWriteTime).TotalSeconds)
$architectureRoot = [IO.Path]::GetFullPath((Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path).TrimEnd('\')
$fixturePrefix = Join-Path $architectureRoot '.runtime\tmp\git-index-lock-recovery-'
if ($DeterministicFixture -and -not $root.StartsWith($fixturePrefix, [StringComparison]::OrdinalIgnoreCase)) {
    throw 'DeterministicFixture is restricted to the Git index-lock recovery test run root.'
}
$activeGit = if ($DeterministicFixture) { @() } else { @(Get-CimInstance Win32_Process -ErrorAction Stop | Where-Object { $_.Name -ieq 'git.exe' -or $_.Name -ieq 'git' }) }
$eligible = $lock.Length -eq 0 -and $ageSeconds -ge $MinimumAgeSeconds -and $activeGit.Count -eq 0
$result = [ordered]@{
    repository_root = $root
    lock_path = $lockPath
    lock_length = $lock.Length
    lock_age_seconds = $ageSeconds
    active_git_processes = $activeGit.Count
    eligible = $eligible
    repaired = $false
    result = if ($eligible) { 'stale-lock-eligible' } else { 'lock-retained' }
    retained_reason = if ($activeGit.Count -gt 0) { 'active-git-processes-present' } elseif ($lock.Length -ne 0) { 'lock-is-not-empty' } elseif ($ageSeconds -lt $MinimumAgeSeconds) { 'lock-is-too-recent' } else { '' }
}

if ($Apply -and $eligible) {
    [IO.File]::Delete($lockPath)
    if (Test-Path -LiteralPath $lockPath) { throw "Stale Git index lock could not be removed: $lockPath" }
    $result.repaired = $true
    $result.result = 'stale-lock-removed'
}

$result | ConvertTo-Json
