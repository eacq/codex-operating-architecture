[CmdletBinding()]
param(
    [string]$RepositoryRoot = 'F:\codex',
    [string]$TaskId = 'career-planning-task',
    [string]$Request = '',
    [string]$Mode = 'auto',
    [string]$WriteSurface = ".runtime/work/career-planning-agent/$TaskId"
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath $RepositoryRoot).Path
$runtimeRoot = $root
if ($env:CODEX_VALIDATION_RUNTIME_ROOT) {
    $runtimeRoot = (Resolve-Path -LiteralPath $env:CODEX_VALIDATION_RUNTIME_ROOT).Path
}
$upstream = Join-Path $runtimeRoot '.runtime\work\network-learning\santifer-career-ops-main'
if (-not (Test-Path -LiteralPath $upstream -PathType Container)) {
    throw 'Installed career-ops upstream corpus is missing.'
}

$knownModes = @(
    'onboarding',
    'life-map',
    'opportunity-evaluation',
    'pipeline',
    'scan',
    'cv',
    'cover',
    'email',
    'contacto',
    'interview',
    'patterns',
    'upskill',
    'offer-prep'
)

function New-TokenFromCodePoints {
    param([int[]]$CodePoints)

    return -join ($CodePoints | ForEach-Object { [string][char]$_ })
}

function Test-IntentSignal {
    param(
        [string]$Text,
        [string[]]$AsciiPatterns,
        [string[]]$UnicodeTokens
    )

    foreach ($pattern in $AsciiPatterns) {
        if ($Text -match $pattern) { return $true }
    }
    foreach ($token in $UnicodeTokens) {
        if ($Text.Contains($token)) { return $true }
    }
    return $false
}

$unicodeIntentTokens = @{
    interview = @(
        (New-TokenFromCodePoints @(0x9762,0x8BD5)),
        (New-TokenFromCodePoints @(0x6A21,0x62DF,0x9762,0x8BD5))
    )
    offer = @(
        (New-TokenFromCodePoints @(0x85AA,0x8D44)),
        (New-TokenFromCodePoints @(0x85AA,0x916C)),
        (New-TokenFromCodePoints @(0x5408,0x540C)),
        (New-TokenFromCodePoints @(0x8C08,0x85AA)),
        (New-TokenFromCodePoints @(0x5F55,0x7528,0x901A,0x77E5)),
        (New-TokenFromCodePoints @(0x5F55,0x7528,0x610F,0x5411))
    )
    cv = @(
        (New-TokenFromCodePoints @(0x7B80,0x5386)),
        (New-TokenFromCodePoints @(0x5C65,0x5386))
    )
    communication = @(
        (New-TokenFromCodePoints @(0x6C42,0x804C,0x4FE1)),
        (New-TokenFromCodePoints @(0x90AE,0x4EF6)),
        (New-TokenFromCodePoints @(0x81EA,0x8350)),
        (New-TokenFromCodePoints @(0x63A8,0x8350)),
        (New-TokenFromCodePoints @(0x8054,0x7CFB,0x4EBA)),
        (New-TokenFromCodePoints @(0x5185,0x63A8))
    )
    scan = @(
        (New-TokenFromCodePoints @(0x626B,0x63CF)),
        (New-TokenFromCodePoints @(0x641C,0x7D22)),
        (New-TokenFromCodePoints @(0x627E,0x5DE5,0x4F5C)),
        (New-TokenFromCodePoints @(0x5C97,0x4F4D)),
        (New-TokenFromCodePoints @(0x804C,0x4F4D)),
        (New-TokenFromCodePoints @(0x673A,0x4F1A))
    )
    opportunity = @(
        (New-TokenFromCodePoints @(0x5C97,0x4F4D)),
        (New-TokenFromCodePoints @(0x804C,0x4F4D)),
        (New-TokenFromCodePoints @(0x5DE5,0x4F5C)),
        (New-TokenFromCodePoints @(0x673A,0x4F1A)),
        (New-TokenFromCodePoints @(0x9879,0x76EE)),
        (New-TokenFromCodePoints @(0x8BC4,0x4F30)),
        (New-TokenFromCodePoints @(0x5339,0x914D))
    )
    upskill = @(
        (New-TokenFromCodePoints @(0x5B66,0x4E60)),
        (New-TokenFromCodePoints @(0x6280,0x80FD)),
        (New-TokenFromCodePoints @(0x8BFE,0x7A0B)),
        (New-TokenFromCodePoints @(0x57F9,0x8BAD)),
        (New-TokenFromCodePoints @(0x63D0,0x5347))
    )
    pipeline = @(
        (New-TokenFromCodePoints @(0x8DDF,0x8FDB)),
        (New-TokenFromCodePoints @(0x6295,0x9012)),
        (New-TokenFromCodePoints @(0x6D41,0x7A0B)),
        (New-TokenFromCodePoints @(0x8FDB,0x5EA6))
    )
    patterns = @(
        (New-TokenFromCodePoints @(0x590D,0x76D8)),
        (New-TokenFromCodePoints @(0x62D2,0x4FE1)),
        (New-TokenFromCodePoints @(0x6A21,0x5F0F)),
        (New-TokenFromCodePoints @(0x89C4,0x5F8B))
    )
    life = @(
        (New-TokenFromCodePoints @(0x804C,0x4E1A,0x89C4,0x5212)),
        (New-TokenFromCodePoints @(0x751F,0x6DAF)),
        (New-TokenFromCodePoints @(0x65B9,0x5411)),
        (New-TokenFromCodePoints @(0x4EF7,0x503C,0x89C2)),
        (New-TokenFromCodePoints @(0x4EBA,0x751F)),
        (New-TokenFromCodePoints @(0x8F6C,0x884C))
    )
}

