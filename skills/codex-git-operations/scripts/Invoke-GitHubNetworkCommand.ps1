[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('git', 'gh')]
    [string]$Tool,
    [Parameter(Mandatory = $true, Position = 1, ValueFromRemainingArguments = $true)]
    [string[]]$Arguments,
    [string]$RepositoryRoot = (Get-Location).Path,
    [string]$ProxyUri = 'http://127.0.0.1:7892',
    [string]$ProxyHost = '127.0.0.1',
    [int]$ProxyPort = 7892,
    [string]$YouTuShortcut = '%PUBLIC%\Desktop\YouTu.lnk',
    [int]$StartupTimeoutSeconds = 45,
    [switch]$ForceProxy
)

$ErrorActionPreference = 'Stop'

function Test-TcpEndpoint {
    param(
        [Parameter(Mandatory = $true)][string]$HostName,
        [Parameter(Mandatory = $true)][int]$Port,
        [int]$TimeoutMilliseconds = 2000
    )
    $client = [Net.Sockets.TcpClient]::new()
    try {
        $async = $client.BeginConnect($HostName, $Port, $null, $null)
        if (-not $async.AsyncWaitHandle.WaitOne($TimeoutMilliseconds)) { return $false }
        $client.EndConnect($async)
        return $true
    }
    catch {
        return $false
    }
    finally {
        $client.Dispose()
    }
}

function Start-YouTuProxy {
    param([string]$ShortcutPath)
    if (Test-TcpEndpoint -HostName $ProxyHost -Port $ProxyPort -TimeoutMilliseconds 500) { return }
    if (-not (Test-Path -LiteralPath $ShortcutPath)) { throw "YouTu shortcut is missing: $ShortcutPath" }

    $shell = New-Object -ComObject WScript.Shell
    $shortcut = $shell.CreateShortcut($ShortcutPath)
    $targetPath = $shortcut.TargetPath
    $workingDirectory = $shortcut.WorkingDirectory
    if (-not $targetPath -or -not (Test-Path -LiteralPath $targetPath)) {
        throw "YouTu target is unavailable from shortcut: $ShortcutPath"
    }
    $startArgs = @{ FilePath = $targetPath; WindowStyle = 'Hidden' }
    if ($workingDirectory -and (Test-Path -LiteralPath $workingDirectory)) {
        $startArgs['WorkingDirectory'] = $workingDirectory
    }
    Start-Process @startArgs | Out-Null
}

function Wait-ProxyPort {
    param([int]$TimeoutSeconds)
    $deadline = [DateTime]::UtcNow.AddSeconds($TimeoutSeconds)
    while ([DateTime]::UtcNow -lt $deadline) {
        if (Test-TcpEndpoint -HostName $ProxyHost -Port $ProxyPort -TimeoutMilliseconds 500) { return }
        Start-Sleep -Milliseconds 500
    }
    throw "YouTu proxy did not listen on ${ProxyHost}:${ProxyPort} within $TimeoutSeconds second(s)."
}

$directGitHub443 = Test-TcpEndpoint -HostName 'github.com' -Port 443 -TimeoutMilliseconds 2500
$useProxy = [bool]$ForceProxy -or -not $directGitHub443
if ($useProxy) {
    Start-YouTuProxy -ShortcutPath $YouTuShortcut
    Wait-ProxyPort -TimeoutSeconds $StartupTimeoutSeconds
}

$oldEnv = @{}
foreach ($name in @('HTTP_PROXY', 'HTTPS_PROXY', 'ALL_PROXY', 'NO_PROXY')) {
    $oldEnv[$name] = [Environment]::GetEnvironmentVariable($name, 'Process')
}

try {
    if ($useProxy) {
        [Environment]::SetEnvironmentVariable('HTTP_PROXY', $ProxyUri, 'Process')
        [Environment]::SetEnvironmentVariable('HTTPS_PROXY', $ProxyUri, 'Process')
        [Environment]::SetEnvironmentVariable('ALL_PROXY', $ProxyUri, 'Process')
        [Environment]::SetEnvironmentVariable('NO_PROXY', 'localhost,127.0.0.1,::1', 'Process')
    }
    & $Tool @Arguments
    $exitCode = if ($null -eq $LASTEXITCODE) { 0 } else { $LASTEXITCODE }
    if ($exitCode -ne 0) {
        throw "GitHub network command failed with exit code ${exitCode}: $Tool $($Arguments -join ' ')"
    }
}
finally {
    foreach ($name in $oldEnv.Keys) {
        [Environment]::SetEnvironmentVariable($name, $oldEnv[$name], 'Process')
    }
}
