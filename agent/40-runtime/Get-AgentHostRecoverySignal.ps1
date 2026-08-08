[CmdletBinding(PositionalBinding = $false)]
param(
    [string]$RepositoryRoot = 'F:\codex',
    [string]$SnapshotJson,
    [string]$SnapshotPath,
    [int]$StallThresholdSeconds = 0,
    [string]$MarkerPath,
    [switch]$Persist
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath $RepositoryRoot).Path
. (Join-Path $root 'agent\40-runtime\TransportRecovery.ps1')
. (Join-Path $root 'agent\40-runtime\HostTransportRecovery.ps1')
$policy = Get-AgentHostTransportRecoveryPolicy -RepositoryRoot $root

if ($SnapshotPath) {
    $SnapshotJson = Get-Content -LiteralPath $SnapshotPath -Raw -Encoding UTF8
}
if ([string]::IsNullOrWhiteSpace($SnapshotJson)) {
    throw 'A Codex app snapshot is required through SnapshotJson or SnapshotPath.'
}
$snapshot = $SnapshotJson | ConvertFrom-Json
$signal = Get-AgentHostRecoverySignal -Snapshot $snapshot -Policy $policy -StallThresholdSeconds $StallThresholdSeconds
if ($Persist -or $signal.restart_required) {
    if ([string]::IsNullOrWhiteSpace($MarkerPath)) {
        $MarkerPath = Join-Path $root '.codex\project\host-recovery\latest.json'
    }
    $signal.marker_path = Write-AgentHostRecoveryMarker -MarkerPath $MarkerPath -Signal $signal
}
$signal | ConvertTo-Json -Depth 20 -Compress
