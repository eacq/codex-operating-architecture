[CmdletBinding()]
param(
    [string]$ProjectRoot = (Get-Location).Path,
    [string]$Module = 'unrouted',
    [string]$Component = 'unspecified',
    [string]$CodeLocation = '',
    [string]$CodeFile = '',
    [int]$StartLine = 0,
    [int]$EndLine = 0,
    [string]$CodeExcerpt = '',
    [string]$Symptom,
    [string]$UserReport = '',
    [string]$UserReportFile = '',
    [string]$ExpectedResult = '',
    [string]$ActualResult = '',
    [string]$Features = '',
    [string]$SuspectedCauses = '',
    [string]$PossibleOutcomes = '',
    [string]$Solutions = '',
    [string]$Verification = '',
    [ValidateSet('info','low','medium','high','critical')]
    [string]$Severity = 'medium',
    [ValidateSet('low','medium','high')]
    [string]$Confidence = 'medium',
    [ValidateSet('observed','triaged','fixed','verified','candidate')]
    [string]$Status = 'observed',
    [string]$Trigger = '',
    [string]$OriginProjectRoot = '',
    [string]$OriginProjectName = '',
    [string]$OriginWorkflow = '',
    [string[]]$GlobalExperienceFunctions = @(),
    [ValidateSet('none','suspected','partial','primary','verified')]
    [string]$ExperienceSystemCausality = 'none',
    [string]$ArchitectureRoot = '',
    [switch]$MirrorToGlobalExperienceSystem,
    [string]$RepairAttempt = '',
    [string]$RepairResult = '',
    [string]$ReportDirectory = '',
    [string]$ReusableLesson = '',
    [switch]$UpdateExperienceCandidates
)

$ErrorActionPreference = 'Stop'

if ($UserReportFile) {
    if (-not (Test-Path -LiteralPath $UserReportFile -PathType Leaf)) { throw "User report file not found: $UserReportFile" }
    $UserReport = Get-Content -LiteralPath $UserReportFile -Raw -Encoding UTF8
}

function Get-SafeFileName([string]$Value) {
    $name = ($Value -replace '[^\p{L}\p{Nd}\._-]+', '-').Trim('-')
    if (-not $name) { return 'error-feedback' }
    if ($name.Length -gt 80) { return $name.Substring(0, 80).Trim('-') }
    return $name
}

function Redact-Text([string]$Text) {
    if (-not $Text) { return '' }
    $redacted = $Text
    $redacted = [regex]::Replace($redacted, '(?i)(api[_-]?key|token|secret|password|cookie|authorization)\s*[:=]\s*["'']?[^"''\s]+', '$1=[REDACTED]')
    $redacted = [regex]::Replace($redacted, 'sk-[A-Za-z0-9_\-]{12,}', '[REDACTED_OPENAI_KEY]')
    $redacted = [regex]::Replace($redacted, '(?i)bearer\s+[A-Za-z0-9._\-]+', 'Bearer [REDACTED]')
    return $redacted
}

function Write-Utf8NoBom([string]$Path, [string]$Value) {
    [IO.File]::WriteAllText($Path, $Value, [Text.UTF8Encoding]::new($false))
}

function Add-Utf8NoBomLine([string]$Path, [string]$Value) {
    $parent = Split-Path -Parent $Path
    if ($parent) { New-Item -ItemType Directory -Force -Path $parent | Out-Null }
    $existing = if (Test-Path -LiteralPath $Path) { [IO.File]::ReadAllText($Path, [Text.UTF8Encoding]::new($false)) } else { '' }
    [IO.File]::WriteAllText($Path, $existing.TrimEnd() + [Environment]::NewLine + $Value + [Environment]::NewLine, [Text.UTF8Encoding]::new($false))
}

function Get-ReportedIssues([string]$Text) {
    if (-not $Text) { return @() }
    $markers = '(?i)(error|failed|failure|exception|bug|wrong|broken|cannot|unable|not work|\u9519\u8bef|\u62a5\u9519|\u5931\u8d25|\u5f02\u5e38|\u95ee\u9898|\u65e0\u6cd5|\u4e0d\u80fd|\u4e0d\u5de5\u4f5c|\u6ca1\u53cd\u5e94|\u4e0d\u6b63\u786e|\u4e22\u5931)'
    $parts = $Text -split '[\r\n\u3002\uFF01\uFF1F!?\uFF1B;]+' |
        ForEach-Object { $_.Trim() } |
        Where-Object { $_ }
    $issues = @($parts | Where-Object { $_ -match $markers })
    if ($issues.Count -eq 0) { $issues = @($Text.Trim()) }
    return @($issues | Select-Object -Unique)
}

