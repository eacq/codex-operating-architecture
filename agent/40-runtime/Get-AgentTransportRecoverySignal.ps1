[CmdletBinding(PositionalBinding = $false)]
param(
    [Parameter(Mandatory = $true)]
    [string]$RepositoryRoot,
    [AllowNull()]
    [string]$ErrorText,
    [string]$Component = 'unknown',
    [switch]$BeforeCompletion
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath $RepositoryRoot).Path
. (Join-Path $root 'agent\40-runtime\TransportRecovery.ps1')
$policy = Get-AgentTransportRecoveryPolicy -RepositoryRoot $root
$signal = Get-AgentTransportRecoverySignal -Policy $policy -ErrorText $ErrorText -Component $Component -BeforeCompletion:$BeforeCompletion.IsPresent
$signal | ConvertTo-Json -Depth 10 -Compress
