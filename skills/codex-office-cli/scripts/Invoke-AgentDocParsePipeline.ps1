[CmdletBinding(PositionalBinding = $false)]
param(
    [Parameter(Mandatory = $true)]
    [string]$Path,
    [string[]]$Keyword = @(),
    [string]$RepositoryRoot = 'F:\codex'
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath $RepositoryRoot).Path
$runtimeConfig = Join-Path $root '.codex\project\validation-runtime.json'
$configuredPython = if (Test-Path -LiteralPath $runtimeConfig -PathType Leaf) {
    (Get-Content -LiteralPath $runtimeConfig -Raw -Encoding UTF8 | ConvertFrom-Json).python_path
} else { $null }
$candidates = @(
    $env:CODEX_PYTHON,
    $configuredPython,
    (Join-Path $root '.runtime\envs\codex-foundation\python.exe'),
    'python'
) | Where-Object { $_ } | Select-Object -Unique

$python = $null
foreach ($candidate in $candidates) {
    if ([IO.Path]::IsPathRooted($candidate) -and -not (Test-Path -LiteralPath $candidate -PathType Leaf)) { continue }
    & $candidate -c "import sys; sys.exit(0)" 2>$null
    if ($LASTEXITCODE -eq 0) {
        $python = $candidate
        break
    }
}
if (-not $python) { throw 'No usable Python runtime found for Agent document parse pipeline.' }

$script = Join-Path $PSScriptRoot 'Invoke-AgentDocParsePipeline.py'
$arguments = @($script, $Path)
foreach ($item in $Keyword) {
    $arguments += @('--keyword', $item)
}
& $python @arguments
return