function Get-CodeExcerptFromFile([string]$Path, [int]$Start, [int]$End) {
    if (-not $Path) { return '' }
    if (-not (Test-Path -LiteralPath $Path)) { return "Code file not found: $Path" }
    $lines = Get-Content -LiteralPath $Path -Encoding UTF8
    if ($Start -le 0) { $Start = 1 }
    if ($End -le 0 -or $End -lt $Start) { $End = [Math]::Min($Start + 20, $lines.Count) }
    $End = [Math]::Min($End, $lines.Count)
    $selected = for ($i = $Start; $i -le $End; $i++) {
        $line = [string]$lines[$i - 1]
        if ($line.Length -eq 0) { '{0}:' -f $i } else { '{0}: {1}' -f $i, $line }
    }
    return ($selected -join "`r`n")
}

function Add-CandidateLesson([string]$ExperiencePath, [string]$Lesson) {
    if (-not $Lesson) { return $false }
    $content = Get-Content -Raw -LiteralPath $ExperiencePath -Encoding UTF8
    if ($content.Contains($Lesson)) { return $false }
    $candidate = "- Error feedback candidate: $Lesson"
    if ($content -match '(?m)^## Candidates\s*$') {
        $updated = $content -replace '(?m)^## Candidates\s*$', "## Candidates`r`n`r`n$candidate"
    }
    else {
        $updated = $content.TrimEnd() + "`r`n`r`n## Candidates`r`n`r`n$candidate"
    }
    Write-Utf8NoBom $ExperiencePath (($updated.TrimEnd()) + [Environment]::NewLine)
    return $true
}

function Get-PathHash([string]$Path) {
    if (-not $Path) { return '' }
    $sha = [Security.Cryptography.SHA256]::Create()
    try {
        $bytes = [Text.Encoding]::UTF8.GetBytes($Path)
        return (([BitConverter]::ToString($sha.ComputeHash($bytes))) -replace '-','').ToLowerInvariant()
    }
    finally { $sha.Dispose() }
}

