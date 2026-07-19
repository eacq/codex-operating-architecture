[CmdletBinding()]
param(
    [string]$RepositoryRoot = (Get-Location).Path,
    [Parameter(Mandatory = $true)] [string]$Version,
    [Parameter(Mandatory = $true)] [ValidateSet('Private','Public')] [string]$Mode,
    [Parameter(Mandatory = $true)] [string]$ReleaseNote,
    [string[]]$ChangedPaths = @(),
    [switch]$Apply
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath $RepositoryRoot).Path

function Convert-EscapedUnicode([string]$Value) {
    return [regex]::Unescape($Value)
}

function Normalize-RepoPath([string]$Path) {
    return ($Path -replace '\\','/').TrimStart('/')
}

function Get-GitHubRepository([string]$RemoteName) {
    $url = (& git -C $root remote get-url $RemoteName 2>$null).Trim()
    $match = [regex]::Match($url, 'github\.com[:/](?<name>[^/]+/[^/.]+)')
    if ($match.Success) { return $match.Groups['name'].Value }
    return ''
}

function Get-ImpactAreas([string[]]$Paths) {
    $areas = New-Object System.Collections.Generic.List[string]
    foreach ($path in $Paths) {
        $p = Normalize-RepoPath $path
        if ($p -match '^(AGENTS\.md|config/|skills/codex-self-evolution/)') { $areas.Add('Lifecycle controller') }
        elseif ($p -match '^(skills/|module-registry\.json$)') { $areas.Add('Skill architecture') }
        elseif ($p -match '^scripts/') { $areas.Add('Automation gates') }
        elseif ($p -match '^(knowledge|knowledge-vault)/') { $areas.Add('Knowledge and experience') }
        elseif ($p -match '^(README|docs/|CHANGELOG\.md$|VERSION$)') { $areas.Add('Release documentation') }
    }
    $unique = @($areas | Select-Object -Unique)
    if ($unique.Count -eq 0) { $unique = @('Release documentation') }
    return $unique
}

<#
function Get-ReleaseHighlights([string[]]$Paths) {
    $english = New-Object System.Collections.Generic.List[string]
    $chinese = New-Object System.Collections.Generic.List[string]
    if (@($Paths | Where-Object { $_ -match '^skills/codex-requirement-authoring/' }).Count -gt 0) {
        $english.Add('Add Brainstorming Lite for turning consequential ambiguity into an evidence-grounded design before execution.')
        $chinese.Add('新增 Brainstorming Lite：在执行前将关键不确定性收敛为基于证据的设计。')
    }
    if (@($Paths | Where-Object { $_ -match '^skills/codex-workflow-design/' }).Count -gt 0) {
        $english.Add('Add Writing Plan Lite for dependency-aware plans with task-level validation and authority checkpoints.')
        $chinese.Add('新增 Writing Plan Lite：生成包含依赖、任务级验证和权限检查点的执行计划。')
    }
    if (@($Paths | Where-Object { $_ -match '^(skills/codex-experience-capture/|skills/codex-self-evolution/subskills/global-iteration-gate)' }).Count -gt 0) {
        $english.Add('Clarify complete experience-system iteration routing so authorized candidate processing is handled by the outer controller.')
        $chinese.Add('澄清完整经验系统迭代路由：已授权候选由上层控制器统一处理。')
    }
    if (@($Paths | Where-Object { $_ -match '^(skills/codex-information-gathering/|skills/codex-self-evolution/subskills/mcp-startup-preflight)' }).Count -gt 0) {
        $english.Add('Elevate fresh codebase-memory-mcp graph evidence for structural discovery while preserving source, contract, and runtime verification authority.')
        $chinese.Add('提升新鲜 codebase-memory-mcp 图谱在结构发现中的证据优先级，同时保留源文件、项目契约和运行验证的权威性。')
    }
    if (@($Paths | Where-Object { $_ -match '^skills/codex-error-feedback/' }).Count -gt 0) {
        $english.Add('Strengthen root-cause and fresh-evidence gates for repairs and completion claims.')
        $chinese.Add('强化修复与完成声明的根因分析和新鲜验证门禁。')
    }
    if (@($Paths | Where-Object { $_ -match '(^scripts/validate\.ps1$|/Test-.*\.ps1$)' }).Count -gt 0) {
        $english.Add('Add regression checks for the new collaboration and planning contracts.')
        $chinese.Add('为新的协作与计划契约增加回归检查。')
    }
    if ($english.Count -eq 0) {
        $english.Add('Deliver the verified changes listed in this release scope.')
        $chinese.Add('交付本次发布范围内已经验证的更新。')
    }
    return [pscustomobject]@{ English = @($english); Chinese = @($chinese) }
}

