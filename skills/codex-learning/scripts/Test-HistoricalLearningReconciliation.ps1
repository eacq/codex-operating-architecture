[CmdletBinding()]
param(
    [string]$ProjectRoot = 'F:\codex'
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath $ProjectRoot).Path
$scriptPath = Join-Path $root 'skills\codex-learning\scripts\Invoke-HistoricalLearningReconciliation.ps1'
$output = Join-Path $root '.runtime\work\historical-learning-reconciliation-test.json'
$raw = & $scriptPath -ProjectRoot $root -Mode full -OutputPath $output -Apply
if ($LASTEXITCODE -ne 0) { throw 'Historical learning reconciliation script failed.' }
if (-not (Test-Path -LiteralPath $output -PathType Leaf)) { throw "Expected reconciliation record missing: $output" }
$record = Get-Content -Raw -LiteralPath $output -Encoding UTF8 | ConvertFrom-Json
if ($record.mode -ne 'full') { throw "Expected full mode, got $($record.mode)." }
if ($record.status -ne 'inventory-ready') { throw "Expected inventory-ready status, got $($record.status)." }
if ([int]$record.inventory.skill_files -lt 100) { throw "Skill inventory unexpectedly small: $($record.inventory.skill_files)." }
if ([int]$record.inventory.specialist_owners -ne 23) { throw "Expected 23 specialist owners, got $($record.inventory.specialist_owners)." }
if (-not ($record.policy.private_content -match 'excluded')) { throw 'Private-content boundary missing.' }
Write-Output (@{ status = 'passed'; mode = $record.mode; skill_files = $record.inventory.skill_files; specialist_owners = $record.inventory.specialist_owners; network_roots = @($record.inventory.network_learning_roots).Count } | ConvertTo-Json -Compress)
