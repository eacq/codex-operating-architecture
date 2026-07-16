[CmdletBinding()]
param(
  [string]$RepositoryRoot = (Get-Location).Path,
  [switch]$Apply,
  [switch]$Replace
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath $RepositoryRoot).Path.TrimEnd('\\')
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$sandbox = Join-Path $root ".codex\iterations\$stamp"
$backupRoot = Join-Path (Split-Path -Parent $root) ('.' + (Split-Path -Leaf $root) + '-codex-backups')
function Write-Step([string]$Name) { Write-Host "[$([DateTime]::Now.ToString('HH:mm:ss'))] $Name" }
if (-not $Apply) {
  [pscustomobject]@{ sandbox=$sandbox; replacement='blocked-until-Apply'; result='plan-only' } | ConvertTo-Json
  exit 0
}
# A local shared clone supplies the Git baseline without re-adding thousands of
# files. Overlay the current worktree so the isolated iteration also tests the
# uncommitted architecture repair being developed.
Write-Step 'clone sandbox'
& git -c core.autocrlf=false clone --shared --quiet $root $sandbox
if ($LASTEXITCODE -ne 0) { throw 'Sandbox shared clone failed.' }
& git -C $sandbox config core.autocrlf false
& robocopy $root $sandbox /E /XD .git .codex /XF auth.json *.dpapi | Out-Null
if ($LASTEXITCODE -gt 7) { throw "Sandbox copy failed with robocopy exit code $LASTEXITCODE." }
Copy-Item -LiteralPath (Join-Path $root '.codex\project') -Destination (Join-Path $sandbox '.codex\project') -Recurse -Force
& git -C $sandbox add -- .
& git -C $sandbox -c user.name='Codex Iteration Sandbox' -c user.email='iteration@local.invalid' commit --allow-empty -m 'sandbox current-worktree baseline' | Out-Null
Write-Step 'backup sandbox baseline'
& (Join-Path $sandbox 'skills\codex-file-organization\scripts\New-FileOrganizationBackup.ps1') -Root $sandbox -BackupRoot $backupRoot -Apply | Out-Null
$externalRestoreRunner = Join-Path $backupRoot "restore-git-layout-$stamp.ps1"
Copy-Item -LiteralPath (Join-Path $sandbox 'skills\codex-file-organization\scripts\Restore-GitTrackedWorkspaceLayout.ps1') -Destination $externalRestoreRunner -Force
Write-Step 'organize sandbox'
& (Join-Path $sandbox 'skills\codex-file-organization\scripts\Invoke-FileOrganizationLifecycle.ps1') -ProjectRoot $sandbox -Phase global-iteration -Apply | Out-Null
Write-Step 'restore Git layout'
& $externalRestoreRunner -ProjectRoot $sandbox | Out-Null
Remove-Item -LiteralPath $externalRestoreRunner -Force
Write-Step 'validate sandbox'
& (Join-Path $sandbox 'scripts\validate.ps1') | Out-Host
if ($LASTEXITCODE -ne 0) { throw 'Sandbox global validation failed; current system is unchanged.' }
$validationHome = Join-Path $sandbox '.validation-codex-home'
Write-Step 'validate sandbox global interfaces'
& (Join-Path $sandbox 'scripts\install-global.ps1') -CodexHome $validationHome -Mode Junction | Out-Null
& (Join-Path $sandbox 'scripts\validate-global-install.ps1') -CodexHome $validationHome | Out-Host
if ($LASTEXITCODE -ne 0) { throw 'Sandbox global interface validation failed; current system is unchanged.' }
if ($Replace) {
  & git -C $root bundle create (Join-Path $backupRoot "pre-replace-$stamp.bundle") --all
  if ($LASTEXITCODE -ne 0) { throw 'Pre-replacement Git bundle failed.' }
  & robocopy $sandbox $root /E /XD .git .codex .validation-codex-home /XF auth.json *.dpapi | Out-Null
  if ($LASTEXITCODE -gt 7) { throw "Replacement copy failed with robocopy exit code $LASTEXITCODE." }
}
$result = [ordered]@{
  schema_version = 1
  sandbox = $sandbox
  validated = $true
  replaced = [bool]$Replace
  result = 'completed'
  completed_at = [DateTime]::UtcNow.ToString('o')
}
$proofPath = Join-Path $root '.codex\project\isolated-global-iteration.json'
$result | ConvertTo-Json | Set-Content -LiteralPath $proofPath -Encoding UTF8
$result | ConvertTo-Json
