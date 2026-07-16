param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('yourapisource', 'chatgpt')]
    [string]$Target,

    # Kept for compatibility with older launchers. This script no longer starts
    # codex.exe because Windows elevation/app shims can reject it with Access denied.
    [switch]$Reauthenticate
)

$ErrorActionPreference = 'Stop'

try {
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
} catch {
}

$codexHome = Join-Path $env:USERPROFILE '.codex'
$configPath = Join-Path $codexHome 'config.toml'
$authPath = Join-Path $codexHome 'auth.json'
$backupDir = Join-Path $codexHome 'backups'
$profileDir = Join-Path $codexHome 'provider-profiles'
$chatGptAuthProfilePath = Join-Path $profileDir 'chatgpt-auth.json'
$timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$backupPath = Join-Path $backupDir "config.toml.$Target-switch.$timestamp.bak"
$authBackupPath = Join-Path $backupDir "auth.json.$Target-switch.$timestamp.bak"

if (-not (Test-Path -LiteralPath $configPath)) {
    throw "Missing Codex config: $configPath"
}

function Get-EnvAnyScope {
    param([Parameter(Mandatory = $true)][string]$Name)
    $value = [Environment]::GetEnvironmentVariable($Name, 'Process')
    if (-not $value) { $value = [Environment]::GetEnvironmentVariable($Name, 'User') }
    if (-not $value) { $value = [Environment]::GetEnvironmentVariable($Name, 'Machine') }
    return $value
}

function Get-YourApiSourceApiKey {
    # A user-level replacement must win over an inherited stale key in the
    # desktop process or Explorer environment block.
    $value = [Environment]::GetEnvironmentVariable('YOUR_API_SOURCE_API_KEY', 'User')
    if (-not $value) { $value = [Environment]::GetEnvironmentVariable('YOUR_API_SOURCE_API_KEY', 'Process') }
    if (-not $value) { $value = [Environment]::GetEnvironmentVariable('YOUR_API_SOURCE_API_KEY', 'Machine') }
    return $value
}

function Get-YourApiSourceBaseUrl {
    $value = Get-EnvAnyScope 'YOUR_API_SOURCE_BASE_URL'
    if (-not $value) { return $null }
    return $value.Trim().TrimEnd('/')
}

