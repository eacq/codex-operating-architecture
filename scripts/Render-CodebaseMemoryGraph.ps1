[CmdletBinding()]
param(
    [string]$OutputPath = '',
    [string]$GifOutputPath = '',
    [int]$NodeCount = 0,
    [int]$EdgeCount = 0,
    [int]$Seed = 20260719,
    [string]$UiUrl = 'http://127.0.0.1:9750',
    [string]$ProjectName = 'F-codex',
    [int]$Frames = 120,
    [int]$GifFrameDurationMilliseconds = 125,
    [switch]$GenerateGif,
    [switch]$PngOnly
)

$ErrorActionPreference = 'Stop'
if ([string]::IsNullOrWhiteSpace($OutputPath)) { $OutputPath = Join-Path $PSScriptRoot '..\docs\assets\codebase-memory-mcp-graph.png' }
if ([string]::IsNullOrWhiteSpace($GifOutputPath)) { $GifOutputPath = Join-Path $PSScriptRoot '..\docs\assets\codebase-memory-mcp-graph.gif' }
$python = 'C:\Users\12484\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe'
$renderer = Join-Path $PSScriptRoot 'render_codebase_memory_graph.py'
$canvasCapture = Join-Path $PSScriptRoot 'capture_codebase_memory_graph_canvas.mjs'
$uiStarter = Join-Path $PSScriptRoot 'Start-CodebaseMemoryGraphUi.ps1'
$runRootResolver = Join-Path $PSScriptRoot 'Resolve-CodexRunRoot.ps1'
if (-not (Test-Path -LiteralPath $uiStarter)) { throw 'Codebase Memory MCP UI starter is missing.' }
if (-not (Test-Path -LiteralPath $runRootResolver)) { throw 'Codex run-root resolver is missing.' }
$runtimeDirectory = Join-Path $env:LOCALAPPDATA 'Codex\codebase-memory-canvas-export'
$playwrightRoot = Join-Path $runtimeDirectory 'node_modules\playwright-core'
$chrome = 'C:\Program Files\Google\Chrome\Application\chrome.exe'
if (-not (Test-Path -LiteralPath $playwrightRoot)) {
    New-Item -ItemType Directory -Force -Path $runtimeDirectory | Out-Null
    Push-Location $runtimeDirectory
    try {
        if (-not (Test-Path -LiteralPath (Join-Path $runtimeDirectory 'package.json'))) { npm init --yes | Out-Null }
        npm install --no-save playwright-core@1.55.0
        if ($LASTEXITCODE -ne 0) { throw 'Failed to install the local Three.js canvas export runtime.' }
    } finally {
        Pop-Location
    }
}
if (-not (Test-Path -LiteralPath $chrome)) { throw 'Google Chrome is required for Codebase Memory canvas export.' }
$ui = & $uiStarter | ConvertFrom-Json
$architectureRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$framesDirectory = & $runRootResolver -ArchitectureRoot $architectureRoot -Kind tmp -ChildPath ("codebase-memory-frames-" + [guid]::NewGuid().ToString('N')) -Create
if ($GenerateGif -and $PngOnly) { throw 'GenerateGif and PngOnly cannot be used together.' }
$renderGif = $GenerateGif.IsPresent
$staticMode = (-not $renderGif).ToString().ToLowerInvariant()
& node $canvasCapture --playwright-root $playwrightRoot --chrome-path $chrome --ui-url $ui.url --project $ui.project_name --frames-dir $framesDirectory --frames $Frames --static $staticMode
if ($LASTEXITCODE -ne 0) { throw 'Codebase Memory Three.js canvas capture failed.' }
if ($renderGif) {
    & $python $renderer --png $OutputPath --gif $GifOutputPath --frames-dir $framesDirectory --loop-duration-ms ($Frames * $GifFrameDurationMilliseconds)
    if ($LASTEXITCODE -ne 0) { throw 'Codebase Memory graph renderer failed.' }
} else {
    Copy-Item -LiteralPath (Join-Path $framesDirectory 'frame-000.png') -Destination $OutputPath -Force
}

[pscustomobject]@{ output = $OutputPath; gif_output = if ($renderGif) { $GifOutputPath } else { $null }; project = $ui.project_name; indexed_nodes = $ui.nodes; indexed_edges = $ui.edges; renderer = 'deployed Codebase Memory MCP Three.js canvas export with UI OrbitControls, WebGL color pipeline, instanced node meshes, AdditiveBlending, Bloom, and labels disabled'; gif_policy = 'Generate or overwrite GIF only when -GenerateGif is explicitly supplied; otherwise retain any existing GIF.' } | ConvertTo-Json