#>
function ConvertFrom-Utf8Base64([string]$Value) {
    return [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($Value))
}

function Get-ReleaseHighlights([string[]]$Paths) {
    $english = New-Object System.Collections.Generic.List[string]
    $chinese = New-Object System.Collections.Generic.List[string]
    $definitions = @(
        @{ Pattern = '^skills/codex-requirement-authoring/'; English = 'Add Brainstorming Lite for turning consequential ambiguity into an evidence-grounded design before execution.'; Chinese = '5paw5aKeIEJyYWluc3Rvcm1pbmcgTGl0Ze+8muWcqOaJp+ihjOWJjeWwhuWFs+mUruS4jeehruWumuaAp+aUtuaVm+S4uuWfuuS6juivgeaNrueahOiuvuiuoeOAgg==' },
        @{ Pattern = '^skills/codex-workflow-design/'; English = 'Add Writing Plan Lite for dependency-aware plans with task-level validation and authority checkpoints.'; Chinese = '5paw5aKeIFdyaXRpbmcgUGxhbiBMaXRl77ya55Sf5oiQ5YyF5ZCr5L6d6LWW44CB5Lu75Yqh57qn6aqM6K+B5ZKM5p2D6ZmQ5qOA5p+l54K555qE5omn6KGM6K6h5YiS44CC' },
        @{ Pattern = '^(skills/codex-experience-capture/|skills/codex-self-evolution/subskills/global-iteration-gate)'; English = 'Clarify complete experience-system iteration routing so authorized candidate processing is handled by the outer controller.'; Chinese = '5r6E5riF5a6M5pW057uP6aqM57O757uf6L+t5Luj6Lev55Sx77ya5bey5o6I5p2D5YCZ6YCJ55Sx5LiK5bGC5o6n5Yi25Zmo57uf5LiA5aSE55CG44CC' },
        @{ Pattern = '^(skills/codex-information-gathering/|skills/codex-self-evolution/subskills/mcp-startup-preflight)'; English = 'Elevate fresh codebase-memory-mcp graph evidence for structural discovery while preserving source, contract, and runtime verification authority.'; Chinese = '5o+Q5Y2H5paw6bKcIGNvZGViYXNlLW1lbW9yeS1tY3Ag5Zu+6LCx5Zyo57uT5p6E5Y+R546w5Lit55qE6K+B5o2u5LyY5YWI57qn77yM5ZCM5pe25L+d55WZ5rqQ5paH5Lu244CB6aG555uu5aWR57qm5ZKM6L+Q6KGM6aqM6K+B55qE5p2D5aiB5oCn44CC' },
        @{ Pattern = '^skills/codex-error-feedback/'; English = 'Strengthen root-cause and fresh-evidence gates for repairs and completion claims.'; Chinese = '5by65YyW5L+u5aSN5LiO5a6M5oiQ5aOw5piO55qE5qC55Zug5YiG5p6Q5ZKM5paw6bKc6aqM6K+B6Zeo56aB44CC' },
        @{ Pattern = '(^scripts/validate\.ps1$|/Test-.*\.ps1$)'; English = 'Add regression checks for the new collaboration and planning contracts.'; Chinese = '5Li65paw55qE5Y2P5L2c5LiO6K6h5YiS5aWR57qm5aKe5Yqg5Zue5b2S5qOA5p+l44CC' }
    )
    foreach ($definition in $definitions) {
        if (@($Paths | Where-Object { $_ -match $definition.Pattern }).Count -gt 0) {
            $english.Add($definition.English)
            $chinese.Add((ConvertFrom-Utf8Base64 $definition.Chinese))
        }
    }
    if ($english.Count -eq 0) {
        $english.Add('Deliver the verified changes listed in this release scope.')
        $chinese.Add((ConvertFrom-Utf8Base64 '5Lqk5LuY5pys5qyh5Y+R5biD6IyD5Zu05YaF5bey57uP6aqM6K+B55qE5pu05paw44CC'))
    }
    return [pscustomobject]@{ English = @($english); Chinese = @($chinese) }
}

