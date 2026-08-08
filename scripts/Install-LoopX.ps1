[CmdletBinding(PositionalBinding = $false)]
param(
    [Parameter(Mandatory = $true)]
    [string]$SourceRoot,
    [string]$RepositoryRoot = 'F:\codex',
    [string]$PythonPath = '',
    [switch]$Apply
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath $RepositoryRoot).Path
$source = (Resolve-Path -LiteralPath $SourceRoot).Path
$pyprojectPath = Join-Path $source 'pyproject.toml'
if (-not (Test-Path -LiteralPath $pyprojectPath -PathType Leaf)) { throw "LoopX source is missing pyproject.toml: $source" }

$pyproject = Get-Content -LiteralPath $pyprojectPath -Raw -Encoding UTF8
$versionMatch = [regex]::Match($pyproject, '(?m)^version\s*=\s*["'']([^"'']+)["'']')
if (-not $versionMatch.Success) { throw 'LoopX source version could not be read from pyproject.toml.' }
$version = $versionMatch.Groups[1].Value
$commit = (& git -C $source rev-parse HEAD).Trim()
if ($LASTEXITCODE -ne 0 -or $commit -notmatch '^[0-9a-f]{40}$') { throw 'LoopX source must be a Git checkout with a resolved commit.' }
$shortCommit = $commit.Substring(0, 8)
$releaseId = "$version-$shortCommit"
$releaseRoot = (& (Join-Path $root 'scripts\Resolve-CodexRunRoot.ps1') -ArchitectureRoot $root -Kind software -ChildPath "loopx\releases\$releaseId" -Create).Trim()
$productRoot = (& (Join-Path $root 'scripts\Resolve-CodexRunRoot.ps1') -ArchitectureRoot $root -Kind software -ChildPath 'loopx' -Create).Trim()
$currentManifestPath = Join-Path $productRoot 'current.json'
$recordRoot = (& (Join-Path $root 'scripts\Resolve-CodexRunRoot.ps1') -ArchitectureRoot $root -Kind installers -ChildPath 'loopx\_records' -Create).Trim()

$preview = [ordered]@{
    product = 'loopx'
    version = $version
    release_id = $releaseId
    source_root = $source
    source_commit = $commit
    install_root = $releaseRoot
    current_manifest = $currentManifestPath
    record_root = $recordRoot
    apply = [bool]$Apply
}
if (-not $Apply) {
    $preview | ConvertTo-Json -Depth 5
    return
}

function Resolve-SupportedPython([string]$Requested) {
    $candidates = [System.Collections.Generic.List[string]]::new()
    if ($Requested) { $candidates.Add($Requested) }
    $bundled = Join-Path $env:USERPROFILE '.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe'
    if (Test-Path -LiteralPath $bundled -PathType Leaf) { $candidates.Add($bundled) }
    $system = Get-Command python.exe -ErrorAction SilentlyContinue
    if ($system) { $candidates.Add($system.Source) }
    foreach ($candidate in @($candidates | Select-Object -Unique)) {
        try {
            $versionText = (& $candidate -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}.{sys.version_info.micro}')").Trim()
            if ($LASTEXITCODE -eq 0 -and [version]$versionText -ge [version]'3.11') { return $candidate }
        } catch { }
    }
    throw 'LoopX requires Python 3.11 or newer; no supported Python runtime was found.'
}

$python = Resolve-SupportedPython $PythonPath
$packageReady = Test-Path -LiteralPath (Join-Path $releaseRoot 'loopx') -PathType Container
$distInfoReady = @(Get-ChildItem -LiteralPath $releaseRoot -Directory -Filter 'loopx-*.dist-info' -ErrorAction SilentlyContinue).Count -gt 0
if (-not ($packageReady -and $distInfoReady)) {
    & $python -m pip install --disable-pip-version-check --no-cache-dir --no-deps --no-build-isolation --target $releaseRoot $source
    if ($LASTEXITCODE -ne 0) { throw 'LoopX package installation failed.' }
}

$releaseScripts = Join-Path $releaseRoot 'scripts'
New-Item -ItemType Directory -Force -Path $releaseScripts | Out-Null
Copy-Item -LiteralPath (Join-Path $source 'scripts\loopx') -Destination (Join-Path $releaseScripts 'loopx') -Force
$windowsWrapper = "@echo off`r`nsetlocal`r`nset `"PYTHONPATH=$releaseRoot`"`r`npowershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File `"$root\scripts\Invoke-LoopX.ps1`" %*`r`nexit /b %errorlevel%`r`n"
[IO.File]::WriteAllText((Join-Path $releaseScripts 'loopx.cmd'), $windowsWrapper, [Text.UTF8Encoding]::new($false))

$sourceUrl = (& git -C $source config --get remote.origin.url 2>$null).Trim()
$installedAt = [DateTime]::UtcNow.ToString('o')
$manifest = [ordered]@{
    schema_version = 'loopx_windows_install_v1'
    product = 'loopx'
    version = $version
    release_id = $releaseId
    release_root = $releaseRoot
    source = [ordered]@{
        repository = if ($sourceUrl) { $sourceUrl } else { 'https://github.com/huangruiteng/loopx.git' }
        commit = $commit
        source_root = $source
    }
    runtime = [ordered]@{ python = $python; python_version = (& $python --version).Trim() }
    entrypoint = (Join-Path $releaseScripts 'loopx.cmd')
    installed_at = $installedAt
}
$json = ($manifest | ConvertTo-Json -Depth 8) + [Environment]::NewLine
[IO.File]::WriteAllText((Join-Path $releaseRoot 'loopx-install.json'), $json, [Text.UTF8Encoding]::new($false))
[IO.File]::WriteAllText($currentManifestPath, $json, [Text.UTF8Encoding]::new($false))
$recordPath = Join-Path $recordRoot ("$releaseId.json")
[IO.File]::WriteAllText($recordPath, $json, [Text.UTF8Encoding]::new($false))

[pscustomobject]@{
    status = 'installed'
    product = 'loopx'
    version = $version
    release_id = $releaseId
    source_commit = $commit
    install_root = $releaseRoot
    entrypoint = (Join-Path $releaseScripts 'loopx.cmd')
    current_manifest = $currentManifestPath
    record = $recordPath
    python = $python
    python_version = (& $python --version).Trim()
} | ConvertTo-Json -Depth 8
