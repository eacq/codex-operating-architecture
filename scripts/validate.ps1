$ErrorActionPreference = 'Stop'
$python = if ($env:CODEX_PYTHON) { $env:CODEX_PYTHON } else { 'python' }
$validator = if ($env:CODEX_SKILL_VALIDATOR) { $env:CODEX_SKILL_VALIDATOR } else { Join-Path $HOME '.codex\skills\.system\skill-creator\scripts\quick_validate.py' }
$env:PYTHONUTF8 = '1'
if (-not (Test-Path -LiteralPath $python)) { $python = 'python' }

& $python -c "import yaml" 2>$null
if ($LASTEXITCODE -ne 0) {
    throw "Skill validation runtime '$python' requires PyYAML. Set CODEX_PYTHON to an existing Python interpreter with PyYAML installed."
}

$failed = @()
Get-ChildItem -LiteralPath (Join-Path $PSScriptRoot '..\skills') -Directory | ForEach-Object {
    & $python $validator $_.FullName
    if ($LASTEXITCODE -ne 0) { $failed += $_.Name }
}

if ($failed.Count -gt 0) { throw "Skill validation failed: $($failed -join ', ')" }
& $python (Join-Path $PSScriptRoot 'index_history.py')
if ($LASTEXITCODE -ne 0) { throw 'History indexing failed.' }
& $python (Join-Path $PSScriptRoot 'scan_repository.py')
if ($LASTEXITCODE -ne 0) { throw 'Repository placeholder or secret scan failed.' }
$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$registry = Get-Content -LiteralPath (Join-Path $root 'module-registry.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$registered = @($registry.modules | ForEach-Object name | Sort-Object)
$skillNames = @(Get-ChildItem -LiteralPath (Join-Path $root 'skills') -Directory | ForEach-Object Name | Sort-Object)
$delta = Compare-Object $registered $skillNames
if ($delta) { throw "Module registry differs from skill folders: $($delta | Out-String)" }
$runtimeManager = Join-Path $root 'skills\codex-runtime-environments\scripts\Manage-CodexEnvironment.ps1'
$parseErrors = $null
[System.Management.Automation.Language.Parser]::ParseFile($runtimeManager, [ref]$null, [ref]$parseErrors) | Out-Null
if ($parseErrors) { throw "Runtime environment manager has PowerShell syntax errors: $($parseErrors | Out-String)" }
& $runtimeManager status | Out-Null
if ($LASTEXITCODE -ne 0) { throw 'Runtime environment status check failed.' }
Get-Content -LiteralPath (Join-Path $root 'runtime-environments\tool-profiles.json') -Raw -Encoding UTF8 | ConvertFrom-Json | Out-Null
& $runtimeManager profiles | Out-Null
if ($LASTEXITCODE -ne 0) { throw 'Runtime environment profile check failed.' }
Get-ChildItem -LiteralPath (Join-Path $root 'skills') -Recurse -Filter '*.ps1' | ForEach-Object {
    $scriptParseErrors = $null
    [System.Management.Automation.Language.Parser]::ParseFile($_.FullName, [ref]$null, [ref]$scriptParseErrors) | Out-Null
    if ($scriptParseErrors) { throw "PowerShell script has syntax errors in $($_.FullName): $($scriptParseErrors | Out-String)" }
}
& $python (Join-Path $root 'skills\codex-knowledge-system\scripts\build_knowledge.py')
if ($LASTEXITCODE -ne 0) { throw 'Knowledge graph validation failed.' }
& $python (Join-Path $root 'skills\codex-knowledge-system\scripts\build_mindmaps.py')
if ($LASTEXITCODE -ne 0) { throw 'Mind-map generation failed.' }
& $python -m unittest discover -s (Join-Path $root 'skills\codex-image-workflow\scripts') -p 'test_*.py'
if ($LASTEXITCODE -ne 0) { throw 'Image workflow tests failed.' }
Write-Host 'All skills, history indexing, module registry, knowledge graph, mind-map views, and image workflow tests validated.'
