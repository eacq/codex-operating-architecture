[CmdletBinding()]
param(
    [string]$ProjectRoot = (Get-Location).Path,
    [string]$OutputDirectory,
    [switch]$Apply
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath $ProjectRoot).Path
if (-not $OutputDirectory) { $OutputDirectory = Join-Path $root '.codex\project\candidate-reports' }
$candidateChineseHeading = [string]([char]0x5019) + [char]0x9009 + [char]0x7ECF + [char]0x9A8C
function Decode-Base64Utf8([string]$Value) { return [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($Value)) }
$zh = [ordered]@{
    project_experience = Decode-Base64Utf8 '6aG555uu57uP6aqM'
    experience_ledger = Decode-Base64Utf8 '57uP6aqM5oC76LSm'
    linked_knowledge = Decode-Base64Utf8 '5YWz6IGU55+l6K+G'
    workflow_learning = Decode-Base64Utf8 '5bel5L2c5rWB5a2m5Lmg'
    error_feedback = Decode-Base64Utf8 '6ZSZ6K+v5Y+N6aaI'
    other = Decode-Base64Utf8 '5YW25LuW5YCZ6YCJ5p2l5rqQ'
    external_action = Decode-Base64Utf8 '5aaC6ZyA5a6J6KOF44CB5pu05paw44CB6L+Q6KGM546v5aKD5oiW6YeN5paw6YWN572u77yM6K+35YWI5b6B5rGC55So5oi35piO56Gu5o6I5p2D44CC'
    ordinary_action = Decode-Base64Utf8 '6K+355Sx55So5oi35Yaz5a6a77ya5L+d55WZ44CB6aqM6K+B6K+V55So44CB5q2j5byP5o6o5bm/5oiW5reY5rGw44CC'
    external_boundary = Decode-Base64Utf8 '5pys5oql5ZGK5LiN5o6I5p2D5aSW6YOo5a6J6KOF44CB5pu05paw5oiW6YeN5paw6YWN572u44CC'
    ordinary_boundary = Decode-Base64Utf8 '5pys5oql5ZGK5LiN6Ieq5Yqo5o6o5bm/5YCZ6YCJ77yM5Lmf5LiN5omn6KGM5aSW6YOo5pON5L2c44CC'
    title = Decode-Base64Utf8 'IyDlhajlsYDov63ku6PlgJnpgInmiqXlkYo='
    generated = Decode-Base64Utf8 '55Sf5oiQ5pe26Ze077ya'
    count = Decode-Base64Utf8 '5YCZ6YCJ5oC76YeP77ya'
    advisory = Decode-Base64Utf8 'PiDmnKzmiqXlkYrku4XkvpvlhrPnrZblj4LogIPvvJrkuI3kvJroh6rliqjmjqjlub/lgJnpgInvvIzkuZ/kuI3kvJrmjojmnYPmiJbmiafooYzlronoo4XjgIHmm7TmlrDjgIHphY3nva7jgIHlj5HluIPjgIHliKDpmaTnrYnlpJbpg6jmk43kvZzjgII='
    reading_heading = Decode-Base64Utf8 'IyMg57uZ55So5oi355qE6ZiF6K+76K+05piO'
    reading_primary = Decode-Base64Utf8 'LSDmnKzpobXkuK3mloflhoXlrrnmmK/kuLvmiqXlkYrvvJvor7flhYjnnIvmr4/pobnnmoTigJzlu7rorq7lhrPnrZbigJ3lkozigJzmjojmnYPovrnnlYzigJ3jgII='
    reading_source = Decode-Base64Utf8 'LSDlgJnpgInmkZjopoHkv53mjIHmnaXmupDljp/mlofvvIzpgb/lhY3oh6rliqjnv7vor5HpgKDmiJDlkKvkuYnmvILnp7vvvJvlrozmlbTkuIrkuIvmloflj6/mjInigJzmnaXmupDigJ3lrprkvY3jgII='
    reading_appendix = Decode-Base64Utf8 'LSDmiqXlkYrmnKvlsL7pmYTmnInkvpvlpKfmqKHlnovnu4/pqozns7vnu5/nqLPlrprop6PmnpDnmoToi7Hmlofnu5PmnoTljJbpmYTlvZXjgII='
    none = Decode-Base64Utf8 '5b2T5YmN5rKh5pyJ5Y+R546w6ZyA6KaB5Yaz562W55qE5YCZ6YCJ6aG344CC'
    summary = Decode-Base64Utf8 '5YCZ6YCJ5pGY6KaB77ya'
    source = Decode-Base64Utf8 '5p2l5rqQ77ya'
    evidence = Decode-Base64Utf8 '6K+B5o2u77ya'
    decision = Decode-Base64Utf8 '5bu66K6u5Yaz562W77ya'
    boundary = Decode-Base64Utf8 '5o6I5p2D6L6555WM77ya'
}
$categoryLabels = [ordered]@{
    'project-experience' = $zh.project_experience
    'experience-ledger' = $zh.experience_ledger
    'linked-knowledge' = $zh.linked_knowledge
    'workflow-learning' = $zh.workflow_learning
    'error-feedback' = $zh.error_feedback
}

