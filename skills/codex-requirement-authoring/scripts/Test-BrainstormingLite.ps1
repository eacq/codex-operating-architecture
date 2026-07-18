[CmdletBinding()]
param([string]$ProjectRoot = (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))))

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath $ProjectRoot).Path
$parent = Join-Path $root 'skills\codex-requirement-authoring\SKILL.md'
$subskill = Join-Path $root 'skills\codex-requirement-authoring\subskills\brainstorming-lite\SKILL.md'
foreach ($path in @($parent, $subskill)) {
  if (-not (Test-Path -LiteralPath $path)) { throw "Missing brainstorming contract: $path" }
}
$parentText = Get-Content -LiteralPath $parent -Raw -Encoding UTF8
$text = Get-Content -LiteralPath $subskill -Raw -Encoding UTF8
foreach ($needle in @('brainstorming-lite/SKILL.md', 'one concise question at a time', 'two or three feasible approaches', 'normalized requirement brief', 'does not treat brainstorming as implementation authorization', 'Stop questioning once remaining uncertainty is low-risk')) {
  if (($parentText + "`n" + $text) -notmatch [regex]::Escape($needle)) { throw "Brainstorming contract is missing: $needle" }
}
Write-Output 'Brainstorming Lite contract test passed.'
