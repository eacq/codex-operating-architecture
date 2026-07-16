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
$snapshot = Join-Path $backup "pre-iteration-snapshot-$stamp"
$payload = Join-Path $snapshot 'files'
$protected = '(^|/)(\.git|\.codex|\.runtime|\.validation-codex-home)(/|$)|(^|/)(\.env($|\.)|auth\.json$|.*\.dpapi$)'
$files = @(Get-ChildItem -LiteralPath $root -Recurse -Force -File -ErrorAction SilentlyContinue | Where-Object {
    $_.FullName.Substring($root.Length).TrimStart('\').Replace('\', '/') -notmatch $protected
})
$directories = @(Get-ChildItem -LiteralPath $root -Recurse -Force -Directory -ErrorAction SilentlyContinue | Where-Object {
    $relative = $_.FullName.Substring($root.Length).TrimStart('\').Replace('\', '/')
    $relative -notmatch $protected -and -not ($_.Attributes -band [IO.FileAttributes]::ReparsePoint)
} | ForEach-Object { $_.FullName.Substring($root.Length).TrimStart('\').Replace('\', '/') })

$record = [ordered]@{
    schema_version = 1
    snapshot_root = if ($Apply) { $snapshot } else { $null }
    file_count = $files.Count
    directory_count = $directories.Count
    protected_paths_excluded = $true
    apply_performed = [bool]$Apply
    created_at = [DateTime]::UtcNow.ToString('o')
}
if (-not $Apply) { $record | ConvertTo-Json -Depth 4; exit 0 }

[IO.Directory]::CreateDirectory($payload) | Out-Null
$manifestFiles = @()
foreach ($file in $files) {
    $relative = $file.FullName.Substring($root.Length).TrimStart('\').Replace('\', '/')
    $target = Join-Path $payload ($relative.Replace('/', '\'))
    [IO.Directory]::CreateDirectory((Split-Path -Parent $target)) | Out-Null
    Copy-Item -LiteralPath $file.FullName -Destination $target -Force
    $hash = (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash.ToLowerInvariant()
    if ((Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash.ToLowerInvariant() -ne $hash) { throw "Rollback snapshot verification failed: $relative" }
    $manifestFiles += [ordered]@{ relative_path = $relative; sha256 = $hash }
}
$manifestPath = Join-Path $snapshot 'manifest.json'
[ordered]@{
    schema_version = 1
    files = $manifestFiles
    directories = $directories
    protected_paths_excluded = $true
    created_at = $record.created_at
} | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $manifestPath -Encoding UTF8
Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'Restore-PreIterationRollbackSnapshot.ps1') -Destination (Join-Path $snapshot 'restore.ps1') -Force
$record['manifest'] = $manifestPath
$record | ConvertTo-Json -Depth 4
