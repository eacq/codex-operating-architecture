[CmdletBinding()]
param(
    [string]$RepositoryRoot = 'F:\codex',
    [string]$ProjectName = 'F-codex',
    [int]$Port = 9750,
    [ValidateRange(1, 300)]
    [int]$IndexTimeoutSeconds = 180
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath $RepositoryRoot).Path
$binary = Join-Path $root '.codex\software-install\codebase-memory-mcp-ui\codebase-memory-mcp.exe'
if (-not (Test-Path -LiteralPath $binary -PathType Leaf)) {
    throw "Codebase Memory MCP UI binary is missing: $binary"
}

$baseUrl = "http://127.0.0.1:$Port"
function Get-UiJson([string]$Path, [int]$TimeoutSeconds = 10) {
    $response = Invoke-WebRequest -UseBasicParsing -Uri "$baseUrl$Path" -TimeoutSec $TimeoutSeconds
    return $response.Content | ConvertFrom-Json
}

# A healthy local UI is the common path. Avoid the comparatively expensive
# TCP connection enumeration unless the HTTP health probe cannot reach it.
$health = $null
try {
    $health = Get-UiJson ("/api/project-health?name=" + [uri]::EscapeDataString($ProjectName)) 2
} catch { }
$listener = $null
if (-not $health) {
    $listener = Get-NetTCPConnection -State Listen -LocalAddress '127.0.0.1' -LocalPort $Port -ErrorAction SilentlyContinue | Select-Object -First 1
}
if (-not $health -and -not $listener) {
    # Keep stdio open because the MCP server exits when it receives EOF.
    $command = "ping -t 127.0.0.1 | `"$binary`" --ui=true --port=$Port"
    $process = Start-Process -FilePath cmd.exe -ArgumentList '/c', $command -WindowStyle Hidden -PassThru
    $deadline = (Get-Date).AddSeconds(15)
    do {
        Start-Sleep -Milliseconds 250
        $listener = Get-NetTCPConnection -State Listen -LocalAddress '127.0.0.1' -LocalPort $Port -ErrorAction SilentlyContinue | Select-Object -First 1
    } while (-not $listener -and (Get-Date) -lt $deadline)
    if (-not $listener) { throw "Codebase Memory MCP UI did not open 127.0.0.1:$Port (launcher PID $($process.Id))." }
}
$health = if ($health) { $health } else { Get-UiJson ("/api/project-health?name=" + [uri]::EscapeDataString($ProjectName)) }
$indexStatus = 'healthy'
if ($health.status -ne 'healthy') {
    $jobs = @(Get-UiJson '/api/index-status')
    $activeJob = @($jobs | Where-Object { $_.path -eq $root -and $_.status -eq 'indexing' }) | Select-Object -First 1
    if (-not $activeJob) {
        $body = @{ root_path = $root; project_name = $ProjectName } | ConvertTo-Json -Compress
        $response = Invoke-WebRequest -UseBasicParsing -Method Post -Uri "$baseUrl/api/index" -ContentType 'application/json' -Body $body -TimeoutSec 10
        $indexStatus = ($response.Content | ConvertFrom-Json).status
    } else {
        $indexStatus = $activeJob.status
    }

    $deadline = (Get-Date).AddSeconds($IndexTimeoutSeconds)
    do {
        Start-Sleep -Seconds 1
        $jobs = @(Get-UiJson '/api/index-status')
        $job = @($jobs | Where-Object { $_.path -eq $root }) | Select-Object -Last 1
        if ($job -and $job.status -eq 'error') { throw "Codebase Memory MCP UI index failed: $($job.error)" }
        $health = Get-UiJson ("/api/project-health?name=" + [uri]::EscapeDataString($ProjectName))
    } while ($health.status -ne 'healthy' -and (Get-Date) -lt $deadline)
    if ($health.status -ne 'healthy') { throw "Codebase Memory MCP UI index did not become healthy within $IndexTimeoutSeconds seconds." }
}

[pscustomobject]@{
    repository_root = $root
    project_name = $ProjectName
    url = "http://127.0.0.1:$Port/"
    port = $Port
    process_id = if ($listener) { $listener.OwningProcess } else { $null }
    index_status = $indexStatus
    nodes = $health.nodes
    edges = $health.edges
    status = 'ready'
} | ConvertTo-Json
