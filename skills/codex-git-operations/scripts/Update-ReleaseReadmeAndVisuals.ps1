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
$visualRequired = $areas.Count -ge 3 -or @($paths | Where-Object { $_ -match '^(skills/|scripts/|config/|AGENTS\.md|module-registry\.json$)' }).Count -gt 0
$releaseNotePath = Join-Path $root (Normalize-RepoPath $ReleaseNote)
$releaseNoteRelative = Normalize-RepoPath $ReleaseNote
$assetRelative = "docs/assets/release-v$Version-highlights.mmd"
$planRelative = "docs/release-visual-plans/v$Version.json"
$generated = New-Object System.Collections.Generic.List[string]

$visualAction = if ($visualRequired) { 'generate-mermaid-release-visual' } else { 'no-new-visual-required' }
$visualPlan = [ordered]@{
    schema_version = 1
    version = $Version
    mode = $Mode
    release_note = $releaseNoteRelative
    impact_areas = $areas
    visual_action = $visualAction
    privacy = 'Use sanitized repository-level labels only; never include credentials, private sessions, local user paths, or private payloads.'
    layout = 'Keep release highlights scannable: latest release block in README, concise release-note summary, and a Mermaid visual when several areas are affected.'
}

if ($Apply) {
    New-Item -ItemType Directory -Force -Path (Join-Path $root 'docs\release-visual-plans') | Out-Null
    $visualPlan | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $root $planRelative) -Encoding UTF8
}
$generated.Add($planRelative)

if ($visualRequired) {
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
$zhDiagram = Convert-EscapedUnicode '\u56fe\u793a'
$zhReadmeLine = Convert-EscapedUnicode '\u4e2d\u6587\uff1a\u672c\u6b21\u53d1\u5e03\u4f1a\u540c\u6b65\u5237\u65b0 README\u3001\u53d1\u5e03\u8bf4\u660e\u548c\u5fc5\u8981\u7684\u56fe\u793a/\u6392\u7248\u6750\u6599\u3002'
$zhReleaseLine = Convert-EscapedUnicode '\u4e2d\u6587\uff1a\u672c\u6b21\u53d1\u5e03\u4f1a\u91cd\u65b0\u540c\u6b65 README\uff0c\u5e76\u5728\u5fc5\u8981\u5904\u751f\u6210\u56fe\u793a\u4e0e\u6392\u7248\u8f85\u52a9\u6750\u6599\u3002'
$zhVisualNone = Convert-EscapedUnicode '\u56fe\u793a\uff1a\u672c\u6b21\u53d1\u5e03\u65e0\u9700\u65b0\u589e\u56fe\u793a\u3002'
$zhRefreshHeading = Convert-EscapedUnicode 'README \u4e0e\u56fe\u793a\u5237\u65b0'
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
    "- $zhReadmeLine"
)

foreach ($readme in @('README.md','README.en.md')) {
    $path = Join-Path $root $readme
    $content = Get-Content -LiteralPath $path -Raw -Encoding UTF8
    $updated = Set-ManagedBlock -Content $content -Name 'latest-release' -Lines $readmeBlock
    if ($Apply) { Set-Content -LiteralPath $path -Value $updated -Encoding UTF8 }
    $generated.Add($readme)
}

if (Test-Path -LiteralPath $releaseNotePath) {
    $note = Get-Content -LiteralPath $releaseNotePath -Raw -Encoding UTF8
    $impactLines = @($areas | ForEach-Object { "- $_" })
    $noteBlock = @(
        "## README And Visual Refresh / $zhRefreshHeading",
        '',
        '- README.md and README.en.md are refreshed for this release.',
        "- Impact areas: $areaText",
        "- $visualText",
        "- $zhReleaseLine",
        "- $zhVisualText",
        '',
        '### Impact Areas',
        ''
    ) + $impactLines
    $updatedNote = Set-ManagedBlock -Content $note -Name 'release-readme-visual-refresh' -Lines $noteBlock
    if ($Apply) { Set-Content -LiteralPath $releaseNotePath -Value $updatedNote -Encoding UTF8 }
    $generated.Add($releaseNoteRelative)
}

[ordered]@{
    version = $Version
    mode = $Mode
    visual_required = $visualRequired
    impact_areas = $areas
    generated_paths = @($generated | Select-Object -Unique)
    applied = [bool]$Apply
} | ConvertTo-Json -Depth 5
