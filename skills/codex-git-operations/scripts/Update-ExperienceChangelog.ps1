[CmdletBinding()]
param(
    [string]$RepositoryRoot = (Get-Location).Path,
    [string]$Version = '',
    [string[]]$ChangedPaths = @(),
    [ValidateSet('Feature', 'Refinement', 'Release')]
    [string]$ChangeClass = 'Feature',
    [switch]$Apply
)

$ErrorActionPreference = 'Stop'

function Convert-EscapedUnicode([string]$Value) {
    return [regex]::Unescape($Value)
}

$root = (Resolve-Path -LiteralPath $RepositoryRoot).Path
if (-not $Version) {
    $Version = (Get-Content -LiteralPath (Join-Path $root 'VERSION') -Raw -Encoding UTF8).Trim()
}
if (-not $ChangedPaths -or $ChangedPaths.Count -eq 0) {
    $ChangedPaths = @(
        & git -C $root diff --name-only
        & git -C $root diff --cached --name-only
        & git -C $root ls-files --others --exclude-standard
    ) | Sort-Object -Unique
}

$paths = @($ChangedPaths | Where-Object { $_ } | Sort-Object -Unique)
$changelogPath = Join-Path $root 'CHANGELOG.md'
$existing = if (Test-Path -LiteralPath $changelogPath) {
    Get-Content -LiteralPath $changelogPath -Raw -Encoding UTF8
} else {
    "# Changelog / Update Log`r`n"
}
$hasSection = $existing -match "(?m)^##\s+$([regex]::Escape($Version))\b"

$english = New-Object System.Collections.Generic.List[string]
if ($paths | Where-Object { $_ -like 'skills/codex-skill-packaging/*' -or $_ -eq 'skills/codex-skill-packaging/SKILL.md' }) {
    $english.Add('Add parent-skill refinement packaging so broad owner skills can stay concise while detailed gates move into owner-internal subskills.')
}
if ($paths | Where-Object { $_ -like 'skills/codex-self-evolution/*' -or $_ -eq 'skills/codex-self-evolution/SKILL.md' }) {
    $english.Add('Refine the self-evolution controller into a routing parent with internal global-iteration and publication-gate subskills.')
}
if ($paths | Where-Object { $_ -like 'skills/codex-experience-capture/*' -or $_ -like 'skills/codex-knowledge-system/*' -or $_ -like 'skills/codex-error-feedback/*' }) {
    $english.Add('Package experience capture, knowledge, and error-feedback modes as owner-internal subskills while preserving their parent discovery surfaces.')
}
if ($paths | Where-Object { $_ -like 'skills/codex-image-workflow/subskills/figure-optimization/*' }) {
    $english.Add('Install the academic figure optimizer as a data-faithful figure-rendering skill with publication-format checks.')
}
if ($paths | Where-Object { $_ -like 'scripts/Invoke-ContinuousIterationDiagnosis.ps1' -or $_ -like 'scripts/Test-ContinuousIterationDiagnosis.ps1' }) {
    $english.Add('Add continuous diagnosis support for safe fail-repair-retest global iteration workflows.')
}
if ($paths | Where-Object { $_ -like 'knowledge-vault/*' }) {
    $english.Add('Regenerate linked knowledge, learning outputs, and mind-map artifacts for the verified architecture changes.')
}
if ($english.Count -eq 0) {
    $english.Add("Record verified automatic $ChangeClass iteration updates for the scoped changed paths.")
}

