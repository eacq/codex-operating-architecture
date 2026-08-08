[CmdletBinding()]
param([string]$RepositoryRoot = 'F:\codex')

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath $RepositoryRoot).Path

function Read-Json([string]$RelativePath) {
    $path = Join-Path $root $RelativePath
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        throw "Required file is missing: $RelativePath"
    }
    Get-Content -LiteralPath $path -Raw -Encoding UTF8 | ConvertFrom-Json
}

function Read-Text([string]$RelativePath) {
    $path = Join-Path $root $RelativePath
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        throw "Required file is missing: $RelativePath"
    }
    Get-Content -LiteralPath $path -Raw -Encoding UTF8
}

$policy = Read-Json 'config\agent-skill-invocation-policy.json'
$system = Read-Json 'config\agent-system.json'
$interfacePolicy = Read-Json 'config\agent-interface-policy.json'
$knowledge = Read-Text 'knowledge-vault\30-Knowledge\Agent Skill Invocation Governance.md'
$registry = Read-Json 'module-registry.json'

if ($policy.model -ne 'global-experience-agent-skill-invocation-policy') {
    throw 'Agent skill invocation policy model name is incorrect.'
}
if ($policy.source.primary -ne 'https://github.com/mattpocock/skills' -or $policy.source.commit -ne 'ed37663cc5fbef691ddfecd080dff42f7e7e350d') {
    throw 'Agent skill invocation policy does not pin the reviewed mattpocock/skills source.'
}
foreach ($requiredSource in @('README.md', 'skills/productivity/writing-great-skills/SKILL.md', 'skills/engineering/tdd/SKILL.md', 'skills/engineering/diagnosing-bugs/SKILL.md', 'skills/engineering/code-review/SKILL.md', 'skills/engineering/to-tickets/SKILL.md', 'skills/engineering/wayfinder/SKILL.md')) {
    if ($requiredSource -notin @($policy.source.source_evidence)) {
        throw "Agent skill invocation policy is missing source evidence: $requiredSource"
    }
}
if ($policy.source.installation_decision -ne 'do-not-install-upstream-skills-by-default') {
    throw 'Upstream mattpocock skills must not be installed by default.'
}

$modelInvoked = $policy.invocation_classes.model_invoked
$userInvoked = $policy.invocation_classes.user_invoked
foreach ($caller in @('human', 'llm', 'internal-functional-unit', 'global-control')) {
    if ($caller -notin @($modelInvoked.allowed_callers)) {
        throw "Model-invoked local mapping is missing caller: $caller"
    }
}
foreach ($deniedCaller in @('llm', 'internal-functional-unit')) {
    if ($deniedCaller -in @($userInvoked.allowed_callers)) {
        throw "$deniedCaller must not be able to directly invoke human-only workflows."
    }
}
foreach ($requiredCaller in @('human', 'global-control')) {
    if ($requiredCaller -notin @($userInvoked.allowed_callers)) {
        throw "User-invoked local mapping is missing caller: $requiredCaller"
    }
}
if ([string]$userInvoked.structural_rule -notmatch 'must not silently invoke another human-only workflow') {
    throw 'User-invoked structural rule must block chained human-only auto-invocation.'
}

foreach ($requiredPolicyText in @(
    'leading word',
    'one trigger branch',
    'max_recommended_description_chars',
    'max_owner_internal_description_chars',
    'max_imported_wrapper_description_chars',
    'parent_skill_rule',
    'subskill_rule',
    'merge_rule',
    'split_rule',
    'concept_agent_rule',
    'completion_criterion',
    'context pointer',
    'one source of truth',
    'tracer-bullet',
    'expand-contract',
    'red-capable',
    'pre-agreed seams',
    'two separate axes',
    'deep modules'
)) {
    $joinedPolicy = $policy | ConvertTo-Json -Depth 10
    if ($joinedPolicy -notmatch [regex]::Escape($requiredPolicyText)) {
        throw "Agent skill invocation policy is missing adapted concept: $requiredPolicyText"
    }
}

foreach ($workflow in @('alignment', 'task_slicing', 'implementation', 'debugging', 'review', 'module_design')) {
    if (-not $policy.workflow_adaptations.PSObject.Properties.Name.Contains($workflow)) {
        throw "Agent skill invocation policy is missing workflow adaptation: $workflow"
    }
}

