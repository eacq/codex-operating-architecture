[CmdletBinding(DefaultParameterSetName = 'Resolve')]
param(
    [string]$RepositoryRoot = 'F:\codex',
    [Parameter(ParameterSetName = 'Resolve', Mandatory = $true)]
    [string]$Id,
    [Parameter(ParameterSetName = 'List', Mandatory = $true)]
    [switch]$List
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath $RepositoryRoot).Path
$agentRoot = Join-Path $root 'agent'
$items = New-Object System.Collections.Generic.List[object]
foreach ($file in @(Get-ChildItem -LiteralPath $agentRoot -Recurse -File -Filter '*.json')) {
    try { $value = Get-Content -LiteralPath $file.FullName -Raw -Encoding UTF8 | ConvertFrom-Json } catch { continue }
    if ($value.generated_by -ne 'agent-filesystem-projection' -or -not $value.projection_id) { continue }
    $items.Add([pscustomobject][ordered]@{
        id = [string]$value.projection_id
        kind = [string]$value.kind
        path = $file.FullName.Substring($root.Length).TrimStart('\').Replace('\', '/')
        sources = @($value.sources)
    })
}
$ordered = @($items | Sort-Object id)
if ($List) { $ordered | ConvertTo-Json -Depth 8; return }
$match = @($ordered | Where-Object id -eq $Id)
if ($match.Count -ne 1) { throw "Agent filesystem id did not resolve uniquely: $Id" }
$match[0] | ConvertTo-Json -Depth 8
