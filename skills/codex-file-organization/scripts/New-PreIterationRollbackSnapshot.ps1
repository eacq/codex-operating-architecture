[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)] [string]$ProjectRoot,
    [Parameter(Mandatory = $true)] [string]$BackupRoot,
    [switch]$Apply
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath $ProjectRoot).Path.TrimEnd('\')
$backup = [IO.Path]::GetFullPath($BackupRoot).TrimEnd('\')
if ($backup.Equals($root, [StringComparison]::OrdinalIgnoreCase) -or $backup.StartsWith($root + '\', [StringComparison]::OrdinalIgnoreCase)) { throw 'Rollback snapshot must be outside the project root.' }
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$snapshot = Join-Path $backup "pre-$stamp"
$payload = Join-Path $snapshot 'files'
$protected = '(^|/)(\.git|\.codex|\.runtime|\.validation-codex-home|\.sandbox-secrets|private-skill-config|node_modules|\.venv|venv|vendor)(/|$)|(^|/)(\.env($|\.)|auth\.json$|.*\.dpapi$)'
$snapshotExcludeDirs = @('.git', '.codex', '.runtime', '.validation-codex-home', '.sandbox-secrets', 'private-skill-config', 'node_modules', '.venv', 'venv', 'vendor')
$snapshotExcludeFiles = @('.env', '.env.*', 'auth.json', '*.dpapi')
function Normalize-GitPath([string]$Path) {
    return $Path.Trim('"').Replace('\', '/')
}
function Get-RelativePath([string]$Path) {
    return $Path.Substring($root.Length).TrimStart('\').Replace('\', '/')
}
function Get-Sha256Lower([string]$Path) {
    $stream = [IO.File]::Open($Path, [IO.FileMode]::Open, [IO.FileAccess]::Read, [IO.FileShare]::ReadWrite)
    try {
        $sha = [Security.Cryptography.SHA256]::Create()
        try {
            return [BitConverter]::ToString($sha.ComputeHash($stream)).Replace('-', '').ToLowerInvariant()
        } finally {
            $sha.Dispose()
        }
    } finally {
        $stream.Dispose()
    }
}
function Get-ReplaceableDirectories {
    $results = New-Object System.Collections.Generic.List[string]
    $stack = New-Object System.Collections.Generic.Stack[System.IO.DirectoryInfo]
    $stack.Push([System.IO.DirectoryInfo]::new($root))
    while ($stack.Count -gt 0) {
        $current = $stack.Pop()
        try {
            foreach ($directory in $current.EnumerateDirectories()) {
                $relative = Get-RelativePath $directory.FullName
                if ($relative -match $protected -or ($directory.Attributes -band [IO.FileAttributes]::ReparsePoint)) { continue }
                [void]$results.Add($relative)
                $stack.Push($directory)
            }
        } catch {
            continue
        }
    }
    return @($results.ToArray())
}
$relativeFilePaths = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
$usedGitFileInventory = $false
try {
    foreach ($path in @(& git -C $root -c core.quotePath=false ls-files --cached)) {
        if ($path) { [void]$relativeFilePaths.Add((Normalize-GitPath $path)) }
    }
    foreach ($path in @(& git -C $root -c core.quotePath=false ls-files --others --exclude-standard)) {
        if ($path) { [void]$relativeFilePaths.Add((Normalize-GitPath $path)) }
    }
    foreach ($path in @(& git -C $root -c core.quotePath=false ls-files --others --ignored --exclude-standard)) {
        if ($path) { [void]$relativeFilePaths.Add((Normalize-GitPath $path)) }
    }
    $usedGitFileInventory = $true
} catch {
    $relativeFilePaths.Clear()
}

if (-not $usedGitFileInventory) {
    $directoryStack = New-Object System.Collections.Generic.Stack[System.IO.DirectoryInfo]
    $directoryStack.Push([System.IO.DirectoryInfo]::new($root))
    while ($directoryStack.Count -gt 0) {
        $currentDirectory = $directoryStack.Pop()
        try {
            foreach ($file in $currentDirectory.EnumerateFiles()) {
                [void]$relativeFilePaths.Add((Get-RelativePath $file.FullName))
            }
            foreach ($directory in $currentDirectory.EnumerateDirectories()) {
                $relativeDirectory = Get-RelativePath $directory.FullName
                if ($relativeDirectory -match $protected -or ($directory.Attributes -band [IO.FileAttributes]::ReparsePoint)) { continue }
                $directoryStack.Push($directory)
            }
        } catch {
            continue
        }
    }
}

$files = @(
    foreach ($relative in $relativeFilePaths) {
        if (-not $relative -or $relative -match $protected) { continue }
        $fullPath = [IO.Path]::GetFullPath((Join-Path $root ($relative.Replace('/', '\'))))
        if (-not $fullPath.StartsWith($root + '\', [StringComparison]::OrdinalIgnoreCase)) { throw "Rollback snapshot candidate escaped project root: $relative" }
        if ([IO.File]::Exists($fullPath)) {
            [pscustomobject]@{ FullName = $fullPath; RelativePath = $relative }
        }
    }
)
$directories = @(Get-ReplaceableDirectories)

$record = [ordered]@{
    schema_version = 1
    snapshot_root = if ($Apply) { $snapshot } else { $null }
    file_count = $files.Count
    directory_count = $directories.Count
    protected_paths_excluded = $true
    file_inventory = if ($usedGitFileInventory) { 'git-tracked-untracked-ignored' } else { 'filesystem-fallback' }
    copy_engine = 'robocopy-filtered-tree'
    hash_engine = 'dotnet-sha256-stream'
    snapshot_name_policy = 'short-prefix'
    apply_performed = [bool]$Apply
    created_at = [DateTime]::UtcNow.ToString('o')
}
if (-not $Apply) { $record | ConvertTo-Json -Depth 4; exit 0 }

[IO.Directory]::CreateDirectory($payload) | Out-Null
& robocopy $root $payload /E /MT:8 /XD $snapshotExcludeDirs /XF $snapshotExcludeFiles | Out-Null
if ($LASTEXITCODE -gt 7) { throw "Rollback snapshot copy failed with robocopy exit code $LASTEXITCODE." }
$manifestFiles = New-Object System.Collections.Generic.List[object]
foreach ($file in $files) {
    $relative = $file.RelativePath
    $target = Join-Path $payload ($relative.Replace('/', '\'))
    if (-not (Test-Path -LiteralPath $target -PathType Leaf)) { throw "Rollback snapshot copy missed file: $relative" }
    $hash = Get-Sha256Lower $file.FullName
    if ((Get-Sha256Lower $target) -ne $hash) { throw "Rollback snapshot verification failed: $relative" }
    [void]$manifestFiles.Add([ordered]@{ relative_path = $relative; sha256 = $hash })
}
$manifestPath = Join-Path $snapshot 'manifest.json'
[ordered]@{
    schema_version = 1
    files = $manifestFiles.ToArray()
    directories = $directories
    protected_paths_excluded = $true
    hash_engine = $record.hash_engine
    created_at = $record.created_at
} | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $manifestPath -Encoding UTF8
Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'Restore-PreIterationRollbackSnapshot.ps1') -Destination (Join-Path $snapshot 'restore.ps1') -Force
$record['manifest'] = $manifestPath
$record | ConvertTo-Json -Depth 4
