[CmdletBinding()]
param(
    [string]$RepositoryRoot = 'F:\codex',
    [int]$Iterations = 8,
    [string]$OutputPath = ''
)

$ErrorActionPreference = 'Stop'
$root = [IO.Path]::GetFullPath($RepositoryRoot)
$backend = Join-Path $root 'agent\40-runtime\Invoke-AgentMemoryStore.py'
$runtimeConfig = Join-Path $root '.codex\project\validation-runtime.json'
$configuredPython = [string](Get-Content -LiteralPath $runtimeConfig -Raw -Encoding UTF8 | ConvertFrom-Json).python_path
if (-not (Test-Path -LiteralPath $configuredPython -PathType Leaf)) {
    throw "Configured Python runtime is missing: $configuredPython"
}
if (-not (Test-Path -LiteralPath $backend -PathType Leaf)) {
    throw "Memory backend is missing: $backend"
}
if ($Iterations -lt 3) { throw 'Iterations must be at least 3.' }

$analysisRoot = Join-Path $root '.codex\project\timing-analysis'
$workRoot = Join-Path $analysisRoot 'memory-backend-benchmark-work'
New-Item -ItemType Directory -Force -Path $workRoot | Out-Null
$dbPath = Join-Path $workRoot 'synthetic-memory.db'
$snapshotPath = Join-Path $workRoot 'snapshot.md'
Remove-Item -LiteralPath $dbPath, "$dbPath-shm", "$dbPath-wal", $snapshotPath -Force -ErrorAction SilentlyContinue

function Invoke-Timed([scriptblock]$Action) {
    $watch = [Diagnostics.Stopwatch]::StartNew()
    & $Action
    $exitCode = $LASTEXITCODE
    $watch.Stop()
    if ($exitCode -ne 0) { throw "Timed action failed with exit code $exitCode" }
    return [double]$watch.Elapsed.TotalMilliseconds
}

function Invoke-Backend([string[]]$Arguments) {
    $env:PYTHONUTF8 = '1'
    $env:PYTHONIOENCODING = 'utf-8'
    $env:PYTHONNOUSERSITE = '1'
    & $configuredPython -s $backend --db $dbPath @Arguments | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "Memory backend failed: $($Arguments -join ' ')" }
}

$startup = @()
$probe = @()
$init = @()
$store = @()
$search = @()
$snapshot = @()

for ($i = 0; $i -lt $Iterations; $i++) {
    $startup += Invoke-Timed { & $configuredPython -s -c 'pass' }
    $probe += Invoke-Timed { & $configuredPython -s -c 'import sys; sys.exit(0)' }
}

Invoke-Backend @('init')
for ($i = 0; $i -lt $Iterations; $i++) {
    $init += Invoke-Timed { Invoke-Backend @('init') }
    $id = "synthetic-$i"
    $store += Invoke-Timed {
        Invoke-Backend @(
            'store', '--id', $id, '--agent-id', 'benchmark-agent', '--session-id', 'benchmark-session',
            '--type', 'context', '--layer', 'episodic', '--content', "synthetic benchmark record $i",
            '--source', 'timing-benchmark', '--confidence', '0.8', '--priority', '5'
        )
    }
    $search += Invoke-Timed { Invoke-Backend @('search', '--query', 'synthetic', '--limit', '10') }
    $snapshot += Invoke-Timed { Invoke-Backend @('snapshot', '--limit', '50', '--output', $snapshotPath) }
}

function Get-Summary([double[]]$Values) {
    $sorted = @($Values | Sort-Object)
    return [ordered]@{
        count = $sorted.Count
        min_ms = [Math]::Round($sorted[0], 3)
        median_ms = [Math]::Round($sorted[[Math]::Floor(($sorted.Count - 1) / 2)], 3)
        max_ms = [Math]::Round($sorted[$sorted.Count - 1], 3)
        mean_ms = [Math]::Round((($sorted | Measure-Object -Average).Average), 3)
    }
}

$result = [ordered]@{
    schema_version = 1
    generated_at = [DateTime]::UtcNow.ToString('o')
    repository_root = $root
    runtime = $configuredPython
    iterations = $Iterations
    dataset = 'synthetic-only; no existing memory database was read or copied'
    measurements = [ordered]@{
        python_process_startup = Get-Summary $startup
        python_runtime_probe = Get-Summary $probe
        sqlite_init_command = Get-Summary $init
        store_round_trip = Get-Summary $store
        search_round_trip = Get-Summary $search
        snapshot_round_trip = Get-Summary $snapshot
    }
    interpretation = [ordered]@{
        result = 'schema-fast-path-applied-no-batch-worker'
        reason = 'Existing databases with the current schema skip repeated DDL; no equivalent multi-operation call site or bounded worker lifecycle was proven, so process resource release remains unchanged.'
        retained_boundaries = @('single-operation API semantics', 'SQLite persistence and FTS behavior', 'process resource release', 'Full validation and rollback gates')
    }
}

if ([string]::IsNullOrWhiteSpace($OutputPath)) {
    $OutputPath = Join-Path $analysisRoot 'memory-backend-benchmark.json'
}
$output = [IO.Path]::GetFullPath($OutputPath)
New-Item -ItemType Directory -Force -Path (Split-Path -Parent $output) | Out-Null
[IO.File]::WriteAllText($output, ($result | ConvertTo-Json -Depth 10), [Text.UTF8Encoding]::new($false))
$result | ConvertTo-Json -Depth 10

Remove-Item -LiteralPath $workRoot -Recurse -Force -ErrorAction SilentlyContinue
