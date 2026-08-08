[CmdletBinding(PositionalBinding = $false)]
param(
    [string]$RepositoryRoot = 'F:\codex',
    [string]$AgentId
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath $RepositoryRoot).Path
$policyPath = Join-Path $root 'config\agent-structural-optimization-policy.json'
$templatePath = Join-Path $root 'config\minimal-agent-template.json'
$registryPath = Join-Path $root 'config\global-experience-agent-registry.json'
$ownerNetworkPath = Join-Path $root 'config\agent-owner-connections.json'
foreach ($path in @($policyPath, $templatePath, $registryPath, $ownerNetworkPath)) {
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "Structural optimization input is missing: $path" }
}

$policy = Get-Content -LiteralPath $policyPath -Raw -Encoding UTF8 | ConvertFrom-Json
$template = Get-Content -LiteralPath $templatePath -Raw -Encoding UTF8 | ConvertFrom-Json
$registry = Get-Content -LiteralPath $registryPath -Raw -Encoding UTF8 | ConvertFrom-Json
$ownerNetwork = Get-Content -LiteralPath $ownerNetworkPath -Raw -Encoding UTF8 | ConvertFrom-Json
$required = @($policy.required_optimizations)
$requiredIds = @($required | ForEach-Object { [string]$_.id })
function Get-NormalizedTextSha256([string]$Path) {
    $utf8 = [Text.UTF8Encoding]::new($false, $true)
    $text = [IO.File]::ReadAllText($Path, $utf8)
    $normalized = $text -replace "`r`n", "`n" -replace "`r", "`n"
    $sha256 = [Security.Cryptography.SHA256]::Create()
    try {
        return ([BitConverter]::ToString($sha256.ComputeHash($utf8.GetBytes($normalized)))).Replace('-', '').ToLowerInvariant()
    } finally {
        $sha256.Dispose()
    }
}

$baselineSha256 = Get-NormalizedTextSha256 $policyPath
if ($policy.status -ne 'active' -or $requiredIds.Count -eq 0 -or @($requiredIds | Sort-Object -Unique).Count -ne $requiredIds.Count) {
    throw 'Structural optimization policy is inactive, empty, or contains duplicate ids.'
}

$templateInheritance = $template.structural_optimization_inheritance
if (-not $templateInheritance -or $templateInheritance.baseline_id -ne $policy.baseline_id -or $templateInheritance.baseline_version -ne $policy.baseline_version -or $templateInheritance.baseline_sha256 -ne $baselineSha256) {
    throw 'Minimal Agent template is stale against the structural optimization policy.'
}
$missingTemplateIds = @($requiredIds | Where-Object { $_ -notin @($templateInheritance.required_optimization_ids) })
$extraTemplateIds = @($templateInheritance.required_optimization_ids | Where-Object { $_ -notin $requiredIds })
if ($missingTemplateIds.Count -gt 0 -or $extraTemplateIds.Count -gt 0) {
    throw "Minimal Agent template optimization ids are not synchronized. Missing: $($missingTemplateIds -join ', '); extra: $($extraTemplateIds -join ', ')"
}
if ($templateInheritance.inheritance_mode -ne $policy.default_inheritance_mode -or @($templateInheritance.profile_fit_dimensions).Count -eq 0 -or [string]::IsNullOrWhiteSpace([string]$templateInheritance.adaptation_rule)) {
    throw 'Minimal Agent template lacks the current adaptive learning optimization contract.'
}

$registeredMatches = @(
    @($registry.root_agent | Where-Object id -eq $AgentId) +
    @($registry.concept_agents | Where-Object id -eq $AgentId) +
    @($registry.child_agent_profiles | Where-Object id -eq $AgentId) +
    @($ownerNetwork.owners | Where-Object owner -eq $AgentId)
)
if ($registeredMatches.Count -ne 1) { throw "Structural optimization snapshot requires exactly one registered Agent: $AgentId" }
$profile = @($registry.child_agent_profiles | Where-Object id -eq $AgentId)
$inheritanceMode = 'template-direct'
$domainAdaptation = $null
$profileFitSummary = $null
$functionalEffects = @()
$adaptationEvidenceRequired = @($templateInheritance.adaptation_evidence_required)
if ($profile.Count -eq 1) {
    $inheritanceMode = 'registered-profile-adapter'
    $declared = $profile[0].structural_optimization_inheritance
    if (-not $declared -or $declared.status -ne 'synchronized' -or $declared.baseline_id -ne $policy.baseline_id -or $declared.baseline_version -ne $policy.baseline_version -or $declared.baseline_sha256 -ne $baselineSha256) {
        throw "Named child Agent profile is stale against the structural optimization baseline: $AgentId"
    }
    $missingProfileIds = @($requiredIds | Where-Object { $_ -notin @($declared.required_optimization_ids) })
    $extraProfileIds = @($declared.required_optimization_ids | Where-Object { $_ -notin $requiredIds })
    if ($missingProfileIds.Count -gt 0 -or $extraProfileIds.Count -gt 0) {
        throw "Named child Agent profile optimization ids are not synchronized: $AgentId"
    }
    if ($declared.inheritance_mode -ne $policy.default_inheritance_mode) {
        throw "Named child Agent profile has the wrong optimization inheritance mode: $AgentId"
    }
    $functionalEffects = @($declared.functional_effects | ForEach-Object { [string]$_ })
    if ([string]::IsNullOrWhiteSpace([string]$declared.profile_fit_summary) -or [string]::IsNullOrWhiteSpace([string]$declared.domain_adaptation) -or $functionalEffects.Count -eq 0) {
        throw "Named child Agent profile lacks adaptive functional optimization evidence: $AgentId"
    }
    $domainAdaptation = $declared.domain_adaptation
    $profileFitSummary = $declared.profile_fit_summary
    $adaptationEvidenceRequired = @($declared.adaptation_evidence_required)
} elseif ($profile.Count -gt 1) {
    throw "Child Agent profile is duplicated: $AgentId"
}

[pscustomobject][ordered]@{
    schema_version = 1
    model = 'agent-structural-optimization-snapshot'
    status = 'synchronized'
    agent_id = $AgentId
    baseline_id = [string]$policy.baseline_id
    baseline_version = [string]$policy.baseline_version
    baseline_sha256 = $baselineSha256
    policy = 'config/agent-structural-optimization-policy.json'
    policy_sha256 = $baselineSha256
    template = 'config/minimal-agent-template.json'
    template_sha256 = (Get-FileHash -LiteralPath $templatePath -Algorithm SHA256).Hash.ToLowerInvariant()
    inheritance_mode = $inheritanceMode
    default_inheritance_mode = [string]$policy.default_inheritance_mode
    adaptation_rule = [string]$policy.adaptation_rule
    functional_effect_rule = [string]$policy.functional_effect_rule
    profile_fit_dimensions = @($policy.profile_fit_dimensions)
    adaptation_evidence_required = @($adaptationEvidenceRequired)
    required_optimization_ids = $requiredIds
    optimizations = $required
    domain_adaptation = $domainAdaptation
    profile_fit_summary = $profileFitSummary
    functional_effects = @($functionalEffects)
} | ConvertTo-Json -Depth 12
