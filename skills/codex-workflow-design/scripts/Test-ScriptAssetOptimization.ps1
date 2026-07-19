$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
$fixture = & (Join-Path $root 'scripts\Resolve-CodexRunRoot.ps1') -ArchitectureRoot $root -Kind tmp -ChildPath ('script-asset-optimization-' + [guid]::NewGuid().ToString('N')) -Create
$script = Join-Path $root 'skills\codex-workflow-design\scripts\Invoke-ScriptAssetOptimization.ps1'

try {
    New-Item -ItemType Directory -Force -Path (Join-Path $fixture '.codex\project') | Out-Null
    [ordered]@{ step_timings = @(@{ name = 'fast check'; duration_seconds = 0.1 }, @{ name = 'create rollback snapshot'; duration_seconds = 2.5 }) } | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath (Join-Path $fixture '.codex\project\global-experience-iteration.json') -Encoding UTF8
    $review = & $script -ProjectRoot $fixture -Apply | ConvertFrom-Json
    if ($review.result -ne 'analyzed' -or $review.asset_class -ne 'first-class-script-asset' -or $review.measurement_count -ne 2) { throw 'Script asset optimization review did not retain its first-class contract.' }
    if ($review.hotspots[0].operation -ne 'create rollback snapshot' -or $review.hotspots[0].recommended_focus -notmatch 'hash-verified rollback') { throw 'Script asset optimization review did not rank rollback timing correctly.' }
    if (-not (Test-Path -LiteralPath (Join-Path $fixture $review.output))) { throw 'Script asset optimization review did not persist its output.' }
    Write-Host 'Script asset optimization test passed.'
}
finally {
    if (Test-Path -LiteralPath $fixture) { Remove-Item -LiteralPath $fixture -Recurse -Force }
}
