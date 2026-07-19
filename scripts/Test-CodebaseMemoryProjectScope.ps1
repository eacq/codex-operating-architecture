$ErrorActionPreference = 'Stop'

$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$configPath = Join-Path $HOME '.codex\config.toml'
if (-not (Test-Path -LiteralPath $configPath -PathType Leaf)) {
    Write-Host 'Codebase Memory project-scope test skipped: Codex config.toml is unavailable.'
    exit 0
}

$config = Get-Content -LiteralPath $configPath -Raw -Encoding UTF8
$commandMatch = [regex]::Match($config, '(?ms)\[mcp_servers\.codebase-memory-mcp\].*?command\s*=\s*''(?<command>[^'']+)''')
if (-not $commandMatch.Success) {
    Write-Host 'Codebase Memory project-scope test skipped: MCP server is not configured.'
    exit 0
}

$cacheMatch = [regex]::Match($config, '(?ms)\[mcp_servers\.codebase-memory-mcp\.env\].*?CBM_CACHE_DIR\s*=\s*''(?<cache>[^'']+)''')
$exe = $commandMatch.Groups['command'].Value
if (-not (Test-Path -LiteralPath $exe -PathType Leaf)) {
    Write-Host "Codebase Memory project-scope test skipped: executable missing: $exe"
    exit 0
}

if ($cacheMatch.Success) {
    $env:CBM_CACHE_DIR = $cacheMatch.Groups['cache'].Value
}

$previousErrorAction = $ErrorActionPreference
$ErrorActionPreference = 'Continue'
$raw = & $exe cli list_projects 2>&1
$exitCode = $LASTEXITCODE
$ErrorActionPreference = $previousErrorAction
if ($exitCode -ne 0) {
    throw "Codebase Memory list_projects failed: $($raw -join "`n")"
}

$jsonLine = @($raw | Where-Object { $_ -match '^\s*\{' } | Select-Object -Last 1)
if (-not $jsonLine) { throw "Codebase Memory list_projects returned no JSON: $($raw -join "`n")" }
$projects = ($jsonLine | ConvertFrom-Json).projects
if (@($projects).Count -ne 1) {
    throw "Global Codebase Memory scope must contain exactly one project; found $(@($projects).Count): $((@($projects) | ForEach-Object name) -join ', ')"
}
$project = @($projects)[0]
if ($project.name -ne 'F-codex') {
    throw "Global Codebase Memory project must be F-codex, got $($project.name)."
}
$rootPath = ([string]$project.root_path).Replace('\','/').TrimEnd('/')
if ($rootPath -ine 'F:/codex') {
    throw "F-codex must be rooted at F:/codex, got $($project.root_path)."
}
if (-not $project.git.root_exists) {
    throw 'F-codex root does not exist according to Codebase Memory.'
}

Write-Host 'Codebase Memory project-scope test passed.'
