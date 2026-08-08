[CmdletBinding()]
param([string]$RepositoryRoot = 'F:\codex')

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath $RepositoryRoot).Path
$policyPath = Join-Path $root 'config\agent-capability-routing-policy.json'
if (-not (Test-Path -LiteralPath $policyPath -PathType Leaf)) { throw 'Capability routing policy is missing.' }
$policy = Get-Content -LiteralPath $policyPath -Raw -Encoding UTF8 | ConvertFrom-Json

if ($policy.model -ne 'global-experience-agent-capability-routing-policy' -or $policy.status -ne 'active') { throw 'Capability routing policy header is invalid.' }
if ($policy.source.repository -ne 'https://github.com/CherryHQ/cherry-studio') { throw 'Cherry Studio source is not recorded.' }
if ($policy.owners.entry -ne 'codex-self-evolution' -or $policy.owners.evidence -ne 'codex-information-gathering') { throw 'Capability routing owners are invalid.' }
if ($policy.catalog.read_mode -ne 'cache-first' -or -not $policy.catalog.never_block_on_external_capability) { throw 'Catalog must be cache-first and non-blocking.' }
foreach ($pool in @('inline', 'deferred', 'cold')) { if ($pool -notin @($policy.exposure.pools.id)) { throw "Missing exposure pool: $pool" } }
foreach ($operation in @('search', 'inspect', 'invoke')) { if ($operation -notin @($policy.exposure.meta_operations)) { throw "Missing meta operation: $operation" } }
foreach ($step in @('classify-intent', 'read-cached-capability-catalog', 'select-owner-and-narrow-surface', 'evaluate-independent-tool-gate', 'execute-or-return-typed-boundary', 'record-result-and-refresh-candidate-evidence')) { if ($step -notin @($policy.exposure.route_sequence)) { throw "Missing route step: $step" } }
if ($policy.gates.approval_required_capabilities -ne 'always-inline') { throw 'Approval-gated capabilities must remain inline.' }
if ($policy.gates.deferred_route_may_bypass_gate -ne $false) { throw 'Deferred routes must not bypass gates.' }
if ($policy.gates.arbitrary_code_execution -ne 'disabled-by-default') { throw 'Arbitrary code execution must remain disabled by default.' }
if ($policy.admission.not_a_new_top_level_owner -ne $true) { throw 'Cherry adaptation must remain under existing owners.' }
foreach ($version in @('economy', 'balanced', 'full')) { if (-not $policy.resource_versions.$version) { throw "Missing resource version: $version" } }

$agentSystem = Get-Content -LiteralPath (Join-Path $root 'config\agent-system.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$informationUnits = @($agentSystem.resources.information_units | ForEach-Object { [string]$_ })
$functionalUnits = @($agentSystem.resources.functional_units | ForEach-Object { [string]$_ })
if ('config/agent-capability-routing-policy.json' -notin $informationUnits) { throw 'Agent system information units do not include the capability routing policy.' }
if ('scripts/Test-AgentCapabilityRoutingPolicy.ps1' -notin $functionalUnits) { throw 'Agent system functional units do not include the capability routing test.' }

[pscustomobject]@{
  result = 'agent-capability-routing-policy-passed'
  source_commit = $policy.source.commit
  route_steps = @($policy.exposure.route_sequence).Count
  resource_versions = @('economy', 'balanced', 'full')
  approval_gate_preserved = $true
  arbitrary_code_execution = $policy.gates.arbitrary_code_execution
} | ConvertTo-Json -Depth 6
