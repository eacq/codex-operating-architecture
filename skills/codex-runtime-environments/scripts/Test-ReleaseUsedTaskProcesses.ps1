[CmdletBinding()]
param([string]$RepositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath $RepositoryRoot).Path
$scriptPath = Join-Path $root 'skills\codex-runtime-environments\scripts\Release-UsedTaskProcesses.ps1'
if (-not (Test-Path -LiteralPath $scriptPath -PathType Leaf)) {
    throw "Missing process release script: $scriptPath"
}

$now = [DateTime]::UtcNow
$scope = 'OpenAI\Codex\runtimes\cua_node'
$table = @(
    [pscustomobject]@{ ProcessId = 1001; Name = 'node_repl.exe'; CommandLine = "`"$scope\bin\node_repl.exe`" --idle"; CreationDate = $now.AddHours(-2) },
    [pscustomobject]@{ ProcessId = 1002; Name = 'node_repl.exe'; CommandLine = "`"$scope\bin\node_repl.exe`" --fresh"; CreationDate = $now.AddMinutes(-1) },
    [pscustomobject]@{ ProcessId = 1003; Name = 'node_repl.exe'; CommandLine = "`"$scope\bin\node_repl.exe`" --owned-by codex.exe"; CreationDate = $now.AddHours(-3) },
    [pscustomobject]@{ ProcessId = 1004; Name = 'other.exe'; CommandLine = 'outside scope'; CreationDate = $now.AddHours(-3) }
)

$dryRun = & $scriptPath -RepositoryRoot $root -ProcessName 'node_repl' -ScopePattern $scope -MinAgeSeconds 600 -ProcessTable $table | ConvertFrom-Json
if ($dryRun.result -ne 'dry-run') { throw 'Default invocation must be a dry-run.' }
if ($dryRun.eligible_count -ne 1) { throw "Expected exactly one eligible process in dry-run, got $($dryRun.eligible_count)." }
if (@($dryRun.terminated).Count -ne 1 -or @($dryRun.terminated)[0].process_id -ne 1001 -or -not @($dryRun.terminated)[0].dry_run) {
    throw 'Dry-run must report only the old in-scope process as eligible, without stopping it.'
}

$applied = & $scriptPath -RepositoryRoot $root -ProcessName 'node_repl' -ScopePattern $scope -MinAgeSeconds 600 -ProcessTable $table -Apply | ConvertFrom-Json
if ($applied.result -ne 'released') { throw 'Apply must report released.' }
$ids = @($applied.terminated | ForEach-Object { $_.process_id })
if (1001 -notin $ids) { throw 'Apply must include the eligible process id 1001.' }
if (1002 -in $ids -or 1003 -in $ids -or 1004 -in $ids) {
    throw 'Apply must not release fresh, protected, or out-of-scope processes.'
}

[pscustomobject]@{
    status = 'passed'
    model = 'codex-runtime-environments-process-release'
    script = 'skills/codex-runtime-environments/scripts/Release-UsedTaskProcesses.ps1'
    dry_run_default = $true
    scope_token_filtered = $true
    age_filtered = $true
    protected_list = $true
} | ConvertTo-Json -Depth 4
