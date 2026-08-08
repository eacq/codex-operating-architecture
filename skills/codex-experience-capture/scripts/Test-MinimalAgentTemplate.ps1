[CmdletBinding()]
param([string]$RepositoryRoot = 'F:\codex')

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath $RepositoryRoot).Path
$templatePath = Join-Path $root 'config\minimal-agent-template.json'
$planner = Join-Path $root 'skills\codex-experience-capture\scripts\New-MinimalAgentPlan.ps1'
foreach ($path in @($templatePath, $planner)) {
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "Minimal Agent template test requires: $path" }
}

$template = Get-Content -LiteralPath $templatePath -Raw -Encoding UTF8 | ConvertFrom-Json
if ($template.model -ne 'minimal-agent-architecture-template' -or $template.root_controller -ne 'agent/40-runtime/Invoke-GlobalExperienceAgent.ps1') {
    throw 'Minimal Agent template does not point to the canonical root controller.'
}
foreach ($section in @('identity','authority','task','resources','work_surface','completion','lifecycle','safety','feynman_structural_scaffold','structural_optimization_inheritance')) {
    if (-not ($template.required_units.PSObject.Properties.Name -contains $section)) { throw "Minimal Agent template is missing section: $section" }
}
foreach ($unit in @('memory_system','intent_recognition','doc_parse_pipeline','chunking_retrieval','rerank_calibration','agent_loop','memory_as_skill')) {
    if ($unit -notin @($template.required_units.feynman_structural_scaffold)) { throw "Minimal Agent template required units are missing feynman scaffold unit: $unit" }
    $entry = @($template.feynman_structural_scaffold.units | Where-Object { $_.id -eq $unit })
    if ($entry.Count -ne 1 -or [string]::IsNullOrWhiteSpace($entry[0].episode) -or [string]::IsNullOrWhiteSpace($entry[0].contract)) {
        throw "Minimal Agent template feynman scaffold is incomplete: $unit"
    }
}

$parseErrors = $null
[System.Management.Automation.Language.Parser]::ParseFile($planner, [ref]$null, [ref]$parseErrors) | Out-Null
if ($parseErrors) { throw "Minimal Agent planner has PowerShell syntax errors: $($parseErrors | Out-String)" }

$plan = & $planner -RepositoryRoot $root -Goal 'design a child agent to update a README diagram' -ChildId 'readme-diagram-child' -AcceptanceCriteria 'diagram plan exists' -Verification 'parent checks generated plan evidence' | ConvertFrom-Json
if ($plan.model -ne 'minimal-agent-plan' -or $plan.result -ne 'designed') { throw 'Minimal Agent planner did not design a plan.' }
if ($plan.child.agent_id -ne 'delivery-agent' -or $plan.child.lifecycle -ne 'designed') { throw 'Minimal Agent planner did not infer the delivery concept Agent.' }
if (@($plan.contract.write_surfaces).Count -eq 0 -or @($plan.contract.acceptance_criteria).Count -eq 0) { throw 'Minimal Agent plan lacks required work or completion surfaces.' }
if ($plan.root_controller -ne 'agent/40-runtime/Invoke-GlobalExperienceAgent.ps1') { throw 'Minimal Agent plan bypasses the canonical root controller.' }
if ($plan.contract.structural_optimization_snapshot.status -ne 'synchronized' -or @($plan.contract.structural_optimization_snapshot.optimizations).Count -lt 8) { throw 'Minimal Agent plan lacks the current structural optimization snapshot.' }
foreach ($unit in @('memory_system','intent_recognition','doc_parse_pipeline','chunking_retrieval','rerank_calibration','agent_loop','memory_as_skill')) {
    if ($unit -notin @($plan.contract.feynman_structural_scaffold.units.id)) {
        throw "Minimal Agent plan does not inherit feynman scaffold unit: $unit"
    }
}

$stateRoot = & (Join-Path $root 'scripts\Resolve-CodexRunRoot.ps1') -ArchitectureRoot $root -Kind tmp -ChildPath ('minimal-agent-template-' + [guid]::NewGuid().ToString('N')) -Create
$sessionId = 'minimal-template-test'
$controller = Join-Path $root 'agent\40-runtime\Invoke-GlobalExperienceAgent.ps1'
try {
    $started = & $controller -RepositoryRoot $root -Mode Run -Operation StartWork -SessionId $sessionId -StateRoot $stateRoot -Goal 'parent session for minimal child template test' -Authority 'fixture authority' -Apply | ConvertFrom-Json
    if ($started.status -ne 'passed') { throw 'Parent Agent session did not start for minimal template delegation test.' }
    $delegatedPlan = & $planner -RepositoryRoot $root -Goal 'inspect experience evidence as a child task' -AgentId 'experience-memory-agent' -ChildId 'experience-template-child' -SessionId $sessionId -StateRoot $stateRoot -WriteSurface '.runtime/work/experience-template-child' -AcceptanceCriteria 'evidence summary exists' -Verification 'parent verifies child evidence' -Delegate -Apply | ConvertFrom-Json
    if ($delegatedPlan.child.lifecycle -ne 'delegated' -or $delegatedPlan.delegation.tool_result.result -ne 'subagent-delegated') { throw 'Minimal Agent planner did not delegate through the root Agent runtime.' }
    if ($delegatedPlan.delegation.tool_result.child.status -ne 'delegated') { throw 'Delegated child state did not settle as delegated.' }
    if ($delegatedPlan.delegation.tool_result.structural_optimization_snapshot.baseline_sha256 -ne $delegatedPlan.contract.structural_optimization_snapshot.baseline_sha256) { throw 'Delegated child did not retain the designed structural optimization baseline.' }
    foreach ($unit in @('memory_system','intent_recognition','doc_parse_pipeline','chunking_retrieval','rerank_calibration','agent_loop','memory_as_skill')) {
        if ($unit -notin @($delegatedPlan.contract.feynman_structural_scaffold.units.id)) {
            throw "Delegated Minimal Agent plan does not preserve feynman scaffold unit: $unit"
        }
    }
} finally {
    $resolvedStateRoot = [IO.Path]::GetFullPath($stateRoot)
    $allowedRoot = [IO.Path]::GetFullPath('F:\.codex-codex-tmp').TrimEnd('\') + '\'
    if ($resolvedStateRoot.StartsWith($allowedRoot, [StringComparison]::OrdinalIgnoreCase) -and (Test-Path -LiteralPath $resolvedStateRoot)) {
        Remove-Item -LiteralPath $resolvedStateRoot -Recurse -Force
    }
}

[pscustomobject][ordered]@{
    status = 'passed'
    model = 'minimal-agent-template'
    template = 'config/minimal-agent-template.json'
    planner = 'skills/codex-experience-capture/scripts/New-MinimalAgentPlan.ps1'
    inferred_profile = $plan.child.agent_id
    delegated_profile = $delegatedPlan.child.agent_id
} | ConvertTo-Json -Compress
