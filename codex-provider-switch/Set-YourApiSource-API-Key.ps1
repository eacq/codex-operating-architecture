$ErrorActionPreference = 'Stop'

Write-Host 'Paste the YourApiSource API key when prompted. Input is hidden and will not be displayed.'
$secureKey = Read-Host 'YourApiSource API key' -AsSecureString
$baseUrl = Read-Host 'YourApiSource base URL, for example https://example.test/v1'
$model = Read-Host 'YourApiSource model name'
$bstr = [IntPtr]::Zero

try {
    $bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureKey)
    $apiKey = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr).Trim()
    if ($apiKey.StartsWith('Bearer ', [StringComparison]::OrdinalIgnoreCase)) {
        $apiKey = $apiKey.Substring(7).Trim()
    }
    if ([string]::IsNullOrWhiteSpace($apiKey)) {
        throw 'No API key was entered. Nothing was changed.'
    }
    if ([string]::IsNullOrWhiteSpace($baseUrl)) {
        throw 'No base URL was entered. Nothing was changed.'
    }
    if ([string]::IsNullOrWhiteSpace($model)) {
        throw 'No model was entered. Nothing was changed.'
    }

    # Codex reads this user-scoped environment variable through env_key = "YOUR_API_SOURCE_API_KEY".
    # Do not print, log, or save the key anywhere else. The base URL and model
    # are non-secret local profile values and are also kept outside Git.
    [Environment]::SetEnvironmentVariable('YOUR_API_SOURCE_API_KEY', $apiKey, 'User')
    [Environment]::SetEnvironmentVariable('YOUR_API_SOURCE_BASE_URL', $baseUrl.Trim().TrimEnd('/'), 'User')
    [Environment]::SetEnvironmentVariable('YOUR_API_SOURCE_MODEL', $model.Trim(), 'User')
    $env:YOUR_API_SOURCE_API_KEY = $apiKey
    $env:YOUR_API_SOURCE_BASE_URL = $baseUrl.Trim().TrimEnd('/')
    $env:YOUR_API_SOURCE_MODEL = $model.Trim()
    Write-Host ''
    Write-Host 'YOUR_API_SOURCE_API_KEY, YOUR_API_SOURCE_BASE_URL, and YOUR_API_SOURCE_MODEL were saved for your Windows user account.'
    Write-Host 'Next, run Switch-Codex-To-YourApiSource.cmd. It will verify the key before changing Codex configuration.'
} finally {
    if ($bstr -ne [IntPtr]::Zero) {
        [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
    }
    Remove-Variable apiKey -ErrorAction SilentlyContinue
}