function Get-RelativePath([string]$Path) {
    return (($Path.Substring($root.Length)).TrimStart('\', '/') -replace '\\', '/')
}

function Get-VsCodeFileUri([string]$Path) {
    $normalized = $Path -replace '\\', '/'
    return 'vscode://file/' + [Uri]::EscapeUriString($normalized)
}

function New-CandidateItem([string]$Category, [string]$Title, [string]$Summary, [string]$Source, [string]$Evidence) {
    $externalChange = $Summary -match '(?i)install|runtime|upgrade|reconfigure'
    $recommendedAction = if ($externalChange) { 'request explicit authorization before external change' } else { 'review: retain, test, promote, or retire' }
    $authorizationBoundary = if ($externalChange) { 'external install/update/reconfiguration requires explicit approval' } else { 'no automatic promotion or external action' }
    return [pscustomobject][ordered]@{
        category = $Category
        title = $Title
        summary = $Summary
        source = $Source
        evidence = $Evidence
        recommended_action = $recommendedAction
        authorization_boundary = $authorizationBoundary
        user_view = [ordered]@{
            category = if ($categoryLabels.Contains($Category)) { $categoryLabels[$Category] } else { $zh.other }
            recommended_action = if ($externalChange) { $zh.external_action } else { $zh.ordinary_action }
            authorization_boundary = if ($externalChange) { $zh.external_boundary } else { $zh.ordinary_boundary }
        }
        model_view = [ordered]@{
            category_label = if ($categoryLabels.Contains($Category)) { $Category } else { 'other-candidate-source' }
            content_language = 'source-preserved'
            summary_note = 'Candidate wording is preserved verbatim for auditability; use the source path for full context.'
            recommended_action = $recommendedAction
            authorization_boundary = $authorizationBoundary
        }
    }
}

function Get-CandidateBullets([string]$Path, [string]$Category) {
    if (-not (Test-Path -LiteralPath $Path)) { return @() }
    $lines = @(Get-Content -LiteralPath $Path -Encoding UTF8)
    $active = $false
    $items = @()
    foreach ($line in $lines) {
        if ($line -match '^#{1,3}\s+') {
            $active = ($line -match '(?i)candidates') -or $line.Contains($candidateChineseHeading)
            continue
        }
        if ($active -and $line -match '^\s*-\s+(.+)$') {
            $summary = $Matches[1].Trim()
            if ($summary) {
                $title = if ($summary.Length -gt 96) { $summary.Substring(0, 96) + '...' } else { $summary }
                $items += New-CandidateItem $Category $title $summary (Get-RelativePath $Path) 'candidate-section bullet'
            }
        }
    }
    return @($items)
}

function Get-FrontMatterValue([string[]]$Lines, [string]$Key) {
    $match = @($Lines | Where-Object { $_ -match "^$([regex]::Escape($Key)):\s*(.+)$" } | Select-Object -First 1)
    if ($match.Count -eq 0) { return $null }
    return ($match[0] -replace "^$([regex]::Escape($Key)):\s*", '').Trim().Trim('"', "'")
}

$items = @()
$items += Get-CandidateBullets (Join-Path $root '.codex\project\EXPERIENCE.md') 'project-experience'
$items += Get-CandidateBullets (Join-Path $root 'knowledge\experience-ledger.md') 'experience-ledger'

$vault = Join-Path $root 'knowledge-vault'
if (Test-Path -LiteralPath $vault) {
    Get-ChildItem -LiteralPath $vault -Recurse -Filter '*.md' -File | ForEach-Object {
        $relativeSource = Get-RelativePath $_.FullName
        if ($relativeSource -match '^knowledge-vault/Templates/') { return }
        $lines = @(Get-Content -LiteralPath $_.FullName -Encoding UTF8 -TotalCount 20)
        if (($lines -join "`n") -match '(?m)^status:\s*candidate\s*$') {
            $title = @($lines | Where-Object { $_ -match '^#\s+' } | Select-Object -First 1)
            $itemTitle = if ($title.Count) { ($title[0] -replace '^#\s+', '').Trim() } else { $_.BaseName }
            $summary = "Candidate linked knowledge: $(Get-FrontMatterValue $lines 'codex_learning')"
            $items += New-CandidateItem 'linked-knowledge' $itemTitle $summary $relativeSource 'knowledge status=candidate'
        }
    }
}

$workflowPath = Join-Path $root '.codex\project\workflow-learning.json'
if (Test-Path -LiteralPath $workflowPath) {
    $workflow = Get-Content -LiteralPath $workflowPath -Raw -Encoding UTF8 | ConvertFrom-Json
    $items += New-CandidateItem 'workflow-learning' 'Current workflow-learning record' "Knowledge: $($workflow.knowledge_status); experience: $($workflow.experience_status)." '.codex/project/workflow-learning.json' 'hash-based workflow-learning record'
}

$errorsRoot = Join-Path $root '.codex\errors'
if (Test-Path -LiteralPath $errorsRoot) {
    Get-ChildItem -LiteralPath $errorsRoot -Recurse -Filter 'report.json' -File | ForEach-Object {
        $errorReport = Get-Content -LiteralPath $_.FullName -Raw -Encoding UTF8 | ConvertFrom-Json
        if ($errorReport.status -eq 'candidate') {
            $items += New-CandidateItem 'error-feedback' "Candidate error feedback: $($errorReport.module)" $errorReport.symptom (Get-RelativePath $_.FullName) 'error report status=candidate'
        }
    }
}

$deduped = @($items | Group-Object { "$($_.category)|$($_.source)|$($_.title)" } | ForEach-Object { $_.Group | Select-Object -First 1 })
$report = [ordered]@{
    schema_version = 2
    result = 'generated'
    generated_at = [DateTime]::UtcNow.ToString('o')
    project_root = '.'
    candidate_count = $deduped.Count
    category_counts = [ordered]@{}
    decision_rule = 'Advisory only. The report never promotes, installs, updates, configures, publishes, or deletes anything.'
    human_reading_rule = 'Chinese is the primary user-facing report. Candidate wording remains source-preserved to avoid changing its meaning.'
    model_reading_rule = 'The English model appendix uses stable English fields. Candidate wording is source-preserved for auditability and may be Chinese; follow source paths for full context.'
    candidates = $deduped
}
foreach ($group in @($deduped | Group-Object category)) { $report.category_counts[$group.Name] = $group.Count }

$markdown = @($zh.title, '', "$($zh.generated)$($report.generated_at)", "$($zh.count)$($report.candidate_count)", '', $zh.advisory, '', $zh.reading_heading, '', $zh.reading_primary, $zh.reading_source, $zh.reading_appendix, '')
if ($deduped.Count -eq 0) {
    $markdown += $zh.none
} else {
    foreach ($group in @($deduped | Group-Object category | Sort-Object Name)) {
        $categoryLabel = if ($categoryLabels.Contains($group.Name)) { $categoryLabels[$group.Name] } else { $zh.other }
        $markdown += "## $categoryLabel"
        $markdown += ''
        foreach ($item in $group.Group) {
            $markdown += "- **$($item.title)**"
            $markdown += "  - $($zh.summary)$($item.summary)"
            $markdown += "  - $($zh.source)$($item.source)"
            $markdown += "  - $($zh.evidence)$($item.evidence)"
            $markdown += "  - $($zh.decision)$($item.user_view.recommended_action)"
            $markdown += "  - $($zh.boundary)$($item.user_view.authorization_boundary)"
        }
        $markdown += ''
    }
}

$markdown += @('## English appendix for the experience system', '', '> Machine-reading contract: stable English field names are in `latest.json`. Candidate wording is source-preserved for auditability and may remain Chinese.', '')
foreach ($group in @($deduped | Group-Object category | Sort-Object Name)) {
    $markdown += "### $($group.Name)"
    $markdown += ''
    foreach ($item in $group.Group) {
        $markdown += "- title: $($item.title)"
        $markdown += "  - source: $($item.source)"
        $markdown += "  - evidence: $($item.evidence)"
        $markdown += "  - recommended_action: $($item.model_view.recommended_action)"
        $markdown += "  - authorization_boundary: $($item.model_view.authorization_boundary)"
        $markdown += "  - content_language: $($item.model_view.content_language)"
    }
    $markdown += ''
}

if ($Apply) {
    New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
    $jsonPath = Join-Path $OutputDirectory 'latest.json'
    $markdownPath = Join-Path $OutputDirectory 'latest.md'
    $report.output = [ordered]@{ json = Get-RelativePath $jsonPath; markdown = Get-RelativePath $markdownPath }
    $report.open_uri = 'codex-report://latest'
    $report.vscode_uri = Get-VsCodeFileUri $markdownPath
    $report | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $jsonPath -Encoding UTF8
    $markdown = @($markdown[0..3] + '> Codex-chat delivery: render this report directly in the assistant response. Chat clicks on local launcher files open source in the sidebar and do not execute commands.' + '> Manual local launcher: Open-LatestGlobalIterationCandidateReport.cmd (run it from File Explorer or a terminal if a local VS Code view is needed).' + '' + $markdown[4..($markdown.Count - 1)])
    $markdown | Set-Content -LiteralPath $markdownPath -Encoding UTF8
}
$report | ConvertTo-Json -Depth 8