$intentRules = @(
    [pscustomobject]@{ mode = 'interview'; patterns = @('interview|mock interview|interview prep'); tokens = $unicodeIntentTokens.interview },
    [pscustomobject]@{ mode = 'offer-prep'; patterns = @('offer|contract|salary|compensation|equity|negotiation'); tokens = $unicodeIntentTokens.offer },
    [pscustomobject]@{ mode = 'cv'; patterns = @('cv|resume|curriculum vitae'); tokens = $unicodeIntentTokens.cv },
    [pscustomobject]@{ mode = 'email'; patterns = @('cover|email|application letter|recruiter message'); tokens = $unicodeIntentTokens.communication },
    [pscustomobject]@{ mode = 'scan'; patterns = @('scan|discover|find roles|new roles|job search'); tokens = $unicodeIntentTokens.scan },
    [pscustomobject]@{ mode = 'opportunity-evaluation'; patterns = @('position|role|job|opening|jd|job description|opportunity|evaluate|fit'); tokens = $unicodeIntentTokens.opportunity },
    [pscustomobject]@{ mode = 'pipeline'; patterns = @('pipeline|tracker|follow up|status|next action'); tokens = $unicodeIntentTokens.pipeline },
    [pscustomobject]@{ mode = 'patterns'; patterns = @('patterns|rejection|progress signals|retrospective'); tokens = $unicodeIntentTokens.patterns },
    [pscustomobject]@{ mode = 'upskill'; patterns = @('learn|skill|upskill|course|training'); tokens = $unicodeIntentTokens.upskill },
    [pscustomobject]@{ mode = 'life-map'; patterns = @('career plan|plan my career|plan career|career planning|career direction|life plan|values|constraints|non-negotiables|transition'); tokens = $unicodeIntentTokens.life }
)

