$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$controller = Join-Path $root 'scripts\Invoke-CodexVerification.ps1'
$content = Get-Content -LiteralPath $controller -Raw -Encoding UTF8
$uiStarter = Get-Content -LiteralPath (Join-Path $root 'scripts\Start-CodebaseMemoryGraphUi.ps1') -Raw -Encoding UTF8

$tokens = $null; $errors = $null
[void][System.Management.Automation.Language.Parser]::ParseFile($controller, [ref]$tokens, [ref]$errors)
if ($errors) { throw "Verification controller has PowerShell syntax errors: $($errors | Out-String)" }
if ($content -notmatch "ValidateSet\('Auto','Fast','Balanced','Full'\)") { throw 'Verification controller must expose Auto, Fast, Balanced, and Full modes.' }
if ($content -notmatch 'codebase-memory-ui-preflight') { throw 'Fast verification must retain the Codebase Memory UI preflight.' }
if ($content -notmatch 'changed-script-syntax') { throw 'Fast verification must check changed script syntax.' }
if ($content -notmatch 'verification-last-run\.json') { throw 'Verification controller must record timing evidence by default.' }
if ($content -notmatch 'elapsed_wall_clock_seconds') { throw 'Verification controller must record end-to-end wall-clock timing.' }
if ($content -notmatch 'task_wall_clock_seconds') { throw 'Verification controller must record the complete task wall-clock time.' }
if ($content -notmatch 'host_reported_worked_seconds') { throw 'Verification controller must accept host-reported worked time.' }
if ($content -notmatch 'controller_wall_clock_seconds') { throw 'Verification controller must distinguish controller time from task time.' }
if ($content -notmatch 'operation_wall_clock_seconds') { throw 'Verification controller must expose local operation time separately.' }
if ($content -notmatch 'task_time_status') { throw 'Verification controller must label whether complete task timing was actually measured.' }
if ($content -notmatch 'caller-task-start-required') { throw 'Verification controller must refuse to infer complete task timing from controller start.' }
if ($content -notmatch "Balanced") { throw 'Verification controller must expose the balanced preliminary execution version.' }
if ($content -notmatch 'preliminary-evidence-only') { throw 'Balanced verification must declare that Full remains required for global closeout.' }
if ($content -notmatch 'unaccounted_time_seconds') { throw 'Verification controller must expose the gap between step timings and end-to-end time.' }
if ($content -notmatch 'verification_profiles') { throw 'Verification controller must use the resource policy verification profiles.' }
if ($content -notmatch 'high_risk_fallback') { throw 'Auto verification must retain a high-risk Full fallback.' }
if ($uiStarter -notmatch '(?s)\$health = \$null.*?Get-UiJson.*?Get-NetTCPConnection') { throw 'Codebase Memory UI starter must probe HTTP health before enumerating TCP listeners.' }

Write-Host 'Codex verification controller test passed.'
