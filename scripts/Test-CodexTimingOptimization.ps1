[CmdletBinding()]
param([string]$RepositoryRoot = 'F:\codex')

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath $RepositoryRoot).Path
$policy = Get-Content -LiteralPath (Join-Path $root 'config\loopx-resource-policy.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$contract = $policy.timing_optimization_contract
if (@($contract.layers).Count -lt 6) { throw 'Timing optimization must cover all required layers.' }
foreach ($gate in @('required_function_set','evidence_boundary','authority_scope','privacy_redaction','rollback_ready','typed_exit','equivalent_validation')) { if ($gate -notin @($contract.no_regression_gates)) { throw "Missing no-regression gate: $gate" } }
$scriptPath = Join-Path $root 'scripts\Invoke-CodexTimingOptimization.ps1'
if (-not (Test-Path -LiteralPath $scriptPath -PathType Leaf)) { throw 'Timing optimization script is missing.' }
$json = & $scriptPath -RepositoryRoot $root -Apply | ConvertFrom-Json
if ($json.result -ne 'analyzed' -or @($json.required_layers).Count -lt 6) { throw 'Timing optimization baseline did not complete.' }
$baseline = Join-Path $root '.codex\project\timing-optimization-baseline.json'
if (-not (Test-Path -LiteralPath $baseline -PathType Leaf)) { throw 'Timing optimization baseline was not persisted.' }
Write-Host 'Codex timing optimization contract test passed.'
