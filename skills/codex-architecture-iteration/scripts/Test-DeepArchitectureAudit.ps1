[CmdletBinding()]
param(
    [string]$RepositoryRoot = 'F:\codex'
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath $RepositoryRoot).Path
$script = Join-Path $root 'skills\codex-architecture-iteration\scripts\Invoke-DeepArchitectureAudit.ps1'
$output = Join-Path $root '.runtime\evidence\deep-architecture-audit-test.json'
& $script -ProjectRoot $root -OutputPath $output -Apply | Out-Null
$result = Get-Content -LiteralPath $output -Raw -Encoding UTF8 | ConvertFrom-Json
if ($result.result -ne 'deep-architecture-audit') { throw 'Deep architecture audit returned an unexpected result.' }
if ($result.mutation.changed) { throw 'Deep architecture audit must be evidence-only.' }
if ([int]$result.baseline.active_top_level_owners -ne 23) { throw 'Active owner count drifted from the registered baseline.' }
if (@($result.structural_health.missing_owner_connections).Count -ne 0) { throw 'Owner connection coverage has a gap.' }
if (@($result.structural_health.orphan_owner_connections).Count -ne 0) { throw 'Owner connection has an orphan.' }
if (@($result.structural_health.missing_owner_skills).Count -ne 0) { throw 'Owner skill coverage has a gap.' }
if (@($result.structural_health.child_profile_gaps).Count -ne 0) { throw 'Child profile contract has a gap.' }
if ([int]$result.baseline.functional_units -lt 1 -or [int]$result.baseline.information_units -lt 1) { throw 'Topology evidence is missing.' }
Write-Output 'Deep architecture audit test passed.'
