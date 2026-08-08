[CmdletBinding(PositionalBinding = $false)]
param(
    [string]$RepositoryRoot = 'F:\codex',
    [Parameter(Mandatory = $true)]
    [string]$Goal,
    [string]$ChildId,
    [string]$AgentId,
    [string]$Owner,
    [string]$SessionId,
    [string]$StateRoot,
    [ValidateSet('human', 'llm', 'internal-functional-unit', 'global-control')]
    [string]$Interface = 'human',
    [ValidateSet('none', 'functional', 'gated', 'global-structure')]
    [string]$AuthorityScope = 'functional',
    [string]$Authority = 'current caller has bounded functional authority',
    [string[]]$WriteSurface = @(),
    [string[]]$ReadSurface = @(),
    [string[]]$AcceptanceCriteria = @(),
    [string]$Verification,
    [string[]]$Inputs = @(),
    [string[]]$ExcludedScope = @(),
    [switch]$Delegate,
    [switch]$Apply
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath $RepositoryRoot).Path
$templatePath = Join-Path $root 'config\minimal-agent-template.json'
$registryPath = Join-Path $root 'config\global-experience-agent-registry.json'
$networkPath = Join-Path $root 'config\agent-owner-connections.json'
$controller = Join-Path $root 'agent\40-runtime\Invoke-GlobalExperienceAgent.ps1'
foreach ($path in @($templatePath, $registryPath, $networkPath, $controller)) {
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "Required Agent template input is missing: $path" }
}

$template = Get-Content -LiteralPath $templatePath -Raw -Encoding UTF8 | ConvertFrom-Json
$registry = Get-Content -LiteralPath $registryPath -Raw -Encoding UTF8 | ConvertFrom-Json
$network = Get-Content -LiteralPath $networkPath -Raw -Encoding UTF8 | ConvertFrom-Json
if ($template.model -ne 'minimal-agent-architecture-template') { throw 'Minimal Agent template model is invalid.' }

function New-SafeChildId([string]$Text) {
    $normalized = ($Text.ToLowerInvariant() -replace '[^a-z0-9]+', '-').Trim('-')
    if ($normalized.Length -gt 36) { $normalized = $normalized.Substring(0, 36).Trim('-') }
    if ([string]::IsNullOrWhiteSpace($normalized)) { $normalized = 'child-agent' }
    return $normalized + '-' + ([Guid]::NewGuid().ToString('N').Substring(0, 8))
}

function Select-AgentProfile([string]$Text) {
    $lower = $Text.ToLowerInvariant()
    if ($lower -match 'release|git|commit|push|tag|credential|runtime|install|file|folder') { return 'platform-agent' }
    if ($lower -match 'write|draft|docx|word|image|figure|diagram|readme|deliver|slide') { return 'delivery-agent' }
    if ($lower -match 'memory|experience|knowledge|learn|failure|error|feedback') { return 'experience-memory-agent' }
    if ($lower -match 'architecture|agent|skill|owner|template|refactor|evolution') { return 'self-evolution-agent' }
    return [string]$template.profile_rule.default_profile
}

if (-not [string]::IsNullOrWhiteSpace($Owner)) { $AgentId = $Owner }
if ([string]::IsNullOrWhiteSpace($AgentId)) { $AgentId = Select-AgentProfile $Goal }
if ([string]::IsNullOrWhiteSpace($ChildId)) { $ChildId = New-SafeChildId $Goal }
if (@($AcceptanceCriteria).Count -eq 0) { $AcceptanceCriteria = @('task result is produced or a blocked boundary is reported with evidence') }
if ([string]::IsNullOrWhiteSpace($Verification)) { $Verification = 'parent verifies repository-relative evidence or explicit blocked state before JoinSubagent' }
if (@($WriteSurface).Count -eq 0) { $WriteSurface = @(".runtime/work/$ChildId") }
if (@($ReadSurface).Count -eq 0) { $ReadSurface = @('selected project evidence and registered Agent resources') }

