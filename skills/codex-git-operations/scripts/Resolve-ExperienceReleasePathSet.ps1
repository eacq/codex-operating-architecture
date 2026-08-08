[CmdletBinding()]
param(
    [string]$RepositoryRoot = (Get-Location).Path,
    [string[]]$Paths = @(),
    [string[]]$GeneratedPaths = @()
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath $RepositoryRoot).Path

function Normalize-RepoPath([string]$Path) {
    return ($Path -replace '\\','/').TrimStart('/')
}

$scope = @($Paths + $GeneratedPaths |
    Where-Object { $_ } |
    ForEach-Object { Normalize-RepoPath $_ } |
    Sort-Object -Unique)

$changed = @(
    & git -C $root diff --name-only
    & git -C $root diff --cached --name-only
    & git -C $root ls-files --others --exclude-standard
) | Where-Object { $_ } | ForEach-Object { Normalize-RepoPath $_ } | Sort-Object -Unique

$unselected = @($changed | Where-Object { $_ -notin $scope })
$commitPaths = @($changed | Where-Object { $_ -in $scope })

[ordered]@{
    all_paths = $scope
    all_changed = $changed
    unselected_paths = $unselected
    commit_paths = $commitPaths
    complete = $unselected.Count -eq 0
    has_commit_paths = $commitPaths.Count -gt 0
} | ConvertTo-Json -Depth 5
