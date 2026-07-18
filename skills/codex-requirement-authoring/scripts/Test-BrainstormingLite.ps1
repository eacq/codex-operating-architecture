[CmdletBinding()]
param([string]$ProjectRoot)

$ErrorActionPreference = 'Stop'
if (-not $ProjectRoot) {
  $scriptRoot = $PSScriptRoot
  if (-not $scriptRoot) { $scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path }
  $ProjectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $scriptRoot))
}
$root = (Resolve-Path -LiteralPath $ProjectRoot).Path
$parent = Join-Path $root 'skills\codex-requirement-authoring\SKILL.md'
$subskill = Join-Path $root 'skills\codex-requirement-authoring\subskills\brainstorming-lite\SKILL.md'
foreach ($path in @($parent, $subskill)) {
  if (-not (Test-Path -LiteralPath $path)) { throw "Missing brainstorming contract: $path" }
}
$parentText = Get-Content -LiteralPath $parent -Raw -Encoding UTF8
$text = Get-Content -LiteralPath $subskill -Raw -Encoding UTF8
foreach ($needle in @('brainstorming-lite/SKILL.md', 'one concise question at a time', 'two or three feasible approaches', 'normalized requirement brief', 'does not treat brainstorming as implementation authorization', 'Stop questioning once remaining uncertainty is low-risk', 'autonomously route to `brainstorming-lite`', 'The global experience system may autonomously open this mode')) {
  if (($parentText + "`n" + $text) -notmatch [regex]::Escape($needle)) { throw "Brainstorming contract is missing: $needle" }
}
Write-Output 'Brainstorming Lite contract test passed.'
