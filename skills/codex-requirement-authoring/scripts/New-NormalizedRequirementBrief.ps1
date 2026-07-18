[CmdletBinding()]
param(
  [string]$ProjectRoot = (Get-Location).Path,
  [Parameter(Mandatory)][string]$Goal,
  [string[]]$Constraints = @(),
 [string[]]$Assumptions = @(),
 [string[]]$Exclusions = @(),
  [string[]]$Vocabulary = @(),
  [string[]]$Decisions = @(),
 [string[]]$AcceptanceCriteria = @(),
  [string[]]$Validation = @(),
  [string]$Authority = 'ordinary local implementation only; external, destructive, credential, paid, and public actions remain separately gated',
  [switch]$Apply
)
$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath $ProjectRoot).Path
$brief = [ordered]@{
  schema_version = 1
  created_at = [DateTime]::UtcNow.ToString('o')
  goal = $Goal
  constraints = @($Constraints)
  assumptions = @($Assumptions)
 exclusions = @($Exclusions)
  vocabulary = @($Vocabulary)
  decisions = @($Decisions)
 authority = $Authority
  acceptance_criteria = @($AcceptanceCriteria)
  validation = @($Validation)
  state = 'execution-ready'
}
if ($Apply) {
  $out = Join-Path $root '.codex\project\requirement-briefs'
  New-Item -ItemType Directory -Force -Path $out | Out-Null
  $json = Join-Path $out 'latest.json'; $markdown = Join-Path $out 'latest.md'
  [IO.File]::WriteAllText($json, (($brief | ConvertTo-Json -Depth 6) + [Environment]::NewLine), [Text.UTF8Encoding]::new($false))
 $lines = @('# Normalized Requirement Brief', '', "Goal: $Goal", '', '## Constraints') + @($Constraints | ForEach-Object { "- $_" }) + @('', '## Assumptions') + @($Assumptions | ForEach-Object { "- $_" }) + @('', '## Exclusions') + @($Exclusions | ForEach-Object { "- $_" }) + @('', '## Authority', '', $Authority, '', '## Acceptance Criteria') + @($AcceptanceCriteria | ForEach-Object { "- $_" }) + @('', '## Validation') + @($Validation | ForEach-Object { "- $_" })
  $lines = @('# Normalized Requirement Brief', '', "Goal: $Goal", '', '## Constraints') + @($Constraints | ForEach-Object { "- $_" }) + @('', '## Assumptions') + @($Assumptions | ForEach-Object { "- $_" }) + @('', '## Exclusions') + @($Exclusions | ForEach-Object { "- $_" }) + @('', '## Vocabulary') + @($Vocabulary | ForEach-Object { "- $_" }) + @('', '## Consequential Decisions') + @($Decisions | ForEach-Object { "- $_" }) + @('', '## Authority', '', $Authority, '', '## Acceptance Criteria') + @($AcceptanceCriteria | ForEach-Object { "- $_" }) + @('', '## Validation') + @($Validation | ForEach-Object { "- $_" })
  [IO.File]::WriteAllText($markdown, (($lines -join [Environment]::NewLine) + [Environment]::NewLine), [Text.UTF8Encoding]::new($false))
  $brief.output = [ordered]@{ json='.codex/project/requirement-briefs/latest.json'; markdown='.codex/project/requirement-briefs/latest.md' }
}
$brief | ConvertTo-Json -Depth 6
