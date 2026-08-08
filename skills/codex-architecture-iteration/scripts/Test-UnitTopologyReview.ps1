$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
$fixture = & (Join-Path $root 'scripts\Resolve-CodexRunRoot.ps1') -ArchitectureRoot $root -Kind tmp -ChildPath ('unit-topology-review-' + [guid]::NewGuid().ToString('N')) -Create
$script = Join-Path $root 'skills\codex-architecture-iteration\scripts\Invoke-UnitTopologyReview.ps1'

try {
    $review = & $script -ProjectRoot $fixture -ArchitectureRoot $root -Apply | ConvertFrom-Json
    if ($review.result -ne 'analyzed' -or $review.principle -ne 'information-functional-unit') {
        throw 'Unit topology review did not establish the information/functional unit contract.'
    }
    if ($review.information_unit_count -lt 1 -or $review.functional_unit_count -lt 1) {
        throw 'Unit topology review did not detect both information and functional units.'
    }
    if ($review.top_owner.active_count -lt 1 -or $review.top_owner.disposition -notin @('retain-current-top-owner-surface', 'requires-owner-boundary-review')) {
        throw 'Unit topology review did not report a valid top-owner disposition.'
    }
    if (-not $review.naming_review.required -or $review.naming_review.rule -notmatch 'user, model, and local experience-system collaboration') {
        throw 'Unit topology review did not require separate naming clarity evaluation.'
    }
    if (($review.top_owner.decision_rule -notmatch 'current authorization') -or ($review.naming_review.rule -notmatch 'config/skill-name-migrations.json') -or ($review.bidirectional_link_health.interpretation -notmatch 'not an automatic defect')) {
        throw 'Unit topology review weakened owner authorization, naming migration, or link-gap interpretation.'
    }
    if (-not (Test-Path -LiteralPath (Join-Path $fixture $review.output))) {
        throw 'Unit topology review did not persist its project-local output.'
    }
    Write-Host 'Unit topology review test passed.'
}
finally {
    if (Test-Path -LiteralPath $fixture) { Remove-Item -LiteralPath $fixture -Recurse -Force }
}
