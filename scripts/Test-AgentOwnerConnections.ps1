[CmdletBinding()]
param(
    [string]$RepositoryRoot = 'F:\codex'
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath $RepositoryRoot).Path
$manifestPath = Join-Path $root 'config\agent-system.json'
$networkPath = Join-Path $root 'config\agent-owner-connections.json'
$diagramPath = Join-Path $root 'config\agent-architecture-diagram.json'
$registryPath = Join-Path $root 'module-registry.json'

foreach ($path in @($manifestPath, $networkPath, $diagramPath, $registryPath)) {
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        throw "Agent owner connection authority is missing: $path"
    }
}

$manifest = Get-Content -LiteralPath $manifestPath -Raw -Encoding UTF8 | ConvertFrom-Json
$network = Get-Content -LiteralPath $networkPath -Raw -Encoding UTF8 | ConvertFrom-Json
$diagram = Get-Content -LiteralPath $diagramPath -Raw -Encoding UTF8 | ConvertFrom-Json
$registry = Get-Content -LiteralPath $registryPath -Raw -Encoding UTF8 | ConvertFrom-Json

if ($network.schema_version -ne 1 -or $network.model -ne 'global-experience-agent-owner-network') {
    throw 'Agent owner connection model is not recognized.'
}
if ($manifest.owner_network.source -ne 'config/agent-owner-connections.json' -or $manifest.owner_network.runtime_operation -ne 'RouteOwner') {
    throw 'Agent manifest does not route through the canonical owner network.'
}
if ('RouteOwner' -notin @($manifest.agent_runtime.operations)) {
    throw 'Agent runtime does not register RouteOwner.'
}

$activeOwners = @($registry.modules | Where-Object status -eq 'active' | ForEach-Object { [string]$_.name } | Sort-Object -Unique)
$ownerNodes = @($network.owners)
$ownerNames = @($ownerNodes | ForEach-Object { [string]$_.owner })
$duplicateOwners = @($ownerNames | Group-Object | Where-Object Count -gt 1 | ForEach-Object Name)
if ($duplicateOwners.Count -gt 0) {
    throw "Agent owner network duplicates owners: $($duplicateOwners -join ', ')"
}
$ownerDelta = @(Compare-Object $activeOwners @($ownerNames | Sort-Object -Unique))
if ($ownerDelta.Count -gt 0 -or $ownerNames.Count -ne 23) {
    throw "Agent owner network must match all 23 active owners: $($ownerDelta | Out-String)"
}
if ($network.harness_owner -ne 'codex-self-evolution') {
    throw 'Agent owner network does not name codex-self-evolution as harness owner.'
}

$diagramNodes = @()
foreach ($plane in @($diagram.planes)) {
    foreach ($module in @($plane.modules)) {
        $diagramNodes += [pscustomobject]@{
            owner = [string]$module.owner
            plane = [string]$plane.id
            stage = [string]$module.stage
        }
    }
}

$gateNames = @($manifest.tool_gates | ForEach-Object { [string]$_.name })
foreach ($node in $ownerNodes) {
    foreach ($field in @('owner', 'plane', 'stage', 'skill', 'verification')) {
        if ([string]::IsNullOrWhiteSpace([string]$node.$field)) {
            throw "Agent owner node '$($node.owner)' is missing $field."
        }
    }
    foreach ($field in @('triggers', 'consumes', 'produces')) {
        if (@($node.$field).Count -eq 0) {
            throw "Agent owner node '$($node.owner)' is missing $field entries."
        }
    }
    $skillPath = Join-Path $root ([string]$node.skill)
    if (-not (Test-Path -LiteralPath $skillPath -PathType Leaf)) {
        throw "Agent owner node '$($node.owner)' points to a missing skill: $($node.skill)"
    }
    if ([string]$node.skill -notin @($manifest.resources.functional_units)) {
        throw "Agent owner skill is not registered as a functional resource: $($node.skill)"
    }
    $presentation = @($diagramNodes | Where-Object owner -eq $node.owner)
    if ($presentation.Count -ne 1 -or $presentation[0].plane -ne $node.plane -or $presentation[0].stage -ne $node.stage) {
        throw "Agent owner '$($node.owner)' does not match the architecture presentation plane/stage."
    }
    if ($null -ne $node.tool_gate -and -not [string]::IsNullOrWhiteSpace([string]$node.tool_gate) -and [string]$node.tool_gate -notin $gateNames) {
        throw "Agent owner '$($node.owner)' references an unregistered tool gate: $($node.tool_gate)"
    }
}

