[CmdletBinding()]
param(
    [string]$RepositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath $RepositoryRoot).Path
$fixtureRoot = & (Join-Path $root 'scripts\Resolve-CodexRunRoot.ps1') -ArchitectureRoot $root -Kind tmp -ChildPath ('file-organization-no-move-' + [guid]::NewGuid().ToString('N')) -Create
try {
    New-Item -ItemType Directory -Force -Path (Join-Path $fixtureRoot '.codex\project') | Out-Null
    New-Item -ItemType Directory -Force -Path (Join-Path $fixtureRoot '00-inbox') | Out-Null
    [ordered]@{
        schema_version = 1
        managed_roots = @('00-inbox')
        backup_root = (Join-Path $fixtureRoot '..\backup')
        validation_commands = @()
    } | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath (Join-Path $fixtureRoot '.codex\project\file-organization.json') -Encoding UTF8

    $elapsed = Measure-Command {
        $result = & (Join-Path $root 'skills\codex-file-organization\scripts\Invoke-FileOrganizationIteration.ps1') -ProjectRoot $fixtureRoot -Phase global-iteration | ConvertFrom-Json
        if ($result.planned_moves -ne 0 -or $result.reference_updates -ne 0 -or $result.result -ne 'passed') {
            throw 'No-move file-organization iteration returned an unexpected result.'
        }
    }
    if ($elapsed.TotalSeconds -gt 5) {
        throw "No-move file-organization iteration took too long: $([math]::Round($elapsed.TotalSeconds, 3))s"
    }

    Write-Host "File-organization no-move fast-path test passed in $([math]::Round($elapsed.TotalSeconds, 3))s."
}
finally {
    if (Test-Path -LiteralPath $fixtureRoot) { Remove-Item -LiteralPath $fixtureRoot -Recurse -Force }
}
