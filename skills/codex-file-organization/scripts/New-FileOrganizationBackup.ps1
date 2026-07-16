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
# Add the separator before comparison: F:\codex-backup is a sibling, not a child of F:\codex.
if ($backup.Equals($source, [StringComparison]::OrdinalIgnoreCase) -or $backup.StartsWith($source + '\\', [StringComparison]::OrdinalIgnoreCase)) { throw 'BackupRoot must be outside the selected root.' }
$protected = '(^|\\)(\.git|\.codex|\.env[^\\]*|\.sandbox-secrets|private-skill-config)(\\|$)|(^|\\)(auth\.json)$'
$files = if ($RelativePaths.Count -gt 0) {
  @($RelativePaths | ForEach-Object {
    $candidate = Join-Path $source $_
    if (-not (Test-Path -LiteralPath $candidate -PathType Leaf)) { throw "Backup candidate is missing: $_" }
    Get-Item -LiteralPath $candidate
  })
} else { @(Get-ChildItem -LiteralPath $source -File -Recurse -Force | Where-Object { $_.FullName -notmatch $protected }) }
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
