[CmdletBinding()]
param(
    [string]$RepositoryRoot = 'F:\codex',
    [string]$ProcessName = 'node_repl',
    [string]$ScopePattern = 'OpenAI\Codex\runtimes\cua_node',
    [int]$MinAgeSeconds = 600,
    [switch]$Apply,
    [object[]]$ProcessTable
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath $RepositoryRoot).Path

$protectedPatterns = @(
    'codex.exe',
    'codebase-memory-mcp',
    'YouTuCore',
    'Adobe',
    'mcp/server.mjs'
)

function Get-ProcessRecords {
    param([string]$NameFilter)
    if ($null -ne $ProcessTable -and @($ProcessTable).Count -gt 0) {
        return @($ProcessTable | Where-Object { ([string]$_.Name) -like "*$NameFilter*" })
    }
    $records = @()
    Get-CimInstance Win32_Process -Filter "Name='$NameFilter.exe'" -ErrorAction SilentlyContinue | ForEach-Object {
        $records += [pscustomobject]@{
            ProcessId = $_.ProcessId
            Name = $_.Name
            CommandLine = [string]$_.CommandLine
            CreationDate = $_.CreationDate
        }
    }
    return $records
}

function Test-Protected([string]$Name, [string]$CommandLine) {
    foreach ($token in $protectedPatterns) {
        if ($Name -like "*$token*" -or $CommandLine -like "*$token*") { return $true }
    }
    return $false
}

$now = [DateTime]::UtcNow
$eligible = @()
foreach ($record in Get-ProcessRecords -NameFilter $ProcessName) {
    $commandLine = [string]$record.CommandLine
    if ($commandLine -notlike "*$ScopePattern*") { continue }
    if (Test-Protected -Name ([string]$record.Name) -CommandLine $commandLine) { continue }
    $ageSeconds = 0
    if ($null -ne $record.CreationDate -and $record.CreationDate -ne '') {
        $start = if ($record.CreationDate -is [datetime]) { $record.CreationDate } else { [datetime]$record.CreationDate }
        $ageSeconds = ($now - $start.ToUniversalTime()).TotalSeconds
    }
    if ($ageSeconds -lt $MinAgeSeconds) { continue }
    $eligible += $record
}

$terminated = @()
foreach ($record in $eligible) {
    if ($Apply) {
        Stop-Process -Id $record.ProcessId -Force -ErrorAction SilentlyContinue
    }
    $terminated += [pscustomobject]@{
        process_id = $record.ProcessId
        name = $record.Name
        command_line = $record.CommandLine
        dry_run = -not [bool]$Apply
    }
}

[pscustomobject]@{
    schema_version = 1
    result = if ($Apply) { 'released' } else { 'dry-run' }
    repository_root = $root
    process_name = $ProcessName
    scope_pattern = $ScopePattern
    min_age_seconds = $MinAgeSeconds
    protected_patterns = $protectedPatterns
    eligible_count = @($eligible).Count
    terminated = @($terminated)
} | ConvertTo-Json -Depth 6
