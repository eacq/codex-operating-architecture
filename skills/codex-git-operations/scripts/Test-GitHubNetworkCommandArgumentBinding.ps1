[CmdletBinding()]
param(
    [string]$RepositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
)

$ErrorActionPreference = 'Stop'
$helper = Join-Path $RepositoryRoot 'skills\codex-git-operations\scripts\Invoke-GitHubNetworkCommand.ps1'

$result = & $helper -RepositoryRoot $RepositoryRoot -Tool gh -NormalizeOnly release view private-v2.5 --repo example-org/example-private-repo --json tagName,url,targetCommitish,isDraft,isPrerelease | ConvertFrom-Json
$jsonIndex = [array]::IndexOf(@($result.arguments), '--json')
if ($jsonIndex -lt 0) { throw 'Normalized gh arguments lost the --json flag.' }
$fieldArgument = @($result.arguments)[$jsonIndex + 1]
if ($fieldArgument -ne 'tagName,url,targetCommitish,isDraft,isPrerelease') {
    throw "Unquoted PowerShell comma-separated --json fields were not normalized: $fieldArgument"
}

$quoted = & $helper -RepositoryRoot $RepositoryRoot -Tool gh -NormalizeOnly release view private-v2.5 --repo example-org/example-private-repo --json 'tagName,url,targetCommitish,isDraft,isPrerelease' | ConvertFrom-Json
$quotedFieldArgument = @($quoted.arguments)[([array]::IndexOf(@($quoted.arguments), '--json') + 1)]
if ($quotedFieldArgument -ne 'tagName,url,targetCommitish,isDraft,isPrerelease') {
    throw "Quoted gh --json fields changed unexpectedly: $quotedFieldArgument"
}

$gitResult = & $helper -RepositoryRoot $RepositoryRoot -Tool git -NormalizeOnly status --short | ConvertFrom-Json
if ((@($gitResult.arguments) -join '|') -ne 'status|--short') {
    throw 'Git argument pass-through changed unexpectedly.'
}

Write-Host 'GitHub network command argument-binding test passed.'
