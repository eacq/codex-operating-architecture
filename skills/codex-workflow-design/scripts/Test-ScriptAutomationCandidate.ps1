$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
$fixture = & (Join-Path $root 'scripts\Resolve-CodexRunRoot.ps1') -ArchitectureRoot $root -Kind tmp -ChildPath ('script-automation-candidate-' + [guid]::NewGuid().ToString('N')) -Create
$script = Join-Path $root 'skills\codex-workflow-design\scripts\New-ScriptAutomationCandidate.ps1'

try {
    New-Item -ItemType Directory -Force -Path (Join-Path $fixture '.codex\project') | Out-Null
    $eligible = & $script -ProjectRoot $fixture -Owner 'codex-workflow-design' -Name 'Repeated status probe' -Trigger 'Repeated local status review' -ObservedOccurrences 2 -Inputs @('repository root') -Validation 'Inspect JSON result' -Language PowerShell -Apply | ConvertFrom-Json
    if ($eligible.status -ne 'eligible-for-script-trial' -or -not (Test-Path -LiteralPath (Join-Path $fixture $eligible.path))) { throw 'Eligible local automation candidate was not recorded.' }
    $restricted = & $script -ProjectRoot $fixture -Owner 'codex-git-operations' -Name 'Remote publish' -Trigger 'Release request' -ObservedOccurrences 3 -Inputs @('remote','tag') -Validation 'Remote release query' -Risk ExternalOrIrreversible | ConvertFrom-Json
    if ($restricted.status -ne 'requires-explicit-authorization') { throw 'External automation candidate bypassed the authorization boundary.' }
    $portable = & $script -ProjectRoot $fixture -Owner 'codex-workflow-design' -Name 'Portable profiler' -Trigger 'Measured script hotspot' -ObservedOccurrences 2 -Inputs @('timing record') -Validation 'Fixture output' -Language Rust | ConvertFrom-Json
    if ($portable.language -ne 'Rust' -or $portable.script_trial_rule -notmatch 'first-class owner asset') { throw 'Automation candidate did not retain the language or script-asset contract.' }
    Write-Host 'Script automation candidate test passed.'
}
finally {
    if (Test-Path -LiteralPath $fixture) { Remove-Item -LiteralPath $fixture -Recurse -Force }
}
