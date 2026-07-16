[CmdletBinding()]
param(
  [Parameter(Mandatory=$true)][string]$Root,
  [Parameter(Mandatory=$true)][string]$BackupRoot,
  [string[]]$RelativePaths = @(),
  [switch]$Apply
)

$ErrorActionPreference = 'Stop'
$source = (Resolve-Path -LiteralPath $Root).Path.TrimEnd('\\')
$backup = [IO.Path]::GetFullPath($BackupRoot).TrimEnd('\\')
# Add the separator before comparison so a same-prefix sibling is not mistaken for a child.
if ($backup.Equals($source, [StringComparison]::OrdinalIgnoreCase) -or $backup.StartsWith($source + '\\', [StringComparison]::OrdinalIgnoreCase)) { throw 'BackupRoot must be outside the selected root.' }
$protected = '(^|\\)(\.git|\.codex|\.env[^\\]*|\.sandbox-secrets|private-skill-config)(\\|$)|(^|\\)(auth\.json)$'
$files = if ($RelativePaths.Count -gt 0) {
  @($RelativePaths | ForEach-Object {
    $candidate = Join-Path $source $_
    if (-not (Test-Path -LiteralPath $candidate -PathType Leaf)) { throw "Backup candidate is missing: $_" }
    Get-Item -LiteralPath $candidate
  })
} else { @(Get-ChildItem -LiteralPath $source -File -Recurse -Force | Where-Object { $_.FullName.Substring($source.Length).TrimStart('\\') -notmatch $protected }) }
$manifest = [ordered]@{
  schema_version = 1
  source = 'user-selected-root'
  file_count = $files.Count
  total_bytes = [long](($files | Measure-Object -Property Length -Sum).Sum)
  protected_paths_excluded = $true
  backup_root = if ($Apply) { 'user-selected-backup-root' } else { 'not-created' }
  apply_performed = [bool]$Apply
  created_at = [DateTime]::UtcNow.ToString('o')
}
if ($Apply) {
  New-Item -ItemType Directory -Force -Path $backup | Out-Null
  $reportedGitRoot = (& git -C $source rev-parse --show-toplevel 2>$null).Trim()
  $normalizedGitRoot = if ($reportedGitRoot) { [IO.Path]::GetFullPath(($reportedGitRoot -replace '/','\\')).TrimEnd('\\') } else { '' }
  $isGitRoot = $normalizedGitRoot.Equals($source, [StringComparison]::OrdinalIgnoreCase)
  if ($files.Count -gt 1000 -and $isGitRoot) {
    $bundle = Join-Path $backup ('file-organization-backup-' + (Get-Date -Format 'yyyyMMdd-HHmmss') + '.bundle')
    & git -C $source bundle create $bundle --all
    if ($LASTEXITCODE -ne 0) { throw 'Git bundle backup failed.' }
    $manifest.backup_type = 'git-bundle'
    $manifest.archive_sha256 = (Get-FileHash -LiteralPath $bundle -Algorithm SHA256).Hash.ToLowerInvariant()
    $manifest | ConvertTo-Json -Depth 4
    exit 0
  }
  $name = 'file-organization-backup-' + (Get-Date -Format 'yyyyMMdd-HHmmss') + '.zip'
  $archive = Join-Path $backup $name
  $staging = Join-Path $backup ('.staging-' + [guid]::NewGuid().ToString('N'))
  try {
    foreach ($file in $files) {
      $relative = $file.FullName.Substring($source.Length).TrimStart('\\')
      $copy = Join-Path $staging $relative
      New-Item -ItemType Directory -Force -Path (Split-Path -Parent $copy) | Out-Null
      Copy-Item -LiteralPath $file.FullName -Destination $copy -Force
    }
    Compress-Archive -Path (Join-Path $staging '*') -DestinationPath $archive -CompressionLevel Optimal
  } finally { if (Test-Path -LiteralPath $staging) { Remove-Item -LiteralPath $staging -Recurse -Force } }
  $manifest.archive_sha256 = (Get-FileHash -LiteralPath $archive -Algorithm SHA256).Hash.ToLowerInvariant()
}
$manifest | ConvertTo-Json -Depth 4