function Resolve-ArchitectureRoot([string]$RequestedRoot, [string]$CurrentRoot) {
    foreach ($candidate in @($RequestedRoot, $env:ARCHITECTURE_ROOT, $CurrentRoot, 'F:\codex') | Where-Object { $_ }) {
        try {
            $full = [IO.Path]::GetFullPath($candidate).TrimEnd('\')
            if ((Test-Path -LiteralPath (Join-Path $full 'module-registry.json')) -and (Test-Path -LiteralPath (Join-Path $full 'skills\codex-self-evolution\SKILL.md'))) {
                return $full
            }
        } catch {
        }
    }
    return ''
}

function Write-GlobalExperienceInbox([string]$ArchitectureRoot, [hashtable]$Entry) {
    if (-not $ArchitectureRoot) { return $false }
    $inbox = Join-Path $ArchitectureRoot '.codex\project\incoming-error-feedback.jsonl'
    $json = ($Entry | ConvertTo-Json -Depth 6 -Compress)
    Add-Utf8NoBomLine $inbox $json
    return $true
}

$root = [IO.Path]::GetFullPath($ProjectRoot).TrimEnd('\')
$resolvedArchitectureRoot = Resolve-ArchitectureRoot $ArchitectureRoot $root
if ($ReportDirectory) {
    $reportDir = [IO.Path]::GetFullPath($ReportDirectory)
    $jsonPath = Join-Path $reportDir 'report.json'
    $reportPath = Join-Path $reportDir 'report.md'
    if (-not (Test-Path -LiteralPath $jsonPath) -or -not (Test-Path -LiteralPath $reportPath)) {
        throw "Existing report is incomplete: $reportDir"
    }
    $existing = Get-Content -LiteralPath $jsonPath -Raw -Encoding UTF8 | ConvertFrom-Json
    $RepairAttempt = Redact-Text $RepairAttempt
    $RepairResult = Redact-Text $RepairResult
    $Verification = if ($Verification) { Redact-Text $Verification } else { [string]$existing.verification }
    $existing.status = $Status
    $existing.verification = $Verification
    if ($ExperienceSystemCausality -ne 'none') { $existing | Add-Member -NotePropertyName experience_system_causality -NotePropertyValue $ExperienceSystemCausality -Force }
    $existing | Add-Member -NotePropertyName repair_attempt -NotePropertyValue $RepairAttempt -Force
    $existing | Add-Member -NotePropertyName repair_result -NotePropertyValue $RepairResult -Force
    $existing | Add-Member -NotePropertyName updated_at -NotePropertyValue ([DateTime]::UtcNow.ToString('o')) -Force
    Write-Utf8NoBom $jsonPath (($existing | ConvertTo-Json -Depth 5) + [Environment]::NewLine)
    $update = @"

## Repair Update

Status: $Status

### Attempt

$RepairAttempt

### Result

$RepairResult

### Verification

$Verification
"@
    $existingMarkdown = Get-Content -LiteralPath $reportPath -Raw -Encoding UTF8
    $existingMarkdown = [regex]::Replace($existingMarkdown, '(?m)^Status:\s*.*$', "Status: $Status", 1)
    Write-Utf8NoBom $reportPath ($existingMarkdown.TrimEnd() + "`r`n" + $update.TrimStart() + [Environment]::NewLine)
    $mirrored = $false
    $effectiveCausality = if ($ExperienceSystemCausality -ne 'none') { $ExperienceSystemCausality } else { [string]$existing.experience_system_causality }
    if (($MirrorToGlobalExperienceSystem -or $effectiveCausality -ne 'none') -and $resolvedArchitectureRoot) {
        $entry = [ordered]@{
            schema_version = 1
            recorded_at = [DateTime]::UtcNow.ToString('o')
            report_metadata = $jsonPath
            origin_project = if ($existing.origin_project.name) { $existing.origin_project.name } else { Split-Path -Leaf $root }
            origin_project_hash = if ($existing.origin_project.path_hash) { $existing.origin_project.path_hash } else { Get-PathHash $root }
            origin_workflow = $existing.origin_workflow
            module = $existing.module
            component = $existing.component
            severity = $existing.severity
            status = $Status
            experience_system_causality = $effectiveCausality
            global_experience_functions = @($existing.global_experience_functions)
            symptom = $existing.symptom
            actual_result = $existing.actual_result
            repair_attempt = $RepairAttempt
            repair_result = $RepairResult
            verification = $Verification
        }
        $mirrored = Write-GlobalExperienceInbox $resolvedArchitectureRoot $entry
    }
    [pscustomobject]@{ report = $reportPath; metadata = $jsonPath; experience_candidates_updated = $false; updated_existing_report = $true; global_inbox_updated = $mirrored }
    return
}

if (-not $Symptom -and -not $UserReport) {
    throw 'Provide -Symptom or -UserReport so the report contains a concrete observed problem.'
}
$timestamp = [DateTime]::UtcNow.ToString('yyyyMMddTHHmmssZ')
$slugInput = if ($Symptom) { $Symptom } else { $UserReport }
$slug = Get-SafeFileName "$Module-$Component-$slugInput"
$reportDir = Join-Path $root ".codex\errors\$timestamp-$slug"
New-Item -ItemType Directory -Force -Path $reportDir | Out-Null

if (-not $CodeExcerpt -and $CodeFile) {
    $CodeExcerpt = Get-CodeExcerptFromFile $CodeFile $StartLine $EndLine
}
if (-not $CodeLocation -and $CodeFile) {
    $CodeLocation = $CodeFile
    if ($StartLine -gt 0) { $CodeLocation = "${CodeFile}:$StartLine" }
}
if (-not $Symptom) { $Symptom = (Get-ReportedIssues $UserReport) -join ' / ' }
if (-not $Features) { $Features = 'Not yet classified; inspect the report evidence and update this field.' }
if (-not $SuspectedCauses) { $SuspectedCauses = 'Unknown; requires triage.' }
if (-not $PossibleOutcomes) { $PossibleOutcomes = 'May recur or mislead future experience capture if left untracked.' }
if (-not $Solutions) { $Solutions = 'Triage owner module, reproduce with minimal evidence, patch the smallest owning surface, then verify.' }
if (-not $Verification) { $Verification = 'Run the smallest relevant validation plus scripts\\validate.ps1 when architecture files changed.' }
if (-not $ReusableLesson) {
    $ReusableLesson = "Unexpected behavior in $Module should produce a structured error report before being promoted to experience or skill changes."
}

$CodeExcerpt = Redact-Text $CodeExcerpt
$Trigger = Redact-Text $Trigger
$OriginWorkflow = Redact-Text $OriginWorkflow
$UserReport = Redact-Text $UserReport
$ExpectedResult = Redact-Text $ExpectedResult
$ActualResult = Redact-Text $ActualResult
$Symptom = Redact-Text $Symptom
$Features = Redact-Text $Features
$SuspectedCauses = Redact-Text $SuspectedCauses
$Solutions = Redact-Text $Solutions
$reportedIssues = @(Get-ReportedIssues $UserReport | ForEach-Object { Redact-Text $_ })
$originName = if ($OriginProjectName) { Redact-Text $OriginProjectName } elseif ($OriginProjectRoot) { Split-Path -Leaf ([IO.Path]::GetFullPath($OriginProjectRoot).TrimEnd('\')) } else { Split-Path -Leaf $root }
$originHash = Get-PathHash $(if ($OriginProjectRoot) { [IO.Path]::GetFullPath($OriginProjectRoot).TrimEnd('\') } else { $root })
$globalFunctions = @($GlobalExperienceFunctions | Where-Object { $_ } | ForEach-Object { Redact-Text $_ } | Select-Object -Unique)

$reportPath = Join-Path $reportDir 'report.md'
$jsonPath = Join-Path $reportDir 'report.json'

$markdown = @"
# Error Feedback Report

Date: $([DateTime]::UtcNow.ToString('yyyy-MM-dd'))
Module: $Module
Component: $Component
Severity: $Severity
Confidence: $Confidence
Status: $Status

## Trigger

$Trigger

## Origin And Global Experience Causality

Origin project: $originName
Origin workflow: $OriginWorkflow
Global experience functions: $($globalFunctions -join ', ')
Experience-system causality: $ExperienceSystemCausality

## User-Reported Problem

$UserReport

## Extracted Error Statements

$($reportedIssues | ForEach-Object { "- $_" } | Out-String)

## Error List

| Field | Detail |
|---|---|
| Module | $Module |
| Component | $Component |
| Code location | $CodeLocation |
| Expected result | $ExpectedResult |
| Actual result | $ActualResult |
| Symptom | $Symptom |
| Concrete features | $Features |
| Suspected causes | $SuspectedCauses |
| Possible outcomes | $PossibleOutcomes |
| Possible solutions | $Solutions |
| Verification | $Verification |

## Code Or Output Excerpt

~~~text
$CodeExcerpt
~~~

## Reusable Lesson

$ReusableLesson

## Promotion Status

Candidate until the diagnosis is reproduced, fixed, or independently observed
again.
"@
Write-Utf8NoBom $reportPath ($markdown + [Environment]::NewLine)

[ordered]@{
    schema_version = 2
    created_at = [DateTime]::UtcNow.ToString('o')
    module = $Module
    component = $Component
    code_location = $CodeLocation
    code_excerpt = $CodeExcerpt
    symptom = $Symptom
    user_report = $UserReport
    reported_issues = $reportedIssues
    expected_result = $ExpectedResult
    actual_result = $ActualResult
    features = $Features
    suspected_causes = $SuspectedCauses
    possible_outcomes = $PossibleOutcomes
    solutions = $Solutions
    verification = $Verification
    severity = $Severity
    confidence = $Confidence
    status = $Status
    trigger = $Trigger
    origin_project = [ordered]@{
        name = $originName
        path_hash = $originHash
    }
    origin_workflow = $OriginWorkflow
    global_experience_functions = $globalFunctions
    experience_system_causality = $ExperienceSystemCausality
    reusable_lesson = $ReusableLesson
    promotion_status = 'candidate'
} | ConvertTo-Json -Depth 5 | ForEach-Object { Write-Utf8NoBom $jsonPath ($_ + [Environment]::NewLine) }

$experienceUpdated = $false
if ($UpdateExperienceCandidates) {
    $experiencePath = Join-Path $root '.codex\project\EXPERIENCE.md'
    $experienceUpdated = Add-CandidateLesson $experiencePath $ReusableLesson
}

$mirrored = $false
if (($MirrorToGlobalExperienceSystem -or $ExperienceSystemCausality -ne 'none') -and $resolvedArchitectureRoot) {
    $entry = [ordered]@{
        schema_version = 1
        recorded_at = [DateTime]::UtcNow.ToString('o')
        report_metadata = $jsonPath
        origin_project = $originName
        origin_project_hash = $originHash
        origin_workflow = $OriginWorkflow
        module = $Module
        component = $Component
        severity = $Severity
        status = $Status
        experience_system_causality = $ExperienceSystemCausality
        global_experience_functions = $globalFunctions
        symptom = $Symptom
        actual_result = $ActualResult
        reusable_lesson = $ReusableLesson
    }
    $mirrored = Write-GlobalExperienceInbox $resolvedArchitectureRoot $entry
}

[pscustomobject]@{
    report = $reportPath
    metadata = $jsonPath
    experience_candidates_updated = $experienceUpdated
    global_inbox_updated = $mirrored
}
