[CmdletBinding()]
param(
    [string]$RepositoryRoot = (Get-Location).Path
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath $RepositoryRoot).Path
$manifest = Get-Content -LiteralPath (Join-Path $root 'config\agent-system.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$diagram = $manifest.architecture_contract.diagram
if (-not $diagram) { throw 'Agent architecture contract does not declare a diagram.' }

$pngPath = Join-Path $root $diagram.path
$paperStylePath = Join-Path $root $diagram.paper_style_path
$paperStyleProvenancePath = Join-Path $root $diagram.paper_style_provenance
$generatorPath = Join-Path $root $diagram.generator
$provenancePath = Join-Path $root $diagram.provenance
$mappingPath = Join-Path $root $diagram.mapping
$ownerNetworkPath = Join-Path $root $diagram.owner_network
$agentRegistryPath = Join-Path $root $diagram.agent_registry
$interfacePolicyPath = Join-Path $root $diagram.interface_policy
$agentFilesystemPath = Join-Path $root $diagram.agent_filesystem
foreach ($path in @($pngPath, $paperStylePath, $paperStyleProvenancePath, $generatorPath, $provenancePath, $mappingPath, $ownerNetworkPath, $agentRegistryPath, $interfacePolicyPath, $agentFilesystemPath)) {
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        throw "Agent architecture diagram contract references a missing file: $path"
    }
}

Add-Type -AssemblyName System.Drawing
$paperBitmap = [Drawing.Bitmap]::FromFile($paperStylePath)
try {
    if ($paperBitmap.Width -ne 3840 -or $paperBitmap.Height -ne 2400) {
        throw "Paper-style Agent architecture PNG has the wrong dimensions: $($paperBitmap.Width)x$($paperBitmap.Height)."
    }
    $paperSample = New-Object 'System.Collections.Generic.HashSet[string]'
    for ($x = 0; $x -lt $paperBitmap.Width; $x += 120) {
        for ($y = 0; $y -lt $paperBitmap.Height; $y += 90) {
            $color = $paperBitmap.GetPixel($x, $y)
            [void]$paperSample.Add("$($color.R),$($color.G),$($color.B)")
        }
    }
    if ($paperSample.Count -lt 12) {
        throw 'Paper-style Agent architecture PNG appears blank or visually under-specified.'
    }
}
finally {
    $paperBitmap.Dispose()
}

$bitmap = [Drawing.Bitmap]::FromFile($pngPath)
try {
    if ($bitmap.Width -lt 3600 -or $bitmap.Height -lt 2200) {
        throw "Agent architecture PNG is too small: $($bitmap.Width)x$($bitmap.Height)."
    }
    $sample = New-Object 'System.Collections.Generic.HashSet[string]'
    for ($x = 0; $x -lt $bitmap.Width; $x += 120) {
        for ($y = 0; $y -lt $bitmap.Height; $y += 90) {
            $color = $bitmap.GetPixel($x, $y)
            [void]$sample.Add("$($color.R),$($color.G),$($color.B)")
        }
    }
    if ($sample.Count -lt 12) {
        throw 'Agent architecture PNG appears blank or visually under-specified.'
    }
}
finally {
    $bitmap.Dispose()
}

