[CmdletBinding()]
param(
    [string]$ProjectRoot = (Get-Location).Path,
    [Parameter(Mandatory = $true)]
    [string]$FollowupRequirement,
    [string]$SourceImage = '',
    [string]$OutputImage = '',
    [string]$OriginalPromptFile = '',
    [string]$TemplateFamily = 'unspecified',
    [string]$ObservedProblems = '',
    [string]$OptimizedPrompt = '',
    [string[]]$NegativeConstraints = @(),
    [string]$ReusableLesson = '',
    [switch]$UpdateExperienceCandidates
)

$ErrorActionPreference = 'Stop'

function Get-SafeFileName([string]$Value) {
    $name = ($Value -replace '[^\p{L}\p{Nd}\._-]+', '-').Trim('-')
    if (-not $name) { return 'image-prompt-experience' }
    if ($name.Length -gt 72) { return $name.Substring(0, 72).Trim('-') }
    return $name
}

function Get-InferredNegativeConstraints([string]$Requirement, [string]$Problems) {
    $text = "$Requirement $Problems".ToLowerInvariant()
    $constraints = New-Object System.Collections.Generic.List[string]
    $constraints.Add('Do not add fake data, fake citations, fake journal logos, watermarks, or unsupported claims.')
    $constraints.Add('Do not rename correct labels, invent new modules, or change arrow meanings unless explicitly requested.')
    if ($text -match '论文|学术|sci|nature|paper|journal|publication') {
        $constraints.Add('Do not use decorative slide styling, heavy shadows, neon colors, dark backgrounds, or crowded callouts.')
        $constraints.Add('Do not make labels too small for manuscript-scale reading.')
    }
    if ($text -match '修图|edit|reference|保持|preserve') {
        $constraints.Add('Do not change preserved subject identity, composition, perspective, lighting, texture, or background continuity.')
    }
    return @($constraints | Select-Object -Unique)
}

function Get-InferredOptimizedPrompt([string]$Requirement, [string]$Problems) {
    $prompt = @"
Revise the image according to the follow-up requirement while preserving the correct content, labels, structure, and semantic relationships.

Follow-up requirement:
$Requirement

Observed problems to correct:
$Problems

Make the result cleaner, more controlled, and more suitable for its declared output use. Use concise readable labels, consistent alignment, meaningful arrows, restrained colors, and enough whitespace. Keep changes scoped to the requirement.
"@
    return $prompt.Trim()
}

function Add-CandidateLesson([string]$ExperiencePath, [string]$Lesson) {
    if (-not $Lesson) { return $false }
    $content = Get-Content -Raw -LiteralPath $ExperiencePath -Encoding UTF8
    if ($content.Contains($Lesson)) { return $false }
    $candidate = "- Image prompt candidate: $Lesson"
    if ($content -match '(?m)^## Candidates\s*$') {
        $updated = $content -replace '(?m)^## Candidates\s*$', "## Candidates`r`n`r`n$candidate"
    }
    else {
        $updated = $content.TrimEnd() + "`r`n`r`n## Candidates`r`n`r`n$candidate`r`n"
    }
    Set-Content -LiteralPath $ExperiencePath -Value ($updated.TrimEnd() + "`r`n") -Encoding UTF8
    return $true
}

$root = [IO.Path]::GetFullPath($ProjectRoot).TrimEnd('\')
$timestamp = [DateTime]::UtcNow.ToString('yyyyMMddTHHmmssZ')
$slug = Get-SafeFileName $FollowupRequirement
$reviewDir = Join-Path $root ".codex\images\post-generation-reviews"
New-Item -ItemType Directory -Force -Path $reviewDir | Out-Null

if (-not $ObservedProblems) {
    $ObservedProblems = 'Follow-up requirement indicates the generated image needs additional refinement; inspect the image and replace this with concrete observed issues when available.'
}
if (-not $OptimizedPrompt) {
    $OptimizedPrompt = Get-InferredOptimizedPrompt $FollowupRequirement $ObservedProblems
}
if ($NegativeConstraints.Count -eq 0) {
    $NegativeConstraints = Get-InferredNegativeConstraints $FollowupRequirement $ObservedProblems
}
if (-not $ReusableLesson) {
    $ReusableLesson = "When a generated image receives a follow-up edit request, capture the requested change, observed problem, optimized prompt wording, and negative constraints before changing shared templates."
}

$reviewPath = Join-Path $reviewDir "$timestamp-$slug.md"
$jsonPath = Join-Path $reviewDir "$timestamp-$slug.json"
$negativeBlock = ($NegativeConstraints | ForEach-Object { "- $_" }) -join "`r`n"

$markdown = @"
# Image Prompt Experience Capture

Date: $([DateTime]::UtcNow.ToString('yyyy-MM-dd'))
Template family: `$TemplateFamily`
Source image: `$SourceImage`
Output image: `$OutputImage`
Original prompt file: `$OriginalPromptFile`

## Follow-Up Requirement

$FollowupRequirement

## Observed Problems

$ObservedProblems

## Optimized Prompt

$OptimizedPrompt

## Negative Constraints

$negativeBlock

## Reusable Lesson

$ReusableLesson

## Promotion Status

Candidate. Promote to a shared template only after the same lesson is verified
across more than one image or one recurring workflow.
"@
Set-Content -LiteralPath $reviewPath -Value $markdown -Encoding UTF8

[ordered]@{
    schema_version = 1
    created_at = [DateTime]::UtcNow.ToString('o')
    template_family = $TemplateFamily
    source_image = $SourceImage
    output_image = $OutputImage
    original_prompt_file = $OriginalPromptFile
    followup_requirement = $FollowupRequirement
    observed_problems = $ObservedProblems
    optimized_prompt = $OptimizedPrompt
    negative_constraints = $NegativeConstraints
    reusable_lesson = $ReusableLesson
    promotion_status = 'candidate'
} | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $jsonPath -Encoding UTF8

$experienceUpdated = $false
if ($UpdateExperienceCandidates) {
    $experiencePath = Join-Path $root '.codex\project\EXPERIENCE.md'
    $experienceUpdated = Add-CandidateLesson $experiencePath $ReusableLesson
}

[pscustomobject]@{
    review = $reviewPath
    metadata = $jsonPath
    experience_candidates_updated = $experienceUpdated
}