function Set-TopLevelTomlValue {
    param(
        [Parameter(Mandatory = $true)][string]$Text,
        [Parameter(Mandatory = $true)][string]$Key,
        [Parameter(Mandatory = $true)][string]$Value
    )
    $line = "$Key = `"$Value`""
    $pattern = "(?m)^$([regex]::Escape($Key))\s*=.*$"
    if ($Text -match $pattern) {
        return [regex]::Replace($Text, $pattern, $line, 1)
    }
    return "$line`r`n$Text"
}

function Set-TomlBlock {
    param(
        [Parameter(Mandatory = $true)][string]$Text,
        [Parameter(Mandatory = $true)][string]$Header,
        [Parameter(Mandatory = $true)][string]$Block
    )
    $escaped = [regex]::Escape($Header)
    $pattern = "(?ms)^$escaped\s*\r?\n.*?(?=^\[|\z)"
    if ($Text -match $pattern) {
        return [regex]::Replace($Text, $pattern, $Block.TrimEnd() + "`r`n`r`n", 1)
    }
    return $Text.TrimEnd() + "`r`n`r`n" + $Block.TrimEnd() + "`r`n"
}

function Remove-TomlBlock {
    param(
        [Parameter(Mandatory = $true)][string]$Text,
        [Parameter(Mandatory = $true)][string]$Header
    )
    $escaped = [regex]::Escape($Header)
    $pattern = "(?ms)^$escaped\s*\r?\n.*?(?=^\[|\z)"
    return [regex]::Replace($Text, $pattern, '')
}

function Get-AuthMode {
    if (-not (Test-Path -LiteralPath $authPath)) { return 'missing' }
    try {
        $auth = Get-Content -LiteralPath $authPath -Raw -Encoding UTF8 | ConvertFrom-Json
        if ($auth.PSObject.Properties.Name -contains 'auth_mode') {
            return [string]$auth.auth_mode
        }
        return 'unknown'
    } catch {
        return 'unreadable'
    }
}

function Test-ChatGptAuthentication {
    param([Parameter(Mandatory = $true)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) { return $false }
    try {
        $auth = Get-Content -LiteralPath $Path -Raw -Encoding UTF8 | ConvertFrom-Json
        if ([string]$auth.auth_mode -ne 'chatgpt') { return $false }
        $tokenFields = @('id_token', 'access_token', 'refresh_token')
        return @($tokenFields | Where-Object {
            $auth.tokens -and $auth.tokens.PSObject.Properties.Name -contains $_ -and -not [string]::IsNullOrWhiteSpace([string]$auth.tokens.$_)
        }).Count -gt 0
    } catch {
        return $false
    }
}

function Save-ChatGptAuthenticationProfile {
    # auth.json is deliberately the active credential file. Keep a separate
    # local profile only while YourApiSource temporarily owns that active file.
    if ((Get-AuthMode) -ne 'chatgpt' -or -not (Test-ChatGptAuthentication -Path $authPath)) {
        return $false
    }

    New-Item -ItemType Directory -Force -Path $profileDir | Out-Null
    $temporaryPath = "$chatGptAuthProfilePath.tmp"
    Copy-Item -LiteralPath $authPath -Destination $temporaryPath -Force
    Move-Item -LiteralPath $temporaryPath -Destination $chatGptAuthProfilePath -Force
    return $true
}

function Restore-ChatGptAuthenticationProfile {
    if (-not (Test-ChatGptAuthentication -Path $chatGptAuthProfilePath)) {
        return $false
    }

    $temporaryPath = "$authPath.restore.tmp"
    Copy-Item -LiteralPath $chatGptAuthProfilePath -Destination $temporaryPath -Force
    Move-Item -LiteralPath $temporaryPath -Destination $authPath -Force
    if (-not (Test-ChatGptAuthentication -Path $authPath)) {
        throw 'The saved ChatGPT authentication profile could not be restored safely.'
    }
    return $true
}

function Save-CodexStateBackups {
    New-Item -ItemType Directory -Force -Path $backupDir | Out-Null
    Copy-Item -LiteralPath $configPath -Destination $backupPath -Force
    if (Test-Path -LiteralPath $authPath) {
        Copy-Item -LiteralPath $authPath -Destination $authBackupPath -Force
    }
    return [PSCustomObject]@{
        Config = $backupPath
        Auth = if (Test-Path -LiteralPath $authBackupPath) { $authBackupPath } else { $null }
    }
}

function Set-YourApiSourceApiKeyAuthentication {
    param([Parameter(Mandatory = $true)][string]$ApiKey)

    # Codex API-key login uses this compact shape. Do not merge ChatGPT token
    # fields into it: they belong to a different active authentication mode.
    $auth = [ordered]@{
        auth_mode = 'apikey'
        OPENAI_API_KEY = $ApiKey
    } | ConvertTo-Json
    Set-Content -LiteralPath $authPath -Value $auth -Encoding UTF8

    if ((Get-AuthMode) -ne 'apikey') {
        throw 'Codex API-key authentication was not written successfully.'
    }
}

function Test-YourApiSourceCredential {
    param(
        [Parameter(Mandatory = $true)][string]$ApiKey,
        [Parameter(Mandatory = $true)][string]$Model,
        [Parameter(Mandatory = $true)][string]$BaseUrl
    )

    # A single minimal request prevents a stale environment key from making Codex
    # appear switched while every model request subsequently fails with 401.
    $body = @{
        model = $Model
        messages = @(@{ role = 'user'; content = 'Reply only with OK.' })
    } | ConvertTo-Json -Depth 4 -Compress
    try {
        $response = Invoke-WebRequest -UseBasicParsing -Method Post `
            -Uri "$($BaseUrl.TrimEnd('/'))/chat/completions" `
            -Headers @{ Authorization = "Bearer $ApiKey"; 'Content-Type' = 'application/json' } `
            -Body $body -TimeoutSec 30
    } catch {
        $statusCode = $null
        if ($_.Exception.Response) {
            $statusCode = [int]$_.Exception.Response.StatusCode
        }
        if ($statusCode -in 401, 403) {
            throw "YourApiSource authentication was rejected (HTTP $statusCode). The existing Codex provider configuration was left unchanged."
        }
        if ($statusCode) {
            throw "YourApiSource preflight failed (HTTP $statusCode). The existing Codex provider configuration was left unchanged."
        }
        throw 'YourApiSource preflight could not reach the service. The existing Codex provider configuration was left unchanged.'
    }

    if ($response.StatusCode -lt 200 -or $response.StatusCode -ge 300) {
        throw "YourApiSource preflight returned HTTP $($response.StatusCode). The existing Codex provider configuration was left unchanged."
    }
}

