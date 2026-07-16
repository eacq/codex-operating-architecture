[CmdletBinding()]
param(
  [string]$ProjectRoot = (Get-Location).Path,
  [ValidateSet('global-iteration','project-initialization','ongoing-work')]
  [string]$Phase = 'ongoing-work',
  [switch]$Apply
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath $ProjectRoot).Path
$project = Join-Path $root '.codex\project'
$policyPath = Join-Path $project 'file-organization.json'
$backupPath = Join-Path $project 'file-organization-backup.json'
$planner = Join-Path $PSScriptRoot 'New-FileOrganizationPlan.ps1'

# The raw plan remains in memory. The lifecycle record intentionally preserves
# aggregate counts only, so a global iteration cannot publish local names/paths.
$plan = & $planner -Root $root | ConvertFrom-Json
$counts = [ordered]@{}
foreach ($item in @($plan.items)) {
  $bucket = ([string]$item.proposed -split '[\\/]')[0]
  if (-not $counts.Contains($bucket)) { $counts[$bucket] = 0 }
  $counts[$bucket]++
}
$policyReady = Test-Path -LiteralPath $policyPath
$backupReady = Test-Path -LiteralPath $backupPath
$record = [ordered]@{
  schema_version = 1
  phase = $Phase
  policy = if ($policyReady) { 'present' } else { 'missing' }
  backup_readiness = if ($backupReady) { 'recorded' } else { 'required-before-apply' }
  inventory = [ordered]@{ item_count = @($plan.items).Count; bucket_counts = $counts; metadata_only = $true }
  integration = [ordered]@{
    workflow = 'organization decisions require workflow-learning review'
    knowledge = 'validated decisions become knowledge candidates'
    experience = 'validated decisions become experience candidates'
    visual = 'GPT-first when nonlinear topology materially improves understanding'
    backup = 'explicit backup outside selected root before any apply'
  }
  apply_performed = $false
  result = if ($policyReady) { 'passed' } else { 'policy-bootstrap-required' }
  reviewed_at = [DateTime]::UtcNow.ToString('o')
}
if ($Apply) {
  New-Item -ItemType Directory -Force -Path $project | Out-Null
  $record | ConvertTo-Json -Depth 7 | Set-Content -LiteralPath (Join-Path $project 'file-organization-review.json') -Encoding UTF8
}
$record | ConvertTo-Json -Depth 7
