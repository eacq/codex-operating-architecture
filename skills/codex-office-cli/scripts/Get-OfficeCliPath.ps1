[CmdletBinding()]
param(
    [string]$RepositoryRoot = ''
)

$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) {
    $RepositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
}

$candidates = @(
    $env:OFFICECLI_EXE,
    (Join-Path $RepositoryRoot '.codex\software-install\OfficeCLI\officecli.exe')
) | Where-Object { $_ }

foreach ($candidate in $candidates) {
    if (Test-Path -LiteralPath $candidate) {
        (Resolve-Path -LiteralPath $candidate).Path
        exit 0
    }
}

$command = Get-Command officecli.exe -ErrorAction SilentlyContinue
if ($command) {
    $command.Source
    exit 0
}

throw 'OfficeCLI executable was not found. Install it through codex-tool-installation before using codex-office-cli.'
