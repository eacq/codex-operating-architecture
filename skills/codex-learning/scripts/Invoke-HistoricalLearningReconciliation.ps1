[CmdletBinding()]
param(
    [string]$ProjectRoot = 'F:\codex',
    [ValidateSet('economy', 'balanced', 'full')]
    [string]$Mode = 'full',
    [string]$OutputPath,
    [switch]$Apply
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath $ProjectRoot).Path
if (-not $OutputPath) {
    $OutputPath = Join-Path $root '.codex\project\historical-learning-reconciliation-current.json'
}
$outputFull = [System.IO.Path]::GetFullPath($OutputPath)
$rootFull = $root.TrimEnd('\')
if (-not ($outputFull.Equals($rootFull, [System.StringComparison]::OrdinalIgnoreCase) -or
        $outputFull.StartsWith($rootFull + '\', [System.StringComparison]::OrdinalIgnoreCase))) {
    throw "Historical learning output must remain under project root: $outputFull"
}

$modulePath = Join-Path $root 'module-registry.json'
$registryPath = Join-Path $root 'config\global-experience-agent-registry.json'
$ownerConnectionsPath = Join-Path $root 'config\agent-owner-connections.json'
$filesystemPath = Join-Path $root 'agent\agent-filesystem.json'
$skillsRoot = Join-Path $root 'skills'
$knowledgeRoot = Join-Path $root 'knowledge-vault'
$networkRoot = Join-Path $root '.runtime\work\network-learning'
$softwareRoot = Join-Path $root '.runtime\software'
foreach ($required in @($modulePath, $registryPath, $ownerConnectionsPath, $filesystemPath, $skillsRoot, $knowledgeRoot)) {
    if (-not (Test-Path -LiteralPath $required)) { throw "Historical learning authority is missing: $required" }
}

$moduleRegistry = Get-Content -Raw -LiteralPath $modulePath -Encoding UTF8 | ConvertFrom-Json
$agentRegistry = Get-Content -Raw -LiteralPath $registryPath -Encoding UTF8 | ConvertFrom-Json
$ownerConnections = Get-Content -Raw -LiteralPath $ownerConnectionsPath -Encoding UTF8 | ConvertFrom-Json
$filesystem = Get-Content -Raw -LiteralPath $filesystemPath -Encoding UTF8 | ConvertFrom-Json
$skillFiles = @(Get-ChildItem -LiteralPath $skillsRoot -Recurse -Filter 'SKILL.md' -File)
$knowledgeFiles = @(Get-ChildItem -LiteralPath $knowledgeRoot -Recurse -Filter '*.md' -File)
$networkRoots = if (Test-Path -LiteralPath $networkRoot) {
    @(Get-ChildItem -LiteralPath $networkRoot -Directory | Where-Object Name -ne '_trash' | ForEach-Object FullName)
} else { @() }
$softwareRoots = if (Test-Path -LiteralPath $softwareRoot) {
    @(Get-ChildItem -LiteralPath $softwareRoot -Directory | ForEach-Object Name)
} else { @() }
$externalRefs = New-Object System.Collections.Generic.HashSet[string] ([System.StringComparer]::OrdinalIgnoreCase)
foreach ($file in $knowledgeFiles) {
    $content = Get-Content -Raw -LiteralPath $file.FullName -Encoding UTF8
    foreach ($match in [regex]::Matches($content, 'https://github\.com/[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+')) {
        [void]$externalRefs.Add($match.Value)
    }
}

$result = [ordered]@{
    schema_version = '1.0'
    id = 'historical-learning-reconciliation-' + (Get-Date).ToUniversalTime().ToString('yyyyMMddTHHmmssZ')
    mode = $Mode
    project_root = $root.Replace('\', '/')
    generated_at_utc = (Get-Date).ToUniversalTime().ToString('o')
    inventory = [ordered]@{
        specialist_owners = @($ownerConnections.owners).Count
        concept_agents = @($agentRegistry.concept_agents).Count
        skill_files = $skillFiles.Count
        knowledge_notes = $knowledgeFiles.Count
        module_registry_entries = @($moduleRegistry.modules).Count
        agent_filesystem_zones = @($filesystem.zones.PSObject.Properties).Count
        network_learning_roots = $networkRoots
        locked_software_roots = $softwareRoots
        referenced_github_projects = @($externalRefs | Sort-Object)
    }
    policy = [ordered]@{
        source_order = @('project lifecycle', 'Agent registry/filesystem', 'knowledge indexes', 'local source snapshots', 'current owner skills', 'tests', 'raw history only when ambiguous')
        private_content = 'excluded; only sanitized pointers and bounded conclusions'
        network_download = 'not performed by this inventory operation'
        top_level_owner_change = 'requires architecture review and two independent verified use cases'
    }
    status = if ($skillFiles.Count -gt 0 -and @($moduleRegistry.modules).Count -gt 0 -and @($agentRegistry.specialist_agents).Count -gt 0) { 'inventory-ready' } else { 'incomplete' }
}
$json = $result | ConvertTo-Json -Depth 10
if ($Apply) {
    $parent = Split-Path -Parent $outputFull
    New-Item -ItemType Directory -Force -Path $parent | Out-Null
    $utf8 = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($outputFull, $json, $utf8)
}
Write-Output $json