$resolvedMode = $Mode
$intentSignals = @()
$secondaryModes = @()
if ($resolvedMode -eq 'auto') {
    $text = $Request.ToLowerInvariant()
    foreach ($rule in $intentRules) {
        if (Test-IntentSignal -Text $text -AsciiPatterns $rule.patterns -UnicodeTokens $rule.tokens) {
            $intentSignals += [pscustomobject][ordered]@{
                mode = $rule.mode
                reason = 'request matched route keywords'
            }
        }
    }
    $resolvedMode = if ($intentSignals.Count -gt 0) { $intentSignals[0].mode } else { 'life-map' }
    $secondaryModes = @($intentSignals | Select-Object -Skip 1 -ExpandProperty mode)
}
if ($resolvedMode -notin $knownModes) {
    throw "Unsupported career-planning mode: $resolvedMode"
}
if ($Mode -ne 'auto') {
    $intentSignals += [pscustomobject][ordered]@{
        mode = $resolvedMode
        reason = 'explicit mode parameter'
    }
}

$sourceFiles = @(
    'AGENTS.md',
    'DATA_CONTRACT.md',
    '.agents/skills/career-ops/SKILL.md'
)

switch ($resolvedMode) {
    'opportunity-evaluation' { $sourceFiles += @('modes/_shared.md', 'modes/oferta.md', 'modes/auto-pipeline.md') }
    'pipeline' { $sourceFiles += @('modes/_shared.md', 'modes/pipeline.md') }
    'scan' { $sourceFiles += @('modes/_shared.md', 'modes/scan.md') }
    'cv' { $sourceFiles += @('modes/_shared.md', 'modes/pdf.md', 'modes/latex.md') }
    'cover' { $sourceFiles += @('modes/cover.md') }
    'email' { $sourceFiles += @('modes/email.md') }
    'contacto' { $sourceFiles += @('modes/_shared.md', 'modes/contacto.md') }
    'interview' { $sourceFiles += @('modes/interview.md', 'modes/interview-prep.md') }
    'patterns' { $sourceFiles += @('modes/patterns.md') }
    'upskill' { $sourceFiles += @('modes/upskill.md') }
    'offer-prep' { $sourceFiles += @('modes/offer-prep.md') }
    default { $sourceFiles += @('modes/_profile.template.md', 'modes/_custom.template.md') }
}

$missing = @($sourceFiles | Where-Object { -not (Test-Path -LiteralPath (Join-Path $upstream $_) -PathType Leaf) })
$optimizationSnapshot = & (Join-Path $root 'agent\40-runtime\Get-AgentStructuralOptimizationSnapshot.ps1') -RepositoryRoot $root -AgentId 'career-planning-agent' | ConvertFrom-Json

[pscustomobject][ordered]@{
    status = if ($missing.Count -eq 0) { 'passed' } else { 'missing-source-files' }
    model = 'career-planning-agent-route-plan'
    task_id = $TaskId
    requested_mode = $Mode
    resolved_mode = $resolvedMode
    upstream_workspace = '.runtime/work/network-learning/santifer-career-ops-main'
    write_surface = $WriteSurface
    intent_signals = $intentSignals
    secondary_modes = $secondaryModes
    source_files = $sourceFiles
    missing = $missing
    structural_optimization_snapshot = $optimizationSnapshot
    required_structural_evidence = @(
        'intent route and confidence or fallback',
        'source parse result or explicit skip reason',
        'retrieval and rerank notes',
        'bounded loop settlement',
        'memory trace or privacy-safe skip reason',
        'authority and human-review boundary'
    )
    safety_boundary = @(
        'draft and recommend only',
        'no fabricated user facts',
        'no submit/send/apply without explicit user authorization',
        'external web/browser/account actions require current permission',
        'parent Global Experience Agent owns delegation, join, memory, Git, release, and structure gates'
    )
    usage_hint = @(
        'invoke the parent Global Experience Agent with DelegateSubagent -AgentId career-planning-agent for real tasks',
        'use this route planner directly only for local route inspection or tests',
        'put personal career files under the isolated write surface unless the user explicitly chooses a workspace'
    )
    next_step = if ($missing.Count -eq 0) { 'run onboarding/status check and load selected mode files' } else { 'repair installed upstream corpus' }
} | ConvertTo-Json -Depth 6