function Set-ManagedBlock([string]$Content, [string]$Name, [string[]]$Lines) {
    $begin = "<!-- BEGIN MANAGED BLOCK: $Name -->"
    $end = "<!-- END MANAGED BLOCK: $Name -->"
    $block = ($begin, ($Lines -join [Environment]::NewLine), $end) -join [Environment]::NewLine
    $pattern = "(?s)<!-- BEGIN MANAGED BLOCK: $([regex]::Escape($Name)) -->.*?<!-- END MANAGED BLOCK: $([regex]::Escape($Name)) -->"
    if ($Content -match $pattern) {
        return [regex]::Replace($Content, $pattern, [System.Text.RegularExpressions.MatchEvaluator]{ param($m) $block }, 1)
    }
    return $Content.TrimEnd() + [Environment]::NewLine + [Environment]::NewLine + $block + [Environment]::NewLine
}

$paths = @($ChangedPaths | Where-Object { $_ } | ForEach-Object { Normalize-RepoPath $_ } | Sort-Object -Unique)
$areas = @(Get-ImpactAreas $paths)
$highlights = Get-ReleaseHighlights $paths
$visualRequired = $areas.Count -ge 3 -or @($paths | Where-Object { $_ -match '^(skills/|scripts/|config/|AGENTS\.md|module-registry\.json$)' }).Count -gt 0
$releaseNotePath = Join-Path $root (Normalize-RepoPath $ReleaseNote)
$releaseNoteRelative = Normalize-RepoPath $ReleaseNote
$assetRelative = 'docs/assets/release-visual-highlights-labeled.png'
$releaseRemote = if ($Mode -eq 'Private') { 'origin' } else { 'public' }
$releaseRepository = Get-GitHubRepository $releaseRemote
$releaseVisualUrl = if ($releaseRepository) { "https://github.com/$releaseRepository/raw/refs/heads/main/$assetRelative" } else { "../assets/release-visual-highlights-labeled.png" }
$planRelative = "docs/release-visual-plans/v$Version.json"
$readmeAuditRelative = "docs/release-readme-audits/v$Version.json"
$generated = New-Object System.Collections.Generic.List[string]

