[CmdletBinding()]
param(
    [string]$RepositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath $RepositoryRoot).Path
$fixtureRoot = & (Join-Path $root 'scripts\Resolve-CodexRunRoot.ps1') -ArchitectureRoot $root -Kind tmp -ChildPath ('file-organization-backup-fastpath-' + [guid]::NewGuid().ToString('N')) -Create
$backupRoot = Join-Path $fixtureRoot '..\backup'
try {
    New-Item -ItemType Directory -Force -Path $fixtureRoot | Out-Null
    & git -C $fixtureRoot init --quiet
    for ($i = 0; $i -lt 1001; $i++) {
        Set-Content -LiteralPath (Join-Path $fixtureRoot ("tracked-$i.txt")) -Value "tracked $i" -Encoding UTF8
    }
    & git -C $fixtureRoot add -- .
    & git -C $fixtureRoot -c user.name='Codex Test' -c user.email='codex-test@local.invalid' commit -m 'fixture' --quiet

    $elapsed = Measure-Command {
        $script:backup = & (Join-Path $root 'skills\codex-file-organization\scripts\New-FileOrganizationBackup.ps1') -Root $fixtureRoot -BackupRoot $backupRoot -Apply | ConvertFrom-Json
    }
    if ($backup.backup_type -ne 'git-bundle') { throw "Expected git-bundle backup type, got $($backup.backup_type)." }
    if ($backup.file_inventory -ne 'git-ls-files-cached-fast-path') { throw "Expected fast-path inventory, got $($backup.file_inventory)." }
    if ($backup.file_count -ne 1001) { throw "Expected 1001 tracked files, got $($backup.file_count)." }
    if (-not $backup.archive_sha256) { throw 'Backup did not report archive sha256.' }
    $bundles = @(Get-ChildItem -LiteralPath $backupRoot -Filter '*.bundle' -File -Recurse)
    if ($bundles.Count -ne 1) { throw "Expected one git bundle, found $($bundles.Count)." }
    $zips = @(Get-ChildItem -LiteralPath $backupRoot -Filter '*.zip' -File -Recurse)
    if ($zips.Count -ne 0) { throw 'Fast path should not create a zip archive.' }
    Write-Host "File-organization Git backup fast-path test passed in $([math]::Round($elapsed.TotalSeconds, 3))s."
}
finally {
    if (Test-Path -LiteralPath $fixtureRoot) { Remove-Item -LiteralPath $fixtureRoot -Recurse -Force }
    if (Test-Path -LiteralPath $backupRoot) { Remove-Item -LiteralPath $backupRoot -Recurse -Force }
}
