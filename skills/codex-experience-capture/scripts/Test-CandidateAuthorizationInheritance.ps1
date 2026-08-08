$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
$policy = Get-Content -Raw -LiteralPath (Join-Path $root 'config\candidate-processing-policy.json') -Encoding UTF8 | ConvertFrom-Json
if ($policy.status -ne 'active' -or -not $policy.inheritance_rule.enabled) { throw 'Candidate authorization inheritance policy is not active.' }
if ($policy.inheritance_rule.default_processing_mode -ne 'structural-optimization') { throw 'Optimization permission must default to structural candidate processing.' }
if (-not $policy.inheritance_rule.formal_promotion_requires_explicit_request) { throw 'Formal promotion must retain an explicit-request gate.' }
if (-not $policy.inheritance_rule.no_periodic_or_unprompted_processing) { throw 'Candidate processing must not become periodic or unprompted.' }
$gates = @($policy.independent_gates)
foreach ($required in @('external action','credential use','software installation or update','publication or upload','destructive mutation','Git commit, push, tag, or release')) {
    if ($gates -notcontains $required) { throw "Independent candidate gate is missing: $required" }
}
$skill = Get-Content -Raw -LiteralPath (Join-Path $root 'skills\codex-experience-capture\SKILL.md') -Encoding UTF8
if ($skill -notmatch 'Permission inheritance') { throw 'Experience-capture skill does not document permission inheritance.' }
if ($skill -notmatch 'structural-optimization') { throw 'Experience-capture skill does not document structural candidate processing.' }
$workflows = Get-Content -Raw -LiteralPath (Join-Path $root '.codex\project\WORKFLOWS.md') -Encoding UTF8
if ($workflows -notmatch 'Permission inheritance') { throw 'Project workflow does not document permission inheritance.' }
Write-Host 'Candidate authorization inheritance test passed.'
