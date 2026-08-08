[CmdletBinding()]
param(
    [string]$RepositoryRoot = 'F:\codex',
    [string]$InputPath,
    [string]$ChunksPath,
    [string]$QueriesPath,
    [string]$Query,
    [ValidateSet('recursive','fixed')]
    [string]$Strategy = 'recursive',
    [int]$ChunkSize = 160,
    [int]$Overlap = 24,
    [int]$TopK = 5,
    [double]$Temperature = 1.0,
    [double]$RefusalThreshold = 0.35,
    [string]$OutputPath
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath $RepositoryRoot).Path
$scriptPath = Join-Path $root 'skills\codex-information-gathering\scripts\Invoke-AgentChunkingRetrieval.py'
if (-not (Test-Path -LiteralPath $scriptPath -PathType Leaf)) { throw "Agent chunking retrieval runner is missing: $scriptPath" }

$localRuntimeConfig = Join-Path $root '.codex\project\validation-runtime.json'
$configuredPython = if (Test-Path -LiteralPath $localRuntimeConfig -PathType Leaf) {
    (Get-Content -LiteralPath $localRuntimeConfig -Raw -Encoding UTF8 | ConvertFrom-Json).python_path
} else { $null }
$pythonCandidates = @(
    $env:CODEX_PYTHON,
    $configuredPython,
    (Join-Path $root '.runtime\envs\codex-foundation\python.exe'),
    'python'
) | Where-Object { $_ } | Select-Object -Unique

$python = $null
foreach ($candidate in $pythonCandidates) {
    if ([IO.Path]::IsPathRooted($candidate) -and -not (Test-Path -LiteralPath $candidate -PathType Leaf)) { continue }
    $previousErrorAction = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    & $candidate -c "import json" 2>$null
    $exit = $LASTEXITCODE
    $ErrorActionPreference = $previousErrorAction
    if ($exit -eq 0) { $python = $candidate; break }
}
if (-not $python) { throw 'No usable Python runtime found for Agent chunking retrieval.' }

if (-not $InputPath -and -not $ChunksPath) { throw 'InputPath or ChunksPath is required.' }
$arguments = @($scriptPath, '--strategy', $Strategy, '--chunk-size', [string]$ChunkSize, '--overlap', [string]$Overlap, '--top-k', [string]$TopK, '--temperature', [string]$Temperature, '--refusal-threshold', [string]$RefusalThreshold)
if ($InputPath) { $arguments += @('--input', (Resolve-Path -LiteralPath $InputPath).Path) }
if ($ChunksPath) { $arguments += @('--chunks', (Resolve-Path -LiteralPath $ChunksPath).Path) }
if ($QueriesPath) { $arguments += @('--queries', (Resolve-Path -LiteralPath $QueriesPath).Path) }
if ($Query) { $arguments += @('--query', $Query) }
if ($OutputPath) { $arguments += @('--output', $OutputPath) }

$env:PYTHONUTF8 = '1'
& $python @arguments
