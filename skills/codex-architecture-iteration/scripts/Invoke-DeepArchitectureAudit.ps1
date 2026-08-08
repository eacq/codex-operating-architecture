[CmdletBinding()]
param(
    [string]$ProjectRoot = 'F:\codex',
    [string]$OutputPath,
    [switch]$Apply
)

# Evidence-only deep audit for owner boundaries, intermediate Agent layers,
# information/functional-unit links, child profiles, and runtime projections.
# It proposes review candidates; it never mutates owner structure.

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath $ProjectRoot).Path
if (-not $OutputPath) {
    $OutputPath = Join-Path $root '.codex\project\deep-architecture-audit.json'
}

function Read-JsonFile([string]$Path) {
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "Required architecture evidence is missing: $Path"
    }
    return Get-Content -LiteralPath $Path -Raw -Encoding UTF8 | ConvertFrom-Json
}

function Get-WordSet([object]$Values) {
    $stop = @('the', 'and', 'or', 'of', 'to', 'for', 'with', 'from', 'through', 'agent', 'owner', 'system', 'current', 'local', 'verified', 'evidence', 'data')
    $words = New-Object System.Collections.Generic.HashSet[string]
    foreach ($value in @($Values)) {
        foreach ($word in ([string]$value).ToLowerInvariant() -split '[^a-z0-9_-]+') {
            if ($word.Length -ge 4 -and $stop -notcontains $word) { [void]$words.Add($word) }
        }
    }
    return $words
}

$moduleRegistry = Read-JsonFile (Join-Path $root 'module-registry.json')
$ownerNetwork = Read-JsonFile (Join-Path $root 'config\agent-owner-connections.json')
$agentRegistry = Read-JsonFile (Join-Path $root 'config\global-experience-agent-registry.json')
$agentSystem = Read-JsonFile (Join-Path $root 'config\agent-system.json')
$topologyPath = Join-Path $root '.codex\project\unit-topology-review.json'
$topology = if (Test-Path -LiteralPath $topologyPath -PathType Leaf) { Read-JsonFile $topologyPath } else { $null }

$activeModules = @($moduleRegistry.modules | Where-Object { $_.status -eq 'active' })
$moduleIds = @($activeModules | ForEach-Object { [string]$_.name })
$owners = @($ownerNetwork.owners)
$ownerIds = @($owners | ForEach-Object { [string]$_.owner })
$missingOwners = @($moduleIds | Where-Object { $ownerIds -notcontains $_ })
$orphanOwners = @($ownerIds | Where-Object { $moduleIds -notcontains $_ })
$missingSkills = @($owners | Where-Object { -not (Test-Path -LiteralPath (Join-Path $root ([string]$_.skill)) -PathType Leaf) } | ForEach-Object { [string]$_.owner })

$concepts = @($agentRegistry.concept_agents)
$conceptCoverage = [ordered]@{}
foreach ($id in $moduleIds) {
    $conceptCoverage[$id] = @($concepts | Where-Object { @($_.owners) -contains $id } | ForEach-Object { [string]$_.id })
}

$childProfiles = @($agentRegistry.child_agent_profiles)
$childRequiredFields = @('id', 'parent_concept', 'owner', 'skill', 'allowed_operations', 'denied_operations', 'authority_boundary')
$childProfileGaps = @()
foreach ($profile in $childProfiles) {
    $missing = @($childRequiredFields | Where-Object {
        $property = $profile.PSObject.Properties[$_]
        $null -eq $property -or [string]::IsNullOrWhiteSpace([string]$property.Value)
    })
    if ($missing.Count -gt 0) {
        $childProfileGaps += [ordered]@{ id = [string]$profile.id; missing = $missing }
    }
}

$overlapCandidates = @()
for ($i = 0; $i -lt $owners.Count; $i++) {
    for ($j = $i + 1; $j -lt $owners.Count; $j++) {
        $left = $owners[$i]
        $right = $owners[$j]
        $leftWords = Get-WordSet @($left.triggers, $left.consumes, $left.produces)
        $rightWords = Get-WordSet @($right.triggers, $right.consumes, $right.produces)
        $intersection = @($leftWords | Where-Object { $rightWords.Contains($_) })
        $union = New-Object System.Collections.Generic.HashSet[string]
        foreach ($word in $leftWords) { [void]$union.Add($word) }
        foreach ($word in $rightWords) { [void]$union.Add($word) }
        if ($union.Count -gt 0) {
            $score = [Math]::Round(($intersection.Count / $union.Count), 3)
            if ($score -ge 0.35 -and $intersection.Count -ge 2) {
                $overlapCandidates += [ordered]@{
                    kind = 'boundary-overlap-review'
                    left_owner = [string]$left.owner
                    right_owner = [string]$right.owner
                    shared_terms = @($intersection | Sort-Object)
                    jaccard = $score
                    disposition = 'review-only; compare trigger, artifact, knowledge, and safety boundaries'
                }
            }
        }
    }
}

$candidateRecommendations = @(
    'Use overlap candidates as review prompts; do not merge or split from lexical similarity alone.',
    'Prefer owner-internal refinement or a typed information/functional link when trigger and safety boundaries remain distinct.',
    'Require two independent use cases plus rollback and equivalent validation before adding or changing a top-level owner.',
    'Synchronize the structural baseline and all named child profiles before delegating after a reusable structure change.'
)

$result = [ordered]@{
    schema_version = 1
    result = 'deep-architecture-audit'
    audit_mode = 'evidence-only'
    project_root = $root
    baseline = [ordered]@{
        active_top_level_owners = $activeModules.Count
        owner_network_entries = $owners.Count
        information_units = if ($topology) { [int]$topology.information_unit_count } else { $null }
        functional_units = if ($topology) { [int]$topology.functional_unit_count } else { $null }
        functional_units_with_information_refs = if ($topology) { [int]$topology.bidirectional_link_health.functional_units_with_information_refs } else { $null }
        information_units_with_functional_refs = if ($topology) { [int]$topology.bidirectional_link_health.information_units_with_functional_refs } else { $null }
        concept_agents = $concepts.Count
        child_profiles = $childProfiles.Count
    }
    structural_health = [ordered]@{
        missing_owner_connections = $missingOwners
        orphan_owner_connections = $orphanOwners
        missing_owner_skills = $missingSkills
        child_profile_gaps = $childProfileGaps
        concept_coverage = $conceptCoverage
        agent_system_status = [string]$agentSystem.status
        topology_result = if ($topology) { [string]$topology.result } else { 'missing-review-artifact' }
    }
    candidates = $overlapCandidates
    recommendations = $candidateRecommendations
    mutation = [ordered]@{
        changed = $false
        rollback_required = $false
        execution_boundary = 'codex-architecture-iteration owner plus agent_structure gate'
    }
    generated_at = [DateTime]::UtcNow.ToString('o')
}

if ($Apply) {
    $parent = Split-Path -Parent $OutputPath
    New-Item -ItemType Directory -Force -Path $parent | Out-Null
    $json = $result | ConvertTo-Json -Depth 30
    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($OutputPath, $json, $utf8NoBom)
}

$result | ConvertTo-Json -Depth 30
