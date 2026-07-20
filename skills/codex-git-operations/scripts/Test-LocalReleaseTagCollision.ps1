$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
$fixture = & (Join-Path $root 'scripts\Resolve-CodexRunRoot.ps1') -ArchitectureRoot $root -Kind tmp -ChildPath ('local-release-tag-' + [guid]::NewGuid().ToString('N')) -Create

try {
    & git -C $fixture init -q
    & git -C $fixture config user.email 'fixture@example.invalid'
    & git -C $fixture config user.name 'Fixture'
    'old' | Set-Content -LiteralPath (Join-Path $fixture 'old.txt') -Encoding UTF8
    & git -C $fixture add old.txt
    & git -C $fixture commit -q -m old
    & git -C $fixture tag -a v2.0 -m old-release
    $originalTag = (& git -C $fixture rev-parse refs/tags/v2.0).Trim()

    & git -C $fixture switch --orphan current -q
    'current' | Set-Content -LiteralPath (Join-Path $fixture 'current.txt') -Encoding UTF8
    & git -C $fixture add current.txt
    & git -C $fixture commit -q -m current

    $result = & (Join-Path $PSScriptRoot 'Resolve-LocalReleaseTagCollision.ps1') -RepositoryRoot $fixture -Tag v2.0 -Apply | ConvertFrom-Json
    if ($result.result -ne 'detached-local-tag-archived') { throw 'Detached local release tag was not reconciled.' }
    if (& git -C $fixture rev-parse -q --verify refs/tags/v2.0 2>$null) { throw 'Original stale release tag still exists.' }
    if ((& git -C $fixture rev-parse $result.archive_ref).Trim() -ne $originalTag) { throw 'Archived tag does not preserve the original tag object.' }

    & git -C $fixture tag -a v3.0 -m current-release
    $blocked = $false
    try {
        & (Join-Path $PSScriptRoot 'Resolve-LocalReleaseTagCollision.ps1') -RepositoryRoot $fixture -Tag v3.0 -Apply | Out-Null
    } catch {
        $blocked = $_.Exception.Message -match 'current history'
    }
    if (-not $blocked) { throw 'A local tag on the current history must remain a release blocker.' }

    Write-Host 'Local release tag collision test passed.'
}
finally {
    if (Test-Path -LiteralPath $fixture) { Remove-Item -LiteralPath $fixture -Recurse -Force }
}
