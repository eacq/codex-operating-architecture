[CmdletBinding()]
param([string]$RepositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath $RepositoryRoot).Path
$scriptPath = Join-Path $root 'skills\codex-runtime-environments\scripts\Invoke-ScriptResourceRelease.ps1'
if (-not (Test-Path -LiteralPath $scriptPath -PathType Leaf)) {
    throw "Missing script resource release controller: $scriptPath"
}

$fixture = Join-Path $root ('.runtime\tmp\srr-test-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Force -Path $fixture | Out-Null
$oldFile = Join-Path $fixture 'old.log'
$freshFile = Join-Path $fixture 'fresh.log'
[IO.File]::WriteAllText($oldFile, 'old', [Text.UTF8Encoding]::new($false))
[IO.File]::WriteAllText($freshFile, 'fresh', [Text.UTF8Encoding]::new($false))
[IO.File]::SetLastWriteTimeUtc($oldFile, [DateTime]::UtcNow.AddDays(-2))
[IO.File]::SetLastWriteTimeUtc($freshFile, [DateTime]::UtcNow.AddMinutes(-1))

$now = [DateTime]::UtcNow
$table = @(
    [pscustomobject]@{ ProcessId = 2001; Name = 'node_repl.exe'; CommandLine = 'OpenAI\Codex\runtimes\cua_node\bin\node_repl.exe --idle'; CreationDate = $now.AddHours(-3) },
    [pscustomobject]@{ ProcessId = 2002; Name = 'node_repl.exe'; CommandLine = 'OpenAI\Codex\runtimes\cua_node\bin\node_repl.exe --fresh'; CreationDate = $now.AddMinutes(-1) }
)

try {
    $dry = & $scriptPath -RepositoryRoot $root -TmpRoot $fixture -TmpRetentionHours 24 -ProcessName 'node_repl' -ScopePattern 'OpenAI\Codex\runtimes\cua_node' -ProcessTable $table | ConvertFrom-Json
    if ($dry.result -ne 'dry-run') { throw 'Default must be a dry-run.' }
    if ($dry.tmp_candidate_count -ne 1 -or $dry.tmp_candidates[0].name -ne 'old.log') { throw 'Dry-run must list only the old tmp file.' }
    if (-not (Test-Path -LiteralPath $oldFile)) { throw 'Dry-run must not delete the old tmp file.' }
    if ($dry.processes.eligible_count -ne 1 -or $dry.processes.terminated[0].process_id -ne 2001) { throw 'Dry-run must report the old in-scope process as eligible.' }

    $applied = & $scriptPath -RepositoryRoot $root -TmpRoot $fixture -TmpRetentionHours 24 -ProcessName 'node_repl' -ScopePattern 'OpenAI\Codex\runtimes\cua_node' -ProcessTable $table -Apply | ConvertFrom-Json
    if ($applied.result -ne 'released') { throw 'Apply must report released.' }
    if (Test-Path -LiteralPath $oldFile) { throw 'Apply must delete the old tmp file.' }
    if (-not (Test-Path -LiteralPath $freshFile)) { throw 'Apply must preserve the fresh tmp file.' }
    if ($applied.tmp_cleaned.Count -ne 1) { throw 'Apply must clean exactly the old tmp file.' }

    $skip = & $scriptPath -RepositoryRoot $root -TmpRoot $fixture -TmpRetentionHours 24 -SkipProcesses | ConvertFrom-Json
    if ($null -ne $skip.processes) { throw 'SkipProcesses must omit the process release step.' }
} finally {
    if (Test-Path -LiteralPath $fixture) { Remove-Item -LiteralPath $fixture -Recurse -Force }
}

[pscustomobject]@{
    status = 'passed'
    model = 'codex-runtime-environments-script-resource-release'
    script = 'skills/codex-runtime-environments/scripts/Invoke-ScriptResourceRelease.ps1'
    dry_run_default = $true
    tmp_retention_enforced = $true
    process_release_integrated = $true
    workspace_advisory_only = $true
} | ConvertTo-Json -Depth 4
