[CmdletBinding()]
param([string]$RepositoryRoot = 'F:\codex')

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath $RepositoryRoot).Path
$policyPath = Join-Path $root 'config\agent-structural-optimization-policy.json'
$templatePath = Join-Path $root 'config\minimal-agent-template.json'
$registryPath = Join-Path $root 'config\global-experience-agent-registry.json'
$manifestPath = Join-Path $root 'config\agent-system.json'
$snapshotProvider = Join-Path $root 'agent\40-runtime\Get-AgentStructuralOptimizationSnapshot.ps1'
$syncController = Join-Path $root 'agent\80-maintenance\Sync-ChildAgentStructuralOptimizations.ps1'
foreach ($path in @($policyPath, $templatePath, $registryPath, $manifestPath, $snapshotProvider, $syncController)) {
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "Structural optimization propagation test requires: $path" }
}

$policy = Get-Content -LiteralPath $policyPath -Raw -Encoding UTF8 | ConvertFrom-Json
$template = Get-Content -LiteralPath $templatePath -Raw -Encoding UTF8 | ConvertFrom-Json
$registry = Get-Content -LiteralPath $registryPath -Raw -Encoding UTF8 | ConvertFrom-Json
$manifest = Get-Content -LiteralPath $manifestPath -Raw -Encoding UTF8 | ConvertFrom-Json
$requiredIds = @($policy.required_optimizations.id)
$baselineSha256 = (Get-FileHash -LiteralPath $policyPath -Algorithm SHA256).Hash.ToLowerInvariant()
if ($policy.model -ne 'global-agent-structural-optimization-policy' -or $policy.status -ne 'active' -or $requiredIds.Count -lt 8) {
    throw 'Structural optimization policy is inactive or incomplete.'
}
if (@($requiredIds | Sort-Object -Unique).Count -ne $requiredIds.Count) { throw 'Structural optimization ids are not unique.' }
if ($policy.default_inheritance_mode -ne 'adaptive-profile-guided' -or [string]::IsNullOrWhiteSpace([string]$policy.adaptation_rule) -or [string]::IsNullOrWhiteSpace([string]$policy.functional_effect_rule)) {
    throw 'Structural optimization policy does not require adaptive profile-guided learning.'
}
if (@($policy.profile_fit_dimensions).Count -lt 6) { throw 'Adaptive learning policy lacks profile-fit dimensions.' }

$sync = & $syncController -RepositoryRoot $root | ConvertFrom-Json
if ($sync.status -ne 'passed' -or @($sync.drifted_surfaces).Count -ne 0 -or $sync.baseline_sha256 -ne $baselineSha256) {
    throw 'Structural optimization synchronization controller reports drift.'
}

function Assert-Inheritance([object]$Contract, [string]$Label) {
    if (-not $Contract -or $Contract.baseline_id -ne $policy.baseline_id -or $Contract.baseline_version -ne $policy.baseline_version -or $Contract.baseline_sha256 -ne $baselineSha256) {
        throw "$Label does not match the current structural optimization baseline."
    }
    $missing = @($requiredIds | Where-Object { $_ -notin @($Contract.required_optimization_ids) })
    $extra = @($Contract.required_optimization_ids | Where-Object { $_ -notin $requiredIds })
    if ($missing.Count -gt 0 -or $extra.Count -gt 0) { throw "$Label does not carry the exact optimization id set." }
    if ($Contract.PSObject.Properties.Name -contains 'inheritance_mode' -and $Contract.inheritance_mode -ne $policy.default_inheritance_mode) {
        throw "$Label does not use the adaptive profile-guided inheritance mode."
    }
}

