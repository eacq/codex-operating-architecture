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

$tracked = @(& git -C $root ls-files)
$changed = New-Object System.Collections.Generic.List[string]
foreach ($relative in $tracked) {
    if ($relative -match '(^|/)(\.git|\.codex|\.runtime)(/|$)') { continue }
    $path = Join-Path $root $relative
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { continue }
    $bytes = [IO.File]::ReadAllBytes($path)
    if ([Array]::IndexOf($bytes, [byte]0) -ge 0) { continue }
    $text = Get-Content -LiteralPath $path -Raw -Encoding UTF8
    $next = $text
    $next = $next -replace 'C:\\Users\\12484', '%USERPROFILE%'
    $next = $next -replace 'C:\\Users\\Public', '%PUBLIC%'
    $next = $next -replace 'C:/Users/12484', '%USERPROFILE%'
    if ($PrivateRepositoryName -and $PublicRepositoryName -and $PrivateRepositoryName -ne $PublicRepositoryName) {
        $next = $next.Replace($PrivateRepositoryName, $PublicRepositoryName)
    }
    if ($next -ne $text) {
        $changed.Add($relative) | Out-Null
        if ($Apply) { Set-Content -LiteralPath $path -Value $next -Encoding UTF8 -NoNewline }
    }
}

[pscustomobject]@{
    result = if ($Apply) { 'public-release-snapshot-privacy-repaired' } else { 'public-release-snapshot-privacy-plan' }
    changed_paths = @($changed)
    changed_count = $changed.Count
} | ConvertTo-Json
