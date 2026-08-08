[CmdletBinding()]
# Information unit: Agent Skill Evolution Optimization.
# Evidence output is consumed by the owner-internal skill-evolution gate.
param(
    [string]$RepositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path,
    [string]$BookRoot = '',
    [string]$OutputPath = '',
    [string]$PythonPath = ''
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath $RepositoryRoot).Path
if ([string]::IsNullOrWhiteSpace($BookRoot)) {
    $BookRoot = Join-Path $root 'book'
}
if ([string]::IsNullOrWhiteSpace($OutputPath)) {
    $OutputPath = Join-Path $root '.runtime\evidence\experience-book-shelf-learning.json'
}
if ([string]::IsNullOrWhiteSpace($PythonPath)) {
    $configured = Join-Path $root '.codex\project\validation-runtime.json'
    if (Test-Path -LiteralPath $configured -PathType Leaf) {
        try { $PythonPath = [string]((Get-Content -LiteralPath $configured -Raw -Encoding UTF8 | ConvertFrom-Json).python_path) } catch { $PythonPath = '' }
    }
}
if ([string]::IsNullOrWhiteSpace($PythonPath)) { $PythonPath = 'python' }

$script = Join-Path $PSScriptRoot 'Invoke-ExperienceBookShelfLearning.py'
if (-not (Test-Path -LiteralPath $script -PathType Leaf)) { throw "Book shelf learning implementation is missing: $script" }
& $PythonPath $script --book-root $BookRoot --output $OutputPath
if ($LASTEXITCODE -ne 0) { throw 'Experience book shelf learning failed.' }
