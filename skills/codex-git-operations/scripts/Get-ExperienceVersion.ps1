[CmdletBinding()]
param(
    [ValidateSet('Initialize', 'AutoFeature', 'AutoFix', 'PrivateRelease', 'PublicRelease')]
    [string]$Action = 'Initialize',
    [string]$PublicRepository = '',
    [string]$PrivateRepository = '',
    [string]$RepositoryRoot = (Get-Location).Path,
    [string]$CurrentVersion = ''
)

$ErrorActionPreference = 'Stop'
function Get-RepoFromRemote([string]$Remote) {
    $url = (& git -C $RepositoryRoot remote get-url $Remote 2>$null).Trim()
    $match = [regex]::Match($url, 'github\.com[:/](?<name>[^/]+/[^/.]+)')
    if (-not $match.Success) { throw "Cannot derive GitHub repository from local '$Remote' remote." }
    return $match.Groups['name'].Value
}
if (-not $PublicRepository) { $PublicRepository = Get-RepoFromRemote 'public' }
if (-not $PrivateRepository) { $PrivateRepository = Get-RepoFromRemote 'origin' }
function Get-ReleaseParts([string]$Repository) {
    $rows = @(& gh release list --repo $Repository --limit 100 2>$null)
    $parts = @()
    foreach ($row in $rows) {
        if ($row -match '\bv(?<first>\d+)\.(?<second>\d+)\b') { $parts += [pscustomobject]@{ First = [int]$Matches.first; Second = [int]$Matches.second } }
    }
    return @($parts | Sort-Object First, Second -Descending)
}
$public = Get-ReleaseParts $PublicRepository
$private = Get-ReleaseParts $PrivateRepository
$publicFirst = if ($public.Count -gt 0) { $public[0].First } else { 1 }
$privateSecond = if ($private.Count -gt 0 -and $private[0].First -eq $publicFirst) { $private[0].Second } else { 0 }
if (-not $CurrentVersion) { $CurrentVersion = "$publicFirst.$privateSecond.0.0" }
if ($CurrentVersion -notmatch '^(?<first>\d+)\.(?<second>\d+)\.(?<third>\d+)\.(?<fourth>\d+)$') { throw "Current version must be four-part: $CurrentVersion" }
$current = [pscustomobject]@{ First = [int]$Matches.first; Second = [int]$Matches.second; Third = [int]$Matches.third; Fourth = [int]$Matches.fourth }
switch ($Action) {
    'Initialize' { $next = [pscustomobject]@{ First = $publicFirst; Second = $privateSecond; Third = 0; Fourth = 0 } }
    'AutoFeature' { $next = [pscustomobject]@{ First = $publicFirst; Second = $privateSecond; Third = $current.Third + 1; Fourth = 0 } }
    'AutoFix' { $next = [pscustomobject]@{ First = $publicFirst; Second = $privateSecond; Third = $current.Third; Fourth = $current.Fourth + 1 } }
    'PrivateRelease' { $next = [pscustomobject]@{ First = $publicFirst; Second = if ($private.Count -eq 0) { 0 } else { $privateSecond + 1 }; Third = 0; Fourth = 0 } }
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