$activeOwners = @($registry.modules | Where-Object { $_.status -eq 'active' } | ForEach-Object { [string]$_.name } | Sort-Object)
$topLevelSkillFiles = @(Get-ChildItem -LiteralPath (Join-Path $root 'skills') -Directory | ForEach-Object {
    $skillPath = Join-Path $_.FullName 'SKILL.md'
    if (Test-Path -LiteralPath $skillPath -PathType Leaf) { $skillPath }
})
$topLevelSkillNames = @()
$overLongDescriptions = @()
$descriptionLimit = [int]$policy.information_hierarchy.model_visible_surface.max_recommended_description_chars
foreach ($skillPath in $topLevelSkillFiles) {
    $text = Get-Content -LiteralPath $skillPath -Raw -Encoding UTF8
    if ($text -notmatch '(?ms)^---\s*(.*?)^---') {
        throw "Top-level skill is missing YAML frontmatter: $skillPath"
    }
    $frontmatter = $Matches[1]
    if ($frontmatter -notmatch '(?m)^name:\s*(.+?)\s*$') {
        throw "Top-level skill frontmatter is missing name: $skillPath"
    }
    $name = $Matches[1].Trim()
    $topLevelSkillNames += $name
    if ($frontmatter -notmatch '(?m)^description:\s*(.+?)\s*$') {
        throw "Top-level skill frontmatter is missing description: $skillPath"
    }
    $description = $Matches[1].Trim()
    if ($description.Length -gt $descriptionLimit) {
        $overLongDescriptions += "$name=$($description.Length)"
    }
}
$missingOwnerSkill = @($activeOwners | Where-Object { $_ -notin $topLevelSkillNames })
$extraTopLevelSkill = @($topLevelSkillNames | Where-Object { $_ -notin $activeOwners })
if ($missingOwnerSkill.Count -or $extraTopLevelSkill.Count) {
    throw "Top-level skill surface does not match active owners. Missing: $($missingOwnerSkill -join ', '); extra: $($extraTopLevelSkill -join ', ')"
}
if ($topLevelSkillNames.Count -ne [int]$policy.information_hierarchy.model_visible_surface.active_top_level_owner_count) {
    throw 'Agent skill invocation policy active top-level owner count is stale.'
}
if ($overLongDescriptions.Count) {
    throw "Top-level model-visible descriptions exceed $descriptionLimit chars: $($overLongDescriptions -join ', ')"
}

