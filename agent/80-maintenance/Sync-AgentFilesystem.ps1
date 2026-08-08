[CmdletBinding()]
param(
    [string]$RepositoryRoot = 'F:\codex',
    [switch]$Apply
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath $RepositoryRoot).Path
$agentRoot = [IO.Path]::GetFullPath((Join-Path $root 'agent'))
$layout = Get-Content -LiteralPath (Join-Path $agentRoot 'agent-filesystem.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$system = Get-Content -LiteralPath (Join-Path $root 'config\agent-system.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$registry = Get-Content -LiteralPath (Join-Path $root 'config\global-experience-agent-registry.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$policy = Get-Content -LiteralPath (Join-Path $root 'config\agent-interface-policy.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$network = Get-Content -LiteralPath (Join-Path $root 'config\agent-owner-connections.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$minimalTemplate = Get-Content -LiteralPath (Join-Path $root 'config\minimal-agent-template.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$structuralOptimizationPolicy = Get-Content -LiteralPath (Join-Path $root 'config\agent-structural-optimization-policy.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$projection = [ordered]@{}

function Assert-AgentRelativePath([string]$RelativePath) {
    $full = [IO.Path]::GetFullPath((Join-Path $root $RelativePath.Replace('/', '\')))
    $prefix = $agentRoot.TrimEnd('\') + '\'
    if (-not $full.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)) {
        throw "Projection path escapes Agent root: $RelativePath"
    }
    return $full
}

function New-Projection([string]$Id, [string]$Kind, [string[]]$Sources, [System.Collections.IDictionary]$Body) {
    $item = [ordered]@{
        schema_version = 1
        generated_by = 'agent-filesystem-projection'
        projection_id = $Id
        kind = $Kind
        sources = @($Sources)
    }
    foreach ($key in $Body.Keys) { $item[$key] = $Body[$key] }
    return $item
}

function Add-Projection([string]$RelativePath, [object]$Value) {
    [void](Assert-AgentRelativePath $RelativePath)
    if ($projection.Contains($RelativePath)) { throw "Duplicate Agent projection target: $RelativePath" }
    $projection[$RelativePath] = $Value
}

$rootAgent = $registry.root_agent
Add-Projection 'agent/00-root/global-experience-agent/agent.json' (New-Projection 'root:global-experience-agent' 'root-agent' @('config/agent-system.json', 'config/global-experience-agent-registry.json') ([ordered]@{
    id = $rootAgent.id
    owner = $rootAgent.owner
    purpose = $rootAgent.purpose
    entrypoint = $rootAgent.entrypoint
    capabilities = @($rootAgent.capabilities)
    filesystem = 'agent/agent-filesystem.json'
    interfaces = @($policy.interfaces.id)
    concepts = @($registry.concept_agents.id)
    specialist_count = @($network.owners).Count
    exit_count = @($policy.exits).Count
}))

foreach ($interface in @($policy.interfaces | Sort-Object id)) {
    $id = [string]$interface.id
    Add-Projection "agent/10-interfaces/$id/interface.json" (New-Projection "interface:$id" 'interface' @('config/agent-interface-policy.json') ([ordered]@{
        id = $id
        audience = $interface.audience
        permissions = @($interface.permissions)
        structural_mutation = $interface.structural_mutation
        rule = $interface.rule
        default_decision = $policy.default_decision
        exits = @($policy.exits | Where-Object { @($_.audience) -contains $id } | ForEach-Object id)
    }))
}

foreach ($concept in @($registry.concept_agents | Sort-Object id)) {
    $id = [string]$concept.id
    Add-Projection "agent/20-agents/concepts/$id/agent.json" (New-Projection "concept:$id" 'concept-agent' @('config/global-experience-agent-registry.json') ([ordered]@{
        id = $id
        owners = @($concept.owners)
        resources = @($concept.resources)
        purpose = $concept.purpose
        child_policy = $registry.dynamic_subagents.policy
    }))
}

foreach ($owner in @($network.owners | Sort-Object owner)) {
    $id = [string]$owner.owner
    $incoming = @($network.connections | Where-Object to -eq $id)
    $outgoing = @($network.connections | Where-Object from -eq $id)
    Add-Projection "agent/20-agents/specialists/$id/agent.json" (New-Projection "specialist:$id" 'specialist-agent' @('config/global-experience-agent-registry.json', 'config/agent-owner-connections.json', [string]$owner.skill) ([ordered]@{
        id = $id
        owner = $id
        plane = $owner.plane
        stage = $owner.stage
        canonical_skill = $owner.skill
        triggers = @($owner.triggers)
        consumes = @($owner.consumes)
        produces = @($owner.produces)
        verification = $owner.verification
        tool_gate = $owner.tool_gate
        incoming = @($incoming | ForEach-Object { [ordered]@{ from = $_.from; artifact = $_.artifact; event = $_.event } })
        outgoing = @($outgoing | ForEach-Object { [ordered]@{ to = $_.to; artifact = $_.artifact; event = $_.event } })
        return_boundary = 'root Agent save point'
    }))
}

Add-Projection 'agent/20-agents/children/template/agent.json' (New-Projection 'child:template' 'child-agent-template' @('config/global-experience-agent-registry.json', 'config/minimal-agent-template.json') ([ordered]@{
    template = 'config/minimal-agent-template.json'
    id_pattern = 'parent-session/child-id'
    policy = $registry.dynamic_subagents.policy
    states = @($registry.dynamic_subagents.states)
    required_contract = @($registry.dynamic_subagents.required_contract)
    completion_contract = @($registry.dynamic_subagents.completion_contract)
    join_contract = @($registry.dynamic_subagents.join_contract)
    planner = 'skills/codex-experience-capture/scripts/New-MinimalAgentPlan.ps1'
    default_behavior = 'design-only unless called with Delegate and Apply from an idle parent session'
    safety = $registry.dynamic_subagents.safety
    structural_optimization_inheritance = $registry.dynamic_subagents.structural_optimization_inheritance
    structural_optimization_template = $minimalTemplate.structural_optimization_inheritance
}))

foreach ($child in @($registry.child_agent_profiles | Sort-Object id)) {
    $id = [string]$child.id
    Add-Projection "agent/20-agents/children/$id/agent.json" (New-Projection "child:$id" 'child-agent-profile' @('config/global-experience-agent-registry.json', 'config/minimal-agent-template.json', 'config/agent-structural-optimization-policy.json', [string]$child.skill) ([ordered]@{
        id = $id
        parent_concept = $child.parent_concept
        owner = $child.owner
        owners = @($child.owners)
        canonical_skill = $child.skill
        resources = @($child.resources)
        upstream_full_repository = $child.upstream_full_repository
        allowed_operations = @($child.allowed_operations)
        denied_operations = @($child.denied_operations)
        delegation_payload_policy = $child.delegation_payload_policy
        feynman_structural_scaffold = $child.feynman_structural_scaffold
        structural_optimization_inheritance = $child.structural_optimization_inheritance
        inherited_structural_optimizations = @($structuralOptimizationPolicy.required_optimizations)
        main_corpus_study_required = $child.main_corpus_study_required
        readability_gate = $child.readability_gate
        required_write_surface = $child.required_write_surface
        required_evidence = @($child.required_evidence)
        merge_verifier = $child.merge_verifier
        authority_boundary = $child.authority_boundary
        lifecycle = @($registry.dynamic_subagents.states)
        safety = $registry.dynamic_subagents.safety
        return_boundary = 'parent Global Experience Agent JoinSubagent save point'
    }))
}

Add-Projection 'agent/30-resources/information/catalog.json' (New-Projection 'resource:information' 'resource-catalog' @('config/agent-system.json') ([ordered]@{
    id = 'information'
    selection_policy = $system.resources.selection_policy
    units = @($system.resources.information_units)
    write_policy = 'canonical source remains at the referenced path'
}))
Add-Projection 'agent/30-resources/functional/catalog.json' (New-Projection 'resource:functional' 'resource-catalog' @('config/agent-system.json') ([ordered]@{
    id = 'functional'
    units = @($system.resources.functional_units)
    owner_rule = 'Owner Skills are referenced and never copied into the Agent tree'
}))

Add-Projection 'agent/40-runtime/runtime.json' (New-Projection 'runtime:controller' 'runtime-catalog' @('config/agent-system.json', 'agent/agent-filesystem.json') ([ordered]@{
    controller = $system.agent_runtime.controller
    implementation = $system.agent_runtime.implementation
    memory_backend = $layout.canonical_surfaces.memory_backend
    intent_policy = $layout.canonical_surfaces.intent_policy
    state_reader = $system.filesystem.state_reader
    modes = @($system.agent_runtime.modes)
    operations = @($system.agent_runtime.operations)
    durable_state_root = $system.agent_runtime.durable_state_root
    state_files = @($system.agent_runtime.state_files)
    compatibility_adapters = @($layout.compatibility_adapters)
}))

Add-Projection 'agent/50-evidence/evidence.json' (New-Projection 'evidence:catalog' 'evidence-catalog' @('config/agent-system.json', 'agent/agent-filesystem.json') ([ordered]@{
    session_state = $system.agent_runtime.durable_state_root
    agent_memory = '.codex/project/agent-memory'
    lifecycle_state = '.codex/project/state.json'
    project_experience = '.codex/project/EXPERIENCE.md'
    candidate_state = '.codex/project/experience-candidates.json'
    runtime_evidence = '.runtime/evidence'
    privacy_contract = $system.agent_runtime.privacy_contract
    tracked_payload_rule = 'derived evidence may be tracked only through its canonical owner and privacy gate'
}))

foreach ($exit in @($policy.exits | Sort-Object id)) {
    $id = [string]$exit.id
    Add-Projection "agent/60-exits/$id/exit.json" (New-Projection "exit:$id" 'agent-exit' @('config/agent-interface-policy.json') ([ordered]@{
        id = $id
        audience = @($exit.audience)
        status = $exit.status
        contract = $policy.exit_contract
    }))
}

Add-Projection 'agent/70-presentation/presentation.json' (New-Projection 'presentation:architecture' 'presentation-catalog' @('config/agent-system.json', 'config/agent-architecture-diagram.json') ([ordered]@{
    diagram_contract = 'config/agent-architecture-diagram.json'
    architecture_document = 'docs/AGENT-ARCHITECTURE.md'
    private_asset = 'docs/assets/codex-global-experience-agent-architecture.png'
    public_asset = 'docs/assets/public/codex-global-experience-agent-architecture.png'
    source_of_truth = 'Agent behavior comes from contracts and runtime; diagrams are generated views'
}))

Add-Projection 'agent/80-maintenance/maintenance.json' (New-Projection 'maintenance:filesystem' 'maintenance-catalog' @('agent/agent-filesystem.json') ([ordered]@{
    owner = $layout.filesystem_owner
    architecture_owner = $layout.architecture_owner
    sync = $layout.projection.generator
    resolver = $layout.projection.resolver
    test = $layout.projection.test
    protected_paths = @($layout.protected_paths)
    generated_file_count = $projection.Count + 1
}))

$drift = New-Object System.Collections.Generic.List[object]
foreach ($entry in $projection.GetEnumerator()) {
    $path = Assert-AgentRelativePath $entry.Key
    $expected = $entry.Value | ConvertTo-Json -Depth 40
    $actual = if (Test-Path -LiteralPath $path -PathType Leaf) { Get-Content -LiteralPath $path -Raw -Encoding UTF8 } else { $null }
    $expectedNormalized = ($expected | ConvertFrom-Json) | ConvertTo-Json -Depth 40 -Compress
    $actualNormalized = if ($actual) { ($actual | ConvertFrom-Json) | ConvertTo-Json -Depth 40 -Compress } else { $null }
    if ($expectedNormalized -ne $actualNormalized) {
        $drift.Add([pscustomobject]@{ path = $entry.Key; status = if ($actual) { 'changed' } else { 'missing' } })
    }
    if ($Apply) {
        $parent = Split-Path -Parent $path
        if (-not (Test-Path -LiteralPath $parent -PathType Container)) { [void](New-Item -ItemType Directory -Path $parent -Force) }
        $temp = "$path.$([Guid]::NewGuid().ToString('N')).tmp"
        [IO.File]::WriteAllText($temp, $expected + [Environment]::NewLine, [Text.UTF8Encoding]::new($false))
        Move-Item -LiteralPath $temp -Destination $path -Force
    }
}

$stale = New-Object System.Collections.Generic.List[string]
$scanRoots = @('agent/00-root', 'agent/10-interfaces', 'agent/20-agents', 'agent/30-resources', 'agent/50-evidence', 'agent/60-exits', 'agent/70-presentation')
$expectedPaths = @($projection.Keys | ForEach-Object { [IO.Path]::GetFullPath((Join-Path $root $_.Replace('/', '\'))) })
foreach ($scanRoot in $scanRoots) {
    $scanPath = Assert-AgentRelativePath ($scanRoot + '/placeholder.json') | Split-Path -Parent
    if (-not (Test-Path -LiteralPath $scanPath -PathType Container)) { continue }
    foreach ($file in @(Get-ChildItem -LiteralPath $scanPath -Recurse -File -Filter '*.json')) {
        if ($expectedPaths -contains $file.FullName) { continue }
        try { $candidate = Get-Content -LiteralPath $file.FullName -Raw -Encoding UTF8 | ConvertFrom-Json } catch { continue }
        if ($candidate.generated_by -eq 'agent-filesystem-projection') {
            $relative = $file.FullName.Substring($root.Length).TrimStart('\').Replace('\', '/')
            $stale.Add($relative)
            if ($Apply) { Remove-Item -LiteralPath $file.FullName -Force }
        }
    }
}

[pscustomobject][ordered]@{
    status = if ($Apply) { 'synchronized' } elseif ($drift.Count -eq 0 -and $stale.Count -eq 0) { 'in-sync' } else { 'drift' }
    agent_root = 'agent'
    expected_files = $projection.Count
    drift = @($drift | ForEach-Object { $_ })
    stale = @($stale | ForEach-Object { $_ })
    applied = [bool]$Apply
} | ConvertTo-Json -Depth 10
