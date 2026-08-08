[CmdletBinding(PositionalBinding = $false)]
param(
    [string]$RepositoryRoot = 'F:\codex',
    [switch]$Apply
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath $RepositoryRoot).Path
$policyPath = Join-Path $root 'config\agent-structural-optimization-policy.json'
$templatePath = Join-Path $root 'config\minimal-agent-template.json'
$registryPath = Join-Path $root 'config\global-experience-agent-registry.json'
$manifestPath = Join-Path $root 'config\agent-system.json'
foreach ($path in @($policyPath, $templatePath, $registryPath, $manifestPath)) {
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "Structural optimization synchronization input is missing: $path" }
}

$policy = Get-Content -LiteralPath $policyPath -Raw -Encoding UTF8 | ConvertFrom-Json
$templateRaw = Get-Content -LiteralPath $templatePath -Raw -Encoding UTF8
$registryRaw = Get-Content -LiteralPath $registryPath -Raw -Encoding UTF8
$manifestRaw = Get-Content -LiteralPath $manifestPath -Raw -Encoding UTF8
$template = $templateRaw | ConvertFrom-Json
$registry = $registryRaw | ConvertFrom-Json
$manifest = $manifestRaw | ConvertFrom-Json
$templateBefore = $template | ConvertTo-Json -Depth 50 -Compress
$registryBefore = $registry | ConvertTo-Json -Depth 50 -Compress
$manifestBefore = $manifest | ConvertTo-Json -Depth 50 -Compress
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
$requiredIds = @($policy.required_optimizations | ForEach-Object { [string]$_.id })
if ($requiredIds.Count -eq 0 -or @($requiredIds | Sort-Object -Unique).Count -ne $requiredIds.Count) {
    throw 'Structural optimization policy must contain unique required optimization ids.'
}

function Set-ObjectProperty([object]$Object, [string]$Name, [object]$Value) {
    if ($Object.PSObject.Properties.Name -contains $Name) { $Object.$Name = $Value }
    else { $Object | Add-Member -NotePropertyName $Name -NotePropertyValue $Value }
}

function Get-DefaultFunctionalEffects([object]$Profile) {
    $id = [string]$Profile.id
    $operations = @($Profile.allowed_operations | ForEach-Object { [string]$_ })
    if ($id -eq 'visual-design-agent' -or ($operations -match 'visual|design|deck|diagram|figure|template|render|preview').Count -gt 0) {
        return @('routing', 'source-processing', 'retrieval', 'tool-use', 'output-quality', 'review', 'recovery', 'economy')
    }
    if ($id -eq 'career-planning-agent' -or ($operations -match 'career|life|cv|interview|offer|pipeline').Count -gt 0) {
        return @('routing', 'memory', 'source-processing', 'retrieval', 'output-quality', 'review', 'recovery', 'economy')
    }
    return @('routing', 'memory', 'source-processing', 'retrieval', 'output-quality', 'review', 'recovery')
}

$profileFitDimensions = @($policy.profile_fit_dimensions | ForEach-Object { [string]$_ })
$adaptationEvidenceRequired = @(
    'profile_fit_summary',
    'functional_effects',
    'domain_adaptation',
    'owner_contract_alignment',
    'quality_or_verification_gate',
    'authority_boundary'
)

$templateContract = [pscustomobject][ordered]@{
    source = 'config/agent-structural-optimization-policy.json'
    baseline_id = [string]$policy.baseline_id
    baseline_version = [string]$policy.baseline_version
    baseline_sha256 = $baselineSha256
    required_optimization_ids = $requiredIds
    synchronization_controller = 'agent/80-maintenance/Sync-ChildAgentStructuralOptimizations.ps1'
    runtime_snapshot_provider = 'agent/40-runtime/Get-AgentStructuralOptimizationSnapshot.ps1'
    inheritance_mode = [string]$policy.default_inheritance_mode
    profile_fit_dimensions = $profileFitDimensions
    adaptation_rule = [string]$policy.adaptation_rule
    functional_effect_rule = [string]$policy.functional_effect_rule
    adaptation_evidence_required = $adaptationEvidenceRequired
    rule = 'verified cross-Agent learning optimizations synchronize to the template and registered child profiles only after profile-fit adaptation; every delegation receives the current checked snapshot and profile functional adaptation'
}
Set-ObjectProperty $template 'structural_optimization_inheritance' $templateContract

