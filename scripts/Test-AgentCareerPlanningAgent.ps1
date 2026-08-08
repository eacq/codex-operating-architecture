[CmdletBinding()]
param(
    [string]$RepositoryRoot = 'F:\codex'
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath $RepositoryRoot).Path
$runtimeRoot = $root
if ($env:CODEX_VALIDATION_RUNTIME_ROOT) {
    $runtimeRoot = (Resolve-Path -LiteralPath $env:CODEX_VALIDATION_RUNTIME_ROOT).Path
}
$registryPath = Join-Path $root 'config\global-experience-agent-registry.json'
$systemPath = Join-Path $root 'config\agent-system.json'
$skillPath = Join-Path $root 'skills\codex-requirement-authoring\subskills\career-planning-agent\SKILL.md'
$routePath = Join-Path $root 'skills\codex-requirement-authoring\subskills\career-planning-agent\references\career-ops-route-contract.md'
$plannerPath = Join-Path $root 'skills\codex-requirement-authoring\subskills\career-planning-agent\scripts\New-AgentCareerPlanningPlan.ps1'
$knowledgePath = Join-Path $root 'knowledge-vault\30-Knowledge\Career Planning Agent Workflow.md'
$upstreamPath = Join-Path $runtimeRoot '.runtime\work\network-learning\santifer-career-ops-main'

foreach ($path in @($registryPath, $systemPath, $skillPath, $routePath, $plannerPath, $knowledgePath)) {
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        throw "Required career planning Agent file is missing: $path"
    }
}
if (-not (Test-Path -LiteralPath $upstreamPath -PathType Container)) {
    throw 'Installed santifer/career-ops workspace is missing.'
}

$skillHead = Get-Content -LiteralPath $skillPath -TotalCount 4 -Encoding UTF8
if ($skillHead[0] -ne '---' -or $skillHead[3] -ne '---') {
    throw 'Career planning Agent skill must have YAML frontmatter delimited by ---'
}

$pkg = Get-Content -LiteralPath (Join-Path $upstreamPath 'package.json') -Raw -Encoding UTF8 | ConvertFrom-Json
if ($pkg.name -ne 'career-ops') {
    throw 'Installed upstream package is not career-ops.'
}
foreach ($scriptName in @('doctor','scan','pdf','tracker','upskill')) {
    if (-not $pkg.scripts.$scriptName) {
        throw "Installed upstream package is missing script: $scriptName"
    }
}
foreach ($upstreamFile in @('AGENTS.md','DATA_CONTRACT.md','.agents/skills/career-ops/SKILL.md','modes/oferta.md','modes/scan.md','modes/upskill.md')) {
    if (-not (Test-Path -LiteralPath (Join-Path $upstreamPath $upstreamFile) -PathType Leaf)) {
        throw "Installed upstream corpus is missing: $upstreamFile"
    }
}
if (-not (Test-Path -LiteralPath (Join-Path $upstreamPath 'node_modules') -PathType Container)) {
    throw 'career-ops local node_modules is missing; run npm install --ignore-scripts in the installed workspace.'
}

$registry = Get-Content -LiteralPath $registryPath -Raw -Encoding UTF8 | ConvertFrom-Json
$child = @($registry.child_agent_profiles | Where-Object { $_.id -eq 'career-planning-agent' })
if ($child.Count -ne 1) {
    throw 'career-planning-agent child profile must be registered exactly once.'
}
$child = $child[0]
if ($child.parent_concept -ne 'work-orchestration-agent' -or $child.owner -ne 'codex-requirement-authoring') {
    throw 'career-planning-agent parent concept or owner is misaligned.'
}
foreach ($requiredOwner in @('codex-requirement-authoring','codex-workflow-design','codex-task-execution','codex-information-gathering')) {
    if ($requiredOwner -notin @($child.owners)) {
        throw "career-planning-agent is missing owner route: $requiredOwner"
    }
}
foreach ($denied in @('application-submit','message-send','credential-use','paid-external-api-call','agent-structure-mutation','git','release')) {
    if ($denied -notin @($child.denied_operations)) {
        throw "career-planning-agent is missing denied operation: $denied"
    }
}

$system = Get-Content -LiteralPath $systemPath -Raw -Encoding UTF8 | ConvertFrom-Json
foreach ($unit in @('knowledge-vault/30-Knowledge/Career Planning Agent Workflow.md','skills/codex-requirement-authoring/subskills/career-planning-agent/references/career-ops-route-contract.md')) {
    if ($unit -notin @($system.resources.information_units)) {
        throw "Agent system information units missing career planning unit: $unit"
    }
}
foreach ($unit in @('skills/codex-requirement-authoring/subskills/career-planning-agent/SKILL.md','skills/codex-requirement-authoring/subskills/career-planning-agent/scripts/New-AgentCareerPlanningPlan.ps1')) {
    if ($unit -notin @($system.resources.functional_units)) {
        throw "Agent system functional units missing career planning unit: $unit"
    }
}

$plan = & $plannerPath -RepositoryRoot $root -TaskId 'test-career-plan' -Request 'help me plan my career and evaluate job options' | ConvertFrom-Json
if ($plan.status -ne 'passed' -or $plan.resolved_mode -ne 'opportunity-evaluation') {
    throw 'Career planning route planner did not produce the expected route.'
}
if (@($plan.intent_signals).Count -lt 2 -or 'life-map' -notin @($plan.secondary_modes)) {
    throw 'Career planning route planner must preserve secondary planning routes for multi-intent requests.'
}
if (@($plan.usage_hint).Count -lt 3) {
    throw 'Career planning route planner must return usage hints for callers.'
}

function New-TestTokenFromCodePoints {
    param([int[]]$CodePoints)

    return -join ($CodePoints | ForEach-Object { [string][char]$_ })
}
$zhRequest = @(
    (New-TestTokenFromCodePoints @(0x8BC4,0x4F30)),
    (New-TestTokenFromCodePoints @(0x5C97,0x4F4D)),
    (New-TestTokenFromCodePoints @(0x673A,0x4F1A)),
    (New-TestTokenFromCodePoints @(0x7B80,0x5386)),
    (New-TestTokenFromCodePoints @(0x9762,0x8BD5))
) -join ' '
$zhPlan = & $plannerPath -RepositoryRoot $root -TaskId 'test-career-plan-zh' -Request $zhRequest | ConvertFrom-Json
if ($zhPlan.status -ne 'passed' -or $zhPlan.resolved_mode -ne 'interview') {
    throw 'Career planning route planner did not recognize the Chinese primary route.'
}
foreach ($secondary in @('cv','opportunity-evaluation')) {
    if ($secondary -notin @($zhPlan.secondary_modes)) {
        throw "Career planning route planner missed Chinese secondary route: $secondary"
    }
}

[pscustomobject][ordered]@{
    status = 'passed'
    model = 'career-planning-agent'
    upstream_package = $pkg.name
    upstream_version = $pkg.version
    child_profile = $child.id
    source_files = @($plan.source_files).Count
    zh_secondary_modes = @($zhPlan.secondary_modes).Count
    denied_operations = @($child.denied_operations).Count
} | ConvertTo-Json -Compress
