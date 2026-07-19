[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$Path,
    [Parameter(Mandatory)]
    [string]$AllowedParent,
    [Parameter(Mandatory)]
    [string]$ExpectedLeaf,
    [switch]$Apply
)

$ErrorActionPreference = 'Stop'

$resolvedParent = (Resolve-Path -LiteralPath $AllowedParent -ErrorAction Stop).Path
$resolved = Resolve-Path -LiteralPath $Path -ErrorAction SilentlyContinue
if (-not $resolved) {
    [pscustomobject]@{
        result = 'not-found'
        path = $Path
    } | ConvertTo-Json
    exit 0
}

$target = $resolved.Path
$parent = [IO.Path]::GetFullPath($resolvedParent).TrimEnd('\')
$targetFull = [IO.Path]::GetFullPath($target).TrimEnd('\')
if (-not $targetFull.StartsWith($parent + '\', [StringComparison]::OrdinalIgnoreCase)) {
    throw "Refusing cleanup outside allowed parent: $targetFull"
}
if ((Split-Path -Leaf $targetFull) -ne $ExpectedLeaf) {
    throw "Refusing cleanup because leaf does not match '$ExpectedLeaf': $targetFull"
}

$fileCount = @(Get-ChildItem -LiteralPath $targetFull -Force -Recurse -File -ErrorAction SilentlyContinue).Count
$directoryCount = @(Get-ChildItem -LiteralPath $targetFull -Force -Recurse -Directory -ErrorAction SilentlyContinue).Count
$plan = [ordered]@{
    result = if ($Apply) { 'ready-to-clean' } else { 'preview' }
    target = $targetFull
    allowed_parent = $parent
    expected_leaf = $ExpectedLeaf
    file_count = $fileCount
    directory_count = $directoryCount
    apply = [bool]$Apply
}

if (-not $Apply) {
    $plan | ConvertTo-Json
    exit 0
}

Get-ChildItem -LiteralPath $targetFull -Force -Recurse -ErrorAction SilentlyContinue | ForEach-Object {
    try { $_.Attributes = [IO.FileAttributes]::Normal } catch {}
}
Remove-Item -LiteralPath $targetFull -Recurse -Force -ErrorAction Stop

$plan.result = if (Test-Path -LiteralPath $targetFull) { 'failed' } else { 'cleaned' }
$plan | ConvertTo-Json