$concept = @($registry.concept_agents | Where-Object id -eq $AgentId)
$childProfile = @($registry.child_agent_profiles | Where-Object id -eq $AgentId)
$specialist = @($network.owners | Where-Object owner -eq $AgentId)
if ($concept.Count -eq 1) {
    $profileKind = 'concept'
    $owners = @($concept[0].owners)
    $resources = @($concept[0].resources)
} elseif ($childProfile.Count -eq 1) {
    $profileKind = 'child'
    $owners = @($childProfile[0].owners)
    $resources = @($childProfile[0].resources)
} elseif ($specialist.Count -eq 1) {
    $profileKind = 'specialist'
    $owners = @($specialist[0].owner)
    $resources = @($specialist[0].skill)
} else {
    throw "Agent profile is not registered as a concept, specialist, or named child Agent: $AgentId"
}
$optimizationSnapshot = & (Join-Path $root 'agent\40-runtime\Get-AgentStructuralOptimizationSnapshot.ps1') -RepositoryRoot $root -AgentId $AgentId | ConvertFrom-Json

$plan = [ordered]@{
    schema_version = 1
    model = 'minimal-agent-plan'
    result = 'designed'
    template = 'config/minimal-agent-template.json'
    root_controller = $template.root_controller
    child = [ordered]@{
        id = $ChildId
        agent_id = $AgentId
        profile_kind = $profileKind
        parent_session_id = $SessionId
        lifecycle = 'designed'
    }
    contract = [ordered]@{
        goal = $Goal
        inputs = @($Inputs)
        excluded_scope = @($ExcludedScope)
        authority_scope = $AuthorityScope
        authority_rule = 'inherits-current-authority-and-never-expands-it'
        interface = $Interface
        owners = @($owners)
        resources = @($resources)
        read_surfaces = @($ReadSurface)
        write_surfaces = @($WriteSurface)
        acceptance_criteria = @($AcceptanceCriteria)
        merge_verification = $Verification
        privacy_boundary = $template.privacy_rule
        error_feedback_route = 'codex-error-feedback'
        feynman_structural_scaffold = $template.feynman_structural_scaffold
        structural_optimization_snapshot = $optimizationSnapshot
    }
    lifecycle = [ordered]@{
        delegate = 'DelegateSubagent'
        complete = 'CompleteSubagent'
        join = 'JoinSubagent'
        cancel = 'CancelSubagent'
    }
    delegation_ready = (-not [string]::IsNullOrWhiteSpace($SessionId) -and $optimizationSnapshot.status -eq 'synchronized')
    delegation_command = [ordered]@{
        script = $template.root_controller
        mode = 'Continue'
        operation = 'DelegateSubagent'
        session_id = $SessionId
        agent_id = $AgentId
        child_id = $ChildId
        write_surface = @($WriteSurface)
        acceptance_criteria = @($AcceptanceCriteria)
        verification = $Verification
    }
}

if ($Delegate) {
    if (-not $Apply) { throw 'Delegation requires -Apply so child state is intentionally persisted.' }
    if ([string]::IsNullOrWhiteSpace($SessionId)) { throw 'Delegation requires -SessionId.' }
    $delegated = & $controller `
        -RepositoryRoot $root `
        -Mode Continue `
        -Operation DelegateSubagent `
        -SessionId $SessionId `
        -StateRoot $StateRoot `
        -Goal $Goal `
        -AgentId $AgentId `
        -ChildId $ChildId `
        -WriteSurface $WriteSurface `
        -AcceptanceCriteria $AcceptanceCriteria `
        -Verification $Verification `
        -Interface $Interface `
        -AuthorityScope $AuthorityScope `
        -Authority $Authority `
        -Apply | ConvertFrom-Json
    $plan.child.lifecycle = 'delegated'
    $plan.delegation = $delegated
}

[pscustomobject]$plan | ConvertTo-Json -Depth 20