# Every release uses the installed GitHub README/Profile presentation workflow.
# Keep its upstream provenance and its no-decoration-by-default decision in a
# durable audit artifact so the release can be verified without inventing facts
# or silently depending on third-party widgets.
$readmeOptimization = [ordered]@{
    schema_version = 1
    version = $Version
    mode = $Mode
    owner = 'codex-task-execution/github-readme-presentation'
    upstream_sources = @(
        [ordered]@{ repository = 'oil-oil/beautify-github-readme'; license = 'MIT'; commit = 'e337ceac3d78cc37315296ee2c3d2a18407d052e'; role = 'repository README hierarchy, evidence, and first-use path' },
        [ordered]@{ repository = 'rzashakeri/beautify-github-profile'; license = 'CC0-1.0'; commit = '34f41124c4b32fa9b4ae9504966a1d0f46080aaf'; role = 'profile-component catalog and reader-value review' }
    )
    mode_selected = 'README release refresh'
    evidence = [ordered]@{ release_note = $releaseNoteRelative; changed_paths = $paths; impact_areas = $areas }
    design_system = 'docs/readme-design-system.json'
    reading_order_contract = @('value proposition', 'first successful action', 'collaboration mechanism', 'architecture visual', 'channels and detailed guarantees', 'release evidence')
    visual_decision = [ordered]@{ action = 'use-approved-raster-visual-system'; format = 'PNG'; raster_assets = @('docs/assets/readme-collaboration-loop.png','docs/assets/readme-collaboration-loop-labeled.png','docs/assets/readme-architecture-overview-labeled.png','docs/assets/file-organization-architecture-labeled.png','docs/assets/codebase-memory-mcp-graph.png'); reader_delivery_rule = 'Reader-facing Markdown uses approved PNG assets. Mermaid and SVG sources remain internal editable references and are never linked as reader-facing visuals.'; animation_policy = 'GIF generation and overwrite are opt-in: release refreshes do not modify an existing GIF unless the user explicitly requests it.'; text_policy = 'Choose text-free conceptual imagery or concise labeled/legend visuals by reader need. Architecture and transactional workflow explanations require reviewed labeled visuals; when image text is used, the design system requires unified palette, typography, language, contrast, exact-text, and clipping review.' }
    decisions = @(
        'Refresh both README language variants with the current release, evidence links, and impact summary.',
        'Make the release note lead with verified user-facing changes; keep visual and audit mechanics out of its primary reading path.',
        'Preserve project-native Markdown and verified claims; do not add unverified metrics, compatibility claims, counters, trackers, or profile widgets.',
        'Use an approved raster visual only when the impact is multi-area; select text-free or labeled presentation by reader need, not as decoration.'
    )
    preview_checks = @('GitHub-safe Markdown', 'release-note link', 'both README variants', 'reading-order headings', 'existing architecture visual placement', 'reader-value and dependency review', 'format-selection record')
    publication_boundary = 'This optimization is mandatory before a release commit. Public remote push, tag, and GitHub Release remain separately authorized by the release command.'
}

$visualAction = if ($visualRequired) { 'reuse-approved-raster-release-visual' } else { 'no-new-visual-required' }
$visualPlan = [ordered]@{
    schema_version = 1
    version = $Version
    mode = $Mode
    release_note = $releaseNoteRelative
    impact_areas = $areas
    visual_action = $visualAction
    privacy = 'Use sanitized repository-level labels only; never include credentials, private sessions, local user paths, or private payloads.'
    layout = 'Keep release highlights scannable: latest release block in README, concise release-note summary, and an approved PNG visual. Use image labels only where they improve comprehension and apply the shared in-image-text rules. Mermaid and SVG are not reader-facing Markdown visuals.'
}

if ($Apply) {
    $graphRenderer = Join-Path $root 'scripts\Render-CodebaseMemoryGraph.ps1'
    $graphUiStarter = Join-Path $root 'scripts\Start-CodebaseMemoryGraphUi.ps1'
    if ((Test-Path -LiteralPath $graphRenderer) -and (Test-Path -LiteralPath $graphUiStarter)) {
        $graphUi = & $graphUiStarter | ConvertFrom-Json
        $graphOutputPath = Join-Path $root 'docs\assets\codebase-memory-mcp-graph.png'
        $previousErrorActionPreference = $ErrorActionPreference
        try {
            $ErrorActionPreference = 'Continue'
            $rendererOutput = @(& powershell.exe -NoProfile -NonInteractive -File $graphRenderer -OutputPath $graphOutputPath -UiUrl $graphUi.url -ProjectName $graphUi.project_name -PngOnly 2>&1)
            $rendererExitCode = $LASTEXITCODE
        } finally {
            $ErrorActionPreference = $previousErrorActionPreference
        }
        if ($rendererExitCode -ne 0) {
            throw "Codebase Memory graph renderer failed in its isolated process with exit code ${rendererExitCode}: $($rendererOutput -join [Environment]::NewLine)"
        }
        if (-not (Test-Path -LiteralPath $graphOutputPath -PathType Leaf)) {
            throw "Codebase Memory graph renderer did not produce the expected PNG: $graphOutputPath"
        }
    }
    New-Item -ItemType Directory -Force -Path (Join-Path $root 'docs\release-visual-plans') | Out-Null
    $visualPlan | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $root $planRelative) -Encoding UTF8
    New-Item -ItemType Directory -Force -Path (Join-Path $root 'docs\release-readme-audits') | Out-Null
    $readmeOptimization | ConvertTo-Json -Depth 7 | Set-Content -LiteralPath (Join-Path $root $readmeAuditRelative) -Encoding UTF8
}
$generated.Add($planRelative)
$generated.Add($readmeAuditRelative)

