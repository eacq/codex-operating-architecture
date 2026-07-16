[CmdletBinding()]
param(
    [string]$ProjectRoot = (Get-Location).Path,
    [string[]]$EvidencePaths,
    [switch]$Apply
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath $ProjectRoot).Path
$workflowPath = Join-Path $root '.codex\project\WORKFLOWS.md'
if (-not (Test-Path -LiteralPath $workflowPath)) { throw "Workflow authority is missing: $workflowPath" }
$content = Get-Content -LiteralPath $workflowPath -Raw -Encoding UTF8
$hash = (Get-FileHash -LiteralPath $workflowPath -Algorithm SHA256).Hash.ToLowerInvariant()
$skillsRoot = Join-Path $root 'skills'
$owners = if (Test-Path -LiteralPath $skillsRoot) { @(Get-ChildItem -LiteralPath $skillsRoot -Directory | Where-Object { $content -match [regex]::Escape($_.Name) } | ForEach-Object Name) } else { @() }
$record = [ordered]@{
    schema_version = 1
    workflow_path = '.codex/project/WORKFLOWS.md'
    workflow_sha256 = $hash
    related_owners = $owners
    evidence_paths = @($EvidencePaths)
    knowledge_status = if (@($EvidencePaths).Count -ge 1) { 'candidate-for-linked-knowledge' } else { 'workflow-only' }
    experience_status = if (@($EvidencePaths).Count -ge 2) { 'candidate-for-verified-experience' } else { 'needs-independent-evidence' }
    architecture_action = 'compare triggers, artifacts, ownership, and safety boundaries before revise, merge, split, add, deprecate, or delete'
    raw_workflow_stored = $false
}
if ($Apply) {
    $recordPath = Join-Path $root '.codex\project\workflow-learning.json'
    $record | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $recordPath -Encoding UTF8
}
$record | ConvertTo-Json -Depth 6
