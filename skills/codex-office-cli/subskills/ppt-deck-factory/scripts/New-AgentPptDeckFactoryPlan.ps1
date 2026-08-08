[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Goal,
    [string[]]$Sources = @(),
    [string]$ExistingPptx,
    [string]$TemplateWorkspace,
    [ValidateSet('auto','generate-image-pptx','reconstruct-editable-pptx','generate-pptx','create-template','fill-native-pptx','enhance-native-pptx')]
    [string]$Route = 'auto',
    [string]$OutputRoot,
    [switch]$Apply,
    [switch]$Json
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..\..\..')).Path
if (-not $OutputRoot) {
    $OutputRoot = Join-Path $root '.runtime\work\agent-ppt-decks'
}

function Resolve-Route {
    param([string]$GoalText, [string[]]$InputSources, [string]$InputPptx, [string]$InputTemplate, [string]$Requested)
    if ($Requested -ne 'auto') { return $Requested }
    $lower = $GoalText.ToLowerInvariant()
    if ($InputPptx -and ($lower -match 'fill|填充|套用|替换|template')) { return 'fill-native-pptx' }
    if ($InputPptx -and ($lower -match 'narrat|audio|timing|transition|notes|旁白|配音|转场|备注')) { return 'enhance-native-pptx' }
    if ($lower -match 'template|模板|母版|版式|brand|layout|workspace') { return 'create-template' }
    if ($lower -match 'element.editable|editable element|native text|native shape|editable chart|可编辑元素|元素可编辑|原生文本|原生形状|图表可编辑') { return 'reconstruct-editable-pptx' }
    return 'generate-image-pptx'
}

$selectedRoute = Resolve-Route -GoalText $Goal -InputSources $Sources -InputPptx $ExistingPptx -InputTemplate $TemplateWorkspace -Requested $Route
$timestamp = [DateTimeOffset]::UtcNow.ToString('yyyyMMddTHHmmssZ')
$safeName = ($Goal.ToLowerInvariant() -replace '[^a-z0-9\u4e00-\u9fa5]+','-').Trim('-')
if ([string]::IsNullOrWhiteSpace($safeName)) { $safeName = 'deck' }
if ($safeName.Length -gt 48) { $safeName = $safeName.Substring(0, 48).Trim('-') }
$projectName = "$timestamp-$safeName"
$projectPath = Join-Path $OutputRoot $projectName

$workspaceProbe = & (Join-Path $PSScriptRoot 'Resolve-PptMasterWorkspace.ps1') -RepositoryRoot $root -Json | ConvertFrom-Json
$templateCatalog = & (Join-Path $PSScriptRoot 'Resolve-AgentPptTemplateCatalog.ps1') -RepositoryRoot $root -Json | ConvertFrom-Json
$optimizationSnapshot = & (Join-Path $root 'agent\40-runtime\Get-AgentStructuralOptimizationSnapshot.ps1') -RepositoryRoot $root -AgentId 'visual-design-agent' | ConvertFrom-Json

$academicPattern = 'academic|research|paper|thesis|defense|technical report|technical review|group meeting|lab meeting|学术|科研|论文|答辩|组会|技术汇报|技术报告|研究|实验|评测|评估'
$isAcademicReport = ($Goal -match $academicPattern)
$isImageDeck = ($selectedRoute -in @('generate-image-pptx','reconstruct-editable-pptx'))
$isEditableReconstruction = ($selectedRoute -eq 'reconstruct-editable-pptx')
$groupMeetingPattern = 'group meeting|lab meeting|组会|实验室汇报|科研进展'
$isGroupMeeting = ($Goal -match $groupMeetingPattern)
$recommendedTemplates = @()
if ($isGroupMeeting) {
    $recommendedTemplates = @($templateCatalog.templates | Where-Object { $_.status -eq 'ready' -and $_.kind -eq 'academic-group-meeting' })
}

$plan = [ordered]@{
    schema_version = 1
    model = 'agent-ppt-deck-factory-plan'
    primary_method = if ($isEditableReconstruction) { 'ningzimu/codex-ppt-skill + native editable reconstruction' } elseif ($isImageDeck) { 'ningzimu/codex-ppt-skill' } else { 'hugohe3/ppt-master' }
    primary_method_path = if ($isImageDeck) { 'skills/codex-office-cli/subskills/imported-codex-home/ningzimu-codex-ppt/upstream/SKILL.md' } else { '.runtime/work/network-learning/ppt-master/full-repo/workspace/ppt-master-main' }
    source = 'https://github.com/hugohe3/ppt-master'
    source_commit = '10f0adc0600ff28a470d55992133b1992c56968a'
    selected_route = $selectedRoute
    goal = $Goal
    sources = @($Sources)
    existing_pptx = $ExistingPptx
    template_workspace = $TemplateWorkspace
    output_root = $OutputRoot
    project_path = $projectPath
    ppt_master_workspace = $workspaceProbe.workspace
    ppt_master_status = $workspaceProbe.status
    ppt_master_release_material_status = $workspaceProbe.release_material_status
    ppt_master_release_material_workspace = $workspaceProbe.release_material_workspace
    full_repository_status = $workspaceProbe.full_repository_status
    full_repository_workspace = $workspaceProbe.full_repository_workspace
    structural_optimization_snapshot = $optimizationSnapshot
    template_catalog_status = if ($templateCatalog.ready_count -gt 0) { 'ready' } else { 'empty' }
    available_templates = @($templateCatalog.templates)
    recommended_template_candidates = @($recommendedTemplates)
    delegation_payload_policy = 'parent passes the complete user demand packet, source boundary, constraints, authority, and validation expectations; parent does not choose topic, thesis, outline, route, visual style, or template unless the user explicitly fixed them'
    child_autonomy_policy = 'visual-design-agent owns visual route selection, PPT narrative framing, slide outline, style/material selection, and design contract; the selected route determines which method corpus is required'
    main_corpus_study_required = ($selectedRoute -in @('reconstruct-editable-pptx','generate-pptx'))
    codex_ppt_workflow_required = $isImageDeck
    codex_ppt_workflow_sources = if ($isImageDeck) { @(
        'skills/codex-office-cli/subskills/imported-codex-home/ningzimu-codex-ppt/SKILL.md',
        'skills/codex-office-cli/subskills/imported-codex-home/ningzimu-codex-ppt/upstream/SKILL.md',
        'skills/codex-office-cli/subskills/imported-codex-home/ningzimu-codex-ppt/upstream/docs/workflow-gates-and-progress.md',
        'skills/codex-office-cli/subskills/imported-codex-home/ningzimu-codex-ppt/upstream/docs/slide-generation-and-subagents.md',
        'skills/codex-office-cli/subskills/imported-codex-home/ningzimu-codex-ppt/upstream/docs/project-assembly-and-reporting.md'
    ) } else { @() }
    image_backend_reliability = if ($isImageDeck) { [ordered]@{
        default_max_concurrent_slides = 1
        health_checked_max_concurrent_slides = 2
        connection_failure_policy = 'on connection failed 5/5, stop new dispatches, preserve recorded slides, and retry only the affected slide once after the queue is idle'
    } } else { $null }
    main_corpus_study_sources = @(
        '.runtime/work/network-learning/ppt-master/full-repo/workspace/ppt-master-main/README.md',
        '.runtime/work/network-learning/ppt-master/full-repo/workspace/ppt-master-main/skills/ppt-master/SKILL.md',
        '.runtime/work/network-learning/ppt-master/full-repo/workspace/ppt-master-main/skills/ppt-master/workflows/routing.md',
        '.runtime/work/network-learning/ppt-master/full-repo/workspace/ppt-master-main/docs/templates-guide.md',
        '.runtime/work/network-learning/ppt-master/full-repo/workspace/ppt-master-main/examples/examples.json',
        '.runtime/work/network-learning/ppt-master/release-v4.1.0/ppt-master/skills/ppt-master/references/visual-styles/',
        '.runtime/work/network-learning/ppt-master/release-v4.1.0/ppt-master/skills/ppt-master/references/image-type-templates/'
    )
    readability_gate = [ordered]@{
        title_pt = '34-44'
        section_title_pt = '26-34'
        body_pt = '18-24'
        caption_source_footnote_pt = '10-14 non-essential only'
        essential_minimum_pt = 18
        contact_sheet_rule = 'if body text is hard to read in screenshot/contact sheet, repair the authoring source and regenerate before export acceptance'
        actual_render_required_when_available = $true
        surrogate_preview_policy = 'PIL, SVG, or hand-drawn previews are authoring aids only; final readability proof must come from actual PPTX rendering when an Office renderer is available, otherwise report residual risk'
        cli_render_agreement_for_text_bearing_ellipses = 'For text-bearing ellipses or ovals, OfficeCLI view issues and actual PPTX render must both show no overflow; repair the authoring source and use a rounded rectangle or decoupled text when they disagree.'
    }
    darwin_learning = [ordered]@{
        method = 'keep-or-revert ratchet'
        current_failure_signals = @('small text', 'parent-selected theme leakage', 'insufficient main-corpus study', 'generic AI card-grid look', 'export without visual readability proof', 'surrogate preview differs from actual PPT rendering')
        accepted_rules = @('larger default type', 'full demand transfer to child', 'mandatory main-corpus study for non-trivial decks', 'actual-render screenshot/contact-sheet readability as validation signal', 'surrogate previews are non-final evidence only', 'paired CLI-render agreement for text-bearing ellipses or ovals')
    }
    style_realism_gate = if ($isAcademicReport) { 'academic-report' } else { 'standard' }
    recommended_visual_styles = if ($isAcademicReport) { @('data-journalism','editorial','swiss-minimal') } else { @() }
    avoid_visual_styles_by_default = if ($isAcademicReport) { @('soft-rounded','glassmorphism','dark-tech') } else { @() }
    anti_ai_style_rules = if ($isAcademicReport) {
        @(
            'prefer semantic rules, grids, tables, charts, matrices, and flow arrows over decorative card grids',
            'use color for evidence role, status, comparison, and emphasis instead of module-by-module decoration',
            'avoid decorative glass, glow, gradient blobs, inflated rounded cards, and generic icon tiles',
            'preserve data, units, source labels, ordering, and relationships; simplify effects instead of rewriting content'
        )
    } else { @() }
    academic_report_style_rules = if ($isAcademicReport) {
        @(
            'default to data-journalism for evidence-dense reports, editorial for analytical exposition, swiss-minimal for sparse architecture or method overview',
            'include source lines, captions, assumptions, limitations, and validation evidence where they clarify claims',
            'prefer editable PowerPoint tables, charts, diagrams, and annotated figures over flattened decorative composites',
            'reject drafts that mainly look like rounded AI cards without visible academic evidence structure'
        )
    } else { @() }
    required_artifacts = if ($isEditableReconstruction) { @(
        'outline.md',
        'deck_spec.json',
        'slide_jobs.json',
        'origin_image/slide_XX.png',
        'analysis/element_manifest.json',
        'authoring/',
        'speech.md',
        'exports/*.pptx',
        'validation/officecli-validate.json',
        'validation/reference-render-comparison.md',
        'validation/visual-proof-or-risk.md'
    ) } elseif ($isImageDeck) { @(
        'outline.md',
        'deck_spec.json',
        'prompts/slide_XX.json',
        'slide_jobs.json',
        'slide_run_state.json',
        'origin_image/slide_XX.png',
        'speech.md',
        'exports/*.pptx',
        'validation/officecli-validate.json',
        'validation/issues.json',
        'validation/visual-proof-or-risk.md'
    ) } else { @(
        'design_contract.md',
        'route_plan.json',
        'validation/structural-optimization-evidence.json',
        'validation/',
        'exports/'
    ) }
    route_phases = @(
        'routing',
        'contract',
        'authoring',
        'preview',
        'export',
        'validation'
    )
    blocking_gates = @(
        'user taste or style decision',
        'provider key or paid external call',
        'dependency installation',
        'irreversible source mutation',
        'publication or Git action'
    )
    owner_gates = @(
        'codex-office-cli delivery validation',
        'codex-runtime-environments for missing Python dependencies',
        'codex-credential-management for optional image/search/TTS providers',
        'codex-image-workflow for generated slide visuals when needed'
    )
    next_actions = @()
}

switch ($selectedRoute) {
    'generate-image-pptx' {
        $plan.next_actions = @(
            'Receive full demand packet from parent without parent-selected theme or outline',
            'Read the managed codex-ppt workflow and phase references',
            'Draft outline.md and wait for user approval',
            'Confirm visual style and built-in image backend',
            'Generate exactly one representative sample slide and wait for approval',
            'Prepare deck_spec.json and per-slide prompt jobs with max_concurrent_slides=1',
            'Delegate and record one slide job at a time; permit at most two after a successful health check',
            'Visually check and record each slide result',
            'Write speech.md and assemble the image-based PPTX',
            'Validate with OfficeCLI and actual PowerPoint rendering when available'
        )
    }
    'reconstruct-editable-pptx' {
        $plan.next_actions = @(
            'Read the managed codex-ppt workflow and phase references before any editable authoring',
            'Draft outline.md, confirm the visual direction and built-in image backend, then approve one sample slide',
            'Generate, record, and visually approve all origin_image/slide_XX.png pages before reconstruction',
            'Lock each approved image layout and content; do not create a second native design',
            'Study the local PPT Master main corpus only for downstream native reconstruction techniques and cite relevant paths',
            'Create analysis/element_manifest.json classifying each approved-page component as editable text, shape, connector, chart/table, or image-layer',
            'Reconstruct semantic components from the manifest as native PowerPoint elements while retaining complex raster artwork as labelled image layers',
            'Export editable PPTX and compare an actual PowerPoint render against the approved origin image for layout, hierarchy, spacing, and arrow attachment',
            'Validate with OfficeCLI; repair the native authoring source and repeat comparison before delivery'
        )
    }
    'generate-pptx' {
        $plan.next_actions = @(
            'Receive full demand packet from parent without parent-selected theme or outline',
            'Study local PPT Master main corpus and cite relevant paths',
            'Confirm factual source boundary and unresolved gaps',
            'Create project workspace',
            'Write design_contract.md before slide authoring',
            'Author editable slide intermediate',
            'Run readability gate with larger default type',
            'Export actual PPTX-rendered contact sheet when an Office renderer is available',
            'Run route quality gate',
            'Export editable PPTX',
            'Validate with OfficeCLI'
        )
    }
    'create-template' {
        $plan.next_actions = @(
            'Classify reusable Brand, Layout, or Deck workspace',
            'Copy references without mutation',
            'Write template contract',
            'Export optional review PPTX',
            'Register exact workspace path only after validation'
        )
    }
    'fill-native-pptx' {
        $plan.next_actions = @(
            'Analyze source PPTX shell',
            'Create fill plan',
            'Check plan against native slide library',
            'Apply fill to cloned PPTX',
            'Validate with OfficeCLI'
        )
    }
    'enhance-native-pptx' {
        $plan.next_actions = @(
            'Inspect finished PPTX',
            'Plan notes, narration, timings, or transitions',
            'Patch native package without visual redesign',
            'Validate with OfficeCLI'
        )
    }
}

if ($Apply) {
    New-Item -ItemType Directory -Force -Path $projectPath | Out-Null
    New-Item -ItemType Directory -Force -Path (Join-Path $projectPath 'validation') | Out-Null
    New-Item -ItemType Directory -Force -Path (Join-Path $projectPath 'exports') | Out-Null
    $planPath = Join-Path $projectPath 'route_plan.json'
    $contractPath = Join-Path $projectPath 'design_contract.md'
    $structuralEvidencePath = Join-Path $projectPath 'validation\structural-optimization-evidence.json'
    $utf8NoBom = [System.Text.UTF8Encoding]::new($false)
    [System.IO.File]::WriteAllText($planPath, ($plan | ConvertTo-Json -Depth 6), $utf8NoBom)
    $structuralEvidence = [ordered]@{
        schema_version = 1
        model = 'ppt-child-structural-optimization-evidence'
        baseline_id = $optimizationSnapshot.baseline_id
        baseline_version = $optimizationSnapshot.baseline_version
        baseline_sha256 = $optimizationSnapshot.baseline_sha256
        status = 'required-before-completion'
        required_records = @(
            'memory retrieval or privacy-safe skip reason',
            'intent route and confidence or fallback',
            'typed source parse or skip reason',
            'retrieved source/template chunks and rerank rationale',
            'bounded author-render-validate-repair settlement',
            'memory trace or skip reason',
            'owner, interface, and actual-render gate results'
        )
    }
    [System.IO.File]::WriteAllText($structuralEvidencePath, ($structuralEvidence | ConvertTo-Json -Depth 6), $utf8NoBom)
    $contractLines = @(
        '# Agent PPT Deck Factory Design Contract',
        '',
        "Goal: $Goal",
        "Route: $selectedRoute",
        "Primary method: $($plan.primary_method)",
        '',
        '## Required decisions before slide authoring',
        '',
        '- Audience:',
        '- Narrative goal:',
        '- Canvas and format:',
        '- Page count:',
        '- Visual style:',
        "- Style realism gate: $($plan.style_realism_gate)",
        '- Source/factual boundary:',
        '- Required editable PowerPoint depth (image-based route means full-slide images, not element editability):',
        '- Images/charts/tables:',
        '- Validation expectations:',
        '',
        '## Child autonomy and corpus study',
        '',
        '- Parent passes the full demand packet and authority boundary.',
        '- Child selects topic framing, route, narrative thesis, slide outline, visual style, and template/materials unless the user explicitly fixed a decision.',
        '- Child studies only the method corpus required by the selected route and cites the studied paths.',
        '',
        '## Readability gate',
        '',
        '- Title text: 34-44 pt.',
        '- Section title: 26-34 pt.',
        '- Body text: 18-24 pt.',
        '- Captions, sources, and footnotes: 10-14 pt only when non-essential.',
        '- If contact-sheet body text is hard to read, repair the authoring source and regenerate.',
        '- Final contact-sheet proof must use actual PPTX rendering when an Office renderer is available; surrogate PIL/SVG/manual previews are non-final.',
        '',
        '## Route next actions',
        ''
    ) + @($plan.next_actions | ForEach-Object { "- $_" })
    if ($isAcademicReport) {
        $contractLines = $contractLines[0..13] + @(
            "- Recommended academic/report styles: $($plan.recommended_visual_styles -join ', ')",
            "- Avoid by default: $($plan.avoid_visual_styles_by_default -join ', ')"
        ) + $contractLines[14..($contractLines.Count - 1)]
    }
    $contractLines = $contractLines | Where-Object { $null -ne $_ }
    $contract = $contractLines -join [Environment]::NewLine
    [System.IO.File]::WriteAllText($contractPath, $contract, $utf8NoBom)
    $plan.plan_path = $planPath
    $plan.design_contract_path = $contractPath
    $plan.structural_optimization_evidence_path = $structuralEvidencePath
}

if ($Json) {
    $plan | ConvertTo-Json -Depth 6
} else {
    "Agent PPT deck factory route: $selectedRoute"
    "Project path: $projectPath"
    "PPT Master workspace: $($workspaceProbe.status) $($workspaceProbe.workspace)"
}
