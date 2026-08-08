[CmdletBinding()]
param([string]$RepositoryRoot = (Get-Location).Path)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath $RepositoryRoot).Path
$renderer = Get-Content -LiteralPath (Join-Path $root 'scripts\Render-CodebaseMemoryGraph.ps1') -Raw -Encoding UTF8
$release = Get-Content -LiteralPath (Join-Path $root 'skills\codex-git-operations\scripts\Update-ReleaseReadmeAndVisuals.ps1') -Raw -Encoding UTF8
$design = Get-Content -LiteralPath (Join-Path $root 'docs\readme-design-system.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$architecture = Get-Content -LiteralPath (Join-Path $root 'ARCHITECTURE.md') -Raw -Encoding UTF8
$provenance = Get-Content -LiteralPath (Join-Path $root 'docs\assets\readme-raster-visuals.provenance.md') -Raw -Encoding UTF8

if ($renderer -notmatch '\[switch\]\$GenerateGif') { throw 'Graph renderer must require the explicit GenerateGif switch for GIF output.' }
if ($renderer -notmatch '\$renderGif = \$GenerateGif\.IsPresent') { throw 'Graph renderer must default to PNG-only output.' }
if ($renderer -notmatch '\$staticMode\s*=\s*\(-not\s+\$renderGif\)\.ToString\(\)\.ToLowerInvariant\(\)') { throw 'Graph renderer must serialize the Node static-mode flag as lowercase text.' }
if ($renderer -match '--static\s+\(-not\s+\$renderGif\)') { throw 'Graph renderer must not pass a PowerShell Boolean token to the Node static-mode protocol.' }
if ($renderer -match '\[string\]\$(OutputPath|GifOutputPath)\s*=\s*\(Join-Path\s+\$PSScriptRoot') { throw 'Graph renderer path defaults must be initialized after script parameter binding.' }
if ($release -match 'Render-CodebaseMemoryGraph\.ps1[^\r\n]*-GenerateGif') { throw 'Release refresh must not generate or overwrite GIF assets.' }
if ($release -notmatch '\$ErrorActionPreference\s*=\s*''Continue''[\s\S]+\$rendererExitCode\s*=\s*\$LASTEXITCODE') { throw 'Release refresh must capture native renderer stderr without bypassing exit-code validation.' }
if ([string]::IsNullOrWhiteSpace($design.visual_assets.codebase_memory_graph.animation_policy)) { throw 'Design system must record the Codebase Memory GIF opt-in policy.' }
if ($architecture -notmatch 'GIF.*release' -or $provenance -notmatch 'explicit user request') { throw 'Architecture and provenance documentation must preserve the GIF opt-in policy.' }

[pscustomobject]@{ result = 'codebase-memory-graph-render-policy-passed'; default_output = 'PNG'; gif_generation = 'explicit-user-request-only' } | ConvertTo-Json
