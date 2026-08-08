[CmdletBinding()]
param(
    [string]$RepositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..\..\..')).Path
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath $RepositoryRoot).Path
$skillPath = Join-Path $root 'skills\codex-office-cli\subskills\ppt-deck-factory\SKILL.md'
$contractPath = Join-Path $root 'skills\codex-office-cli\subskills\ppt-deck-factory\references\ppt-master-route-contract.md'
$academicContractPath = Join-Path $root 'skills\codex-office-cli\subskills\ppt-deck-factory\references\academic-report-style-contract.md'
$resolverPath = Join-Path $root 'skills\codex-office-cli\subskills\ppt-deck-factory\scripts\Resolve-PptMasterWorkspace.ps1'
$templateCatalogPath = Join-Path $root 'skills\codex-office-cli\subskills\ppt-deck-factory\scripts\Resolve-AgentPptTemplateCatalog.ps1'
$plannerPath = Join-Path $root 'skills\codex-office-cli\subskills\ppt-deck-factory\scripts\New-AgentPptDeckFactoryPlan.ps1'

foreach ($path in @($skillPath, $contractPath, $academicContractPath, $resolverPath, $templateCatalogPath, $plannerPath)) {
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        throw "Missing PPT deck factory artifact: $path"
    }
}

$skill = Get-Content -LiteralPath $skillPath -Raw -Encoding UTF8
foreach ($required in @(
    'hugohe3/ppt-master',
    'visual-design-agent',
    'generate-pptx',
    'generate-image-pptx',
    'reconstruct-editable-pptx',
    'codex-ppt',
    'connection failed 5/5',
    'fill-native-pptx',
    'OfficeCLI validation',
    'select exactly one route',
    'typed Agent',
    'exit instead of deciding silently',
    'Parent-child delegation protocol',
    'full PPT Master repository',
    'Readability and Darwin learning gate',
    'Title text: 34-44 pt',
    'It studies the local PPT Master main corpus only for editable-page',
    'Resolve-AgentPptTemplateCatalog.ps1',
    'Style realism gate',
    'actual PPTX rendering',
    'surrogate preview',
    'CLI-render agreement',
    'text-bearing ellipse'
)) {
    if ($skill -notmatch [regex]::Escape($required)) {
        throw "PPT deck factory skill is missing required rule: $required"
    }
}

$contract = Get-Content -LiteralPath $contractPath -Raw -Encoding UTF8
foreach ($required in @(
    'Route selection is the first correctness boundary',
    'Artifact model',
    'Global Experience Agent adaptation',
    'Rejected or guarded upstream behavior',
    'Gate model',
    'Blocking upstream gates become local Agent exits',
    'Style realism gate',
    'academic-report',
    'complete demand packet',
    'parent must not pre-select the deck topic',
    '34-44 pt',
    'hard-to-read contact sheet'
)) {
    if ($contract -notmatch [regex]::Escape($required)) {
        throw "PPT Master route contract is missing required section: $required"
    }
}

$academicContract = Get-Content -LiteralPath $academicContractPath -Raw -Encoding UTF8
foreach ($required in @(
    'data-journalism',
    'editorial',
    'swiss-minimal',
    'Anti-AI style rules',
    'Academic/report page patterns',
    'rounded cards with generic icons and decorative gradients'
)) {
    if ($academicContract -notmatch [regex]::Escape($required)) {
        throw "Academic report style contract is missing required rule: $required"
    }
}

$probe = & $resolverPath -RepositoryRoot $root -Json | ConvertFrom-Json
if ($probe.status -eq 'missing') {
    throw 'Expected downloaded PPT Master workspace to be present.'
}
if ($probe.release_material_status -ne 'ready') {
    throw 'Expected downloaded PPT Master v4.1.0 release material package to be present.'
}
if ($probe.full_repository_status -ne 'ready') {
    throw 'Expected full PPT Master repository runtime corpus to be present.'
}
if ($probe.full_repository_archive_sha256 -ne '34283c7d885b71bac4d9c07b950dc2ac9ac3e5bf3621288ec3b1c308e5940dcf') {
    throw 'Expected full PPT Master repository archive hash to match the downloaded corpus.'
}

$templateCatalog = & $templateCatalogPath -RepositoryRoot $root -Json | ConvertFrom-Json
if ($templateCatalog.ready_count -lt 1) { throw 'Expected at least one ready local PPT template candidate.' }
$groupTemplate = @($templateCatalog.templates | Where-Object id -eq 'general-group-meeting-template')
if ($groupTemplate.Count -ne 1 -or $groupTemplate[0].status -ne 'ready') {
    throw 'Expected the general group-meeting template to be ready.'
}
foreach ($field in @('pptx','potx','authoring','potx_exporter','preview')) {
    if (-not $groupTemplate[0].checks.$field) {
        throw "Expected group-meeting template catalog check to pass: $field"
    }
}

