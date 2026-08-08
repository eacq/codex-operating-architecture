[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory)]
    [string]$PackageId,
    [Parameter(Mandatory)]
    [string]$ProductName,
    [string]$Version,
    [string]$Source = 'winget',
    [switch]$Execute
)

$ErrorActionPreference = 'Stop'
$architectureRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
$profilePath = if ($env:CODEX_PORTABLE_SKILL_PROFILE) { $env:CODEX_PORTABLE_SKILL_PROFILE } else { Join-Path $HOME '.codex\private-skill-config\portable-skill.json' }
$profile = $null
if (Test-Path -LiteralPath $profilePath) {
    $profile = Get-Content -LiteralPath $profilePath -Raw -Encoding UTF8 | ConvertFrom-Json
}
$profileArchiveRoot = if ($profile -and $profile.software -and $profile.software.archive_root) { [string]$profile.software.archive_root } else { '' }
$profileInstallRoot = if ($profile -and $profile.software -and $profile.software.install_root) { [string]$profile.software.install_root } else { '' }
$packageRoot = if ($env:SOFTWARE_ARCHIVE_ROOT) {
    $env:SOFTWARE_ARCHIVE_ROOT
} elseif ($profileArchiveRoot.Trim()) {
    $profileArchiveRoot
} else {
    & (Join-Path $architectureRoot 'scripts\Resolve-CodexRunRoot.ps1') -ArchitectureRoot $architectureRoot -Kind installers -Create
}
$installRoot = if ($env:SOFTWARE_INSTALL_ROOT) {
    $env:SOFTWARE_INSTALL_ROOT
} elseif ($profileInstallRoot.Trim()) {
    $profileInstallRoot
} else {
    & (Join-Path $architectureRoot 'scripts\Resolve-CodexRunRoot.ps1') -ArchitectureRoot $architectureRoot -Kind software -Create
}
$folderName = ($ProductName -replace '[^\p{L}\p{Nd}._-]+', '-').Trim('-', '.', '_')
if (-not $folderName) { throw 'ProductName does not contain a usable folder name.' }
$packageDir = Join-Path $packageRoot $folderName
$installDir = Join-Path $installRoot $folderName

$plan = [ordered]@{
    package_id = $PackageId
    product_name = $ProductName
    version = if ($Version) { $Version } else { 'latest' }
    source = $Source
    package_directory = $packageDir
    install_directory = $installDir
    execute = [bool]$Execute
}
$plan | ConvertTo-Json | Write-Output
if (-not $Execute) { return }

$action = "Download installer to '$packageDir' and install to '$installDir'"
if (-not $PSCmdlet.ShouldProcess($ProductName, $action)) { return }

New-Item -ItemType Directory -Force -Path $packageDir, $installDir | Out-Null
$common = @('--id', $PackageId, '--exact', '--source', $Source, '--accept-source-agreements')
$download = @('download') + $common + @('--download-directory', $packageDir, '--accept-package-agreements')
if ($Version) { $download += @('--version', $Version) }
& winget @download
if ($LASTEXITCODE -ne 0) { throw "winget download failed with exit code $LASTEXITCODE" }

$install = @('install') + $common + @('--location', $installDir, '--accept-package-agreements')
if ($Version) { $install += @('--version', $Version) }
& winget @install
if ($LASTEXITCODE -ne 0) { throw "winget install failed with exit code $LASTEXITCODE" }

$executables = @(Get-ChildItem -LiteralPath $installDir -Recurse -File -Filter '*.exe' -ErrorAction SilentlyContinue)
$verified = $executables.Count -gt 0
$record = [ordered]@{
    installed_at = [DateTimeOffset]::UtcNow.ToString('o')
    package_id = $PackageId
    product_name = $ProductName
    version_requested = if ($Version) { $Version } else { 'latest' }
    source = $Source
    package_directory = $packageDir
    install_directory = $installDir
    location_verified = $verified
    executable_count = $executables.Count
}
$recordDir = Join-Path $packageRoot '_records'
New-Item -ItemType Directory -Force -Path $recordDir | Out-Null
$recordPath = Join-Path $recordDir "$folderName.json"
$record | ConvertTo-Json | Set-Content -LiteralPath $recordPath -Encoding UTF8
if (-not $verified) {
    throw "Installation completed but no executable was found under $installDir. Treat this as a path-policy exception and inspect the actual location."
}
Write-Host "Verified installation under $installDir"