$dynamicContract = [pscustomobject][ordered]@{
    source = 'config/agent-structural-optimization-policy.json'
    baseline_id = [string]$policy.baseline_id
    baseline_version = [string]$policy.baseline_version
    baseline_sha256 = $baselineSha256
    synchronization_controller = 'agent/80-maintenance/Sync-ChildAgentStructuralOptimizations.ps1'
    runtime_snapshot_provider = 'agent/40-runtime/Get-AgentStructuralOptimizationSnapshot.ps1'
    inheritance_mode = [string]$policy.default_inheritance_mode
    profile_fit_dimensions = $profileFitDimensions
    delegation_behavior = 'inject current snapshot and profile adaptation for every delegated Agent and fail closed when a named child profile is stale or lacks functional effect evidence'
}
Set-ObjectProperty $registry.dynamic_subagents 'structural_optimization_inheritance' $dynamicContract

$childCount = 0
foreach ($profile in @($registry.child_agent_profiles)) {
    $existing = $profile.structural_optimization_inheritance
    $domainAdaptation = if ($existing -and $existing.domain_adaptation) { [string]$existing.domain_adaptation } else { "Apply the shared baseline through the $($profile.id) domain contract without expanding authority." }
    $functionalEffects = if ($existing -and $existing.functional_effects) { @($existing.functional_effects | ForEach-Object { [string]$_ }) } else { @(Get-DefaultFunctionalEffects $profile) }
    $profileFitSummary = if ($existing -and $existing.profile_fit_summary) { [string]$existing.profile_fit_summary } else { "Adapt shared learning through $($profile.id) purpose, allowed operations, owner resources, output artifacts, verifier, and authority boundary before execution." }
    $profileContract = [pscustomobject][ordered]@{
        status = 'synchronized'
        baseline_id = [string]$policy.baseline_id
        baseline_version = [string]$policy.baseline_version
        baseline_sha256 = $baselineSha256
        required_optimization_ids = $requiredIds
        inheritance_mode = [string]$policy.default_inheritance_mode
        profile_fit_summary = $profileFitSummary
        functional_effects = $functionalEffects
        adaptation_evidence_required = $adaptationEvidenceRequired
        domain_adaptation = $domainAdaptation
    }
    Set-ObjectProperty $profile 'structural_optimization_inheritance' $profileContract
    $childCount++
}