$mapping = Get-Content -LiteralPath $mappingPath -Raw -Encoding UTF8 | ConvertFrom-Json
if ($mapping.schema_version -ne 2 -or $mapping.model -ne 'global-experience-agent-module-map') {
    throw 'Agent architecture mapping has the wrong schema or model.'
}
if ($mapping.owner_network -ne $diagram.owner_network) {
    throw 'Agent architecture mapping does not reference the executable owner network.'
}
if ($mapping.agent_registry -ne $diagram.agent_registry -or $mapping.root_agent -ne 'global-experience-agent') {
    throw 'Agent architecture mapping does not reference the canonical root Agent registry.'
}
if ($mapping.agent_filesystem -ne 'agent/agent-filesystem.json' -or -not (Test-Path -LiteralPath (Join-Path $root $mapping.agent_filesystem) -PathType Leaf)) {
    throw 'Agent architecture mapping does not reference the physical Agent filesystem.'
}
$interfacePolicy = Get-Content -LiteralPath $interfacePolicyPath -Raw -Encoding UTF8 | ConvertFrom-Json
if ($mapping.interface_policy -ne $diagram.interface_policy -or @($mapping.interface_band.interfaces).Count -ne 4 -or @($interfacePolicy.interfaces).Count -ne 4 -or @($interfacePolicy.exits).Count -ne 9) {
    throw 'Agent architecture mapping does not align with the four permission interfaces and typed exits.'
}
if (@(Compare-Object @($mapping.interface_band.interfaces.id | Sort-Object) @($interfacePolicy.interfaces.id | Sort-Object)).Count -gt 0) {
    throw 'Agent architecture mapping interface ids have drifted from the policy.'
}
$planes = @($mapping.planes)
if ($planes.Count -ne 4 -or @($planes.id | Sort-Object -Unique).Count -ne 4) {
    throw 'Agent architecture mapping must define four unique responsibility planes.'
}
$runtimeStageIds = @('harness') + @($mapping.runtime_steps.id)
$mappedModules = @($planes | ForEach-Object { @($_.modules) })
$mappedOwnerNames = @($mappedModules.owner)
$duplicateOwners = @($mappedOwnerNames | Group-Object | Where-Object Count -gt 1 | ForEach-Object Name)
if ($duplicateOwners.Count -gt 0) {
    throw "Agent architecture mapping duplicates owner modules: $($duplicateOwners -join ', ')"
}
foreach ($module in $mappedModules) {
    foreach ($requiredField in @('owner', 'stage', 'responsibility_zh', 'responsibility_en', 'durable_output_zh', 'durable_output_en')) {
        if (-not $module.$requiredField) {
            throw "Agent architecture mapping module '$($module.owner)' is missing $requiredField."
        }
    }
    if ($module.stage -notin $runtimeStageIds) {
        throw "Agent architecture mapping module '$($module.owner)' references unknown stage '$($module.stage)'."
    }
}
$registry = Get-Content -LiteralPath (Join-Path $root 'module-registry.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$activeOwners = @($registry.modules | Where-Object status -eq 'active' | ForEach-Object name | Sort-Object -Unique)
$mappedOwners = @($mappedOwnerNames | Sort-Object -Unique)
$missingOwners = @($activeOwners | Where-Object { $_ -notin $mappedOwners })
$extraOwners = @($mappedOwners | Where-Object { $_ -notin $activeOwners })
if ($mappedOwners.Count -ne 23 -or $missingOwners.Count -gt 0 -or $extraOwners.Count -gt 0) {
    throw "Agent architecture mapping does not match the 23 active owners. Missing: $($missingOwners -join ', '); extra: $($extraOwners -join ', ')."
}
if (@($mappedModules | Where-Object owner -eq 'codex-self-evolution').stage -ne 'harness') {
    throw 'codex-self-evolution must map to the harness stage.'
}

$ownerNetwork = Get-Content -LiteralPath $ownerNetworkPath -Raw -Encoding UTF8 | ConvertFrom-Json
$networkOwners = @($ownerNetwork.owners | ForEach-Object owner | Sort-Object -Unique)
if (@(Compare-Object $mappedOwners $networkOwners).Count -gt 0 -or @($ownerNetwork.connections).Count -lt 23) {
    throw 'Agent architecture presentation is not aligned with the executable owner network.'
}

$agentRegistry = Get-Content -LiteralPath $agentRegistryPath -Raw -Encoding UTF8 | ConvertFrom-Json
$conceptAgents = @($agentRegistry.concept_agents)
$childStates = @($agentRegistry.dynamic_subagents.states)
if ($agentRegistry.root_agent.id -ne 'global-experience-agent' -or $conceptAgents.Count -ne 5) {
    throw 'Agent registry must expose one canonical root Agent and five concept Agents.'
}
if ($mapping.concept_agent_count -ne $conceptAgents.Count -or $mapping.specialist_agent_count -ne $mappedOwners.Count) {
    throw 'Architecture mapping Agent counts have drifted from the executable registries.'
}
if (@(Compare-Object @($mapping.child_lifecycle) $childStates).Count -gt 0 -or $childStates.Count -ne 4) {
    throw 'Architecture mapping has drifted from the executable child Agent lifecycle.'
}
foreach ($module in $mappedModules) {
    $plane = @($planes | Where-Object { $module.owner -in @($_.modules.owner) })[0]
    $ownerNode = @($ownerNetwork.owners | Where-Object owner -eq $module.owner)
    if ($ownerNode.Count -ne 1 -or $ownerNode[0].plane -ne $plane.id -or $ownerNode[0].stage -ne $module.stage) {
        throw "Agent architecture module '$($module.owner)' has drifted from its owner-network plane or stage."
    }
}

$provenance = Get-Content -LiteralPath $provenancePath -Raw -Encoding UTF8
foreach ($required in @('Purpose', 'Final format', 'Theme', 'Module correspondence', 'Agent registry', 'Owner network', 'Regenerate when', 'Privacy boundary', 'Chinese')) {
    if ($provenance -notmatch [regex]::Escape($required)) {
        throw "Agent architecture diagram provenance is missing: $required"
    }
}

[ordered]@{
    status = 'passed'
    path = $diagram.path
    paper_style_path = $diagram.paper_style_path
    generator = $diagram.generator
    provenance = $diagram.provenance
    mapping = $diagram.mapping
    owner_network = $diagram.owner_network
    agent_registry = $diagram.agent_registry
    interface_policy = $diagram.interface_policy
    interfaces = @($interfacePolicy.interfaces).Count
    exits = @($interfacePolicy.exits).Count
    active_owner_coverage = $mappedOwners.Count
    concept_agents = $conceptAgents.Count
    child_states = $childStates.Count
    handoffs = @($ownerNetwork.connections).Count
    minimum_size = '3600x2200'
} | ConvertTo-Json -Compress