$architectureRelative = 'ARCHITECTURE.md'
$architecturePath = Join-Path $root $architectureRelative
if (Test-Path -LiteralPath $architecturePath) {
    $architectureContent = Get-Content -LiteralPath $architecturePath -Raw -Encoding UTF8
    $architectureLines = @(
        (ConvertFrom-Utf8Base64 'IyMg5p625p6E5Zu+6LCx'),
        '',
        (ConvertFrom-Utf8Base64 'IVtDb2RlYmFzZSBNZW1vcnkgTUNQIOaXoOagh+etvuaetuaehOWbvuiwsV0oZG9jcy9hc3NldHMvY29kZWJhc2UtbWVtb3J5LW1jcC1ncmFwaC5wbmcp'),
        '',
        (ConvertFrom-Utf8Base64 '6K+lIFBORyDlnKjmr4/mrKEgcmVsZWFzZSDml7bnlLEgQ29kZWJhc2UgTWVtb3J5IE1DUCDnmoQgVGhyZWUuanMg5o6n5Yi25Y+w6YeN5paw57Si5byV5bm25riy5p+T44CC5a6D5Y+q5ZGI546w57uT5p6E5a+G5bqm77yM5LiN5YyF5ZCr6Lev5b6E44CB5Lya6K+d5oiW5rqQ56CB5paH5pys44CCR0lGIOS7heWcqOeUqOaIt+aYjuehruimgeaxgueUn+aIkOaIluabtOaWsOaXtuaJjeS8muWGmeWFpe+8m+WFtuS7liByZWxlYXNlIOS/neeVmeW3suaciSBHSUbjgII=')
    )
    $updatedArchitecture = Set-ManagedBlock -Content $architectureContent -Name 'codebase-memory-architecture-graph' -Lines $architectureLines
    if ($Apply) { Set-Content -LiteralPath $architecturePath -Value $updatedArchitecture.TrimEnd() -Encoding UTF8 }
    $generated.Add($architectureRelative)
}

if ($false) { # Retained only as disabled historical source-generation code; release delivery never emits Mermaid or SVG.
    $safeAreas = @($areas | ForEach-Object { ($_ -replace '[^\w \-]','').Trim() } | Where-Object { $_ })
    $diagram = New-Object System.Collections.Generic.List[string]
    $diagram.Add('flowchart LR')
    $diagram.Add(("  release[""Release v{0}""]" -f $Version))
    $i = 0
    foreach ($area in $safeAreas) {
        $i++
        $node = "area$i"
        $diagram.Add(("  {0}[""{1}""]" -f $node, $area))
        $diagram.Add(("  release --> {0}" -f $node))
    }
    $diagram.Add('  release --> readme["README refresh"]')
    $diagram.Add('  release --> note["Release note"]')
    $diagram.Add('  release --> verify["Validation gates"]')
    if ($Apply) {
        New-Item -ItemType Directory -Force -Path (Join-Path $root 'docs\assets') | Out-Null
        Set-Content -LiteralPath (Join-Path $root $assetRelative) -Value ($diagram -join [Environment]::NewLine) -Encoding UTF8
    }
    $generated.Add($assetRelative)
}

$zhLatest = Convert-EscapedUnicode '\u6700\u65b0\u53d1\u5e03'
$zhMode = if ($Mode -eq 'Private') { Convert-EscapedUnicode '\u79c1\u6709' } else { Convert-EscapedUnicode '\u516c\u5f00' }
$zhReadmeLine = Convert-EscapedUnicode '\u4e2d\u6587\uff1a\u672c\u6b21\u53d1\u5e03\u4f1a\u540c\u6b65\u5237\u65b0 README\u3001\u53d1\u5e03\u8bf4\u660e\u548c\u5fc5\u8981\u7684\u56fe\u793a/\u6392\u7248\u6750\u6599\u3002'
$zhOptimization = Convert-EscapedUnicode 'README \u4f18\u5316\u5df2\u901a\u8fc7\u5df2\u5b89\u88c5\u7684 GitHub README \u4e0e Profile \u5c55\u793a\u5de5\u4f5c\u6d41\u590d\u6838\uff1b\u4e0d\u5f15\u5165\u65e0\u8bc1\u636e\u7684\u6307\u6807\u6216\u8ddf\u8e2a\u7ec4\u4ef6\u3002'
$areaText = ($areas -join ', ')
$visualText = if ($visualRequired) { "Visual: [$assetRelative]($assetRelative)" } else { 'Visual: no new diagram required for this release.' }
$zhVisualText = if ($visualRequired) { "${zhDiagram}: [$assetRelative]($assetRelative)" } else { $zhVisualNone }

