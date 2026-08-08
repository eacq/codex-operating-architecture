[CmdletBinding()]
param(
    [string]$RepositoryRoot = 'F:\codex'
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath $RepositoryRoot).Path
$terminologyPath = Join-Path $root 'docs\SKILL-TERMINOLOGY.md'
$requirementSkillPath = Join-Path $root 'skills\codex-requirement-authoring\SKILL.md'
$contractPath = Join-Path $root 'skills\codex-requirement-authoring\references\normalized-requirement-contract.md'

foreach ($path in @($terminologyPath, $requirementSkillPath, $contractPath)) {
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        throw "Required file is missing: $path"
    }
}

$terminology = [IO.File]::ReadAllText($terminologyPath, [Text.UTF8Encoding]::new($false))
$skill = [IO.File]::ReadAllText($requirementSkillPath, [Text.UTF8Encoding]::new($false))
$contract = [IO.File]::ReadAllText($contractPath, [Text.UTF8Encoding]::new($false))

$requiredTerms = @(
    'Collaboration Terminology',
    'Three-party Collaboration',
    'Requirement Brief',
    'Completion Boundary',
    'Authority Gate',
    'Verification Evidence',
    'Project-local Vocabulary',
    'Git Milestone',
    'Agent Harness',
    'Agent Resource',
    'Agent Tool Gate',
    'Save Point',
    'Extension Surface',
    'Project Trust'
)

$missingTerms = @($requiredTerms | Where-Object { $terminology -notmatch [regex]::Escape($_) })
if ($missingTerms.Count -gt 0) {
    throw "Terminology document is missing required terms: $($missingTerms -join ', ')"
}

if ($skill -notmatch [regex]::Escape('docs\SKILL-TERMINOLOGY.md')) {
    throw 'Requirement authoring skill does not reference the shared terminology document.'
}

if ($contract -notmatch [regex]::Escape('docs/SKILL-TERMINOLOGY.md')) {
    throw 'Normalized requirement contract does not reference the shared terminology document.'
}

[pscustomobject]@{
    status = 'passed'
    terminology_path = $terminologyPath
    required_terms = $requiredTerms.Count
} | ConvertTo-Json -Compress
