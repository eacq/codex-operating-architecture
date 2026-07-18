[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)] [string]$ProjectRoot,
    [Parameter(Mandatory = $true)] [string]$BackupRoot,
    [string]$TrackedPathsFile = '',
    [switch]$LightweightDirectoryCleanup,
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
function Normalize-GitPath([string]$Path) {
    return $Path.Trim('"').Replace('\', '/')
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
$candidateRelativePaths = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
$usedGitCandidateScan = $false
try {
    foreach ($path in @(& git -C $root -c core.quotePath=false ls-files --others --exclude-standard)) {
        if ($path) { [void]$candidateRelativePaths.Add((Normalize-GitPath $path)) }
    }
    foreach ($path in @(& git -C $root -c core.quotePath=false ls-files --others --ignored --exclude-standard)) {
        if ($path) { [void]$candidateRelativePaths.Add((Normalize-GitPath $path)) }
    }
    $usedGitCandidateScan = $true
} catch {
    $candidateRelativePaths.Clear()
}

if (-not $usedGitCandidateScan) {
    Get-ChildItem -LiteralPath $root -Recurse -Force -File -ErrorAction SilentlyContinue | ForEach-Object {
        [void]$candidateRelativePaths.Add((Get-RelativePath $_.FullName))
    }
}

$candidates = @(
    foreach ($relative in $candidateRelativePaths) {
        if (-not $relative -or $relative -match $protected -or $tracked.Contains($relative)) { continue }
        $fullPath = [IO.Path]::GetFullPath((Join-Path $root ($relative.Replace('/', '\'))))
        if (-not $fullPath.StartsWith($root + '\', [StringComparison]::OrdinalIgnoreCase)) { throw "Cleanup candidate escaped project root: $relative" }
        if (-not [IO.File]::Exists($fullPath)) { continue }
        $file = Get-Item -LiteralPath $fullPath -Force
        if ($relative -match $cachePath -or $file.Name -match $disposableName) { $file }
    }
)

$preview = [ordered]@{
    schema_version = 1
    candidate_files = $candidates.Count
    tracked_files_protected = $tracked.Count
    protected_roots_excluded = $true
    candidate_scan = if ($usedGitCandidateScan) { 'git-untracked-and-ignored' } else { 'filesystem-fallback' }
    empty_directory_scan = if ($LightweightDirectoryCleanup) { 'candidate-parents-only' } else { 'full-non-protected-tree' }
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
    if (-not [IO.File]::Exists($file.FullName)) { continue }
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
$directoryCandidates = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
if ($LightweightDirectoryCleanup) {
    foreach ($entry in $deleted) {
        $parent = Split-Path -Parent ([string]$entry.relative_path)
        while ($parent) {
            [void]$directoryCandidates.Add($parent.Replace('\', '/'))
            $parent = Split-Path -Parent $parent
        }
    }
} else {
    foreach ($directory in @(Get-ChildItem -LiteralPath $root -Recurse -Force -Directory -ErrorAction SilentlyContinue)) {
        [void]$directoryCandidates.Add((Get-RelativePath $directory.FullName))
    }
}
$directories = @(
    foreach ($relativeDirectory in $directoryCandidates) {
        if (-not $relativeDirectory) { continue }
        $fullDirectory = [IO.Path]::GetFullPath((Join-Path $root ($relativeDirectory.Replace('/', '\'))))
        if (-not $fullDirectory.StartsWith($root + '\', [StringComparison]::OrdinalIgnoreCase)) { throw "Cleanup directory escaped project root: $relativeDirectory" }
        if (Test-Path -LiteralPath $fullDirectory -PathType Container) { Get-Item -LiteralPath $fullDirectory -Force }
    }
) | Sort-Object { $_.FullName.Length } -Descending
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
