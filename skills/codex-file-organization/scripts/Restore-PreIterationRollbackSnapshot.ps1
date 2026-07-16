[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)] [string]$ProjectRoot,
    [Parameter(Mandatory = $true)] [string]$SnapshotRoot,
    [switch]$Apply
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath $ProjectRoot).Path.TrimEnd('\')
$snapshot = (Resolve-Path -LiteralPath $SnapshotRoot).Path.TrimEnd('\')
$payload = Join-Path $snapshot 'files'
$manifest = Get-Content -LiteralPath (Join-Path $snapshot 'manifest.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$protected = '(^|/)(\.git|\.codex|\.runtime|\.validation-codex-home)(/|$)|(^|/)(\.env($|\.)|auth\.json$|.*\.dpapi$)'
$expectedFiles = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
foreach ($item in @($manifest.files)) { [void]$expectedFiles.Add([string]$item.relative_path) }
$expectedDirectories = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
foreach ($item in @($manifest.directories)) { [void]$expectedDirectories.Add([string]$item) }
$currentFiles = @(Get-ChildItem -LiteralPath $root -Recurse -Force -File -ErrorAction SilentlyContinue | Where-Object {
    $_.FullName.Substring($root.Length).TrimStart('\').Replace('\', '/') -notmatch $protected
})
$extraFiles = @($currentFiles | Where-Object { -not $expectedFiles.Contains($_.FullName.Substring($root.Length).TrimStart('\').Replace('\', '/')) })
$record = [ordered]@{ schema_version = 1; files_restored = @($manifest.files).Count; extra_files_removed = $extraFiles.Count; hash_verified = $false; apply_performed = [bool]$Apply; result = if ($Apply) { 'pending' } else { 'preview' } }
if (-not $Apply) { $record | ConvertTo-Json -Depth 4; exit 0 }

foreach ($file in $extraFiles) { [IO.File]::Delete($file.FullName) }
foreach ($item in @($manifest.files)) {
    $relative = [string]$item.relative_path
    $source = Join-Path $payload ($relative.Replace('/', '\'))
    $target = [IO.Path]::GetFullPath((Join-Path $root ($relative.Replace('/', '\'))))
    if (-not $target.StartsWith($root + '\', [StringComparison]::OrdinalIgnoreCase)) { throw 'Rollback manifest escaped the project root.' }
    [IO.Directory]::CreateDirectory((Split-Path -Parent $target)) | Out-Null
    Copy-Item -LiteralPath $source -Destination $target -Force
    if ((Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash.ToLowerInvariant() -ne $item.sha256) { throw "Rollback hash verification failed: $relative" }
}
$currentDirectories = @(Get-ChildItem -LiteralPath $root -Recurse -Force -Directory -ErrorAction SilentlyContinue | Sort-Object { $_.FullName.Length } -Descending)
foreach ($directory in $currentDirectories) {
    $relative = $directory.FullName.Substring($root.Length).TrimStart('\').Replace('\', '/')
    if ($relative -match $protected -or ($directory.Attributes -band [IO.FileAttributes]::ReparsePoint) -or $expectedDirectories.Contains($relative)) { continue }
    if (@(Get-ChildItem -LiteralPath $directory.FullName -Force -ErrorAction SilentlyContinue).Count -eq 0) { [IO.Directory]::Delete($directory.FullName, $false) }
}
$record.hash_verified = $true
$record.result = 'rolled-back'
$record | ConvertTo-Json -Depth 4
