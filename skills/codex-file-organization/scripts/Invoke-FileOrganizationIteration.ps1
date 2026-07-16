[CmdletBinding()]
param(
  [string]$ProjectRoot = (Get-Location).Path,
  [ValidateSet('global-iteration','project-initialization','ongoing-work')][string]$Phase = 'ongoing-work',
  [switch]$Apply
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath $ProjectRoot).Path.TrimEnd('\\')
$project = Join-Path $root '.codex\project'
$policyPath = Join-Path $project 'file-organization.json'
if (-not (Test-Path -LiteralPath $policyPath)) { throw 'File-organization policy is missing.' }
$policy = Get-Content -LiteralPath $policyPath -Raw -Encoding UTF8 | ConvertFrom-Json
$plan = & (Join-Path $PSScriptRoot 'New-FileOrganizationPlan.ps1') -Root $root | ConvertFrom-Json
$moves = @($plan.items | Where-Object { $_.source -ne $_.proposed })
$textExtensions = @('.md','.txt','.json','.yaml','.yml','.toml','.ps1','.py','.js','.ts','.cmd','.bat','.xml')
$referenceFiles = @(Get-ChildItem -LiteralPath $root -File -Recurse -Force | Where-Object { $_.FullName -notmatch '(^|\\)(\.git|\.codex|\.env[^\\]*|private-skill-config)(\\|$)' -and $textExtensions -contains $_.Extension.ToLowerInvariant() })
$rewrites = @()
foreach ($move in $moves) {
  foreach ($candidate in $referenceFiles) {
    $text = Get-Content -LiteralPath $candidate.FullName -Raw -Encoding UTF8
    if ($text.Contains([string]$move.source)) { $rewrites += [pscustomobject]@{ file=$candidate.FullName; old=[string]$move.source; new=[string]$move.proposed } }
  }
}
$backupRoot = if ($policy.backup_root) { [string]$policy.backup_root } else { Join-Path (Split-Path -Parent $root) ('.' + (Split-Path -Leaf $root) + '-codex-backups') }
$record = [ordered]@{ schema_version=2; phase=$Phase; managed_root='00-inbox'; planned_moves=$moves.Count; reference_updates=$rewrites.Count; backup='not-needed'; moved=0; result='passed'; completed_at=[DateTime]::UtcNow.ToString('o') }
if ($Apply -and $moves.Count -gt 0) {
  $backupInputs = @($moves.source + @($rewrites | ForEach-Object { $_.file.Substring($root.Length).TrimStart('\\') }) | Sort-Object -Unique)
  $backup = & (Join-Path $PSScriptRoot 'New-FileOrganizationBackup.ps1') -Root $root -BackupRoot $backupRoot -RelativePaths $backupInputs -Apply | ConvertFrom-Json
  if (-not $backup.archive_sha256) { throw 'Required pre-move backup was not created.' }
  foreach ($rewrite in $rewrites) {
    $content = Get-Content -LiteralPath $rewrite.file -Raw -Encoding UTF8
    Set-Content -LiteralPath $rewrite.file -Value $content.Replace($rewrite.old, $rewrite.new) -Encoding UTF8
  }
  foreach ($move in $moves) {
    $destination = Join-Path $root $move.proposed
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $destination) | Out-Null
    if (Test-Path -LiteralPath $destination) { throw "Destination collision: $($move.proposed)" }
    Move-Item -LiteralPath (Join-Path $root $move.source) -Destination $destination
  }
  foreach ($rewrite in $rewrites) {
    if ((Get-Content -LiteralPath $rewrite.file -Raw -Encoding UTF8).Contains($rewrite.old)) { throw "Stale reference remains after rewrite: $($rewrite.file)" }
  }
  foreach ($command in @($policy.validation_commands)) { Invoke-Expression $command; if ($LASTEXITCODE -ne 0) { throw "Configured validation failed: $command" } }
  $record.backup='created'; $record.backup_sha256=$backup.archive_sha256; $record.moved=$moves.Count
}
if ($Apply) { New-Item -ItemType Directory -Force -Path $project | Out-Null; $record | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $project 'file-organization-iteration.json') -Encoding UTF8 }
$record | ConvertTo-Json -Depth 5
