[CmdletBinding()]
param(
    [string]$ProjectRoot = (Get-Location).Path,
    [string]$ArchitectureRoot = '',
    [switch]$Apply
)

$ErrorActionPreference = 'Stop'
$project = (Resolve-Path -LiteralPath $ProjectRoot).Path
if ([string]::IsNullOrWhiteSpace($ArchitectureRoot)) {
    $scriptRoot = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
    $ArchitectureRoot = (Resolve-Path -LiteralPath (Join-Path $scriptRoot '..\..\..')).Path
}
$architecture = (Resolve-Path -LiteralPath $ArchitectureRoot).Path
$registryPath = Join-Path $architecture 'module-registry.json'
$principlePath = Join-Path $architecture 'knowledge-vault\30-Knowledge\Information and Functional Unit Principle.md'
$knowledgeRoot = Join-Path $architecture 'knowledge-vault\30-Knowledge'
$skillsRoot = Join-Path $architecture 'skills'

foreach ($path in @($registryPath, $principlePath, $knowledgeRoot, $skillsRoot)) {
    if (-not (Test-Path -LiteralPath $path)) { throw "Unit topology review is missing required source: $path" }
}

function ConvertTo-RelativePath([string]$BasePath, [string]$FullPath) {
    $baseUri = [Uri]((Resolve-Path -LiteralPath $BasePath).Path.TrimEnd('\') + '\')
    $fullUri = [Uri](Resolve-Path -LiteralPath $FullPath).Path
    return [Uri]::UnescapeDataString($baseUri.MakeRelativeUri($fullUri).ToString()).Replace('/', '\')
}

function Test-TextReference([string]$Text, [string[]]$Terms) {
    foreach ($term in $Terms) {
        if ([string]::IsNullOrWhiteSpace($term)) { continue }
        if ($Text -match [regex]::Escape($term)) { return $true }
    }
    return $false
}

$registry = Get-Content -LiteralPath $registryPath -Raw -Encoding UTF8 | ConvertFrom-Json
$modules = @($registry.modules)
$activeOwners = @($modules | Where-Object { $_.status -eq 'active' } | Sort-Object name)
$deprecatedOwners = @($modules | Where-Object { $_.status -eq 'deprecated' } | Sort-Object name)
$ownerNames = @($modules | ForEach-Object { [string]$_.name })
$activeOwnerNames = @($activeOwners | ForEach-Object { [string]$_.name })

$knowledgeNotes = @(Get-ChildItem -LiteralPath $knowledgeRoot -Filter '*.md' -File)
$ownerSkillFiles = @(Get-ChildItem -LiteralPath $skillsRoot -Directory | ForEach-Object {
    $skillFile = Join-Path $_.FullName 'SKILL.md'
    if (Test-Path -LiteralPath $skillFile) { Get-Item -LiteralPath $skillFile }
})
$subskillFiles = @(Get-ChildItem -LiteralPath $skillsRoot -Recurse -Filter 'SKILL.md' -File | Where-Object { $_.FullName -match '\\subskills\\' })
$scriptExtensions = @('.ps1', '.py', '.js', '.mjs', '.ts')
$scriptFiles = @(Get-ChildItem -LiteralPath $skillsRoot -Recurse -File | Where-Object { $_.Extension -in $scriptExtensions })
$testFiles = @($scriptFiles | Where-Object { $_.Name -match '(^Test-|^test_|\.test\.)' })

$informationUnits = @($knowledgeNotes | ForEach-Object {
    $text = Get-Content -LiteralPath $_.FullName -Raw -Encoding UTF8
    [pscustomobject]@{
        name = $_.BaseName
        path = ConvertTo-RelativePath $architecture $_.FullName
        references_functional_unit = (Test-TextReference $text $ownerNames)
        references_principle = ($_.BaseName -eq 'Information and Functional Unit Principle' -or $text -match 'Information and Functional Unit Principle|information units|functional units')
    }
})

$functionalTerms = @('Information and Functional Unit Principle', 'Global Experience System', 'Learning Governance', 'Experience and Knowledge Architecture', 'Agent Skill Evolution Optimization', 'REQUIREMENTS.md', 'WORKFLOWS.md', 'EXPERIENCE.md', 'module-registry.json')
$functionalUnits = @($ownerSkillFiles + $subskillFiles + $scriptFiles | Sort-Object FullName -Unique | ForEach-Object {
    $text = Get-Content -LiteralPath $_.FullName -Raw -Encoding UTF8
    $kind = if ($_.Name -eq 'SKILL.md' -and $_.FullName -notmatch '\\subskills\\') { 'owner-skill' } elseif ($_.Name -eq 'SKILL.md') { 'owner-internal-subskill' } elseif ($_.Name -match '(^Test-|^test_|\.test\.)') { 'test-or-validator' } else { 'script-or-implementation' }
    [pscustomobject]@{
        name = $_.BaseName
        kind = $kind
        path = ConvertTo-RelativePath $architecture $_.FullName
        references_information_unit = (Test-TextReference $text $functionalTerms)
    }
})

$missingOwnerSkills = @($activeOwners | Where-Object { -not (Test-Path -LiteralPath (Join-Path $skillsRoot "$($_.name)\SKILL.md")) } | ForEach-Object { [string]$_.name })
$deprecatedWithoutReplacement = @($deprecatedOwners | Where-Object { -not $_.replaced_by } | ForEach-Object { [string]$_.name })
$duplicateOwnerNames = @($ownerNames | Group-Object | Where-Object Count -gt 1 | ForEach-Object Name)
$informationWithoutFunctionalRefs = @($informationUnits | Where-Object { -not $_.references_functional_unit } | Select-Object -First 25)
$functionalWithoutInformationRefs = @($functionalUnits | Where-Object { -not $_.references_information_unit } | Select-Object -First 25)

$topOwnerDisposition = if ($missingOwnerSkills.Count -eq 0 -and $deprecatedWithoutReplacement.Count -eq 0 -and $duplicateOwnerNames.Count -eq 0) {
    'retain-current-top-owner-surface'
} else {
    'requires-owner-boundary-review'
}

$namingReview = [ordered]@{
    required = $true
    disposition = 'evaluate-naming-clarity-separately-from-owner-boundary'
    rule = 'If a naming-only change improves user, model, and local experience-system collaboration while preserving the owner contract, trigger, artifacts, maintained knowledge, parent, and safety boundary, route it through config/skill-name-migrations.json with a compatibility entry and validation.'
    evidence_required = @(
        'actual contract evidence',
        'user-recognizable task language',
        'verified experience or repeated routing evidence',
        'reference and global-interface update plan',
        'Test-SkillNameMigrations.ps1 and validate-global-install.ps1'
    )
    current_candidate_policy = 'This review does not invent rename candidates by itself. It requires evidence that the current name causes ambiguity, routing friction, or collaboration loss, or that a new name measurably improves shared understanding.'
}

$review = [ordered]@{
    schema_version = 1
    result = 'analyzed'
    principle = 'information-functional-unit'
    information_unit_count = $informationUnits.Count
    functional_unit_count = $functionalUnits.Count
    top_owner = [ordered]@{
        active_count = $activeOwners.Count
        deprecated_count = $deprecatedOwners.Count
        disposition = $topOwnerDisposition
        missing_owner_skills = $missingOwnerSkills
        duplicate_owner_names = $duplicateOwnerNames
        deprecated_without_replacement = $deprecatedWithoutReplacement
        decision_rule = 'Change top-level owners only with current authorization, boundary evidence, rollback or migration conditions, and validation. Retain the current surface when gaps are link-level or owner-internal.'
    }
    naming_review = $namingReview
    bidirectional_link_health = [ordered]@{
        information_units_with_functional_refs = @($informationUnits | Where-Object references_functional_unit).Count
        functional_units_with_information_refs = @($functionalUnits | Where-Object references_information_unit).Count
        sampled_information_gaps = @($informationWithoutFunctionalRefs | ForEach-Object { [ordered]@{ name = $_.name; path = $_.path } })
        sampled_functional_gaps = @($functionalWithoutInformationRefs | ForEach-Object { [ordered]@{ kind = $_.kind; path = $_.path } })
        interpretation = 'A sampled gap is a review target, not an automatic defect. Imported upstream material, tests, and small helper scripts may remain indirectly governed by their parent owner when duplication would add more maintenance cost than retrieval value.'
    }
    recommendations = @(
        'Retain the current top-level owner surface unless the same trigger, artifact lifecycle, maintained knowledge, and safety boundary overlap is proven across independent use cases.',
        'Evaluate naming separately from owner-boundary changes. Apply a naming-only migration when it improves three-party collaboration and all migration evidence, compatibility, and validation gates pass.',
        'Prefer adding or repairing links between information units and functional units before moving files or changing owner boundaries.',
        'Use this review before material owner add, merge, split, deprecation, deletion, or large skill refactoring.',
        'Promote only validated link patterns into skills or knowledge; keep weak link gaps as project-local review input.'
    )
    generated_at = [DateTime]::UtcNow.ToString('o')
}

if ($Apply) {
    $outputDirectory = Join-Path $project '.codex\project'
    New-Item -ItemType Directory -Path $outputDirectory -Force | Out-Null
    $output = Join-Path $outputDirectory 'unit-topology-review.json'
    [IO.File]::WriteAllText($output, (($review | ConvertTo-Json -Depth 8) + [Environment]::NewLine), [Text.UTF8Encoding]::new($false))
    $review['output'] = '.codex/project/unit-topology-review.json'
}

$review | ConvertTo-Json -Depth 8