function Invoke-SidebarRepairAfterSwitch {
    $repairScript = Join-Path $PSScriptRoot 'Repair-Codex-Sidebar-State.ps1'
    if (-not (Test-Path -LiteralPath $repairScript)) {
        Write-Warning 'Provider switch completed, but the sidebar repair tool is missing.'
        return
    }

    try {
        $firstResult = & $repairScript -Apply
        Start-Sleep -Milliseconds 600
        $secondResult = & $repairScript -Apply
        $checkResult = & $repairScript
        Write-Host "Sidebar repair pass 1: $firstResult"
        Write-Host "Sidebar repair pass 2: $secondResult"
        Write-Host "Sidebar repair check: $checkResult"
    } catch {
        # A provider switch must not be rolled back after its active auth has
        # changed. Surface UI-state trouble explicitly for a separate repair.
        Write-Warning "Provider switch completed, but automatic sidebar repair failed: $($_.Exception.Message)"
    }
}

function Invoke-ConversationCatalogRefreshAfterSwitch {
    $catalogScript = Join-Path $PSScriptRoot '..\skills\codex-conversation-continuity\scripts\build_conversation_catalog.py'
    if (-not (Test-Path -LiteralPath $catalogScript)) {
        Write-Warning 'Provider switch completed, but the conversation continuity catalog is unavailable.'
        return
    }

    $python = Get-Command py -ErrorAction SilentlyContinue
    if (-not $python) { $python = Get-Command python -ErrorAction SilentlyContinue }
    if (-not $python) {
        Write-Warning 'Provider switch completed, but Python is unavailable for the conversation catalog refresh.'
        return
    }

    try {
        $result = & $python.Source $catalogScript --codex-home $codexHome --refresh
        Write-Host "Conversation catalog: $result"
    } catch {
        # Local history discovery must never roll back a provider/auth change.
        Write-Warning "Provider switch completed, but conversation catalog refresh failed: $($_.Exception.Message)"
    }
}

$content = Get-Content -LiteralPath $configPath -Raw -Encoding UTF8
Invoke-ConversationCatalogRefreshAfterSwitch

