[CmdletBinding()]
param(
    [string]$Root = $(Join-Path (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path 'knowledge-vault'),
    [switch]$Apply,
    [string]$AllowedImageRoot,
    [string]$CredentialPath = $(Join-Path $HOME '.codex\.sandbox-secrets\bilibili-image-bed.dpapi.json'),
    [string]$StatePath = $(Join-Path $HOME '.codex\.sandbox-secrets\bilibili-image-bed.state.json')
)

$ErrorActionPreference = 'Stop'
$python = if ($env:CODEX_PYTHON) { $env:CODEX_PYTHON } else { 'python' }
$script = Join-Path $PSScriptRoot 'migrate_markdown_images.py'
$arguments = @($script, '--root', $Root)
if ($AllowedImageRoot) { $arguments += @('--allowed-image-root', $AllowedImageRoot) }
if (-not $Apply) {
    & $python @arguments
    if ($LASTEXITCODE -ne 0) { throw "Image migration preview failed with exit code $LASTEXITCODE" }
    return
}
if (-not (Test-Path -LiteralPath $CredentialPath)) {
    throw "Bilibili credentials are not configured. Run configure_bilibili_credentials.ps1 first."
}
if (-not (Test-Path -LiteralPath $StatePath)) { throw 'Bilibili credential state is missing.' }
$credentialState = Get-Content -LiteralPath $StatePath -Raw -Encoding UTF8 | ConvertFrom-Json
if (-not $credentialState.rotation_confirmed) {
    throw 'Bilibili credentials have not been confirmed as refreshed after exposure. Rerun configure_bilibili_credentials.ps1.'
}
$record = Get-Content -LiteralPath $CredentialPath -Raw -Encoding UTF8 | ConvertFrom-Json
$secureJct = ConvertTo-SecureString $record.bili_jct_dpapi
$secureSessdata = ConvertTo-SecureString $record.sessdata_dpapi
$jctPointer = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureJct)
$sessdataPointer = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureSessdata)
try {
    $plainJct = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($jctPointer)
    $plainSessdata = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($sessdataPointer)
    $env:BILIBILI_IMAGE_COOKIE = "bili_jct=$plainJct; SESSDATA=$plainSessdata"
    & $python @arguments --apply --delete-local
    if ($LASTEXITCODE -ne 0) {
        throw "Image migration failed. If Bilibili rejected authentication, reacquire bili_jct and SESSDATA in Chrome and rerun configure_bilibili_credentials.ps1."
    }
} finally {
    Remove-Item Env:BILIBILI_IMAGE_COOKIE -ErrorAction SilentlyContinue
    $plainJct = $null
    $plainSessdata = $null
    [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($jctPointer)
    [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($sessdataPointer)
}
& (Join-Path $PSScriptRoot 'cleanup_quarantine.ps1')
