[CmdletBinding()]
param([string]$RepositoryRoot = 'F:\codex')

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath $RepositoryRoot).Path
$policyPath = Join-Path $root 'config\agent-intent-policy.json'
$controller = Join-Path $root 'agent\40-runtime\Invoke-GlobalExperienceAgent.ps1'
if (-not (Test-Path -LiteralPath $policyPath -PathType Leaf)) { throw 'Agent intent policy is missing.' }
if (-not (Test-Path -LiteralPath $controller -PathType Leaf)) { throw 'Global Experience Agent controller is missing.' }

$policy = Get-Content -LiteralPath $policyPath -Raw -Encoding UTF8 | ConvertFrom-Json
if ($policy.model -ne 'global-experience-agent-intent-policy' -or $policy.status -ne 'active') {
    throw 'Agent intent policy header is invalid.'
}
foreach ($layer in @('L0', 'L1', 'L2', 'L3')) {
    if ($layer -notin @($policy.layers.id)) { throw "Agent intent policy is missing layer: $layer" }
}
foreach ($operation in @('CandidateReport', 'CompleteIteration', 'SearchMemory', 'StoreMemory', 'DescribeInterfaces', 'RequestStructureChange')) {
    if ($operation -notin @($policy.routes.operation)) { throw "Agent intent policy is missing operation route: $operation" }
}
if ($policy.safety.llm_adapter_status -ne 'not-implemented') {
    throw 'Local Agent intent recognition must not require an LLM adapter by default.'
}

$testRoot = Join-Path $root ('.runtime\tmp\agent-intent-' + [guid]::NewGuid().ToString('N'))
$stateRoot = Join-Path $testRoot 'state'
try {
    New-Item -ItemType Directory -Force -Path $testRoot | Out-Null

    $l0 = & $controller -RepositoryRoot $root -Mode Run -Operation ClassifyIntent -SessionId 'intent-l0' -StateRoot $stateRoot -OutputPath (Join-Path $testRoot 'l0.json') -Query '/verify' -Interface llm -AuthorityScope functional -Apply | ConvertFrom-Json
    if ($l0.status -ne 'passed' -or $l0.tool_result.decision.layer -ne 'L0' -or $l0.tool_result.decision.operation -ne 'VerifyAgent' -or $l0.tool_result.side_effect_executed) {
        throw 'L0 intent classification did not resolve /verify as evidence-only VerifyAgent.'
    }

    $l1 = & $controller -RepositoryRoot $root -Mode Run -Operation ClassifyIntent -SessionId 'intent-l1' -StateRoot $stateRoot -OutputPath (Join-Path $testRoot 'l1.json') -Goal 'please generate the current candidate report' -Interface llm -AuthorityScope functional -Apply | ConvertFrom-Json
    if ($l1.status -ne 'passed' -or $l1.tool_result.decision.layer -ne 'L1' -or $l1.tool_result.decision.operation -ne 'CandidateReport' -or $l1.tool_result.decision.llm_called) {
        throw 'L1 intent classification did not resolve the candidate-report route without an LLM call.'
    }

    $fallback = & $controller -RepositoryRoot $root -Mode Run -Operation ClassifyIntent -SessionId 'intent-fallback' -StateRoot $stateRoot -OutputPath (Join-Path $testRoot 'fallback.json') -Goal 'unregistered random request fixture' -Interface llm -AuthorityScope functional -Apply | ConvertFrom-Json
    if ($fallback.status -ne 'passed' -or $fallback.tool_result.decision.layer -ne 'L3' -or $fallback.tool_result.decision.operation -ne 'StartWork' -or -not $fallback.tool_result.decision.fallback_needed) {
        throw 'L3 fallback did not produce a bounded StartWork route.'
    }

    $auto = & $controller -RepositoryRoot $root -Mode Run -Operation Auto -SessionId 'intent-auto' -StateRoot $stateRoot -OutputPath (Join-Path $testRoot 'auto.json') -Goal 'please generate the current candidate report' -Interface human -AuthorityScope functional -Apply | ConvertFrom-Json
    if ($auto.status -ne 'passed' -or $auto.operation -ne 'CandidateReport') {
        throw 'Auto operation did not use intent classification to select CandidateReport.'
    }
    $autoEvents = @(Get-Content -LiteralPath (Join-Path $stateRoot 'intent-auto\events.jsonl') -Encoding UTF8 | Where-Object { $_ } | ForEach-Object { $_ | ConvertFrom-Json })
    if ('intent_classified' -notin @($autoEvents.type)) {
        throw 'Auto operation did not persist intent_classified evidence.'
    }

    $blocked = & $controller -RepositoryRoot $root -Mode Run -Operation Auto -SessionId 'intent-structure-denied' -StateRoot $stateRoot -OutputPath (Join-Path $testRoot 'blocked.json') -Goal 'change agent structure' -Interface llm -AuthorityScope functional -Apply | ConvertFrom-Json
    if ($blocked.status -ne 'blocked' -or $blocked.operation -ne 'RequestStructureChange' -or $blocked.durable_session_mutated) {
        throw 'Intent classification bypassed structural interface denial.'
    }

    $result = [ordered]@{
        status = 'passed'
        model = $policy.model
        source = $policy.source.repository
        layers = @($policy.layers).Count
        routes = @($policy.routes).Count
        l0_operation = $l0.tool_result.decision.operation
        l1_operation = $l1.tool_result.decision.operation
        fallback_operation = $fallback.tool_result.decision.operation
        auto_operation = $auto.operation
        denied_structure_mutation = $true
    }
    [pscustomobject]$result | ConvertTo-Json -Depth 8
} finally {
    if (Test-Path -LiteralPath $testRoot) {
        Remove-Item -LiteralPath $testRoot -Recurse -Force
    }
}
