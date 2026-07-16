[CmdletBinding(SupportsShouldProcess)]
param(
    [string]$QuarantineRoot = $(if ($env:CODEX_IMAGE_QUARANTINE_ROOT) { $env:CODEX_IMAGE_QUARANTINE_ROOT } else { Join-Path $PSScriptRoot '..\..\..\knowledge-vault\.image-hosting\quarantine' }),
    [int]$RetentionDays = 7
)

$ErrorActionPreference = 'Stop'
if (-not (Test-Path -LiteralPath $QuarantineRoot)) { return }
$resolved = (Resolve-Path -LiteralPath $QuarantineRoot).Path
if ((Split-Path -Leaf $resolved) -ne 'quarantine') {
    throw "Unexpected quarantine path: $resolved"
}
$cutoff = (Get-Date).AddDays(-$RetentionDays)
Get-ChildItem -LiteralPath $resolved -Directory | Where-Object LastWriteTime -lt $cutoff | ForEach-Object {
    if ($PSCmdlet.ShouldProcess($_.FullName, "Delete expired image quarantine")) {
        Remove-Item -LiteralPath $_.FullName -Recurse -Force
    }
}
