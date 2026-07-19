$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$controller = Join-Path $root 'scripts\Invoke-CodexVerification.ps1'
$content = Get-Content -LiteralPath $controller -Raw -Encoding UTF8
$uiStarter = Get-Content -LiteralPath (Join-Path $root 'scripts\Start-CodebaseMemoryGraphUi.ps1') -Raw -Encoding UTF8

$tokens = $null; $errors = $null
[void][System.Management.Automation.Language.Parser]::ParseFile($controller, [ref]$tokens, [ref]$errors)
if ($errors) { throw "Verification controller has PowerShell syntax errors: $($errors | Out-String)" }
if ($content -notmatch "ValidateSet\('Fast','Full'\)") { throw 'Verification controller must expose Fast and Full modes.' }
if ($content -notmatch 'codebase-memory-ui-preflight') { throw 'Fast verification must retain the Codebase Memory UI preflight.' }
if ($content -notmatch 'changed-script-syntax') { throw 'Fast verification must check changed script syntax.' }
if ($content -notmatch 'verification-last-run\.json') { throw 'Verification controller must record timing evidence by default.' }
if ($uiStarter -notmatch '(?s)\$health = \$null.*?Get-UiJson.*?Get-NetTCPConnection') { throw 'Codebase Memory UI starter must probe HTTP health before enumerating TCP listeners.' }

Write-Host 'Codex verification controller test passed.'
