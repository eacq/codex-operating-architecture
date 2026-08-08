[CmdletBinding()]
param(
    [string]$RepositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath $RepositoryRoot).Path
$fixtureRoot = & (Join-Path $root 'scripts\Resolve-CodexRunRoot.ps1') -ArchitectureRoot $root -Kind tmp -ChildPath ('file-organization-global-scope-' + [guid]::NewGuid().ToString('N')) -Create
try {
    New-Item -ItemType Directory -Force -Path (Join-Path $fixtureRoot '.codex\project') | Out-Null
    [ordered]@{
        schema_version = 1
        managed_roots = @('.')
        backup_root = (Join-Path $fixtureRoot '..\backup')
        validation_commands = @()
    } | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath (Join-Path $fixtureRoot '.codex\project\file-organization.json') -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $fixtureRoot 'tracked.md') -Value 'tracked' -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $fixtureRoot 'untracked.md') -Value 'untracked' -Encoding UTF8
    & git -C $fixtureRoot init --quiet
    & git -C $fixtureRoot add -- tracked.md
    & git -C $fixtureRoot -c user.name='Codex Test' -c user.email='codex-test@local.invalid' commit -m 'fixture' --quiet

    $global = & (Join-Path $root 'skills\codex-file-organization\scripts\Invoke-FileOrganizationIteration.ps1') -ProjectRoot $fixtureRoot -Phase global-iteration | ConvertFrom-Json
    if ($global.candidate_scope -ne 'git-untracked' -or $global.planned_moves -ne 1) {
        throw "Global iteration should inspect only untracked organization candidates, got scope=$($global.candidate_scope), moves=$($global.planned_moves)."
    }

    $ongoing = & (Join-Path $root 'skills\codex-file-organization\scripts\Invoke-FileOrganizationIteration.ps1') -ProjectRoot $fixtureRoot -Phase ongoing-work | ConvertFrom-Json
    if ($ongoing.candidate_scope -ne 'managed-root-files' -or $ongoing.planned_moves -lt 2) {
        throw "Ongoing work should preserve the managed-root scan semantics, got scope=$($ongoing.candidate_scope), moves=$($ongoing.planned_moves)."
    }

    Write-Host 'File-organization global-iteration scope test passed.'
}
finally {
    if (Test-Path -LiteralPath $fixtureRoot) { Remove-Item -LiteralPath $fixtureRoot -Recurse -Force }
}