Assert-Inheritance $template.structural_optimization_inheritance 'Minimal Agent template'
if (@($template.structural_optimization_inheritance.profile_fit_dimensions).Count -lt 6 -or @($template.structural_optimization_inheritance.adaptation_evidence_required).Count -lt 4) {
    throw 'Minimal Agent template lacks adaptive learning evidence requirements.'
}
Assert-Inheritance $manifest.subagents.structural_optimization_propagation 'Agent system manifest'
foreach ($profile in @($registry.child_agent_profiles)) {
    if ($profile.structural_optimization_inheritance.status -ne 'synchronized') { throw "Child profile is not synchronized: $($profile.id)" }
    Assert-Inheritance $profile.structural_optimization_inheritance "Child profile $($profile.id)"
    if ([string]::IsNullOrWhiteSpace([string]$profile.structural_optimization_inheritance.domain_adaptation) -or [string]::IsNullOrWhiteSpace([string]$profile.structural_optimization_inheritance.profile_fit_summary) -or @($profile.structural_optimization_inheritance.functional_effects).Count -eq 0) {
        throw "Child profile lacks profile-specific functional adaptation: $($profile.id)"
    }
    $projectionPath = Join-Path $root "agent\20-agents\children\$($profile.id)\agent.json"
    $projection = Get-Content -LiteralPath $projectionPath -Raw -Encoding UTF8 | ConvertFrom-Json
    Assert-Inheritance $projection.structural_optimization_inheritance "Child projection $($profile.id)"
    if (@($projection.inherited_structural_optimizations).Count -ne $requiredIds.Count) { throw "Child projection lacks effective optimization contracts: $($profile.id)" }
    if (@($projection.structural_optimization_inheritance.functional_effects).Count -eq 0) { throw "Child projection lacks functional effect evidence: $($profile.id)" }
}

$namedSnapshot = & $snapshotProvider -RepositoryRoot $root -AgentId 'visual-design-agent' | ConvertFrom-Json
$directSnapshot = & $snapshotProvider -RepositoryRoot $root -AgentId 'work-orchestration-agent' | ConvertFrom-Json
if ($namedSnapshot.inheritance_mode -ne 'registered-profile-adapter' -or $directSnapshot.inheritance_mode -ne 'template-direct') {
    throw 'Structural optimization snapshot inheritance modes are incorrect.'
}
foreach ($snapshot in @($namedSnapshot, $directSnapshot)) {
    if ($snapshot.status -ne 'synchronized' -or $snapshot.baseline_sha256 -ne $baselineSha256 -or @($snapshot.optimizations).Count -ne $requiredIds.Count) {
        throw 'Structural optimization snapshot is incomplete.'
    }
    if ($snapshot.default_inheritance_mode -ne $policy.default_inheritance_mode -or [string]::IsNullOrWhiteSpace([string]$snapshot.adaptation_rule)) {
        throw 'Structural optimization snapshot lacks the adaptive learning contract.'
    }
}
if (@($namedSnapshot.functional_effects).Count -eq 0 -or [string]::IsNullOrWhiteSpace([string]$namedSnapshot.profile_fit_summary) -or [string]::IsNullOrWhiteSpace([string]$namedSnapshot.domain_adaptation)) {
    throw 'Named child snapshot lacks profile-specific functional adaptation.'
}
if (@($directSnapshot.functional_effects).Count -ne 0 -or $null -ne $directSnapshot.domain_adaptation) {
    throw 'Template-direct concept snapshot should not invent a named-child functional adaptation.'
}

$unknownRejected = $false
try { & $snapshotProvider -RepositoryRoot $root -AgentId 'not-a-registered-agent' | Out-Null } catch { $unknownRejected = $true }
if (-not $unknownRejected) { throw 'Unknown Agent id did not fail closed in the snapshot provider.' }

$namedPlan = & (Join-Path $root 'skills\codex-experience-capture\scripts\New-MinimalAgentPlan.ps1') -RepositoryRoot $root -Goal 'prepare a bounded career plan' -AgentId 'career-planning-agent' -ChildId 'career-plan-contract' | ConvertFrom-Json
if ($namedPlan.child.profile_kind -ne 'child' -or $namedPlan.contract.structural_optimization_snapshot.baseline_sha256 -ne $baselineSha256) {
    throw 'Minimal Agent planner does not support synchronized named child profiles.'
}

