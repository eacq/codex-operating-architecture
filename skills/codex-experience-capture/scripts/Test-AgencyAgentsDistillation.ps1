[CmdletBinding()]
param([string]$RepositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath $RepositoryRoot).Path

$reference = Join-Path $root 'skills\codex-experience-capture\references\agency-agents-specialist-design.md'
if (-not (Test-Path -LiteralPath $reference -PathType Leaf)) {
    throw "Missing distilled owner reference: $reference"
}
$text = Get-Content -LiteralPath $reference -Raw -Encoding UTF8

$required = @(
    'https://github.com/msitarzewski/agency-agents',
    'ebe9c99acb5c96f9468de368d8bead775387d1a7',
    'MIT',
    'minimal-agent-template',
    '## Activation',
    'Do not use it when',
    '## Pressure-test prompts',
    'cross-skill confusion',
    '## Boundary and rollback'
)
foreach ($needle in $required) {
    if ($text -notlike "*$needle*") {
        throw "Missing required distilled reference content: $needle"
    }
}

$rejectedRawInstall = $text -match 'install\.sh --tool|\~/.codex/agents.*install'
if (-not $rejectedRawInstall) {
    throw 'The reference must explicitly reject raw upstream installers and bulk Codex TOML installs.'
}

$knowledge = Join-Path $root 'knowledge-vault\30-Knowledge\Agency Agents Specialist Design Method.md'
if (-not (Test-Path -LiteralPath $knowledge -PathType Leaf)) {
    throw "Missing distilled knowledge note: $knowledge"
}
$knowledgeText = Get-Content -LiteralPath $knowledge -Raw -Encoding UTF8
if ($knowledgeText -notmatch 'ebe9c99acb5c96f9468de368d8bead775387d1a7' -or $knowledgeText -notmatch 'status:\s*active') {
    throw 'Knowledge note must pin the source commit and carry active status.'
}

[pscustomobject]@{
    status = 'passed'
    model = 'agency-agents-methodology-distillation'
    source = 'https://github.com/msitarzewski/agency-agents'
    source_commit = 'ebe9c99acb5c96f9468de368d8bead775387d1a7'
    reference = 'skills/codex-experience-capture/references/agency-agents-specialist-design.md'
    knowledge = 'knowledge-vault/30-Knowledge/Agency Agents Specialist Design Method.md'
} | ConvertTo-Json -Depth 4
