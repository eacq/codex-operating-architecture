$ErrorActionPreference = 'Stop'

$codexHome = Join-Path $env:USERPROFILE '.codex'
$configPath = Join-Path $codexHome 'config.toml'
$authPath = Join-Path $codexHome 'auth.json'
$chatGptProfilePath = Join-Path $codexHome 'provider-profiles\chatgpt-auth.json'
$conversationCatalogPath = Join-Path $codexHome 'conversation-history\catalog.json'

if (-not (Test-Path -LiteralPath $configPath)) {
    throw "Missing Codex config: $configPath"
}

$configText = Get-Content -LiteralPath $configPath -Raw -Encoding UTF8
$providerMatch = [regex]::Match($configText, '(?m)^model_provider\s*=\s*"([^"]+)"')
$modelMatch = [regex]::Match($configText, '(?m)^model\s*=\s*"([^"]+)"')
$provider = if ($providerMatch.Success) { $providerMatch.Groups[1].Value } else { 'missing' }
$model = if ($modelMatch.Success) { $modelMatch.Groups[1].Value } else { 'missing' }
$authMode = 'missing'
$hasApiKey = $false
$authFields = @()

if (Test-Path -LiteralPath $authPath) {
    try {
        $auth = Get-Content -LiteralPath $authPath -Raw -Encoding UTF8 | ConvertFrom-Json
        $authMode = [string]$auth.auth_mode
        $hasApiKey = -not [string]::IsNullOrWhiteSpace([string]$auth.OPENAI_API_KEY)
        $authFields = @($auth.PSObject.Properties.Name | Sort-Object)
    } catch {
        $authMode = 'unreadable'
    }
}

$expectedAuth = if ($provider -eq 'openai-chat-completions') { 'apikey' } elseif ($provider -eq 'openai') { 'chatgpt' } else { 'unknown' }
$alignment = if ($expectedAuth -eq 'unknown') { 'unknown provider' } elseif ($authMode -eq $expectedAuth) { 'aligned' } else { 'MISMATCH' }

Write-Output "provider=$provider"
Write-Output "model=$model"
Write-Output "auth_mode=$authMode"
Write-Output "auth_has_openai_api_key=$hasApiKey"
Write-Output "auth_fields=$($authFields -join ',')"
Write-Output "expected_auth_mode=$expectedAuth"
Write-Output "configuration_auth_alignment=$alignment"
Write-Output "saved_chatgpt_profile_present=$(Test-Path -LiteralPath $chatGptProfilePath)"
Write-Output "conversation_catalog_present=$(Test-Path -LiteralPath $conversationCatalogPath)"
Write-Output 'Note: existing tasks retain their original provider/session context; restart Codex or create a new task after a switch.'