$ownerInternalDescriptionLimit = [int]$policy.information_hierarchy.model_visible_surface.max_owner_internal_description_chars
$ownerInternalSkillFiles = @(Get-ChildItem -LiteralPath (Join-Path $root 'skills') -Recurse -Filter 'SKILL.md' | Where-Object {
    $_.FullName -notmatch '\\upstream\\' -and
    $_.FullName -notmatch '\\imported-codex-home\\[^\\]+\\SKILL\.md$' -and
    $_.FullName -notin $topLevelSkillFiles
})
$overLongOwnerInternalDescriptions = @()
foreach ($skillFile in $ownerInternalSkillFiles) {
    $text = Get-Content -LiteralPath $skillFile.FullName -Raw -Encoding UTF8
    if ($text -notmatch '(?ms)^---\s*(.*?)^---') {
        throw "Owner-internal skill is missing YAML frontmatter: $($skillFile.FullName)"
    }
    $frontmatter = $Matches[1]
    if ($frontmatter -notmatch '(?m)^description:\s*(.+?)\s*$') {
        throw "Owner-internal skill frontmatter is missing description: $($skillFile.FullName)"
    }
    $description = $Matches[1].Trim()
    if ($description.Length -gt $ownerInternalDescriptionLimit) {
        $relative = $skillFile.FullName.Substring($root.Length).TrimStart('\') -replace '\\', '/'
        $overLongOwnerInternalDescriptions += "$relative=$($description.Length)"
    }
}
if ($overLongOwnerInternalDescriptions.Count) {
    throw "Owner-internal model-visible descriptions exceed $ownerInternalDescriptionLimit chars: $($overLongOwnerInternalDescriptions -join ', ')"
}

$importedWrapperLimit = [int]$policy.information_hierarchy.model_visible_surface.max_imported_wrapper_description_chars
$importedWrapperFiles = @(Get-ChildItem -LiteralPath (Join-Path $root 'skills') -Recurse -Filter 'SKILL.md' | Where-Object {
    $_.FullName -match '\\imported-codex-home\\[^\\]+\\SKILL\.md$' -and $_.FullName -notmatch '\\upstream\\'
})
if ($importedWrapperFiles.Count -lt 1) { throw 'No imported Codex Home compatibility wrappers were found.' }
$badImportedWrappers = @()
foreach ($wrapperPath in $importedWrapperFiles) {
    $relative = $wrapperPath.FullName.Substring($root.Length).TrimStart('\') -replace '\\', '/'
    $parts = @($relative -split '/')
    $owner = $parts[1]
    $package = $parts[4]
    $wrapperText = Get-Content -LiteralPath $wrapperPath.FullName -Raw -Encoding UTF8
    if ($wrapperText -notmatch '(?ms)^---\s*(.*?)^---') {
        $badImportedWrappers += "$relative missing-frontmatter"
        continue
    }
    $wrapperFrontmatter = $Matches[1]
    $wrapperName = if ($wrapperFrontmatter -match '(?m)^name:\s*(.+?)\s*$') { $Matches[1].Trim() } else { '' }
    $wrapperDescription = if ($wrapperFrontmatter -match '(?m)^description:\s*(.+?)\s*$') { $Matches[1].Trim() } else { '' }
    $upstreamSkill = Join-Path $wrapperPath.Directory.FullName 'upstream\SKILL.md'
    if ($wrapperName -ne "imported-$package") { $badImportedWrappers += "$relative wrong-name=$wrapperName" }
    if ($wrapperDescription.Length -gt $importedWrapperLimit) { $badImportedWrappers += "$relative description-too-long=$($wrapperDescription.Length)" }
    if ($wrapperDescription -notmatch [regex]::Escape("Codex Home import '$package'; use through $owner, never as a top-level entry.")) {
        $badImportedWrappers += "$relative nonstandard-description"
    }
    if (-not (Test-Path -LiteralPath $upstreamSkill -PathType Leaf)) {
        $badImportedWrappers += "$relative missing-upstream-skill"
    }
}
if ($badImportedWrappers.Count) {
    throw "Imported Codex Home compatibility wrapper economy failed: $($badImportedWrappers -join '; ')"
}

foreach ($relativePath in @(
    'knowledge-vault/30-Knowledge/Agent Skill Invocation Governance.md',
    'config/agent-skill-invocation-policy.json',
    'scripts/Test-AgentSkillInvocationPolicy.ps1'
)) {
    if ($relativePath -notin @($system.resources.information_units + $system.resources.functional_units)) {
        throw "Agent system resources do not register: $relativePath"
    }
}

if ($interfacePolicy.interfaces.Count -ne 4 -or [string]$interfacePolicy.default_decision -ne 'deny') {
    throw 'Agent interface policy must remain default-deny with four caller interfaces.'
}
foreach ($operation in @('StartWork', 'RouteOwner', 'CandidateReport')) {
    if ([string]$interfacePolicy.operation_permissions.$operation -ne 'functional-unit-use') {
        throw "Invocation governance must not alter operation permission: $operation"
    }
}
if ([string]$interfacePolicy.operation_permissions.RequestStructureChange -ne 'agent-structure') {
    throw 'Invocation governance must preserve the agent_structure gate for structural changes.'
}

foreach ($requiredKnowledge in @(
    'mattpocock/skills',
    'ed37663cc5fbef691ddfecd080dff42f7e7e350d',
    'Human-only orchestration',
    'Model-reachable discipline',
    'tracer-bullet',
    'red-capable',
    'Two-axis review',
    '[[Global Experience System]]',
    '[[Learning Governance]]'
)) {
    if ($knowledge -notmatch [regex]::Escape($requiredKnowledge)) {
        throw "Agent Skill Invocation Governance note is missing: $requiredKnowledge"
    }
}

[pscustomobject][ordered]@{
    status = 'passed'
    model = 'agent-skill-invocation-policy'
    source = $policy.source.primary
    commit = $policy.source.commit
    invocation_classes = @($policy.invocation_classes.PSObject.Properties).Count
    workflow_adaptations = @($policy.workflow_adaptations.PSObject.Properties).Count
    active_top_level_owner_count = $topLevelSkillNames.Count
    max_description_chars = $descriptionLimit
    owner_internal_skill_count = $ownerInternalSkillFiles.Count
    max_owner_internal_description_chars = $ownerInternalDescriptionLimit
    imported_wrapper_count = $importedWrapperFiles.Count
    max_imported_wrapper_chars = $importedWrapperLimit
} | ConvertTo-Json -Compress
