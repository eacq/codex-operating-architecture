[CmdletBinding()]
param(
  [string]$RepositoryRoot = (Get-Location).Path,
  [switch]$Apply,
  [switch]$Replace,
  [switch]$ContinuousDiagnosis,
  [string]$RepairScript = '',
  [ValidateRange(0, 1000)][int]$MaxRepairAttempts = 0,
  [switch]$InjectPostReplacementFailureForTest
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath $RepositoryRoot).Path.TrimEnd('\\')
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$sandbox = Join-Path $root ".codex\iterations\$stamp"
$backupRoot = Join-Path (Split-Path -Parent $root) ('.' + (Split-Path -Leaf $root) + '-codex-backups')
$statePath = Join-Path $root '.codex\project\state.json'
function Write-Step([string]$Name) { Write-Host "[$([DateTime]::Now.ToString('HH:mm:ss'))] $Name" }
$stepTimings = New-Object System.Collections.Generic.List[object]
function Invoke-Step {
  param(
    [Parameter(Mandatory = $true)][string]$Name,
    [Parameter(Mandatory = $true)][scriptblock]$Script
  )
  Write-Step $Name
  $started = [DateTime]::UtcNow
  try {
    & $Script
  } finally {
    $ended = [DateTime]::UtcNow
    [void]$stepTimings.Add([pscustomobject]@{
      name = $Name
      started_at = $started.ToString('o')
      ended_at = $ended.ToString('o')
      duration_seconds = [math]::Round(($ended - $started).TotalSeconds, 3)
    })
  }
}
function Normalize-GitPath([string]$Path) {
  return $Path.Trim('"').Replace('\', '/')
}
function Test-ProtectedOverlayPath([string]$RelativePath) {
  return ($RelativePath -match '(^|/)(\.git|\.codex|\.runtime|\.validation-codex-home|\.sandbox-secrets|private-skill-config)(/|$)|(^|/)(auth\.json|.*\.dpapi|\.env($|\.))')
}
function Copy-ChangedPathOverlay {
  param(
    [Parameter(Mandatory = $true)][string]$SourceRoot,
    [Parameter(Mandatory = $true)][string]$TargetRoot
  )
  $collector = Join-Path $SourceRoot 'scripts\Get-CodexGitChangedPaths.ps1'
  if (-not (Test-Path -LiteralPath $collector)) { throw 'Shared Git changed-path collector is missing from the source root.' }
  $paths = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
  foreach ($path in @(& $collector -RepositoryRoot $SourceRoot)) {
    if ($path) { [void]$paths.Add((Normalize-GitPath $path)) }
  }
  $copied = 0
  $removed = 0
  foreach ($relative in $paths) {
    if (-not $relative -or (Test-ProtectedOverlayPath $relative)) { continue }
    $source = [IO.Path]::GetFullPath((Join-Path $SourceRoot ($relative.Replace('/', '\'))))
    $target = [IO.Path]::GetFullPath((Join-Path $TargetRoot ($relative.Replace('/', '\'))))
    if (-not $source.StartsWith($SourceRoot + '\', [StringComparison]::OrdinalIgnoreCase) -or -not $target.StartsWith($TargetRoot + '\', [StringComparison]::OrdinalIgnoreCase)) { throw "Sandbox overlay path escaped root: $relative" }
    if ([IO.File]::Exists($source)) {
      [IO.Directory]::CreateDirectory((Split-Path -Parent $target)) | Out-Null
      Copy-Item -LiteralPath $source -Destination $target -Force
      $copied += 1
    } elseif ([IO.File]::Exists($target)) {
      [IO.File]::Delete($target)
      $removed += 1
    } elseif ([IO.Directory]::Exists($target) -and -not [IO.Directory]::Exists($source)) {
      Remove-Item -LiteralPath $target -Recurse -Force
      $removed += 1
    }
  }
  return [pscustomobject]@{ changed_paths = $paths.Count; copied = $copied; removed = $removed }
}
if ($ContinuousDiagnosis) {
  & (Join-Path $root 'scripts\Invoke-ContinuousIterationDiagnosis.ps1') -RepositoryRoot $root -Target global-iteration -RepairScript $RepairScript -MaxRepairAttempts $MaxRepairAttempts -Apply:$Apply
  if (-not $?) { exit 1 }
  exit 0
}
if (-not $Apply) {
  [pscustomobject]@{ sandbox=$sandbox; replacement='blocked-until-Apply'; result='plan-only' } | ConvertTo-Json
  exit 0
}
$rollbackSnapshot = $null
$replacementStarted = $false
try {
if ($Replace -and (Test-Path -LiteralPath $statePath)) {
  $state = Get-Content -LiteralPath $statePath -Raw -Encoding UTF8 | ConvertFrom-Json
  $state.pending_sync = $true
  $state.updated_at = [DateTime]::Now.ToString('o')
  $state | Add-Member -NotePropertyName active_iteration -NotePropertyValue $stamp -Force
  $state | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $statePath -Encoding UTF8
}
# A local shared clone supplies the Git baseline without re-adding thousands of
# files. Keep the repository's checkout conversion policy so active replacement
# does not create line-ending-only Git status noise on Windows. Overlay the
# current worktree so the isolated iteration also tests the uncommitted
# architecture repair being developed.
Invoke-Step 'clone sandbox' {
  & git clone --shared --quiet $root $sandbox
  if ($LASTEXITCODE -ne 0) { throw 'Sandbox shared clone failed.' }
  $originUrl = (& git -C $root remote get-url origin 2>$null).Trim()
  if ($originUrl) { & git -C $sandbox remote set-url origin $originUrl }
  $publicUrl = (& git -C $root remote get-url public 2>$null).Trim()
  if ($publicUrl) { & git -C $sandbox remote add public $publicUrl }
  $script:sandboxOverlay = Copy-ChangedPathOverlay -SourceRoot $root -TargetRoot $sandbox
  Copy-Item -LiteralPath (Join-Path $root '.codex\project') -Destination (Join-Path $sandbox '.codex\project') -Recurse -Force
  $script:trackedAuthority = Join-Path $sandbox '.codex\project\isolation-source-tracked.txt'
  & git -C $root ls-files | Set-Content -LiteralPath $trackedAuthority -Encoding UTF8
  & git -C $sandbox add -- .
  & git -C $sandbox -c user.name='Codex Iteration Sandbox' -c user.email='iteration@local.invalid' commit --allow-empty -m 'sandbox current-worktree baseline' | Out-Null
}
Invoke-Step 'backup sandbox baseline' {
  & (Join-Path $sandbox 'skills\codex-file-organization\scripts\New-FileOrganizationBackup.ps1') -Root $sandbox -BackupRoot $backupRoot -Apply | Out-Null
  $script:externalRestoreRunner = Join-Path $backupRoot "restore-git-layout-$stamp.ps1"
  Copy-Item -LiteralPath (Join-Path $sandbox 'skills\codex-file-organization\scripts\Restore-GitTrackedWorkspaceLayout.ps1') -Destination $externalRestoreRunner -Force
}
Invoke-Step 'organize sandbox' {
  & (Join-Path $sandbox 'skills\codex-file-organization\scripts\Invoke-FileOrganizationLifecycle.ps1') -ProjectRoot $sandbox -Phase global-iteration -Apply | Out-Null
}
Invoke-Step 'restore Git layout' {
  & $externalRestoreRunner -ProjectRoot $sandbox | Out-Null
  Remove-Item -LiteralPath $externalRestoreRunner -Force
}
Invoke-Step 'validate sandbox' {
  & (Join-Path $sandbox 'scripts\validate.ps1') | Out-Host
  if ($LASTEXITCODE -ne 0) { throw 'Sandbox global validation failed; current system is unchanged.' }
}
$validationHome = Join-Path $sandbox '.validation-codex-home'
Invoke-Step 'validate sandbox global interfaces' {
  & (Join-Path $sandbox 'scripts\install-global.ps1') -CodexHome $validationHome -Mode Junction | Out-Null
  & (Join-Path $sandbox 'scripts\validate-global-install.ps1') -CodexHome $validationHome | Out-Host
  if ($LASTEXITCODE -ne 0) { throw 'Sandbox global interface validation failed; current system is unchanged.' }
}
Invoke-Step 'quarantine and delete unnecessary sandbox artifacts' {
  $script:cleanup = & (Join-Path $sandbox 'skills\codex-file-organization\scripts\Remove-UnnecessaryOrganizationArtifacts.ps1') -ProjectRoot $sandbox -BackupRoot $backupRoot -TrackedPathsFile $trackedAuthority -Apply | ConvertFrom-Json
  if ($cleanup.result -ne 'completed') { throw 'Isolated cleanup did not complete.' }
}
$activeCleanupBefore = $null
$activeCleanupAfter = $null
if ($Replace) {
  Invoke-Step 'create exact pre-iteration rollback snapshot' {
    $script:rollbackSnapshot = & (Join-Path $root 'skills\codex-file-organization\scripts\New-PreIterationRollbackSnapshot.ps1') -ProjectRoot $root -BackupRoot $backupRoot -Apply | ConvertFrom-Json
    if (-not $rollbackSnapshot.snapshot_root -or -not $rollbackSnapshot.manifest) { throw 'Pre-iteration rollback snapshot is incomplete.' }
    & git -C $root bundle create (Join-Path $backupRoot "pre-replace-$stamp.bundle") --all
    if ($LASTEXITCODE -ne 0) { throw 'Pre-replacement Git bundle failed.' }
  }
  $replacementStarted = $true
  Invoke-Step 'replace active tree' {
    & robocopy $sandbox $root /E /XD .git .codex .runtime .validation-codex-home /XF auth.json *.dpapi | Out-Null
    if ($LASTEXITCODE -gt 7) { throw "Replacement copy failed with robocopy exit code $LASTEXITCODE." }
  }
  if ($InjectPostReplacementFailureForTest) { throw 'Injected post-replacement failure for rollback verification.' }
  Invoke-Step 'quarantine and delete unnecessary active artifacts' {
    $script:activeCleanupBefore = & (Join-Path $root 'skills\codex-file-organization\scripts\Remove-UnnecessaryOrganizationArtifacts.ps1') -ProjectRoot $root -BackupRoot $backupRoot -LightweightDirectoryCleanup -Apply | ConvertFrom-Json
    if ($activeCleanupBefore.result -ne 'completed') { throw 'Pre-validation active cleanup did not complete.' }
  }
  Invoke-Step 'validate replaced global system pass 1' {
    & (Join-Path $root 'scripts\validate.ps1') | Out-Host
    if (-not $?) { throw 'First post-replacement global validation failed.' }
  }
  Invoke-Step 'validate replaced global system pass 2' {
    & (Join-Path $root 'scripts\validate.ps1') | Out-Host
    if (-not $?) { throw 'Second post-replacement global validation failed.' }
  }
  Invoke-Step 'remove validation-regenerated disposable artifacts' {
    $script:activeCleanupAfter = & (Join-Path $root 'skills\codex-file-organization\scripts\Remove-UnnecessaryOrganizationArtifacts.ps1') -ProjectRoot $root -BackupRoot $backupRoot -LightweightDirectoryCleanup -Apply | ConvertFrom-Json
    if ($activeCleanupAfter.result -ne 'completed') { throw 'Post-validation active cleanup did not complete.' }
  }
  Invoke-Step 'refresh and validate real global interfaces' {
    & (Join-Path $root 'scripts\install-global.ps1') -Mode Junction | Out-Host
    if (-not $?) { throw 'Post-replacement global interface refresh failed.' }
    & (Join-Path $root 'scripts\validate-global-install.ps1') | Out-Host
    if (-not $?) { throw 'Post-replacement global interface validation failed.' }
  }
}
$result = [ordered]@{
  schema_version = 1
  sandbox = $sandbox
  validated = $true
  replaced = [bool]$Replace
  post_replacement_validated = [bool]$Replace
  lifecycle_written_back = [bool]$Replace
  rollback_ready = [bool]($Replace -and $rollbackSnapshot)
  continuous_diagnosis_supported = (Test-Path -LiteralPath (Join-Path $root 'scripts\Invoke-ContinuousIterationDiagnosis.ps1'))
  cleanup = $null
  result = 'completed'
  step_timings = @($stepTimings.ToArray())
  completed_at = [DateTime]::UtcNow.ToString('o')
}
$activeFilesDeleted = 0
$regeneratedFilesDeleted = 0
$activeEmptyDirectoriesDeleted = 0
$regeneratedEmptyDirectoriesDeleted = 0
if ($activeCleanupBefore) {
  $activeFilesDeleted = [int]$activeCleanupBefore.files_deleted
  $activeEmptyDirectoriesDeleted = [int]$activeCleanupBefore.empty_directories_deleted
}
if ($activeCleanupAfter) {
  $regeneratedFilesDeleted = [int]$activeCleanupAfter.files_deleted
  $regeneratedEmptyDirectoriesDeleted = [int]$activeCleanupAfter.empty_directories_deleted
}
$result.cleanup = [ordered]@{
  sandbox_files_deleted = [int]$cleanup.files_deleted
  active_files_deleted = $activeFilesDeleted
  regenerated_files_deleted = $regeneratedFilesDeleted
  empty_directories_deleted = $activeEmptyDirectoriesDeleted + $regeneratedEmptyDirectoriesDeleted
  quarantine_created = [bool]($cleanup.quarantine_created -or ($activeCleanupBefore -and $activeCleanupBefore.quarantine_created) -or ($activeCleanupAfter -and $activeCleanupAfter.quarantine_created))
}
$proofPath = Join-Path $root '.codex\project\isolated-global-iteration.json'
$result | ConvertTo-Json | Set-Content -LiteralPath $proofPath -Encoding UTF8
if ($Replace) {
  [ordered]@{
    schema_version = 2
    phase = 'post-replacement-global-iteration'
    cleanup = $result.cleanup
    replacement = [ordered]@{ validated = $true; applied = $true }
    rollback = [ordered]@{ ready = $result.rollback_ready; failure_policy = 'restore-continuous-diagnosis-rerun-or-critical-error' }
    diagnostics = [ordered]@{ continuous_mode = $result.continuous_diagnosis_supported; targets = @('file-organization','global-iteration') }
    validation = [ordered]@{ repository_runs = 2; global_interfaces = 'passed' }
    step_timings = $result.step_timings
    lifecycle_writeback = 'completed'
    result = 'passed'
    completed_at = $result.completed_at
  } | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath (Join-Path $root '.codex\project\file-organization-review.json') -Encoding UTF8
  if (Test-Path -LiteralPath $statePath) {
    $state = Get-Content -LiteralPath $statePath -Raw -Encoding UTF8 | ConvertFrom-Json
    $state.updated_at = [DateTime]::Now.ToString('o')
    $state.last_observed_head = (& git -C $root rev-parse HEAD).Trim()
    $state.last_completed_iteration = 'transactional-cleanup-post-replacement-validation'
    $state.pending_sync = $false
    $state | Add-Member -NotePropertyName last_iteration_status -NotePropertyValue 'completed' -Force
    $state.PSObject.Properties.Remove('active_iteration')
    $state | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $statePath -Encoding UTF8
  }
  $candidateReport = & (Join-Path $root 'skills\codex-experience-capture\scripts\New-GlobalIterationCandidateReport.ps1') -ProjectRoot $root -Apply | ConvertFrom-Json
  if ($candidateReport.result -ne 'generated') { throw 'Global iteration candidate report generation failed.' }
  $result | Add-Member -NotePropertyName candidate_report -NotePropertyValue $candidateReport.output -Force
  $result | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $proofPath -Encoding UTF8
}
$result | ConvertTo-Json
} catch {
  $iterationFailure = $_.Exception.Message
  $rollbackResult = 'not-required-before-replacement'
  $rollbackVerified = $false
  $rollbackFailure = $null
  if ($Replace -and $replacementStarted -and $rollbackSnapshot) {
    try {
      Write-Step 'rollback failed iteration to exact pre-iteration snapshot'
      $rollback = & (Join-Path $rollbackSnapshot.snapshot_root 'restore.ps1') -ProjectRoot $root -SnapshotRoot $rollbackSnapshot.snapshot_root -Apply | ConvertFrom-Json
      if ($rollback.result -ne 'rolled-back' -or -not $rollback.hash_verified) { throw 'Rollback executor did not verify the restored snapshot.' }
      & (Join-Path $root 'scripts\install-global.ps1') -Mode Junction | Out-Host
      if (-not $?) { throw 'Global interface refresh failed after rollback.' }
      & (Join-Path $root 'scripts\validate-global-install.ps1') | Out-Host
      if (-not $?) { throw 'Global interface validation failed after rollback.' }
      $rollbackResult = 'rolled-back-to-pre-iteration-snapshot'
      $rollbackVerified = $true
    } catch {
      $rollbackResult = 'rollback-failed'
      $rollbackFailure = $_.Exception.Message
    }
  }
  [ordered]@{
    schema_version = 1
    iteration = $stamp
    failure = $iterationFailure
    replacement_started = $replacementStarted
    rollback_result = $rollbackResult
    rollback_verified = $rollbackVerified
    rollback_failure = $rollbackFailure
    next_action = if ($rollbackResult -eq 'rollback-failed') { 'stop-and-report-critical-error' } else { 'enter-continuous-diagnosis-repair-owner-and-rerun-complete-probe' }
    failed_at = [DateTime]::UtcNow.ToString('o')
  } | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $root '.codex\project\last-iteration-failure.json') -Encoding UTF8
  if (Test-Path -LiteralPath $statePath) {
    $state = Get-Content -LiteralPath $statePath -Raw -Encoding UTF8 | ConvertFrom-Json
    $state.updated_at = [DateTime]::Now.ToString('o')
    $state.pending_sync = ($rollbackResult -eq 'rollback-failed')
    $state | Add-Member -NotePropertyName last_iteration_status -NotePropertyValue $rollbackResult -Force
    $state.PSObject.Properties.Remove('active_iteration')
    $state | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $statePath -Encoding UTF8
  }
  if ($rollbackResult -eq 'rollback-failed') { throw "Global iteration failed and rollback also failed. Iteration error: $iterationFailure Rollback error: $rollbackFailure" }
  throw "Global iteration failed; active content is unchanged or has been restored. Repair the owning error and rerun the complete iteration. Cause: $iterationFailure"
}
