[CmdletBinding()]
param(
    [string]$RepositoryRoot = (Get-Location).Path
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath $RepositoryRoot).Path
$errorsRoot = Join-Path $root '.codex\errors'
$unresolved = @()

if (Test-Path -LiteralPath $errorsRoot) {
    $unresolved = @(
        Get-ChildItem -LiteralPath $errorsRoot -Filter report.json -Recurse -File |
            ForEach-Object {
                $raw = Get-Content -LiteralPath $_.FullName -Raw -Encoding UTF8
                if ($raw -notmatch '"module"\s*:\s*"codex-git-operations"') { return }
                $report = $raw | ConvertFrom-Json
                if ($report.status -notin @('fixed', 'verified')) {
                    [pscustomobject]@{ path = $_.FullName; status = $report.status; component = $report.component }
                }
            }
    )
}

if ($unresolved.Count -gt 0) {
    throw "Git recovery is incomplete: $($unresolved.Count) Git-process error report(s) must be fixed or verified before network, rendering, version, or release work begins."
}

[ordered]@{
    result = 'git-recovery-ready'
    unresolved_git_reports = 0
} | ConvertTo-Json
