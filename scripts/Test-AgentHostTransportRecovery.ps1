[CmdletBinding()]
param([string]$RepositoryRoot = 'F:\codex')

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath $RepositoryRoot).Path
$runner = Join-Path $root 'agent\40-runtime\Get-AgentHostRecoverySignal.ps1'
$fixtureRoot = & (Join-Path $root 'scripts\Resolve-CodexRunRoot.ps1') -ArchitectureRoot $root -Kind tmp -ChildPath ('agent-host-recovery-' + [guid]::NewGuid().ToString('N')) -IgnoreConfiguredRoot -Create
$marker = Join-Path $fixtureRoot 'latest.json'
try {
    $oldEpoch = [DateTimeOffset]::UtcNow.AddSeconds(-300).ToUnixTimeSeconds()
    $staleSnapshot = [ordered]@{ threads = @([ordered]@{
        id = 'stale-thread'; title = 'stale fixture'; status = 'active'
        latestTurn = [ordered]@{ status = 'inProgress'; startedAt = $oldEpoch; items = @() }
        latestAssistantMessageId = $null; latestToolMarkerId = $null; error = $null
    }) } | ConvertTo-Json -Depth 10 -Compress
    $stale = (& $runner -RepositoryRoot $root -SnapshotJson $staleSnapshot -StallThresholdSeconds 180 -MarkerPath $marker -Persist) | ConvertFrom-Json
    if (-not $stale.restart_required -or $stale.classification -ne 'host-stall-suspected' -or -not (Test-Path -LiteralPath $marker)) { throw 'Host watchdog did not detect a stale in-progress thread.' }

    $staleToolSnapshot = [ordered]@{ polls = @([ordered]@{
        thread = [ordered]@{ id = 'stale-tool-thread'; title = 'stale tool fixture'; status = [ordered]@{ type = 'active' } }
        latestTurn = [ordered]@{ status = 'inProgress'; startedAt = $oldEpoch }
        latestAssistantMessageId = 'assistant-before-tool'
        latestToolMarkerId = 'tool-still-running'
        latestToolMarker = [ordered]@{ id = 'tool-still-running'; type = 'mcpToolCall'; name = 'js'; status = 'inProgress' }
    }) } | ConvertTo-Json -Depth 10 -Compress
    $staleTool = (& $runner -RepositoryRoot $root -SnapshotJson $staleToolSnapshot -StallThresholdSeconds 180 -MarkerPath $marker) | ConvertFrom-Json
    $staleToolEvidence = @($staleTool.threads[0].evidence)
    if (-not $staleTool.restart_required -or $staleTool.classification -ne 'host-stall-suspected' -or 'stale_in_progress_tool_marker' -notin $staleToolEvidence) { throw 'Host watchdog did not detect a stale in-progress tool marker.' }

    $freshSnapshot = [ordered]@{ threads = @([ordered]@{
        id = 'fresh-thread'; title = 'fresh fixture'; status = 'active'
        latestTurn = [ordered]@{ status = 'inProgress'; startedAt = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds(); items = @() }
        latestAssistantMessageId = $null; latestToolMarkerId = $null; error = $null
    }) } | ConvertTo-Json -Depth 10 -Compress
    $fresh = (& $runner -RepositoryRoot $root -SnapshotJson $freshSnapshot -StallThresholdSeconds 180 -MarkerPath $marker) | ConvertFrom-Json
    if ($fresh.restart_required -or $fresh.classification -ne 'not-stalled') { throw 'Host watchdog falsely classified a fresh thread.' }

    $errorSnapshot = [ordered]@{ threads = @([ordered]@{
        id = 'error-thread'; title = 'error fixture'; status = 'active'
        latestTurn = [ordered]@{ status = 'inProgress'; startedAt = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds(); error = 'stream disconnected before completion: error sending request for url'; items = @() }
        latestAssistantMessageId = $null; latestToolMarkerId = $null
    }) } | ConvertTo-Json -Depth 10 -Compress
    $transport = (& $runner -RepositoryRoot $root -SnapshotJson $errorSnapshot -StallThresholdSeconds 180 -MarkerPath $marker) | ConvertFrom-Json
    if (-not $transport.restart_required -or $transport.classification -ne 'transport-disconnect') { throw 'Host watchdog did not preserve the transport classifier.' }

    [pscustomobject]@{
        status = 'passed'
        stale_snapshot = $stale.classification
        stale_tool_snapshot = $staleTool.classification
        fresh_snapshot = $fresh.classification
        transport_snapshot = $transport.classification
        marker_persisted = $true
        action = $stale.automatic_action
    } | ConvertTo-Json -Compress
} finally {
    if (Test-Path -LiteralPath $fixtureRoot) { Remove-Item -LiteralPath $fixtureRoot -Recurse -Force }
}
