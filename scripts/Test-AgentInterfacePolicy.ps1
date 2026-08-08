[CmdletBinding()]
param([string]$RepositoryRoot = (Get-Location).Path)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath $RepositoryRoot).Path
$policyPath = Join-Path $root 'config\agent-interface-policy.json'
$controller = Join-Path $root 'agent\40-runtime\Invoke-GlobalExperienceAgent.ps1'
if (-not (Test-Path -LiteralPath $policyPath -PathType Leaf)) { throw 'Agent interface policy is missing.' }
if (-not (Test-Path -LiteralPath $controller -PathType Leaf)) { throw 'Canonical Global Experience Agent controller is missing.' }

$policy = Get-Content -LiteralPath $policyPath -Raw -Encoding UTF8 | ConvertFrom-Json
if ($policy.schema_version -ne 1 -or $policy.status -ne 'active' -or $policy.default_decision -ne 'deny') {
    throw 'Agent interface policy header or default-deny rule is invalid.'
}
foreach ($id in @('human', 'llm', 'internal-functional-unit', 'global-control')) {
    if (@($policy.interfaces | Where-Object id -eq $id).Count -ne 1) { throw "Agent interface is missing or duplicated: $id" }
}
foreach ($id in @('human', 'llm', 'internal-functional-unit')) {
    $entry = @($policy.interfaces | Where-Object id -eq $id)[0]
    if ('agent-structure' -in @($entry.permissions) -or $entry.structural_mutation -ne 'deny') {
        throw "Non-global interface can directly mutate Agent structure: $id"
    }
}
$global = @($policy.interfaces | Where-Object id -eq 'global-control')[0]
if ('agent-structure' -notin @($global.permissions) -or $global.structural_mutation -ne 'allow-with-global-structure-authority') {
    throw 'Global-control does not expose the guarded Agent structure permission.'
}
if ($policy.structure_change_contract.owner -ne 'codex-architecture-iteration' -or $policy.structure_change_contract.tool_gate -ne 'agent_structure') {
    throw 'Agent structure changes do not route through the architecture owner and gate.'
}
foreach ($exit in @('response', 'evidence', 'save-point', 'handoff', 'authorization-required', 'gated-action-request', 'global-structure-change-request', 'error-feedback')) {
    if ($exit -notin @($policy.exits.id)) { throw "Agent interface exit is missing: $exit" }
}
if ($policy.operation_permissions.ClassifyIntent -ne 'observe') {
    throw 'ClassifyIntent must remain an observe-only Agent operation.'
}

$testRoot = Join-Path $root ('.runtime\tmp\agent-interface-policy-' + [guid]::NewGuid().ToString('N'))
$resolvedRuntimeRoot = [IO.Path]::GetFullPath((Join-Path $root '.runtime\tmp'))
$resolvedTestRoot = [IO.Path]::GetFullPath($testRoot)
if (-not $resolvedTestRoot.StartsWith($resolvedRuntimeRoot.TrimEnd('\') + '\', [StringComparison]::OrdinalIgnoreCase)) {
    throw 'Agent interface test root escaped .runtime/tmp.'
}

try {
    $stateRoot = Join-Path $testRoot 'state'

    $llmBlocked = & $controller -RepositoryRoot $root -Mode Run -Operation RequestStructureChange -SessionId 'llm-denied' -StateRoot $stateRoot -OutputPath (Join-Path $testRoot 'llm-denied.json') -Interface llm -AuthorityScope global-structure -AuthorizationEvidence 'fixture-does-not-elevate-interface' -RequestedSurfaces 'config/agent-system.json' -Apply | ConvertFrom-Json
    if ($llmBlocked.status -ne 'blocked' -or $llmBlocked.exit.type -ne 'authorization-required' -or $llmBlocked.durable_session_mutated -or (Test-Path -LiteralPath (Join-Path $stateRoot 'llm-denied'))) {
        throw 'LLM structural denial was not enforced before durable session mutation.'
    }

    $missingEvidence = & $controller -RepositoryRoot $root -Mode Run -Operation RequestStructureChange -SessionId 'global-denied' -StateRoot $stateRoot -OutputPath (Join-Path $testRoot 'global-denied.json') -Interface global-control -AuthorityScope global-structure -RequestedSurfaces 'config/agent-system.json' -Apply | ConvertFrom-Json
    if ($missingEvidence.status -ne 'blocked' -or $missingEvidence.authorization_decision.reason -notmatch 'authorization evidence' -or (Test-Path -LiteralPath (Join-Path $stateRoot 'global-denied'))) {
        throw 'Global-control structural authorization evidence is not mandatory before state mutation.'
    }

    $evaluated = & $controller -RepositoryRoot $root -Mode Run -Operation EvaluateAccess -RequestedOperation RequestStructureChange -RequestedSurfaces 'config/agent-system.json' -SessionId 'llm-evaluate' -StateRoot $stateRoot -OutputPath (Join-Path $testRoot 'llm-evaluate.json') -Interface llm -AuthorityScope functional -Apply | ConvertFrom-Json
    if ($evaluated.status -ne 'passed' -or $evaluated.tool_result.evaluation.decision -ne 'deny' -or $evaluated.tool_result.side_effect_executed -or $evaluated.exit.type -ne 'save-point') {
        throw 'LLM read-only access evaluation did not return a denied evidence-only result.'
    }

    $authorized = & $controller -RepositoryRoot $root -Mode Run -Operation RequestStructureChange -SessionId 'global-authorized' -StateRoot $stateRoot -OutputPath (Join-Path $testRoot 'global-authorized.json') -Interface global-control -AuthorityScope global-structure -AuthorizationEvidence 'current-user-fixture:agent-interface-policy' -RequestedSurfaces 'config/agent-system.json','agent/40-runtime/Invoke-GlobalExperienceAgentRuntime.ps1' -Authority 'explicit bounded structural test authority' -Apply | ConvertFrom-Json
    if ($authorized.status -ne 'passed' -or $authorized.tool_result.result -ne 'structure-change-authorized' -or -not $authorized.tool_result.evidence_only -or $authorized.tool_result.side_effect_executed -or $authorized.tool_result.tool_gate -ne 'agent_structure' -or $authorized.exit.type -ne 'global-structure-change-request') {
        throw 'Authorized global-control request did not produce an evidence-only architecture route.'
    }

    $human = & $controller -RepositoryRoot $root -Mode Run -Operation StartWork -SessionId 'human-functional' -StateRoot $stateRoot -OutputPath (Join-Path $testRoot 'human-functional.json') -Interface human -AuthorityScope functional -Goal 'Verify ordinary Agent functional-unit access remains available.' -AgentId 'work-orchestration-agent' -AcceptanceCriteria 'registered work contract is created' -Apply | ConvertFrom-Json
    if ($human.status -ne 'passed' -or $human.tool_result.result -ne 'work-started' -or $human.authorization_decision.required_permission -ne 'functional-unit-use') {
        throw 'Human functional-unit access regressed.'
    }

    [pscustomobject][ordered]@{
        status = 'passed'
        model = $policy.model
        interfaces = @($policy.interfaces).Count
        exits = @($policy.exits).Count
        denied_before_session_mutation = $true
        global_control_gate = $authorized.tool_result.tool_gate
        authorized_structure_side_effect = [bool]$authorized.tool_result.side_effect_executed
        functional_access = $human.tool_result.result
    } | ConvertTo-Json -Depth 8
} finally {
    if (Test-Path -LiteralPath $resolvedTestRoot) {
        Remove-Item -LiteralPath $resolvedTestRoot -Recurse -Force
    }
}
