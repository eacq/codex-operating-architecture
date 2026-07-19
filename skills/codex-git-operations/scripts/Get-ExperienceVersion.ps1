[CmdletBinding()]
param(
    [ValidateSet('Initialize', 'AutoFeature', 'AutoFix', 'PrivateRelease', 'PublicRelease')]
    [string]$Action = 'Initialize',
    [string]$PublicRepository = '',
    [string]$PrivateRepository = '',
    [string]$RepositoryRoot = (Get-Location).Path,
    [string]$CurrentVersion = '',
    [string[]]$PublicReleaseRows = @(),
    [string[]]$PrivateReleaseRows = @(),
    [switch]$UseProvidedReleaseRows
)

$ErrorActionPreference = 'Stop'
$githubCommand = Join-Path $PSScriptRoot 'Invoke-GitHubNetworkCommand.ps1'
function Get-RepoFromRemote([string]$Remote) {
    $url = (& git -C $RepositoryRoot remote get-url $Remote 2>$null).Trim()
    $match = [regex]::Match($url, 'github\.com[:/](?<name>[^/]+/[^/.]+)')
    if (-not $match.Success) { throw "Cannot derive GitHub repository from local '$Remote' remote." }
    return $match.Groups['name'].Value
}
if (-not $PublicRepository) { $PublicRepository = Get-RepoFromRemote 'public' }
if (-not $PrivateRepository) { $PrivateRepository = Get-RepoFromRemote 'origin' }
function Get-ReleaseParts([string]$Repository, [string[]]$ProvidedRows, [bool]$UseProvidedRows) {
    $rows = if ($UseProvidedRows -or $ProvidedRows.Count -gt 0) { @($ProvidedRows) } else { @(& $githubCommand -RepositoryRoot $RepositoryRoot -Tool gh release list --repo $Repository --limit 100 2>$null) }
    $parts = @()
    foreach ($row in $rows) {
        if ($row -match '\bv(?<first>\d+)\.(?<second>\d+)\b') { $parts += [pscustomobject]@{ First = [int]$Matches.first; Second = [int]$Matches.second } }
    }
    return @($parts | Sort-Object First, Second -Descending)
}
$public = @(Get-ReleaseParts $PublicRepository $PublicReleaseRows $UseProvidedReleaseRows)
$privateReleases = @(Get-ReleaseParts $PrivateRepository $PrivateReleaseRows $UseProvidedReleaseRows)
$publicFirst = if ($public.Count -gt 0) { $public[0].First } else { 1 }
$privateSecond = if ($privateReleases.Count -gt 0 -and $privateReleases[0].First -eq $publicFirst) { $privateReleases[0].Second } else { 0 }
if (-not $CurrentVersion) { $CurrentVersion = "$publicFirst.$privateSecond.0.0" }
if ($CurrentVersion -notmatch '^(?<first>\d+)\.(?<second>\d+)\.(?<third>\d+)\.(?<fourth>\d+)$') { throw "Current version must be four-part: $CurrentVersion" }
$current = [pscustomobject]@{ First = [int]$Matches.first; Second = [int]$Matches.second; Third = [int]$Matches.third; Fourth = [int]$Matches.fourth }
switch ($Action) {
    'Initialize' { $next = [pscustomobject]@{ First = $publicFirst; Second = $privateSecond; Third = 0; Fourth = 0 } }
    'AutoFeature' { $next = [pscustomobject]@{ First = $publicFirst; Second = $privateSecond; Third = $current.Third + 1; Fourth = 0 } }
    'AutoFix' { $next = [pscustomobject]@{ First = $publicFirst; Second = $privateSecond; Third = $current.Third; Fourth = $current.Fourth + 1 } }
    'PrivateRelease' { $next = [pscustomobject]@{ First = $publicFirst; Second = if ($privateReleases.Count -eq 0) { 0 } else { $privateSecond + 1 }; Third = 0; Fourth = 0 } }
    'PublicRelease' { $next = [pscustomobject]@{ First = $publicFirst + 1; Second = 0; Third = 0; Fourth = 0 } }
}
[ordered]@{
    action = $Action
    public_release_component = $publicFirst
    private_release_component = $privateSecond
    auto_feature_component = $next.Third
    auto_fix_component = $next.Fourth
    version = "$($next.First).$($next.Second).$($next.Third).$($next.Fourth)"
    release_tag = "v$($next.First).$($next.Second)"
} | ConvertTo-Json
