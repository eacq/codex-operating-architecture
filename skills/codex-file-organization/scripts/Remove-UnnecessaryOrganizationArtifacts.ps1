[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)] [string]$ProjectRoot,
    [Parameter(Mandatory = $true)] [string]$BackupRoot,
    [string]$TrackedPathsFile = '',
    [switch]$Apply
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath $ProjectRoot).Path.TrimEnd('\')
$backup = [IO.Path]::GetFullPath($BackupRoot).TrimEnd('\')
if ($backup.Equals($root, [StringComparison]::OrdinalIgnoreCase) -or $backup.StartsWith($root + '\', [StringComparison]::OrdinalIgnoreCase)) {
    throw 'Cleanup quarantine must be outside the selected root.'
}

function Get-RelativePath([string]$Path) {
    return $Path.Substring($root.Length).TrimStart('\').Replace('\', '/')
}

$tracked = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
$trackedLines = if ($TrackedPathsFile) {
    if (-not (Test-Path -LiteralPath $TrackedPathsFile)) { throw 'Tracked-path authority file is missing.' }
    Get-Content -LiteralPath $TrackedPathsFile -Encoding UTF8
} else {
    @(& git -C $root ls-files)
}
foreach ($path in $trackedLines) { if ($path) { [void]$tracked.Add($path.Replace('\', '/')) } }

$protected = '(^|/)(\.git|\.codex|\.runtime|node_modules|\.venv|venv|vendor|\.env[^/]*|\.sandbox-secrets|private-skill-config)(/|$)|(^|/)(auth\.json|.*\.dpapi)$'
$cachePath = '(^|/)(__pycache__|\.pytest_cache|\.mypy_cache|\.ruff_cache|\.tox|\.nox)(/|$)'
$disposableName = '^(\.DS_Store|Thumbs\.db)$|\.(pyc|pyo|tmp|temp|bak|orig|rej)$|~$'
$candidates = @(
    Get-ChildItem -LiteralPath $root -Recurse -Force -File -ErrorAction SilentlyContinue | Where-Object {
        $relative = Get-RelativePath $_.FullName
        $relative -notmatch $protected -and
        -not $tracked.Contains($relative) -and
        ($relative -match $cachePath -or $_.Name -match $disposableName)
    }
)

$preview = [ordered]@{
    schema_version = 1
    candidate_files = $candidates.Count
    tracked_files_protected = $tracked.Count
    protected_roots_excluded = $true
    quarantine_created = $false
    files_deleted = 0
    empty_directories_deleted = 0
    detail_manifest = $null
    result = if ($Apply) { 'pending' } else { 'preview' }
}
if (-not $Apply) { $preview | ConvertTo-Json -Depth 4; exit 0 }

$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$quarantine = Join-Path $backup "cleanup-quarantine-$stamp"
$deleted = @()
foreach ($file in $candidates) {
    $relative = Get-RelativePath $file.FullName
    $hash = (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash.ToLowerInvariant()
    $target = Join-Path $quarantine ($relative.Replace('/', '\'))
    [IO.Directory]::CreateDirectory((Split-Path -Parent $target)) | Out-Null
    Copy-Item -LiteralPath $file.FullName -Destination $target -Force
    if ((Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash.ToLowerInvariant() -ne $hash) { throw "Cleanup quarantine verification failed: $relative" }
    [IO.File]::Delete($file.FullName)
    $deleted += [ordered]@{ relative_path = $relative; sha256 = $hash }
}

$removedDirectories = @()
$directories = @(Get-ChildItem -LiteralPath $root -Recurse -Force -Directory -ErrorAction SilentlyContinue | Sort-Object { $_.FullName.Length } -Descending)
foreach ($directory in $directories) {
    $relative = Get-RelativePath $directory.FullName
    if ($relative -match $protected -or ($directory.Attributes -band [IO.FileAttributes]::ReparsePoint)) { continue }
    if (@(Get-ChildItem -LiteralPath $directory.FullName -Force -ErrorAction SilentlyContinue).Count -eq 0) {
        [IO.Directory]::Delete($directory.FullName, $false)
        $removedDirectories += $relative
    }
}

if ($deleted.Count -gt 0 -or $removedDirectories.Count -gt 0) {
    [IO.Directory]::CreateDirectory($quarantine) | Out-Null
    $manifestPath = Join-Path $quarantine 'manifest.json'
    [ordered]@{
        schema_version = 1
        source = 'isolated-iteration-copy'
        deleted_files = $deleted
        removed_empty_directories = $removedDirectories
        created_at = [DateTime]::UtcNow.ToString('o')
    } | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $manifestPath -Encoding UTF8
    $preview.detail_manifest = $manifestPath
    $preview.quarantine_created = $true
}
$preview.files_deleted = $deleted.Count
$preview.empty_directories_deleted = $removedDirectories.Count
$preview.result = 'completed'
$preview | ConvertTo-Json -Depth 4
