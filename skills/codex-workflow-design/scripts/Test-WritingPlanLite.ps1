[CmdletBinding()]
param([string]$ProjectRoot = (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))))

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath $ProjectRoot).Path
$parent = Join-Path $root 'skills\codex-workflow-design\SKILL.md'
$subskill = Join-Path $root 'skills\codex-workflow-design\subskills\writing-plan-lite\SKILL.md'
foreach ($path in @($parent, $subskill)) {
  if (-not (Test-Path -LiteralPath $path)) { throw "Missing writing-plan contract: $path" }
}
$text = (Get-Content -LiteralPath $parent -Raw -Encoding UTF8) + "`n" + (Get-Content -LiteralPath $subskill -Raw -Encoding UTF8)
$normalizedText = [regex]::Replace($text, '\s+', ' ')
foreach ($needle in @('writing-plan-lite/SKILL.md', 'accepted design or normalized requirement', 'exact file paths, symbols, commands, and expected results only after confirming them locally', 'every acceptance criterion to a task and check', 'does not authorize execution', 'return the precise question or evidence task instead of creating a false-complete plan')) {
  if ($normalizedText -notmatch [regex]::Escape($needle)) { throw "Writing-plan contract is missing: $needle" }
}
Write-Output 'Writing Plan Lite contract test passed.'