$connections = @($network.connections)
$connectionKeys = @()
foreach ($connection in $connections) {
    foreach ($field in @('from', 'to', 'artifact', 'event')) {
        if ([string]::IsNullOrWhiteSpace([string]$connection.$field)) {
            throw "Agent owner connection is missing $field."
        }
    }
    if ([string]$connection.from -notin $ownerNames -or [string]$connection.to -notin $ownerNames) {
        throw "Agent owner connection references an inactive owner: $($connection.from) -> $($connection.to)"
    }
    $connectionKeys += "$($connection.from)|$($connection.to)|$($connection.event)"
}
$duplicateConnections = @($connectionKeys | Group-Object | Where-Object Count -gt 1 | ForEach-Object Name)
if ($duplicateConnections.Count -gt 0) {
    throw "Agent owner network duplicates connections: $($duplicateConnections -join ', ')"
}

foreach ($owner in $ownerNames) {
    if (@($connections | Where-Object from -eq $owner).Count -eq 0) {
        throw "Agent owner has no outgoing handoff: $owner"
    }
    if (@($connections | Where-Object to -eq $owner).Count -eq 0) {
        throw "Agent owner has no incoming handoff: $owner"
    }
}

function Get-ReachableOwners([string]$Start, [bool]$Reverse) {
    $seen = @{}
    $queue = [Collections.Generic.Queue[string]]::new()
    $queue.Enqueue($Start)
    $seen[$Start] = $true
    while ($queue.Count -gt 0) {
        $current = $queue.Dequeue()
        $next = if ($Reverse) {
            @($connections | Where-Object to -eq $current | ForEach-Object { [string]$_.from })
        } else {
            @($connections | Where-Object from -eq $current | ForEach-Object { [string]$_.to })
        }
        foreach ($candidate in $next) {
            if (-not $seen.ContainsKey($candidate)) {
                $seen[$candidate] = $true
                $queue.Enqueue($candidate)
            }
        }
    }
    return @($seen.Keys)
}

$forward = @(Get-ReachableOwners -Start $network.harness_owner -Reverse $false)
$reverse = @(Get-ReachableOwners -Start $network.harness_owner -Reverse $true)
if (@($ownerNames | Where-Object { $_ -notin $forward }).Count -gt 0) {
    throw 'Not every active owner is reachable from the Agent harness.'
}
if (@($ownerNames | Where-Object { $_ -notin $reverse }).Count -gt 0) {
    throw 'Not every active owner can return evidence to the Agent harness.'
}

$controllerText = Get-Content -LiteralPath (Join-Path $root 'agent\40-runtime\Invoke-GlobalExperienceAgent.ps1') -Raw -Encoding UTF8
$runtimeText = Get-Content -LiteralPath (Join-Path $root 'agent\40-runtime\Invoke-GlobalExperienceAgentRuntime.ps1') -Raw -Encoding UTF8
foreach ($text in @($controllerText, $runtimeText)) {
    if ($text -notmatch 'RouteOwner' -or $text -notmatch '\$Owner') {
        throw 'Agent controller/runtime does not expose the owner routing operation and selector.'
    }
}

[pscustomobject][ordered]@{
    status = 'passed'
    model = $network.model
    active_owner_coverage = $ownerNames.Count
    planes = @($ownerNodes.plane | Sort-Object -Unique).Count
    connections = $connections.Count
    reachable_from_harness = $forward.Count
    returnable_to_harness = $reverse.Count
    gated_owners = @($ownerNodes | Where-Object { $null -ne $_.tool_gate -and -not [string]::IsNullOrWhiteSpace([string]$_.tool_gate) }).Count
} | ConvertTo-Json -Compress
