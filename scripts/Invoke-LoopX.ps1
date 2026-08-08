[CmdletBinding(PositionalBinding = $false)]
param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$LoopXArguments = @()
)

$ErrorActionPreference = 'Stop'
$repositoryRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).Path
$runtimeRepositoryRoot = if ($env:CODEX_VALIDATION_RUNTIME_ROOT) { (Resolve-Path -LiteralPath $env:CODEX_VALIDATION_RUNTIME_ROOT).Path } else { $repositoryRoot }
$productRoot = Join-Path $runtimeRepositoryRoot '.runtime\software\loopx'
$manifestPath = Join-Path $productRoot 'current.json'

if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) {
    throw "LoopX is not installed. Run scripts\Install-LoopX.ps1 with a reviewed source checkout."
}

$manifest = Get-Content -LiteralPath $manifestPath -Raw -Encoding UTF8 | ConvertFrom-Json
$releaseRoot = [string]$manifest.release_root
if (-not $releaseRoot -or -not (Test-Path -LiteralPath $releaseRoot -PathType Container)) {
    throw "LoopX installation record points to a missing release root: $releaseRoot"
}
if (-not (Test-Path -LiteralPath (Join-Path $releaseRoot 'loopx') -PathType Container)) {
    throw "LoopX release is incomplete: $releaseRoot"
}

$pythonCandidates = [System.Collections.Generic.List[string]]::new()
if ($env:LOOPX_PYTHON) { $pythonCandidates.Add($env:LOOPX_PYTHON) }
$bundledPython = Join-Path $env:USERPROFILE '.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe'
if (Test-Path -LiteralPath $bundledPython -PathType Leaf) { $pythonCandidates.Add($bundledPython) }
$systemPython = Get-Command python.exe -ErrorAction SilentlyContinue
if ($systemPython) { $pythonCandidates.Add($systemPython.Source) }

$python = $null
foreach ($candidate in @($pythonCandidates | Select-Object -Unique)) {
    try {
        $versionText = (& $candidate -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}.{sys.version_info.micro}')").Trim()
        if ($LASTEXITCODE -eq 0 -and [version]$versionText -ge [version]'3.11') {
            $python = $candidate
            break
        }
    } catch { }
}
if (-not $python) {
    throw 'LoopX requires Python 3.11 or newer; no supported Python runtime was found.'
}

$oldPythonPath = $env:PYTHONPATH
$env:PYTHONPATH = if ($oldPythonPath) { "$releaseRoot;$oldPythonPath" } else { $releaseRoot }
$env:PYTHONUTF8 = '1'
$env:LOOPX_RELEASE_ROOT = $releaseRoot
# Keep command discovery self-contained for the reviewed release. This is a
# process-local PATH overlay; it does not install LoopX or modify the user's
# persistent PATH. Doctor and release-candidate probes use command discovery
# to prove that the active package and entrypoint are the same release.
$oldPath = $env:PATH
$releaseScripts = Join-Path $releaseRoot 'scripts'
$projectScripts = Join-Path $repositoryRoot 'scripts'
$pathEntries = @($releaseScripts, $projectScripts)
if ($oldPath) { $pathEntries += $oldPath }
$env:PATH = ($pathEntries -join ';')
$entrypoint = 'import sys; from loopx.entrypoint import main; raise SystemExit(main(sys.argv[1:]))'
$effectiveArguments = @($LoopXArguments)
$hasRegistry = @($LoopXArguments | Where-Object { $_ -eq '--registry' -or $_ -like '--registry=*' }).Count -gt 0
$hasRuntimeRoot = @($LoopXArguments | Where-Object { $_ -eq '--runtime-root' -or $_ -like '--runtime-root=*' }).Count -gt 0
$currentDirectory = (Get-Location).Path
$rootPrefix = $repositoryRoot.TrimEnd('\') + '\'
$isArchitectureContext = $currentDirectory.Equals($repositoryRoot, [StringComparison]::OrdinalIgnoreCase) -or $currentDirectory.StartsWith($rootPrefix, [StringComparison]::OrdinalIgnoreCase)
if ($isArchitectureContext -and (-not $hasRegistry -or -not $hasRuntimeRoot)) {
    $defaultRuntimeRoot = Join-Path $repositoryRoot '.runtime\loopx-trajectory'
    $defaultRegistryPath = Join-Path $defaultRuntimeRoot 'registry.json'
    $prefixArguments = @()
    if (-not $hasRegistry) { $prefixArguments += @('--registry', $defaultRegistryPath) }
    if (-not $hasRuntimeRoot) { $prefixArguments += @('--runtime-root', $defaultRuntimeRoot) }
    $effectiveArguments = @($prefixArguments + $effectiveArguments)
}
& $python -c $entrypoint @effectiveArguments
exit $LASTEXITCODE
