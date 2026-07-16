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
$managedRoots = @($policy.managed_roots | Where-Object { $_ })
if ($managedRoots.Count -eq 0) { $managedRoots = @('00-inbox') }
$plan = & (Join-Path $PSScriptRoot 'New-FileOrganizationPlan.ps1') -Root $root -ManagedRoots $managedRoots | ConvertFrom-Json
$moves = @($plan.items | Where-Object { $_.source -ne $_.proposed })
$rewrites = @()
# ripgrep builds one fixed-string automaton for every source path. JSON output
# preserves both the matching file and exact matched spelling without an O(N*M)
# PowerShell comparison loop.
$replacementByOld = @{}
foreach ($move in $moves) {
  $old = [string]$move.source; $new = [string]$move.proposed
  $replacementByOld[$old] = $new
  $replacementByOld[$old.Replace('\','/')] = $new.Replace('\','/')
}
$patternFile = Join-Path $project 'file-organization-reference-patterns.txt'
New-Item -ItemType Directory -Force -Path $project | Out-Null
$patterns = @($replacementByOld.Keys | Where-Object { $_ } | Sort-Object -Unique)
[IO.File]::WriteAllLines($patternFile, $patterns, [Text.UTF8Encoding]::new($false))
$rgOutput = @(& rg --json --fixed-strings --file $patternFile --hidden --glob '!/.git/**' --glob '!/.codex/**' --glob '*.md' --glob '*.txt' --glob '*.json' --glob '*.yaml' --glob '*.yml' --glob '*.toml' --glob '*.ps1' --glob '*.py' --glob '*.js' --glob '*.ts' --glob '*.cmd' --glob '*.bat' --glob '*.xml' $root)
if ($LASTEXITCODE -gt 1) { throw "Reference index failed with rg exit code $LASTEXITCODE." }
$seenRewrite = @{}
foreach ($line in $rgOutput) {
  $event = $line | ConvertFrom-Json
  if ($event.type -ne 'match') { continue }
  $reportedPath = [string]$event.data.path.text
  $file = if ([IO.Path]::IsPathRooted($reportedPath)) { $reportedPath } else { Join-Path $root $reportedPath }
  foreach ($submatch in @($event.data.submatches)) {
    $old = [string]$submatch.match.text
    if (-not $replacementByOld.ContainsKey($old)) { continue }
    $key = "$file`0$old"
    if (-not $seenRewrite.ContainsKey($key)) {
      $rewrites += [pscustomobject]@{ file=$file; old=$old; new=$replacementByOld[$old] }
      $seenRewrite[$key] = $true
    }
  }
}
$backupRoot = if ($policy.backup_root) { [string]$policy.backup_root } else { Join-Path (Split-Path -Parent $root) ('.' + (Split-Path -Leaf $root) + '-codex-backups') }
$record = [ordered]@{ schema_version=3; phase=$Phase; managed_roots=$managedRoots; planned_moves=$moves.Count; reference_updates=$rewrites.Count; backup='not-needed'; moved=0; result='passed'; completed_at=[DateTime]::UtcNow.ToString('o') }
if ($Apply -and $moves.Count -gt 0) {
  $duplicateDestinations = @($moves | Group-Object proposed | Where-Object { $_.Count -gt 1 })
  if ($duplicateDestinations.Count -gt 0) { throw 'Organization plan has destination collisions; refine the taxonomy before any backup or move.' }
  foreach ($move in $moves) {
    if (Test-Path -LiteralPath (Join-Path $root $move.proposed)) { throw "Organization destination already exists: $($move.proposed)" }
  }
  $rewriteInputs = @($rewrites | Where-Object { $_ -and $_.file } | ForEach-Object {
    ([string]$_.file).Substring($root.Length).TrimStart('\\')
  })
  $backupInputs = @(@($moves | ForEach-Object { [string]$_.source }) + $rewriteInputs | Sort-Object -Unique)
  $backup = & (Join-Path $PSScriptRoot 'New-FileOrganizationBackup.ps1') -Root $root -BackupRoot $backupRoot -RelativePaths $backupInputs -Apply | ConvertFrom-Json
  if (-not $backup.archive_sha256) { throw 'Required pre-move backup was not created.' }
  foreach ($rewrite in $rewrites) {
    $content = Get-Content -LiteralPath $rewrite.file -Raw -Encoding UTF8
    Set-Content -LiteralPath $rewrite.file -Value $content.Replace($rewrite.old, $rewrite.new) -Encoding UTF8
  }
  $createdDirectories = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
  foreach ($move in $moves) {
    $destination = Join-Path $root $move.proposed
    $destinationDirectory = Split-Path -Parent $destination
    if ($createdDirectories.Add($destinationDirectory)) { [void][IO.Directory]::CreateDirectory($destinationDirectory) }
    if (Test-Path -LiteralPath $destination) { throw "Destination collision: $($move.proposed)" }
    [IO.File]::Move((Join-Path $root $move.source), $destination)
  }
  $moveBySource = @{}; foreach ($move in $moves) { $moveBySource[[string]$move.source] = [string]$move.proposed }
  foreach ($rewrite in $rewrites) {
    $relative = ([string]$rewrite.file).Substring($root.Length).TrimStart('\\')
    $verificationFile = if (Test-Path -LiteralPath $rewrite.file) { [string]$rewrite.file } elseif ($moveBySource.ContainsKey($relative)) { Join-Path $root $moveBySource[$relative] } else { throw "Rewritten file is missing after move: $relative" }
    $verifiedContent = Get-Content -LiteralPath $verificationFile -Raw -Encoding UTF8
    $withoutNewReferences = $verifiedContent.Replace([string]$rewrite.new, '')
    if ($withoutNewReferences.Contains([string]$rewrite.old)) { throw "Stale reference remains after rewrite: $relative" }
  }
  foreach ($command in @($policy.validation_commands | Where-Object { $_ })) { Invoke-Expression ([string]$command); if ($LASTEXITCODE -ne 0) { throw "Configured validation failed: $command" } }
  $record.backup='created'; $record.backup_sha256=$backup.archive_sha256; $record.moved=$moves.Count
  # This local-only manifest lets the Git boundary restore tracked paths without
  # exposing names or path references in a repository artifact.
  [ordered]@{ schema_version=1; moves=@($moves); rewrites=@($rewrites); created_at=[DateTime]::UtcNow.ToString('o') } |
    ConvertTo-Json -Depth 6 | Set-Content -LiteralPath (Join-Path $project 'file-organization-move-manifest.json') -Encoding UTF8
}
if ($Apply) { New-Item -ItemType Directory -Force -Path $project | Out-Null; $record | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $project 'file-organization-iteration.json') -Encoding UTF8 }
$record | ConvertTo-Json -Depth 5
