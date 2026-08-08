[CmdletBinding()]
param(
    [string]$RepositoryRoot = (Get-Location).Path,
    [string]$ProxyUri = 'http://127.0.0.1:7892',
    [string]$ProxyHost = '127.0.0.1',
    [int]$ProxyPort = 7892,
    [string]$GameProcessPattern = 'mihoyo|hoyoverse|genshin|yuanshen|starrail|zenless|zzz|bh3|bh3rd|hkrpg|nap|HoYoPlay',
    [switch]$SkipNetwork
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath $RepositoryRoot).Path

function Invoke-CurlProbe {
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][string]$Url,
        [switch]$UseProxy
    )
    $args = @('-s', '-o', 'NUL', '-w', "$Name`:%{http_code},connect:%{http_connect},remote:%{remote_ip},time:%{time_total}", '--max-time', '20')
    if ($UseProxy) { $args = @('-x', $ProxyUri) + $args }
    $args += $Url
    $output = & curl.exe @args
    $exit = if ($null -eq $LASTEXITCODE) { 0 } else { $LASTEXITCODE }
    [ordered]@{ name = $Name; url = $Url; proxy = [bool]$UseProxy; exit_code = $exit; result = $output }
}

$internet = Get-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings'
$listener = Get-NetTCPConnection -LocalAddress $ProxyHost -LocalPort $ProxyPort -State Listen -ErrorAction SilentlyContinue |
    Select-Object -First 1 LocalAddress, LocalPort, State, OwningProcess
$tunAdapters = @(Get-NetAdapter -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -match 'YouTu|TUN|TAP|Wintun|Clash|Meta' -or $_.InterfaceDescription -match 'YouTu|TUN|TAP|Wintun|Clash|Meta' } |
    Select-Object Name, InterfaceDescription, Status)

$gameProcesses = @(Get-Process -ErrorAction SilentlyContinue |
    Where-Object { ($_.ProcessName -match $GameProcessPattern) -or ($_.Path -match $GameProcessPattern) } |
    Select-Object ProcessName, Id, Path)
$gameConnections = @()
foreach ($process in $gameProcesses) {
    $connections = @(Get-NetTCPConnection -OwningProcess $process.Id -ErrorAction SilentlyContinue |
        Select-Object LocalAddress, LocalPort, RemoteAddress, RemotePort, State)
    $gameConnections += [ordered]@{
        process = $process.ProcessName
        id = $process.Id
        active_local_proxy_connections = @($connections | Where-Object { $_.RemoteAddress -eq $ProxyHost -and $_.RemotePort -eq $ProxyPort -and $_.State -eq 'Established' }).Count
        stale_local_proxy_connections = @($connections | Where-Object { $_.RemoteAddress -eq $ProxyHost -and $_.RemotePort -eq $ProxyPort -and $_.State -ne 'Established' }).Count
        established_remote_connections = @($connections | Where-Object { $_.State -eq 'Established' -and $_.RemoteAddress -ne $ProxyHost }).Count
    }
}

$probes = @()
if (-not $SkipNetwork) {
    $probes += Invoke-CurlProbe -Name 'github_direct' -Url 'https://github.com'
    $probes += Invoke-CurlProbe -Name 'github_proxy' -Url 'https://github.com' -UseProxy
    $probes += Invoke-CurlProbe -Name 'api_openai_direct' -Url 'https://api.openai.com/v1/models'
    $probes += Invoke-CurlProbe -Name 'api_openai_proxy' -Url 'https://api.openai.com/v1/models' -UseProxy
    $githubCommand = Join-Path $root 'skills\codex-git-operations\scripts\Invoke-GitHubNetworkCommand.ps1'
    $ghName = (& $githubCommand -RepositoryRoot $root -ForceProxy -Tool gh repo view cli/cli --json name --jq .name).Trim()
    $remoteHead = (& $githubCommand -RepositoryRoot $root -ForceProxy -Tool git -C $root ls-remote origin refs/heads/main).Trim()
}

[ordered]@{
    repository_root = $root
    windows_system_proxy_enabled = [bool]$internet.ProxyEnable
    windows_system_proxy_server = $internet.ProxyServer
    process_http_proxy = $env:HTTP_PROXY
    process_https_proxy = $env:HTTPS_PROXY
    local_proxy_listening = [bool]$listener
    local_proxy_listener = $listener
    tun_adapters = $tunAdapters
    game_processes = $gameProcesses
    game_proxy_summary = $gameConnections
    network_probes = $probes
    gh_probe = $ghName
    git_remote_head_probe = $remoteHead
    result = 'codex-scoped-proxy-isolation-checked'
} | ConvertTo-Json -Depth 8
