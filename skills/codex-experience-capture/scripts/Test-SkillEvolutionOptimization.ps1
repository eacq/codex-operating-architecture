param(
    [string]$RepositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
)

$ErrorActionPreference = 'Stop'

$skillPath = Join-Path $RepositoryRoot 'skills/codex-experience-capture/subskills/skill-evolution-optimization/SKILL.md'
$gatePath = Join-Path $RepositoryRoot 'skills/codex-experience-capture/scripts/Invoke-SkillEvolutionOptimizationGate.ps1'

foreach ($path in @($skillPath, $gatePath)) {
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        throw "Missing skill evolution optimization artifact: $path"
    }
}

$text = Get-Content -LiteralPath $skillPath -Raw -Encoding UTF8
if ($text -notmatch '(?s)^---\r?\nname:\s*codex-experience-capture-skill-evolution-optimization\r?\ndescription:\s*.+?\r?\n---') {
    throw 'SKILL.md must start with valid minimal YAML frontmatter.'
}

$required = @(
    'alchaincyf/darwin-skill',
    '7c7b7909b630dc3b5cbb91bd4bcb1b10bfb1f894',
    'microsoft/SkillOpt',
    '61735e3922efc2b90c6d6cab561e62e98452ca90',
    'strictly higher',
    'SkillOpt-Sleep Adaptation',
    'Darwin Adaptation',
    'Technology-Evolution Lens',
    'Book-Shelf Learning Lens',
    'Brian Arthur',
    'component inventory',
    'phenomenon capture',
    'recursive assembly',
    'domain grammar',
    'problem cascade',
    'multi-model triangulation',
    'parser degradation',
    'combinatorial_fit',
    'Only one primary',
    'risk_blacklist'
)

foreach ($needle in $required) {
    if ($text -notlike "*$needle*") {
        throw "Missing required skill evolution rule: $needle"
    }
}

$accepted = & $gatePath -CurrentScore 31 -CandidateScore 36 -BestScore 35 -Evidence 'fixture:pass' -SafetyChecks 'frontmatter','runtime-neutrality' -SkillPath 'skills/example/SKILL.md' -CandidateId 'accept-fixture' | ConvertFrom-Json
if ($accepted.decision -ne 'accept') { throw 'Strict-improvement fixture should be accepted.' }

$rejected = & $gatePath -CurrentScore 36 -CandidateScore 36 -BestScore 36 -Evidence 'fixture:tie' -SafetyChecks 'frontmatter' -SkillPath 'skills/example/SKILL.md' -CandidateId 'tie-fixture' | ConvertFrom-Json
if ($rejected.decision -ne 'reject' -or @($rejected.reasons) -notcontains 'candidate_score is not strictly greater than current_score') {
    throw 'Tie fixture should be rejected by strict-improvement gate.'
}

$paused = & $gatePath -CurrentScore 30 -CandidateScore 35 -Evidence 'fixture:needs-human' -SafetyChecks 'frontmatter' -HumanCheckpointRequired -SkillPath 'skills/example/SKILL.md' -CandidateId 'pause-fixture' | ConvertFrom-Json
if ($paused.decision -ne 'pause') { throw 'Unsatisfied human checkpoint should pause adoption.' }

$candidateOnly = & $gatePath -CurrentScore 30 -CandidateScore 35 -Evidence 'fixture:dry-run' -SafetyChecks 'frontmatter' -DryRunRatio 0.9 -SkillPath 'skills/example/SKILL.md' -CandidateId 'dry-run-fixture' | ConvertFrom-Json
if ($candidateOnly.decision -ne 'candidate-only') { throw 'Dry-run dominated fixture should remain candidate-only.' }

$bookTest = & (Join-Path $RepositoryRoot 'skills/codex-experience-capture/scripts/Test-ExperienceBookShelfLearning.ps1') -RepositoryRoot $RepositoryRoot | ConvertFrom-Json
if ($bookTest.status -ne 'passed') { throw 'Book shelf learning fixture did not pass.' }

[pscustomobject]@{
    status = 'passed'
    model = 'skill-evolution-optimization'
    sources = @('https://github.com/alchaincyf/darwin-skill', 'https://github.com/microsoft/SkillOpt', 'user-provided EPUB: The Nature of Technology')
    source_commits = @('7c7b7909b630dc3b5cbb91bd4bcb1b10bfb1f894', '61735e3922efc2b90c6d6cab561e62e98452ca90')
    skill = 'skills/codex-experience-capture/subskills/skill-evolution-optimization/SKILL.md'
    gate = 'skills/codex-experience-capture/scripts/Invoke-SkillEvolutionOptimizationGate.ps1'
    book_shelf_learning = 'skills/codex-experience-capture/scripts/Invoke-ExperienceBookShelfLearning.ps1'
} | ConvertTo-Json -Depth 4