$plan = & $plannerPath -Goal 'Create an 8 slide visually unified product strategy deck from source notes' -Json | ConvertFrom-Json
if ($plan.selected_route -ne 'generate-image-pptx') { throw 'Expected default new-deck request to route to generate-image-pptx.' }
if (-not $plan.codex_ppt_workflow_required) { throw 'Expected default image route to require codex-ppt workflow.' }
if ($plan.image_backend_reliability.default_max_concurrent_slides -ne 1) { throw 'Expected built-in image generation to default to one active slide.' }
if ($plan.image_backend_reliability.health_checked_max_concurrent_slides -ne 2) { throw 'Expected health-checked built-in image generation to cap at two active slides.' }
if ($plan.image_backend_reliability.connection_failure_policy -notmatch 'retry only the affected slide once') { throw 'Expected isolated retry after connection failed 5/5.' }
if ($plan.ppt_master_status -eq 'missing') { throw 'Expected planner to see PPT Master workspace.' }
if ('contract' -notin @($plan.route_phases)) { throw 'Expected planner to expose route phases.' }
if ('dependency installation' -notin @($plan.blocking_gates)) { throw 'Expected planner to expose blocking gates.' }

$editablePlan = & $plannerPath -Goal 'Create an 8 slide deck with element-editable native text and shapes' -Json | ConvertFrom-Json
if ($editablePlan.selected_route -ne 'reconstruct-editable-pptx') { throw 'Expected explicit element-editable request to route to reconstruct-editable-pptx.' }
if (-not $editablePlan.main_corpus_study_required) { throw 'Expected editable route to retain PPT Master corpus study.' }
if (-not $editablePlan.codex_ppt_workflow_required) { throw 'Expected editable reconstruction route to start with codex-ppt.' }
if ('analysis/element_manifest.json' -notin @($editablePlan.required_artifacts)) { throw 'Expected editable reconstruction plan to require an element manifest.' }
if ('validation/reference-render-comparison.md' -notin @($editablePlan.required_artifacts)) { throw 'Expected editable reconstruction plan to compare its real render to the approved image.' }

$academicPlan = & $plannerPath -Goal 'Create a 4 slide academic research report deck about the Global Experience Agent memory architecture' -Json | ConvertFrom-Json
if ($academicPlan.style_realism_gate -ne 'academic-report') { throw 'Expected academic request to use academic-report style gate.' }
if (-not $academicPlan.codex_ppt_workflow_required) { throw 'Expected default academic deck to use codex-ppt workflow.' }
if ($academicPlan.full_repository_status -ne 'ready') { throw 'Expected planner to expose full repository status.' }
if ($academicPlan.readability_gate.essential_minimum_pt -ne 18) { throw 'Expected readability gate to enforce 18 pt essential minimum.' }
if ($academicPlan.readability_gate.title_pt -ne '34-44') { throw 'Expected title readability range of 34-44 pt.' }
if (-not $academicPlan.readability_gate.actual_render_required_when_available) { throw 'Expected actual PPTX render to be required when available.' }
if ($academicPlan.readability_gate.surrogate_preview_policy -notmatch 'authoring aids only') { throw 'Expected surrogate preview policy to mark previews non-final.' }
if ($academicPlan.readability_gate.cli_render_agreement_for_text_bearing_ellipses -notmatch 'OfficeCLI view issues') { throw 'Expected readability gate to require CLI-render agreement for text-bearing ellipses.' }
if ($academicPlan.delegation_payload_policy -notmatch 'parent does not choose topic') { throw 'Expected parent not to choose topic in delegation payload policy.' }
if ($academicPlan.child_autonomy_policy -notmatch 'route selection') { throw 'Expected child autonomy over route selection.' }
if ('larger default type' -notin @($academicPlan.darwin_learning.accepted_rules)) { throw 'Expected Darwin ratchet to keep larger default type rule.' }
if ('actual-render screenshot/contact-sheet readability as validation signal' -notin @($academicPlan.darwin_learning.accepted_rules)) { throw 'Expected Darwin ratchet to require actual-render readability proof.' }
if ('paired CLI-render agreement for text-bearing ellipses or ovals' -notin @($academicPlan.darwin_learning.accepted_rules)) { throw 'Expected Darwin ratchet to retain the CLI-render agreement rule.' }
if (@($academicPlan.codex_ppt_workflow_sources | Where-Object { $_ -match 'upstream/SKILL.md' }).Count -ne 1) { throw 'Expected codex-ppt upstream skill in selected route sources.' }
if ('data-journalism' -notin @($academicPlan.recommended_visual_styles)) { throw 'Expected academic plan to recommend data-journalism.' }
if ('glassmorphism' -notin @($academicPlan.avoid_visual_styles_by_default)) { throw 'Expected academic plan to avoid glassmorphism by default.' }
if (@($academicPlan.anti_ai_style_rules).Count -lt 3) { throw 'Expected anti-AI style rules in academic plan.' }

$groupMeetingPlan = & $plannerPath -Goal 'Create a 4 slide group meeting academic progress deck' -Json | ConvertFrom-Json
if ($groupMeetingPlan.template_catalog_status -ne 'ready') { throw 'Expected planner to expose a ready local template catalog.' }
if (@($groupMeetingPlan.recommended_template_candidates | Where-Object id -eq 'general-group-meeting-template').Count -ne 1) {
    throw 'Expected planner to recommend the general group-meeting template as a candidate.'
}

$fill = & $plannerPath -Goal 'Fill this template with the new content' -ExistingPptx 'template.pptx' -Json | ConvertFrom-Json
if ($fill.selected_route -ne 'fill-native-pptx') {
    throw 'Expected raw PPTX template fill request to route to fill-native-pptx.'
}

Write-Host 'Agent PPT deck factory test passed.'