$zhHeading = Convert-EscapedUnicode '\u4e2d\u6587'
$chinese = New-Object System.Collections.Generic.List[string]
$chinese.Add((Convert-EscapedUnicode '\u540c\u6b65\u8bb0\u5f55\u672c\u6b21\u5df2\u9a8c\u8bc1\u7684\u7ecf\u9a8c\u7cfb\u7edf\u8fed\u4ee3\uff0c\u786e\u4fdd\u66f4\u65b0\u65e5\u5fd7\u4e0e\u7248\u672c\u5316\u884c\u4e3a\u4e00\u81f4\u3002'))
if ($paths | Where-Object { $_ -like 'skills/codex-skill-packaging/*' -or $_ -like 'skills/codex-self-evolution/*' }) {
    $chinese.Add((Convert-EscapedUnicode '\u65b0\u589e\u6bcd skill \u63d0\u70bc\u4e0e\u5185\u90e8\u5b50 skill \u95e8\u7981\u62c6\u5206\u89c4\u5219\uff0c\u51cf\u5c11\u9876\u5c42\u5165\u53e3\u81a8\u80c0\u3002'))
}
if ($paths | Where-Object { $_ -like 'skills/codex-experience-capture/*' -or $_ -like 'skills/codex-knowledge-system/*' -or $_ -like 'skills/codex-error-feedback/*' }) {
    $chinese.Add((Convert-EscapedUnicode '\u5c06\u7ecf\u9a8c\u3001\u77e5\u8bc6\u4e0e\u9519\u8bef\u53cd\u9988\u7684\u957f\u6d41\u7a0b\u4e0b\u6c89\u4e3a owner \u5185\u90e8\u5b50 skill\uff0c\u5e76\u4fdd\u7559\u7236\u5165\u53e3\u53d1\u73b0\u8fb9\u754c\u3002'))
}
if ($paths | Where-Object { $_ -like 'skills/codex-image-workflow/subskills/figure-optimization/*' }) {
    $chinese.Add((Convert-EscapedUnicode '\u5b89\u88c5\u5e76\u8bb0\u5f55\u5b66\u672f\u56fe\u5f62\u4f18\u5316\u80fd\u529b\uff0c\u4fdd\u6301\u6570\u636e\u3001\u5c3a\u5bf8\u3001\u683c\u5f0f\u4e0e\u8d28\u91cf\u68c0\u67e5\u8fb9\u754c\u3002'))
}

$date = (Get-Date).ToString('yyyy-MM-dd')
$section = @(
    "## $Version - $date",
    '',
    '### English',
    ''
) + @($english | ForEach-Object { "- $_" }) + @(
    '',
    "### Chinese / $zhHeading",
    ''
) + @($chinese | ForEach-Object { "- $_" }) + @('')

if (-not $hasSection -and $Apply) {
    $lines = $existing -split "\r?\n"
    $title = if ($lines.Count -gt 0) { $lines[0] } else { '# Changelog / Update Log' }
    $rest = if ($lines.Count -gt 1) { ($lines[1..($lines.Count - 1)] -join [Environment]::NewLine).TrimStart() } else { '' }
    $updated = $title + [Environment]::NewLine + [Environment]::NewLine + (($section -join [Environment]::NewLine).TrimEnd()) + [Environment]::NewLine + [Environment]::NewLine + $rest.TrimStart()
    Set-Content -LiteralPath $changelogPath -Value $updated -Encoding UTF8
}

if ($hasSection -and $Apply -and $ChangeClass -eq 'Release') {
    $releaseEnglish = 'Publish the verified experience-system release metadata, private tag, and release notes for the current version.'
    $releaseChinese = Convert-EscapedUnicode '\u540c\u6b65\u53d1\u5e03\u5f53\u524d\u7248\u672c\u7684\u7ecf\u9a8c\u7cfb\u7edf\u53d1\u5e03\u5143\u6570\u636e\u3001\u79c1\u6709\u6807\u7b7e\u4e0e\u53d1\u5e03\u8bf4\u660e\u3002'
    if ($existing -notmatch [regex]::Escape($releaseEnglish)) {
        $sectionPattern = "(?ms)^##\s+$([regex]::Escape($Version))\b.*?(?=^##\s+|\z)"
        $updated = [regex]::Replace($existing, $sectionPattern, {
            param($match)
            $value = $match.Value
            $value = [regex]::Replace(
                $value,
                "(?m)(### English\s*\r?\n\s*\r?\n)",
                ('$1' + "- $releaseEnglish`r`n"),
                1
            )
            $value = [regex]::Replace(
                $value,
                "(?m)(### Chinese / .+\s*\r?\n\s*\r?\n)",
                ('$1' + "- $releaseChinese`r`n"),
                1
            )
            return $value
        }, 1)
        Set-Content -LiteralPath $changelogPath -Value $updated.TrimEnd() -Encoding UTF8
    }
}

[ordered]@{
    version = $Version
    changelog_path = 'CHANGELOG.md'
    had_section = $hasSection
    applied = [bool]$Apply
    generated_items = $english.Count
} | ConvertTo-Json
