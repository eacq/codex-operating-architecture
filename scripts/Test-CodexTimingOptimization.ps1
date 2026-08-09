[CmdletBinding()]
param([string]$RepositoryRoot = 'F:\codex')

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath $RepositoryRoot).Path
$policy = Get-Content -LiteralPath (Join-Path $root 'config\loopx-resource-policy.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$contract = $policy.timing_optimization_contract
if (@($contract.layers).Count -lt 6) { throw 'Timing optimization must cover all required layers.' }
foreach ($gate in @('required_function_set','evidence_boundary','authority_scope','privacy_redaction','rollback_ready','typed_exit','equivalent_validation')) { if ($gate -notin @($contract.no_regression_gates)) { throw "Missing no-regression gate: $gate" } }
$objective = $policy.speed_quality_contract.optimization_objective
if ($policy.speed_quality_contract.primary_metric -ne 'customer_visible_complete_seconds') { throw 'Codex client customer-visible time must be the primary optimization metric.' }
if ([double]$objective.customer_visible_outcome.weight -le [double]$objective.execution_efficiency.weight -or [double]$objective.customer_visible_outcome.weight -le [double]$objective.quality_and_safety.weight) { throw 'Customer-visible optimization weight must be highest.' }
if ($objective.quality_and_safety.rule -notmatch 'Hard floor') { throw 'Quality and safety must remain a hard floor.' }
$scriptPath = Join-Path $root 'scripts\Invoke-CodexTimingOptimization.ps1'
if (-not (Test-Path -LiteralPath $scriptPath -PathType Leaf)) { throw 'Timing optimization script is missing.' }
$functionsPath = Join-Path $root 'scripts\CodexTimingFunctions.ps1'
if (-not (Test-Path -LiteralPath $functionsPath -PathType Leaf)) { throw 'Codex client timing functions are missing.' }
$functions = Get-Content -LiteralPath $functionsPath -Raw -Encoding UTF8
foreach ($term in @('durationMs','client_task_wall_clock_seconds','external-monotonic','independent-suboperation-stopwatch','scope-required','interval union')) { if ($functions -notmatch [regex]::Escape($term)) { throw "Codex timing cross-validation contract is missing: $term" } }
$iterationScript = Get-Content -LiteralPath (Join-Path $root 'scripts\Invoke-IsolatedGlobalExperienceIteration.ps1') -Raw -Encoding UTF8
if ($iterationScript -notmatch '\$IncludeAllGitRefs' -or $iterationScript -notmatch '\$bundleRef' -or $iterationScript -notmatch 'pre-replace-\$stamp\.bundle') { throw 'Scoped Git bundle optimization contract is missing.' }
$json = & $scriptPath -RepositoryRoot $root -Apply | ConvertFrom-Json
if ($json.result -ne 'analyzed' -or @($json.required_layers).Count -lt 6) { throw 'Timing optimization baseline did not complete.' }
if (@($json.observations | Where-Object { $_.metric -eq 'rollback_snapshot_seconds' -and $_.status -in @('baseline','candidate') }).Count -lt 4) { throw 'Rollback baseline/candidate timing evidence was not ingested.' }
$baseline = Join-Path $root '.codex\project\timing-optimization-baseline.json'
if (-not (Test-Path -LiteralPath $baseline -PathType Leaf)) { throw 'Timing optimization baseline was not persisted.' }
Write-Host 'Codex timing optimization contract test passed.'