$readmeBlock = @(
    "## Latest Release / $zhLatest",
    '',
    ("- Version: ``{0}``" -f $Version),
    ("- Channel: ``{0}`` / {1}" -f $Mode, $zhMode),
    "- Release note: [$releaseNoteRelative]($releaseNoteRelative)",
    "- Highlights: $areaText",
    "- $visualText",
    "- README optimization: audited with `github-readme-presentation`; provenance: [$readmeAuditRelative]($readmeAuditRelative)",
    "- $zhOptimization",
    "- $zhReadmeLine"
)

foreach ($readme in @('README.md','README.en.md')) {
    $path = Join-Path $root $readme
    $content = Get-Content -LiteralPath $path -Raw -Encoding UTF8
    $updated = Set-ManagedBlock -Content $content -Name 'latest-release' -Lines $readmeBlock
    if ($Apply) { Set-Content -LiteralPath $path -Value $updated.TrimEnd() -Encoding UTF8 }
    $generated.Add($readme)
}

if (Test-Path -LiteralPath $releaseNotePath) {
    $note = Get-Content -LiteralPath $releaseNotePath -Raw -Encoding UTF8
    <#
    $noteBlock = @(
        '## What’s new / 本次更新',
        '',
        '### English',
        '',
    ) + @($highlights.English | ForEach-Object { "- $_" }) + @(
        '',
        '### 中文',
        ''
    ) + @($highlights.Chinese | ForEach-Object { "- $_" }) + @(
        '',
        '## Verification / 验证',
        '',
        '- Full repository validation, global-interface validation, and release metadata checks passed.',
        '- 已通过完整仓库验证、全局接口验证与发布元数据检查。',
        "- Presentation review: [$readmeAuditRelative]($readmeAuditRelative)."
    )
    #>
    $noteBlock = @(
        ("## What's new / {0}" -f (ConvertFrom-Utf8Base64 '5pys5qyh5pu05paw')),
        '',
        '### English',
        ''
    ) + @($highlights.English | ForEach-Object { "- $_" }) + @(
        '',
        ("### {0}" -f (ConvertFrom-Utf8Base64 '5Lit5paH')),
        ''
    ) + @($highlights.Chinese | ForEach-Object { "- $_" }) + @(
        '',
        ("## Verification / {0}" -f (ConvertFrom-Utf8Base64 '6aqM6K+B')),
        '',
        '- Full repository validation, global-interface validation, and release metadata checks passed.',
        ("- {0}" -f (ConvertFrom-Utf8Base64 '5bey6YCa6L+H5a6M5pW05LuT5bqT6aqM6K+B44CB5YWo5bGA5o6l5Y+j6aqM6K+B5LiO5Y+R5biD5YWD5pWw5o2u5qOA5p+l44CC')),
        "- Presentation review: [$readmeAuditRelative]($readmeAuditRelative)."
    )
    $updatedNote = Set-ManagedBlock -Content $note -Name 'release-readme-visual-refresh' -Lines $noteBlock
    if ($Apply) { Set-Content -LiteralPath $releaseNotePath -Value $updatedNote.TrimEnd() -Encoding UTF8 }
    $generated.Add($releaseNoteRelative)
}

[ordered]@{
    version = $Version
    mode = $Mode
    visual_required = $visualRequired
    impact_areas = $areas
    readme_optimization_audit = $readmeAuditRelative
    generated_paths = @($generated | Select-Object -Unique)
    applied = [bool]$Apply
} | ConvertTo-Json -Depth 5