$stateRoot = & (Join-Path $root 'scripts\Resolve-CodexRunRoot.ps1') -ArchitectureRoot $root -Kind tmp -ChildPath ('structural-optimization-propagation-' + [guid]::NewGuid().ToString('N')) -Create
$sessionId = 'structural-optimization-propagation-test'
$controller = Join-Path $root 'agent\40-runtime\Invoke-GlobalExperienceAgent.ps1'
$fixtureOutput = Join-Path $stateRoot 'last-run.json'
try {
    $started = & $controller -RepositoryRoot $root -Mode Run -Operation StartWork -SessionId $sessionId -StateRoot $stateRoot -OutputPath $fixtureOutput -Goal 'test structural optimization propagation' -Authority 'fixture bounded authority' -Apply | ConvertFrom-Json
    if ($started.status -ne 'passed') { throw 'Propagation fixture parent session did not start.' }
    $delegated = & $controller -RepositoryRoot $root -Mode Continue -Operation DelegateSubagent -SessionId $sessionId -StateRoot $stateRoot -OutputPath $fixtureOutput -Goal 'delegate synchronized visual-design child' -AgentId 'visual-design-agent' -ChildId 'visual-optimization-child' -WriteSurface '.runtime/work/visual-design-agent/optimization-test' -AcceptanceCriteria 'return bounded evidence' -Verification 'parent validates synchronized child evidence' -Authority 'fixture bounded authority' -Apply | ConvertFrom-Json
    if ($delegated.tool_result.structural_optimization_snapshot.baseline_sha256 -ne $baselineSha256) { throw 'Delegation result lacks the current structural optimization snapshot.' }
    if (@($delegated.tool_result.structural_optimization_snapshot.functional_effects).Count -eq 0) { throw 'Delegation result lacks the child functional adaptation.' }
    $childStatePath = Join-Path $stateRoot "$sessionId--visual-optimization-child\state.json"
    $childState = Get-Content -LiteralPath $childStatePath -Raw -Encoding UTF8 | ConvertFrom-Json
    if ($childState.schema_version -lt 2 -or $childState.structural_optimization_snapshot.baseline_sha256 -ne $baselineSha256 -or @($childState.structural_optimization_snapshot.optimizations).Count -ne $requiredIds.Count) {
        throw 'Durable child state does not carry the effective structural optimization snapshot.'
    }
    if (@($childState.structural_optimization_snapshot.functional_effects).Count -eq 0 -or [string]::IsNullOrWhiteSpace([string]$childState.structural_optimization_snapshot.profile_fit_summary)) {
        throw 'Durable child state does not carry the profile-specific functional adaptation.'
    }
} finally {
    $resolvedStateRoot = [IO.Path]::GetFullPath($stateRoot)
    $allowedRoot = [IO.Path]::GetFullPath((Join-Path $root '.runtime\tmp')).TrimEnd('\') + '\'
    if ($resolvedStateRoot.StartsWith($allowedRoot, [StringComparison]::OrdinalIgnoreCase) -and (Test-Path -LiteralPath $resolvedStateRoot)) {
        Remove-Item -LiteralPath $resolvedStateRoot -Recurse -Force
    }
}

[pscustomobject][ordered]@{
    status = 'passed'
    model = 'agent-structural-optimization-propagation'
    baseline_version = $policy.baseline_version
    baseline_sha256 = $baselineSha256
    required_optimizations = $requiredIds.Count
    child_profiles = @($registry.child_agent_profiles).Count
    runtime_snapshot_modes = @($namedSnapshot.inheritance_mode, $directSnapshot.inheritance_mode)
} | ConvertTo-Json -Compress
