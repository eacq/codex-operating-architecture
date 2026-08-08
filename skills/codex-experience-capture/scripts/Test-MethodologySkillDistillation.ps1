param(
    [string]$RepositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
)

$ErrorActionPreference = 'Stop'

$skillPath = Join-Path $RepositoryRoot 'skills/codex-experience-capture/subskills/methodology-skill-distillation/SKILL.md'
if (-not (Test-Path -LiteralPath $skillPath)) {
    throw "Missing methodology skill distillation subskill: $skillPath"
}

$text = Get-Content -LiteralPath $skillPath -Raw -Encoding UTF8
if ($text -notmatch '(?s)^---\r?\nname:\s*codex-experience-capture-methodology-skill-distillation\r?\ndescription:\s*.+?\r?\n---') {
    throw 'SKILL.md must start with valid minimal YAML frontmatter.'
}

$required = @(
    'kangarooking/cangjie-skill',
    '355dd47a97eeb87d249bf7d32aab561405b6de76',
    'Experience triple verification',
    'Experience RIA++ shaping',
    'positive triggers',
    'negative lures',
    'cross-skill confusion',
    'canonical architecture repo'
)

foreach ($needle in $required) {
    if ($text -notlike "*$needle*") {
        throw "Missing required methodology distillation rule: $needle"
    }
}

[pscustomobject]@{
    status = 'passed'
    model = 'methodology-skill-distillation'
    source = 'https://github.com/kangarooking/cangjie-skill'
    source_commit = '355dd47a97eeb87d249bf7d32aab561405b6de76'
    skill = 'skills/codex-experience-capture/subskills/methodology-skill-distillation/SKILL.md'
} | ConvertTo-Json -Depth 4
