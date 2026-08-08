$ErrorActionPreference = 'Stop'

$codexHome = Join-Path $env:USERPROFILE '.codex'
$authPath = Join-Path $codexHome 'auth.json'
$profileDir = Join-Path $codexHome 'provider-profiles'
$profilePath = Join-Path $profileDir 'chatgpt-auth.json'

if (-not (Test-Path -LiteralPath $authPath)) {
    throw "Missing active Codex authentication: $authPath"
}

try {
    $auth = Get-Content -LiteralPath $authPath -Raw -Encoding UTF8 | ConvertFrom-Json
} catch {
    throw 'Active Codex authentication is not valid JSON.'
}

$tokenFields = @('id_token', 'access_token', 'refresh_token')
$hasToken = @($tokenFields | Where-Object {
    $auth.tokens -and $auth.tokens.PSObject.Properties.Name -contains $_ -and -not [string]::IsNullOrWhiteSpace([string]$auth.tokens.$_)
}).Count -gt 0
if ([string]$auth.auth_mode -ne 'chatgpt' -or -not $hasToken) {
    throw 'Active authentication is not a usable ChatGPT login; no profile was created.'
}

New-Item -ItemType Directory -Force -Path $profileDir | Out-Null
$temporaryPath = "$profilePath.tmp"
Copy-Item -LiteralPath $authPath -Destination $temporaryPath -Force
Move-Item -LiteralPath $temporaryPath -Destination $profilePath -Force
Write-Output 'Saved local ChatGPT login profile for provider switching. No credential values were displayed.'
