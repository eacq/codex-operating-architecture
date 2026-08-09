[CmdletBinding()]
param(
    [string]$RepositoryRoot = (Get-Location).Path,
    [string]$PrivateRepositoryName = '',
    [string]$PublicRepositoryName = '',
    [switch]$Apply
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath $RepositoryRoot).Path
if (-not $PrivateRepositoryName) {
    $originUrl = (& git -C $root remote get-url origin 2>$null).Trim()
    $originMatch = [regex]::Match($originUrl, 'github\.com[:/](?<name>[^/]+/[^/.]+)')
    if ($originMatch.Success) { $PrivateRepositoryName = $originMatch.Groups['name'].Value }
}
if (-not $PublicRepositoryName) {
    $publicUrl = (& git -C $root remote get-url public 2>$null).Trim()
    $publicMatch = [regex]::Match($publicUrl, 'github\.com[:/](?<name>[^/]+/[^/.]+)')
    if ($publicMatch.Success) { $PublicRepositoryName = $publicMatch.Groups['name'].Value }
}

$tracked = @(& git -C $root -c core.quotePath=false ls-files)
$changed = New-Object System.Collections.Generic.List[string]
foreach ($relative in $tracked) {
    if ($relative -match '(^|/)(\.git|\.codex|\.runtime)(/|$)') { continue }
    $path = Join-Path $root $relative
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { continue }
    $bytes = [IO.File]::ReadAllBytes($path)
    if ([Array]::IndexOf($bytes, [byte]0) -ge 0) { continue }
    $text = Get-Content -LiteralPath $path -Raw -Encoding UTF8
    $next = $text
    $privateHome = 'C:' + [IO.Path]::DirectorySeparatorChar + 'Users' + [IO.Path]::DirectorySeparatorChar + '12484'
    $privatePublic = 'C:' + [IO.Path]::DirectorySeparatorChar + 'Users' + [IO.Path]::DirectorySeparatorChar + 'Public'
    $privateHomeUrl = 'C:' + '/' + 'Users' + '/' + '12484'
    $next = $next -replace [regex]::Escape($privateHome), '%USERPROFILE%'
    $next = $next -replace [regex]::Escape($privatePublic), '%PUBLIC%'
    $next = $next -replace [regex]::Escape($privateHomeUrl), '%USERPROFILE%'
    if ($PrivateRepositoryName -and $PublicRepositoryName -and $PrivateRepositoryName -ne $PublicRepositoryName) {
        $next = $next.Replace($PrivateRepositoryName, $PublicRepositoryName)
    }
    if ($next -ne $text) {
        $changed.Add($relative) | Out-Null
        if ($Apply) { [IO.File]::WriteAllText($path, $next, [Text.UTF8Encoding]::new($false)) }
    }
}

[pscustomobject]@{
    result = if ($Apply) { 'public-release-snapshot-privacy-repaired' } else { 'public-release-snapshot-privacy-plan' }
    changed_paths = @($changed)
    changed_count = $changed.Count
} | ConvertTo-Json
