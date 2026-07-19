$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
$fixture = & (Join-Path $root 'scripts\Resolve-CodexRunRoot.ps1') -ArchitectureRoot $root -Kind tmp -ChildPath ('owner-self-iteration-review-' + [guid]::NewGuid().ToString('N')) -Create
$script = Join-Path $root 'skills\codex-architecture-iteration\scripts\Invoke-OwnerSelfIterationReview.ps1'

try {
    $review = & $script -ProjectRoot $fixture -ArchitectureRoot $root -Apply | ConvertFrom-Json
    if ($review.result -ne 'analyzed' -or $review.asset_class -ne 'first-class-owner-and-skill-asset') {
        throw 'Owner self-iteration review did not establish the policy contract.'
    }
    if ($review.active_owner_count -lt 1 -or -not $review.automatic_local_optimization.enabled -or -not $review.automatic_rename.enabled) {
        throw 'Owner self-iteration review did not retain active-owner or automatic local optimization coverage.'
    }
    if ((($review.authorization_required -join "`n") -notmatch 'Git commit') -or $review.automatic_rename.migration_authority -ne 'config/skill-name-migrations.json' -or $review.candidate_disposition -notmatch 'naming-only owner or skill migration') {
        throw 'Owner self-iteration review weakened an authorization boundary.'
    }
    if (-not (Test-Path -LiteralPath (Join-Path $fixture $review.output))) {
        throw 'Owner self-iteration review did not persist its project-local output.'
    }
    Write-Host 'Owner self-iteration review test passed.'
}
finally {
    if (Test-Path -LiteralPath $fixture) { Remove-Item -LiteralPath $fixture -Recurse -Force }
}
