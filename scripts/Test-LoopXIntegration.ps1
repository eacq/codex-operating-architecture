[CmdletBinding(PositionalBinding = $false)]
param(
    [string]$RepositoryRoot = 'F:\codex'
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath $RepositoryRoot).Path
$manifestPath = Join-Path $root '.runtime\software\loopx\current.json'
$entrypoint = Join-Path $root 'scripts\loopx.cmd'
if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) { throw 'LoopX current install manifest is missing.' }
if (-not (Test-Path -LiteralPath $entrypoint -PathType Leaf)) { throw 'Windows LoopX entrypoint is missing.' }
$manifest = Get-Content -LiteralPath $manifestPath -Raw -Encoding UTF8 | ConvertFrom-Json
$releaseRoot = [string]$manifest.release_root
$releaseEntrypoint = Join-Path $releaseRoot 'scripts\loopx.cmd'
if (-not (Test-Path -LiteralPath $releaseEntrypoint -PathType Leaf)) { throw 'LoopX release Windows entrypoint is missing.' }

$oldPath = $env:PATH
$env:PATH = "$(Split-Path -Parent $releaseEntrypoint);$(Join-Path $root 'scripts');$oldPath"
$version = (& $entrypoint --version).Trim()
if ($LASTEXITCODE -ne 0 -or $version -notmatch '^loopx\s+') { throw "LoopX version check failed: $version" }
$doctorRaw = (& $releaseEntrypoint --format json doctor --deep | Out-String).Trim()
$doctor = $doctorRaw | ConvertFrom-Json
if (-not $doctor.ok) { throw 'LoopX deep doctor failed after Windows installation.' }

$fixture = (& (Join-Path $root 'scripts\Resolve-CodexRunRoot.ps1') -ArchitectureRoot $root -Kind work -ChildPath 'loopx-integration-fixture' -Create).Trim()
$runtime = (& (Join-Path $root 'scripts\Resolve-CodexRunRoot.ps1') -ArchitectureRoot $root -Kind work -ChildPath 'loopx-integration-runtime' -Create).Trim()
$goalRaw = (& $entrypoint --runtime-root $runtime --format json start-goal --guided --project $fixture --goal-text 'Validate the installed Windows LoopX control-plane adapter.' --host-surface shell | Out-String).Trim()
$goal = $goalRaw | ConvertFrom-Json
$connection = $goal.project_connection.connection_state
if (-not $connection) { throw 'LoopX guided start did not return a project connection state.' }

[pscustomobject]@{
    status = 'passed'
    version = $version
    release_id = $manifest.release_id
    doctor_ok = [bool]$doctor.ok
    doctor_mode = $doctor.mode
    guided_connection_state = $connection
    fixture = $fixture
    runtime = $runtime
} | ConvertTo-Json -Depth 8