$manifestContract = [pscustomobject][ordered]@{
    source = 'config/agent-structural-optimization-policy.json'
    baseline_id = [string]$policy.baseline_id
    baseline_version = [string]$policy.baseline_version
    baseline_sha256 = $baselineSha256
    required_optimization_ids = $requiredIds
    synchronization_controller = 'agent/80-maintenance/Sync-ChildAgentStructuralOptimizations.ps1'
    runtime_snapshot_provider = 'agent/40-runtime/Get-AgentStructuralOptimizationSnapshot.ps1'
    inheritance_mode = [string]$policy.default_inheritance_mode
    profile_fit_dimensions = $profileFitDimensions
    adaptation_evidence_required = $adaptationEvidenceRequired
    adoption_rule = 'a verified Global Experience Agent learning optimization is incomplete until it is adapted to affected child profiles, improves a declared functional effect, and aligns template, registered profiles, projections, and delegation snapshots'
}
Set-ObjectProperty $manifest.subagents 'structural_optimization_propagation' $manifestContract
foreach ($profile in @($manifest.subagents.named_profiles)) {
    $registryProfile = @($registry.child_agent_profiles | Where-Object id -eq $profile.id)
    $declared = if ($registryProfile.Count -eq 1) { $registryProfile[0].structural_optimization_inheritance } else { $null }
    $namedContract = [pscustomobject][ordered]@{
        status = 'synchronized'
        baseline_id = [string]$policy.baseline_id
        baseline_version = [string]$policy.baseline_version
        baseline_sha256 = $baselineSha256
        required_optimization_ids = $requiredIds
        inheritance_mode = [string]$policy.default_inheritance_mode
        profile_fit_summary = if ($declared) { $declared.profile_fit_summary } else { 'Adapt shared learning through the named child profile before execution.' }
        functional_effects = if ($declared) { @($declared.functional_effects) } else { @('routing', 'memory', 'source-processing', 'review') }
        adaptation_evidence_required = $adaptationEvidenceRequired
    }
    Set-ObjectProperty $profile 'structural_optimization_inheritance' $namedContract
}

$templateAfter = $template | ConvertTo-Json -Depth 50 -Compress
$registryAfter = $registry | ConvertTo-Json -Depth 50 -Compress
$manifestAfter = $manifest | ConvertTo-Json -Depth 50 -Compress
$driftedSurfaces = @()
if ($templateBefore -ne $templateAfter) { $driftedSurfaces += 'config/minimal-agent-template.json' }
if ($registryBefore -ne $registryAfter) { $driftedSurfaces += 'config/global-experience-agent-registry.json' }
if ($manifestBefore -ne $manifestAfter) { $driftedSurfaces += 'config/agent-system.json' }

$projectionStatus = 'not-requested'
if ($Apply) {
    $utf8NoBom = [Text.UTF8Encoding]::new($false)
    try {
        [IO.File]::WriteAllText($templatePath, (($template | ConvertTo-Json -Depth 50) + [Environment]::NewLine), $utf8NoBom)
        [IO.File]::WriteAllText($registryPath, (($registry | ConvertTo-Json -Depth 50) + [Environment]::NewLine), $utf8NoBom)
        [IO.File]::WriteAllText($manifestPath, (($manifest | ConvertTo-Json -Depth 50) + [Environment]::NewLine), $utf8NoBom)
        $projectionResult = & (Join-Path $root 'agent\80-maintenance\Sync-AgentFilesystem.ps1') -RepositoryRoot $root -Apply | ConvertFrom-Json
        if ($projectionResult.status -ne 'synchronized') { throw 'Agent filesystem projection synchronization did not settle.' }
        $projectionStatus = $projectionResult.status
    } catch {
        [IO.File]::WriteAllText($templatePath, $templateRaw, $utf8NoBom)
        [IO.File]::WriteAllText($registryPath, $registryRaw, $utf8NoBom)
        [IO.File]::WriteAllText($manifestPath, $manifestRaw, $utf8NoBom)
        & (Join-Path $root 'agent\80-maintenance\Sync-AgentFilesystem.ps1') -RepositoryRoot $root -Apply | Out-Null
        throw
    }
}

[pscustomobject][ordered]@{
    status = if ($Apply -or $driftedSurfaces.Count -eq 0) { 'passed' } else { 'drift' }
    model = 'child-agent-structural-optimization-sync'
    applied = [bool]$Apply
    baseline_id = $policy.baseline_id
    baseline_version = $policy.baseline_version
    baseline_sha256 = $baselineSha256
    required_optimization_count = $requiredIds.Count
    registered_child_count = $childCount
    drifted_surfaces = $driftedSurfaces
    projection_status = $projectionStatus
    synchronized_surfaces = @(
        'config/minimal-agent-template.json',
        'config/global-experience-agent-registry.json',
        'config/agent-system.json'
    )
} | ConvertTo-Json -Depth 6
