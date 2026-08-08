[CmdletBinding()]
param(
    [string]$CredentialPath = $(Join-Path $HOME '.codex\.sandbox-secrets\bilibili-image-bed.dpapi.json'),
    [string]$StatePath = $(Join-Path $HOME '.codex\.sandbox-secrets\bilibili-image-bed.state.json')
)

$ErrorActionPreference = 'Stop'
$rotationConfirmation = Read-Host 'Type YES only if these values were refreshed after the chat exposure'
if ($rotationConfirmation -cne 'YES') { throw 'Refresh the Bilibili session before storing credentials.' }
$biliJct = Read-Host 'Paste the refreshed bili_jct value' -AsSecureString
$sessdata = Read-Host 'Paste the refreshed SESSDATA value' -AsSecureString
if ($biliJct.Length -eq 0 -or $sessdata.Length -eq 0) { throw 'Both values are required.' }
$directory = Split-Path -Parent $CredentialPath
New-Item -ItemType Directory -Force -Path $directory | Out-Null
$record = [ordered]@{
    schema_version = 1
    bili_jct_dpapi = ($biliJct | ConvertFrom-SecureString)
    sessdata_dpapi = ($sessdata | ConvertFrom-SecureString)
}
$record | ConvertTo-Json | Set-Content -LiteralPath $CredentialPath -Encoding UTF8
$state = [ordered]@{
    schema_version = 1
    chrome_login_verified = $true
    dpapi_credentials_configured = $true
    background_migration_ready = $true
    trigger_mode = 'on-demand'
    periodic_scan = $false
    rotation_confirmed = $true
    configured_at = [DateTimeOffset]::UtcNow.ToString('o')
}
$state | ConvertTo-Json | Set-Content -LiteralPath $StatePath -Encoding UTF8
Write-Host "Stored DPAPI-encrypted Bilibili credentials at $CredentialPath"
