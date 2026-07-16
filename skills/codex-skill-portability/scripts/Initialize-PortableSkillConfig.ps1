[CmdletBinding()]
param(
    [string]$ConfigRoot = (Join-Path $HOME '.codex\private-skill-config'),
    [switch]$Force,
    [switch]$NonInteractive
)

$ErrorActionPreference = 'Stop'
$configPath = Join-Path $ConfigRoot 'portable-skill.json'

if ((Test-Path -LiteralPath $configPath) -and -not $Force) {
    Write-Output "Private configuration already exists: $configPath"
    Write-Output 'Use -Force only to deliberately replace local choices.'
    exit 0
}

function Read-Choice([string]$Prompt, [string]$Default) {
    if ($NonInteractive) { return $Default }
    $value = Read-Host "$Prompt [$Default]"
    if ([string]::IsNullOrWhiteSpace($value)) { return $Default }
    return $value.Trim()
}

$providerName = Read-Choice 'Provider label (or skip)' 'skip'
$authPreference = Read-Choice 'Authentication: api-key, chatgpt-login, both, or skip' 'both'
if ($authPreference -notin @('api-key', 'chatgpt-login', 'both', 'skip')) {
    throw 'Authentication choice must be api-key, chatgpt-login, both, or skip.'
}
$baseUrl = if ($providerName -eq 'skip') { '' } else { Read-Choice 'OpenAI-compatible base URL (blank to configure later)' '' }
$keyVariable = if ($authPreference -in @('api-key', 'both')) { Read-Choice 'Environment-variable name for an API key (never enter the key here)' 'OPENAI_API_KEY' } else { '' }
$model = if ($providerName -eq 'skip') { '' } else { Read-Choice 'Preferred model (blank to configure later)' '' }
$useCustomPaths = Read-Choice 'Configure custom software archive/install roots? yes or no' 'no'
$archiveRoot = ''
$installRoot = ''
$tools = @()
if ($useCustomPaths -eq 'yes') {
    $archiveRoot = Read-Choice 'Installer archive root' ''
    $installRoot = Read-Choice 'Software install root' ''
    $toolInput = Read-Choice 'Optional tools, comma-separated' ''
    $tools = @($toolInput -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ })
}

$profile = [ordered]@{
    schema_version = 1
    provider = [ordered]@{
        display_name = if ($providerName -eq 'skip') { '' } else { $providerName }
        base_url = $baseUrl
        auth_preference = $authPreference
        api_key_environment_variable = $keyVariable
        preferred_model = $model
    }
    software = [ordered]@{
        archive_root = $archiveRoot
        install_root = $installRoot
        selected_tools = $tools
    }
    notes = 'Local-only choices. No secrets, tokens, cookies, or account data are stored here.'
}

New-Item -ItemType Directory -Force -Path $ConfigRoot | Out-Null
$profile | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $configPath -Encoding UTF8
Write-Output "Private configuration created: $configPath"
Write-Output 'Configure secrets separately through a secure store or environment variable; no software was installed.'
