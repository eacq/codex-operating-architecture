#Requires -Version 5.1
[CmdletBinding()]
param(
    [string] $RepositoryRoot = 'F:\codex'
)
$ErrorActionPreference = 'Stop'

function Assert-Condition([bool] $Condition, [string] $Message) {
    if (-not $Condition) { throw "REVERSE-SKILL INTEGRATION FAIL: $Message" }
    Write-Host "[OK] $Message" -ForegroundColor Green
}

$root = (Resolve-Path -LiteralPath $RepositoryRoot).Path
$manifestPath = Join-Path $root 'config\reverse-skill-integration.json'
$manifest = Get-Content -LiteralPath $manifestPath -Raw -Encoding UTF8 | ConvertFrom-Json
Assert-Condition ($manifest.status -eq 'installed-adapted-routing-bootstrap-evolution') 'adapter includes routed learning mechanisms'
Assert-Condition ($manifest.adapter.default_enabled -eq $true) 'safe collaboration adapter is default-enabled'
Assert-Condition ($manifest.deferred_surfaces.Count -ge 5) 'high-risk and external-bootstrap surfaces are deferred'

$source = Join-Path $root $manifest.upstream.local_release
$source = (Resolve-Path -LiteralPath $source).Path
$head = (git -C $source rev-parse HEAD).Trim()
Assert-Condition ($head -eq $manifest.upstream.commit) 'source release commit is pinned'
Assert-Condition (Test-Path -LiteralPath (Join-Path $source 'LICENSE')) 'source license is present'

$skill = Join-Path $root $manifest.adapter.skill
$grounding = Join-Path $root $manifest.adapter.source_grounding
$contract = Join-Path $root $manifest.adapter.local_contract
$lens = Join-Path $root $manifest.adapter.methodology_lens
$router = Join-Path $root $manifest.adapter.router
foreach($p in @($skill,$grounding,$contract,$lens,$router)) {
    Assert-Condition (Test-Path -LiteralPath $p) "adapter artifact exists: $p"
}
$skillText = Get-Content -LiteralPath $skill -Raw -Encoding UTF8
foreach($term in @('Evidence','Finding','Path','owner','EvolutionPlan','RouteOwner','verified architecture guidance')) {
    Assert-Condition ($skillText -match [regex]::Escape($term)) "adapter contains $term contract"
}

$route = & powershell -NoProfile -ExecutionPolicy Bypass -File $router -Mode Route -Task 'experience library evolution review' | ConvertFrom-Json
Assert-Condition ($route.route.primary_owner -eq 'codex-experience-capture') 'route selects experience owner'
$plan = & powershell -NoProfile -ExecutionPolicy Bypass -File $router -Mode ToolchainPlan -Task 'inspect offline toolchain' -Capabilities 'jadx' | ConvertFrom-Json
Assert-Condition ($plan.toolchain[0].install_authorization -eq 'explicit-user-or-owner-gate-required') 'toolchain plan preserves install gate'
$evo = & powershell -NoProfile -ExecutionPolicy Bypass -File $router -Mode EvolutionPlan -Task 'record failure and evolve experience' -Outcome 'blocked' -Failure 'dependency missing' -Evidence 'F:\codex\config\reverse-skill-integration.json' | ConvertFrom-Json
Assert-Condition ($evo.evolution.candidate_status -eq 'candidate-awaiting-verification') 'evolution plan creates guarded candidate'

foreach($rel in @('skills/ops/scope-contract.md','skills/ops/evidence-finding-path.md','skills/ops/role-map.md','skills/ops/timeline-workitem.md','skills/ops/skill-supply-chain.md')) {
    Assert-Condition (Test-Path -LiteralPath (Join-Path $source ($rel -replace '/', '\'))) "reviewed source surface exists: $rel"
}

$all = @($skill,$grounding,$contract,$lens,$router,$manifestPath)
foreach($p in $all) {
    Assert-Condition (([IO.Path]::GetFullPath($p)).StartsWith('F:\', [StringComparison]::OrdinalIgnoreCase)) "artifact remains on F: $p"
}

Write-Host 'REVERSE-SKILL INTEGRATION PASS' -ForegroundColor Green
