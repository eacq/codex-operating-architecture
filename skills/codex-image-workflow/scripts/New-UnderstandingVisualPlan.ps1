[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)] [string]$Subject,
    [ValidateSet('knowledge','experience','workflow')] [string]$Kind,
    [string[]]$Relationships = @(),
    [string[]]$PrivateTerms = @(),
    [ValidateSet('new','changed','removed')] [string]$Change = 'new',
    [switch]$Apply
)

$ErrorActionPreference = 'Stop'
$privatePattern = '(?i)(api[_-]?key|token|secret|password|cookie|auth\.json|[A-Za-z]:\\Users\\|https?://[^/\s]+@)'
$joined = @($Subject) + $Relationships + $PrivateTerms -join "`n"
if ($joined -match $privatePattern) { throw 'Visual-plan input contains private or credential-like content; summarize it before image generation.' }
$complexity = @($Relationships | Where-Object { $_ }).Count
$action = if ($Change -eq 'removed') { 'delete-or-unlink-visual' } elseif ($complexity -ge 3) { 'generate-gpt-image-first' } elseif ($complexity -ge 2) { 'use-svg-or-mermaid' } else { 'no-visual-required' }
$plan = [ordered]@{ kind = $Kind; action = $action; privacy = 'Use a sanitized abstract summary only; never send raw workflow, local paths, remote identities, credentials, sessions, or user data to image generation.'; readability = 'One idea per visual, clear hierarchy, readable labels, no decorative clutter.'; change_handling = if ($Change -eq 'changed') { 'Compare semantic structure: edit when topology is stable, regenerate when topology changes, delete when no longer useful.' } else { 'Create only when it materially improves comprehension.' } }
if ($Apply) { $plan | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath (Join-Path (Get-Location) '.codex\project\visual-plan.json') -Encoding UTF8 }
$plan | ConvertTo-Json -Depth 4
