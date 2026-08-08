[CmdletBinding()]
param(
    [string]$RepositoryRoot = 'F:\codex',
    [string]$ProjectName = 'F-codex',
    [Alias('HostAddress', 'BindAddress')]
    [string]$Address = '127.0.0.1',
    [int]$Port = 9749,
    [ValidateRange(1, 300)]
    [int]$IndexTimeoutSeconds = 180
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath $RepositoryRoot).Path
$binary = Join-Path $root '.codex\software-install\codebase-memory-mcp-ui\codebase-memory-mcp.exe'
if (-not (Test-Path -LiteralPath $binary -PathType Leaf)) {
    throw "Codebase Memory MCP UI binary is missing: $binary"
}
$cacheDir = Join-Path $root '.codex\tool-cache\codebase-memory-mcp'
New-Item -ItemType Directory -Force -Path $cacheDir | Out-Null
$env:CBM_CACHE_DIR = $cacheDir

# The MCP auto-indexer may discover the Codex installation on C:. Keep
# automatic discovery disabled; this script explicitly indexes only F-codex.
$autoIndexOutput = @(& $binary config get auto_index 2>&1)
if (($autoIndexOutput -join ([Environment]::NewLine)) -match '(?im)^\s*true\s*$|=\s*true\s*$') {
    $autoIndexSetOutput = @(& $binary config set auto_index false 2>&1)
    if ($LASTEXITCODE -ne 0) {
        throw "Codebase Memory MCP auto_index could not be disabled: $($autoIndexSetOutput -join ([Environment]::NewLine))"
    }
}

$baseUrl = "http://$Address`:$Port"
function Get-UiJson([string]$Path, [int]$TimeoutSeconds = 10) {
    $response = Invoke-WebRequest -UseBasicParsing -Uri "$baseUrl$Path" -TimeoutSec $TimeoutSeconds
    return $response.Content | ConvertFrom-Json
}

function Get-CanonicalProjectStats {
    $previousErrorAction = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    $raw = & $binary cli list_projects 2>&1
    $exitCode = $LASTEXITCODE
    $ErrorActionPreference = $previousErrorAction
    if ($exitCode -ne 0) { return $null }
    $jsonLine = @($raw | Where-Object { $_ -match '^\s*\{' } | Select-Object -Last 1)
    if (-not $jsonLine) { return $null }
    try {
        $projects = ($jsonLine | ConvertFrom-Json).projects
        return @($projects | Where-Object { $_.name -eq $ProjectName } | Select-Object -First 1)
    } catch {
        return $null
    }
}

# A healthy local UI is the common path. Avoid the comparatively expensive
# TCP connection enumeration unless the HTTP health probe cannot reach it.
$health = $null
try {
    $health = Get-UiJson ("/api/project-health?name=" + [uri]::EscapeDataString($ProjectName)) 2
} catch { }
$listener = $null
$listener = Get-NetTCPConnection -State Listen -LocalAddress $Address -LocalPort $Port -ErrorAction SilentlyContinue | Select-Object -First 1
if ($health -and $listener) {
    $canonicalProject = Get-CanonicalProjectStats
    if ($canonicalProject -and (([int64]$canonicalProject.nodes -ne [int64]$health.nodes) -or ([int64]$canonicalProject.edges -ne [int64]$health.edges))) {
        $process = Get-Process -Id $listener.OwningProcess -ErrorAction SilentlyContinue
        if ($process -and $process.Path -eq $binary) {
            Stop-Process -Id $listener.OwningProcess -Force
            Start-Sleep -Milliseconds 500
            $health = $null
            $listener = $null
        } else {
            throw "Port $Address`:$Port is in use by a non-canonical process; cannot verify Codebase Memory cache consistency."
        }
    }
}
if (-not $health -and -not $listener) {
    # Keep stdio open because the MCP server exits when it receives EOF.
    $command = "ping -t $Address | `"$binary`" --ui=true --port=$Port"
    $process = Start-Process -FilePath cmd.exe -ArgumentList '/c', $command -WindowStyle Hidden -PassThru
    $deadline = (Get-Date).AddSeconds(15)
    do {
        Start-Sleep -Milliseconds 250
        $listener = Get-NetTCPConnection -State Listen -LocalAddress $Address -LocalPort $Port -ErrorAction SilentlyContinue | Select-Object -First 1
    } while (-not $listener -and (Get-Date) -lt $deadline)
    if (-not $listener) { throw "Codebase Memory MCP UI did not open $Address`:$Port (launcher PID $($process.Id))." }
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
    url = "http://$Address`:$Port/"
    port = $Port
    process_id = if ($listener) { $listener.OwningProcess } else { $null }
    index_status = $indexStatus
    nodes = $health.nodes
    edges = $health.edges
    status = 'ready'
} | ConvertTo-Json
