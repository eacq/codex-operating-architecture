[CmdletBinding()]
param(
    [string]$ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path,
    [switch]$RequireGraphviz
)

$ErrorActionPreference = 'Stop'
$privateConfigPath = Join-Path $env:USERPROFILE '.codex\private-skill-config\drawio-skill.json'
$templatePath = Join-Path $ProjectRoot 'config\drawio-skill-runtime.template.json'
$config = [ordered]@{}
if (Test-Path -LiteralPath $privateConfigPath) {
    $config = Get-Content -LiteralPath $privateConfigPath -Raw -Encoding UTF8 | ConvertFrom-Json
}

function Resolve-ExecutablePath {
    param([string[]]$Candidates)
    foreach ($candidate in $Candidates) {
        if (-not [string]::IsNullOrWhiteSpace($candidate) -and (Test-Path -LiteralPath $candidate -PathType Leaf)) {
            return (Resolve-Path -LiteralPath $candidate).Path
        }
    }
    return $null
}

$drawio = Resolve-ExecutablePath @(
    [string]$config.drawio_executable,
    (Join-Path $ProjectRoot '.runtime\software\drawio\draw.io.exe'),
    'C:\Program Files\draw.io\draw.io.exe'
)
$graphviz = Resolve-ExecutablePath @(
    [string]$config.graphviz_executable,
    (Join-Path $ProjectRoot '.runtime\software\graphviz\bin\dot.exe'),
    'C:\Program Files\Graphviz\bin\dot.exe'
)
$python = Resolve-ExecutablePath @(
    [string]$config.python_executable,
    (Join-Path $ProjectRoot '.codex\runtime\env\python.exe')
)

if (-not $drawio) { throw "draw.io executable was not found. Configure $privateConfigPath from $templatePath or install draw.io." }
if (-not $python) { throw "Project Python executable was not found. Configure $privateConfigPath from $templatePath." }
if ($RequireGraphviz -and -not $graphviz) { throw "Graphviz dot executable was not found. Configure $privateConfigPath from $templatePath or install Graphviz." }

[ordered]@{
    schema_version = 1
    drawio_executable = $drawio
    graphviz_executable = $graphviz
    python_executable = $python
    private_config_path = $privateConfigPath
    template_path = $templatePath
    export_wait_strategy = 'Start-Process -Wait; verify the requested artifact exists after the child process exits.'
} | ConvertTo-Json -Depth 3
