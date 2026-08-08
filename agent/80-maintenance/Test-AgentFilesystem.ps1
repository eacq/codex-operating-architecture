[CmdletBinding()]
param([string]$RepositoryRoot = 'F:\codex')

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath $RepositoryRoot).Path
$layout = Get-Content -LiteralPath (Join-Path $root 'agent\agent-filesystem.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$system = Get-Content -LiteralPath (Join-Path $root 'config\agent-system.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$registry = Get-Content -LiteralPath (Join-Path $root 'config\global-experience-agent-registry.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$policy = Get-Content -LiteralPath (Join-Path $root 'config\agent-interface-policy.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$network = Get-Content -LiteralPath (Join-Path $root 'config\agent-owner-connections.json') -Raw -Encoding UTF8 | ConvertFrom-Json

foreach ($zone in @($layout.zones)) {
    if (-not (Test-Path -LiteralPath (Join-Path $root ([string]$zone.path)) -PathType Container)) { throw "Agent filesystem zone missing: $($zone.path)" }
    $leaf = Split-Path -Leaf ([string]$zone.path)
    if ($leaf -cnotmatch '^([0-9]{2}-)?[a-z0-9]+(?:-[a-z0-9]+)*$') { throw "Agent filesystem zone is not lowercase kebab-case: $leaf" }
}

$sync = & (Join-Path $root 'agent\80-maintenance\Sync-AgentFilesystem.ps1') -RepositoryRoot $root | ConvertFrom-Json
if ($sync.status -ne 'in-sync') { throw "Agent filesystem projection drift detected: $($sync | ConvertTo-Json -Depth 8 -Compress)" }
$resolvedJson = & (Join-Path $root 'agent\80-maintenance\Resolve-AgentFilesystemPath.ps1') -RepositoryRoot $root -List
$resolved = $resolvedJson | ConvertFrom-Json
$expectedCount = 1 + @($policy.interfaces).Count + @($registry.concept_agents).Count + @($network.owners).Count + 1 + @($registry.child_agent_profiles).Count + 2 + 1 + 1 + @($policy.exits).Count + 1 + 1
if ($resolved.Count -ne $expectedCount) { throw "Agent filesystem projection count mismatch: expected $expectedCount, got $($resolved.Count)" }

$specialists = @($resolved | Where-Object kind -eq 'specialist-agent')
if ($specialists.Count -ne @($network.owners).Count) { throw 'Every active owner must have exactly one specialist Agent folder.' }
foreach ($owner in @($network.owners)) {
    $item = @($specialists | Where-Object id -eq "specialist:$($owner.owner)")
    if ($item.Count -ne 1) { throw "Missing specialist Agent projection: $($owner.owner)" }
    $manifest = Get-Content -LiteralPath (Join-Path $root $item[0].path) -Raw -Encoding UTF8 | ConvertFrom-Json
    if ($manifest.canonical_skill -ne $owner.skill) { throw "Specialist Agent skill mismatch: $($owner.owner)" }
    if (-not (Test-Path -LiteralPath (Join-Path $root ([string]$manifest.canonical_skill)) -PathType Leaf)) { throw "Specialist Agent canonical skill missing: $($owner.owner)" }
    if (@($manifest.incoming).Count -lt 1 -or @($manifest.outgoing).Count -lt 1) { throw "Specialist Agent is disconnected: $($owner.owner)" }
}

$children = @($resolved | Where-Object kind -eq 'child-agent-profile')
if ($children.Count -ne @($registry.child_agent_profiles).Count) { throw 'Every registered child Agent profile must have exactly one child Agent folder.' }
foreach ($profile in @($registry.child_agent_profiles)) {
    $item = @($children | Where-Object id -eq "child:$($profile.id)")
    if ($item.Count -ne 1) { throw "Missing child Agent profile projection: $($profile.id)" }
    $manifest = Get-Content -LiteralPath (Join-Path $root $item[0].path) -Raw -Encoding UTF8 | ConvertFrom-Json
    if ($manifest.canonical_skill -ne $profile.skill) { throw "Child Agent skill mismatch: $($profile.id)" }
    if (-not (Test-Path -LiteralPath (Join-Path $root ([string]$manifest.canonical_skill)) -PathType Leaf)) { throw "Child Agent canonical skill missing: $($profile.id)" }
    if ([string]::IsNullOrWhiteSpace($manifest.parent_concept) -or @($manifest.denied_operations).Count -lt 1 -or @($manifest.required_evidence).Count -lt 1) { throw "Child Agent safety contract incomplete: $($profile.id)" }
}

foreach ($surface in @('runtime_controller', 'runtime_implementation', 'memory_backend', 'state_reader')) {
    $relative = [string]$layout.canonical_surfaces.$surface
    if (-not (Test-Path -LiteralPath (Join-Path $root $relative) -PathType Leaf)) { throw "Canonical Agent runtime surface missing: $relative" }
}
foreach ($adapter in @($layout.compatibility_adapters)) {
    $legacy = Join-Path $root ([string]$adapter.legacy)
    if (-not (Test-Path -LiteralPath $legacy -PathType Leaf)) { throw "Compatibility adapter missing: $($adapter.legacy)" }
    $text = Get-Content -LiteralPath $legacy -Raw -Encoding UTF8
    if ($text -notmatch [regex]::Escape(([string]$adapter.canonical).Replace('/', '\'))) { throw "Compatibility adapter does not route to canonical runtime: $($adapter.legacy)" }
}
if ($system.agent_runtime.controller -ne $layout.canonical_surfaces.runtime_controller) { throw 'System runtime controller does not match Agent filesystem authority.' }
if ($registry.root_agent.entrypoint -ne $layout.canonical_surfaces.runtime_controller) { throw 'Registry entrypoint does not match Agent filesystem authority.' }
if ($system.filesystem.manifest -ne 'agent/agent-filesystem.json') { throw 'System manifest does not declare the Agent filesystem.' }
if (@($layout.protected_paths) -notcontains '.codex' -or @($layout.protected_paths) -notcontains '.runtime' -or @($layout.protected_paths) -notcontains '.git') { throw 'Agent filesystem protected-path contract is incomplete.' }

$stateRoot = & (Join-Path $root 'scripts\Resolve-CodexRunRoot.ps1') -ArchitectureRoot $root -Kind tmp -ChildPath ('agent-filesystem-test-' + [guid]::NewGuid().ToString('N')) -Create
try {
    $controller = Join-Path $root 'agent\40-runtime\Invoke-GlobalExperienceAgent.ps1'
    $described = & $controller -RepositoryRoot $root -Mode Run -Operation DescribeFilesystem -SessionId 'llm-filesystem' -StateRoot $stateRoot -Interface llm -AuthorityScope functional -Authority 'fixture bounded read authority' -Apply | ConvertFrom-Json
    if ($described.tool_result.result -ne 'filesystem-described' -or $described.tool_result.projection_count -ne $expectedCount -or @($described.tool_result.zones).Count -ne 10 -or $described.tool_result.side_effect_executed) { throw 'LLM interface could not describe the Agent filesystem safely.' }
    $pathResult = & $controller -RepositoryRoot $root -Mode Run -Operation ResolveAgentPath -FilesystemId 'specialist:codex-file-organization' -SessionId 'human-filesystem' -StateRoot $stateRoot -Interface human -AuthorityScope functional -Authority 'fixture bounded read authority' -Apply | ConvertFrom-Json
    if ($pathResult.tool_result.result -ne 'agent-path-resolved' -or $pathResult.tool_result.resolution.path -ne 'agent/20-agents/specialists/codex-file-organization/agent.json' -or $pathResult.tool_result.side_effect_executed) { throw 'Human interface could not resolve a typed Agent filesystem path safely.' }
} finally {
    $resolvedStateRoot = [IO.Path]::GetFullPath($stateRoot)
    $allowedRoot = [IO.Path]::GetFullPath('F:\.codex-codex-tmp').TrimEnd('\') + '\'
    if ($resolvedStateRoot.StartsWith($allowedRoot, [StringComparison]::OrdinalIgnoreCase) -and (Test-Path -LiteralPath $resolvedStateRoot)) { Remove-Item -LiteralPath $resolvedStateRoot -Recurse -Force }
}

[pscustomobject][ordered]@{
    status = 'passed'
    zones = @($layout.zones).Count
    projections = $resolved.Count
    root_agents = @($resolved | Where-Object kind -eq 'root-agent').Count
    interfaces = @($resolved | Where-Object kind -eq 'interface').Count
    concepts = @($resolved | Where-Object kind -eq 'concept-agent').Count
    specialists = $specialists.Count
    exits = @($resolved | Where-Object kind -eq 'agent-exit').Count
    compatibility_adapters = @($layout.compatibility_adapters).Count
    callable_interfaces = @('llm', 'human')
    drift = 0
} | ConvertTo-Json -Depth 8
