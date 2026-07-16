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
function Test-Tracked([string]$Path) { & git -C $root ls-files --error-unmatch -- $Path 2>$null | Out-Null; return $LASTEXITCODE -eq 0 }
foreach ($rewrite in @($manifest.rewrites)) {
  $relative = ([string]$rewrite.file).Substring($root.Length).TrimStart('\\')
  if (Test-Tracked $relative) { & git -C $root restore --source=HEAD --worktree -- $relative; $restored++ }
}
foreach ($move in @($manifest.moves)) {
  $source = [string]$move.source; $destination = [string]$move.proposed
  if (Test-Tracked $source) {
    & git -C $root restore --source=HEAD --worktree -- $source
    $restored++
    $destinationPath = Join-Path $root $destination
    if ((Test-Path -LiteralPath $destinationPath) -and -not (Test-Tracked $destination)) {
      Remove-Item -LiteralPath $destinationPath -Force
      $removed++
    }
  }
}
[pscustomobject]@{ restored=$restored; removed_relocated_copies=$removed; result='git-tracked-layout-restored' } | ConvertTo-Json
