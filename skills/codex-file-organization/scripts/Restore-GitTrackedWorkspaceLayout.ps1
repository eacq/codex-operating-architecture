[CmdletBinding()]
param([string]$ProjectRoot = (Get-Location).Path)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath $ProjectRoot).Path
$manifestPath = Join-Path $root '.codex\project\file-organization-move-manifest.json'
if (-not (Test-Path -LiteralPath $manifestPath)) {
  [pscustomobject]@{ restored=0; removed_relocated_copies=0; result='no-local-move-manifest' } | ConvertTo-Json
  exit 0
}
$manifest = Get-Content -LiteralPath $manifestPath -Raw -Encoding UTF8 | ConvertFrom-Json
$restored = 0; $removed = 0
$tracked = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
@(& git -C $root ls-files) | ForEach-Object { [void]$tracked.Add(([string]$_).Replace('/','\')) }
$restorePaths = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
foreach ($rewrite in @($manifest.rewrites)) {
  $relative = ([string]$rewrite.file).Substring($root.Length).TrimStart('\\')
  if ($tracked.Contains($relative)) { [void]$restorePaths.Add($relative) }
}
foreach ($move in @($manifest.moves)) {
  $source = [string]$move.source; $destination = [string]$move.proposed
  if ($tracked.Contains($source)) {
    [void]$restorePaths.Add($source)
    $destinationPath = Join-Path $root $destination
    if ((Test-Path -LiteralPath $destinationPath) -and -not $tracked.Contains($destination)) {
      [IO.File]::Delete($destinationPath)
      $removed++
    }
  } else {
    $sourcePath = Join-Path $root $source
    $destinationPath = Join-Path $root $destination
    if (Test-Path -LiteralPath $destinationPath -PathType Leaf) {
      [void][IO.Directory]::CreateDirectory((Split-Path -Parent $sourcePath))
      if (Test-Path -LiteralPath $sourcePath) { throw "Cannot restore untracked path because source already exists: $source" }
      [IO.File]::Move($destinationPath, $sourcePath)
      $restored++
    }
  }
}
$batch = @()
foreach ($path in $restorePaths) {
  $batch += $path
  if ($batch.Count -ge 100) { & git -C $root restore --source=HEAD --worktree -- $batch; if ($LASTEXITCODE -ne 0) { throw 'Batch Git layout restore failed.' }; $restored += $batch.Count; $batch=@() }
}
if ($batch.Count -gt 0) { & git -C $root restore --source=HEAD --worktree -- $batch; if ($LASTEXITCODE -ne 0) { throw 'Final Git layout restore failed.' }; $restored += $batch.Count }
foreach ($bucket in @('00-inbox','10-active','20-reference','30-output','40-archive','90-private-local')) {
  $bucketPath = Join-Path $root $bucket
  if (-not (Test-Path -LiteralPath $bucketPath)) { continue }
  Get-ChildItem -LiteralPath $bucketPath -Directory -Recurse -Force | Sort-Object FullName -Descending | ForEach-Object {
    if (@(Get-ChildItem -LiteralPath $_.FullName -Force).Count -eq 0) { [IO.Directory]::Delete($_.FullName) }
  }
}
[pscustomobject]@{ restored=$restored; removed_relocated_copies=$removed; result='git-tracked-layout-restored' } | ConvertTo-Json