if ($Target -eq 'yourapisource') {
    $yourapisourceKey = Get-YourApiSourceApiKey
    if (-not $yourapisourceKey) {
        throw 'YOUR_API_SOURCE_API_KEY is missing. The existing Codex provider configuration was left unchanged.'
    }
    $yourapisourceBaseUrl = Get-YourApiSourceBaseUrl
    if (-not $yourapisourceBaseUrl) {
        throw 'YOUR_API_SOURCE_BASE_URL is missing. The existing Codex provider configuration was left unchanged.'
    }
    $yourapisourceModel = Get-EnvAnyScope 'YOUR_API_SOURCE_MODEL'
    if (-not $yourapisourceModel) {
        throw 'YOUR_API_SOURCE_MODEL is missing. The existing Codex provider configuration was left unchanged.'
    }
    Test-YourApiSourceCredential -ApiKey $yourapisourceKey -Model $yourapisourceModel -BaseUrl $yourapisourceBaseUrl

    $content = Set-TopLevelTomlValue -Text $content -Key 'model_provider' -Value 'openai-chat-completions'
    $content = Set-TopLevelTomlValue -Text $content -Key 'model' -Value $yourapisourceModel
    $providerBlock = @"
[model_providers.openai-chat-completions]
name = "YourApiSource"
wire_api = "responses"
base_url = "$yourapisourceBaseUrl"
env_key = "YOUR_API_SOURCE_API_KEY"
"@
    $content = Set-TomlBlock -Text $content -Header '[model_providers.openai-chat-completions]' -Block $providerBlock

    $savedBackups = Save-CodexStateBackups
    $savedChatGptProfile = Save-ChatGptAuthenticationProfile
    Set-Content -LiteralPath $configPath -Value $content -Encoding UTF8
    Set-YourApiSourceApiKeyAuthentication -ApiKey $yourapisourceKey
    Invoke-ConversationCatalogRefreshAfterSwitch
    Invoke-SidebarRepairAfterSwitch
    Write-Host ''
    Write-Host 'Codex provider and active authentication switched to YourApiSource API-key mode.'
    Write-Host "Config backup: $($savedBackups.Config)"
    if ($savedBackups.Auth) { Write-Host "Auth backup: $($savedBackups.Auth)" }
    if ($savedChatGptProfile) { Write-Host 'Saved ChatGPT login profile for automatic restoration.' }
    Write-Host "Model: $yourapisourceModel"
    Write-Host 'Restart Codex or open a new task for the provider change to take effect.'
    return
}

$savedBackups = Save-CodexStateBackups
$content = Set-TopLevelTomlValue -Text $content -Key 'model_provider' -Value 'openai'
$content = Set-TopLevelTomlValue -Text $content -Key 'model' -Value 'gpt-5.6-terra'
$yourapisourceBaseUrl = Get-YourApiSourceBaseUrl
if (-not $yourapisourceBaseUrl) { $yourapisourceBaseUrl = 'https://example.invalid/v1' }
$preservedProviderBlock = @"
[model_providers.openai-chat-completions]
name = "YourApiSource"
wire_api = "responses"
base_url = "$yourapisourceBaseUrl"
env_key = "YOUR_API_SOURCE_API_KEY"
"@
$content = Set-TomlBlock -Text $content -Header '[model_providers.openai-chat-completions]' -Block $preservedProviderBlock
# Keep the YourApiSource provider definition while ChatGPT is active. Existing local
# tasks persist their original provider name; removing this block makes those
# tasks fail to load before Codex can select the current active provider.
# The top-level model_provider above still ensures newly created tasks use the
# current ChatGPT login mode.

Set-Content -LiteralPath $configPath -Value $content -Encoding UTF8
$restoredChatGptProfile = Restore-ChatGptAuthenticationProfile
Invoke-ConversationCatalogRefreshAfterSwitch
Invoke-SidebarRepairAfterSwitch
$authMode = Get-AuthMode
Write-Host ''
Write-Host 'Codex provider switched to OpenAI / ChatGPT mode.'
Write-Host "Config backup: $($savedBackups.Config)"
if ($savedBackups.Auth) { Write-Host "Auth backup: $($savedBackups.Auth)" }
if ($restoredChatGptProfile) { Write-Host 'Restored the saved ChatGPT login profile; no browser login is required.' }
Write-Host "Current auth mode: $authMode"
if ($authMode -ne 'chatgpt') {
    Write-Host ''
    Write-Host 'Configuration is switched, but ChatGPT subscription quota requires ChatGPT sign-in.'
    Write-Host 'Open Codex/ChatGPT and sign in with ChatGPT, then restart Codex or open a new task.'
} else {
    Write-Host 'ChatGPT authentication appears to be active.'
}
Write-Host 'Restart Codex or open a new task for the provider change to take effect.'
