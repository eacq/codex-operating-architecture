[CmdletBinding()]
param([string]$RepositoryRoot = 'F:\codex')

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath $RepositoryRoot).Path
$controller = Join-Path $root 'agent\40-runtime\Invoke-GlobalExperienceAgent.ps1'
$policyPath = Join-Path $root 'config\agent-autonomous-capability-decision-policy.json'
$systemPath = Join-Path $root 'config\agent-system.json'
if (-not (Test-Path -LiteralPath $controller -PathType Leaf)) { throw 'Global Experience Agent controller is missing.' }
if (-not (Test-Path -LiteralPath $policyPath -PathType Leaf)) { throw 'Autonomous capability decision policy is missing.' }

$policy = Get-Content -LiteralPath $policyPath -Raw -Encoding UTF8 | ConvertFrom-Json
$system = Get-Content -LiteralPath $systemPath -Raw -Encoding UTF8 | ConvertFrom-Json
if ($policy.model -ne 'global-experience-agent-autonomous-capability-decision-policy' -or $policy.status -ne 'active') {
    throw 'Autonomous capability decision policy header is invalid.'
}
if (-not $policy.contract.selection_is_not_authority -or -not $policy.contract.smallest_sufficient_set) {
    throw 'Autonomous capability policy does not preserve selection and economy boundaries.'
}
foreach ($class in @('auto-select', 'recommend-and-wait', 'owner-gated', 'never-auto')) {
    if ($class -notin @($policy.decision_classes.id)) { throw "Missing autonomous decision class: $class" }
}
foreach ($capability in @('expert-contract-mode', 'expert-template-synthesis', 'methodology-distillation', 'brainstorming-lite', 'loopx-control-plane', 'evidence-review-mode', 'verified-memory-writeback')) {
    if ($capability -notin @($policy.capabilities.id)) { throw "Missing autonomous capability: $capability" }
}
foreach ($requiredResource in @('config/agent-autonomous-capability-decision-policy.json', 'scripts/Test-AgentAutonomousCapabilityDecision.ps1')) {
    if ($requiredResource -notin @($system.resources.information_units + $system.resources.functional_units)) {
        throw "Agent system resources do not register: $requiredResource"
    }
}

$testRoot = Join-Path $root ('.runtime\tmp\agent-autonomous-capability-' + [guid]::NewGuid().ToString('N'))
$stateRoot = Join-Path $testRoot 'state'
New-Item -ItemType Directory -Force -Path $testRoot | Out-Null

function Invoke-Decision([string]$Id, [string]$Goal) {
    $outputPath = Join-Path $testRoot ($Id + '.json')
    return (& $controller -RepositoryRoot $root -Mode Run -Operation ClassifyIntent -SessionId ('capability-' + $Id) -StateRoot $stateRoot -OutputPath $outputPath -Goal $Goal -Interface llm -AuthorityScope functional -Apply | ConvertFrom-Json)
}

function Get-SelectedIds([object]$Result) {
    return @($Result.tool_result.decision.capability_plan.selected_ids | ForEach-Object { [string]$_ })
}

try {
    $source = Invoke-Decision 'source' 'deep learn https://github.com/msitarzewski/agency-agents and distill the method into a reusable skill; do not install the upstream runtime'
    if ($source.status -ne 'passed' -or 'methodology-distillation' -notin (Get-SelectedIds $source)) {
        throw 'External methodology learning did not autonomously select methodology-distillation.'
    }

    $expert = Invoke-Decision 'expert' 'this is a cross-domain task; decide which expert contracts and specialist owners are needed'
    if ($expert.status -ne 'passed' -or 'expert-contract-mode' -notin (Get-SelectedIds $expert)) {
        throw 'Cross-domain work did not autonomously select expert-contract-mode.'
    }

    $template = Invoke-Decision 'template' 'there is no matching expert template; derive a design from the existing expert template and knowledge framework'
    if ($template.status -ne 'passed' -or 'expert-template-synthesis' -notin (Get-SelectedIds $template)) {
        throw 'Missing expert template did not autonomously select expert-template-synthesis.'
    }

    $longRunning = Invoke-Decision 'long-running' 'keep optimizing until complete; use todo, quota, and heartbeat for this multi-turn task'
    if ($longRunning.status -ne 'passed' -or 'loopx-control-plane' -notin (Get-SelectedIds $longRunning)) {
        throw 'Long-running work did not autonomously select loopx-control-plane.'
    }

    $review = Invoke-Decision 'review' 'take a screenshot to verify the exported result, refresh, and review the visual outcome'
    if ($review.status -ne 'passed' -or 'evidence-review-mode' -notin (Get-SelectedIds $review)) {
        throw 'Visual acceptance work did not autonomously select evidence-review-mode.'
    }

    $simple = Invoke-Decision 'simple' 'change one sentence and replace one typo directly'
    $simpleIds = Get-SelectedIds $simple
    foreach ($broadCapability in @('expert-contract-mode', 'brainstorming-lite', 'loopx-control-plane')) {
        if ($broadCapability -in $simpleIds) { throw "Simple one-line work falsely selected $broadCapability." }
    }

    foreach ($result in @($source, $expert, $template, $longRunning, $review, $simple)) {
        $plan = $result.tool_result.decision.capability_plan
        if ([string]$plan.authority_rule -notmatch 'never grant authority') {
            throw 'Capability plan does not expose the no-authority-elevation rule.'
        }
        foreach ($selected in @($plan.selected)) {
            if ([string]$selected.next_authority_boundary -eq 'typed boundary; no autonomous activation') {
                throw 'A never-auto capability was selected.'
            }
        }
    }

    [pscustomobject][ordered]@{
        status = 'passed'
        model = $policy.model
        selected_positive_cases = 5
        simple_task_broad_capabilities_suppressed = $true
        authority_boundary_preserved = $true
        policy_capability_count = @($policy.capabilities).Count
    } | ConvertTo-Json -Depth 8
}
finally {
    if (Test-Path -LiteralPath $testRoot) {
        Remove-Item -LiteralPath $testRoot -Recurse -Force
    }
}
