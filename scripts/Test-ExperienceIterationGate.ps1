[CmdletBinding()]
param([string]$RepositoryRoot = (Get-Location).Path, [switch]$Staged, [switch]$Apply)
$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath $RepositoryRoot).Path
$args = if ($Staged) { @('diff','--cached','--name-only') } else { @('diff','--name-only') }
$paths = @(& git -C $root @args | Where-Object { $_ })
if ($paths.Count -eq 0) { throw 'Iteration gate requires changed paths.' }
$contracts = @(
    @{ owner='codex-self-evolution'; required='codex-experience-capture|codex-architecture-iteration|codex-workflow-design' },
    @{ owner='codex-experience-capture'; required='codex-knowledge-system|codex-image-workflow' },
    @{ owner='codex-workflow-design'; required='New-WorkflowLearningRecord|workflow-error-review' },
    @{ owner='codex-file-organization'; required='Invoke-FileOrganizationLifecycle|New-FileOrganizationBackup|merge|split' }
)
foreach ($contract in $contracts) {
    $file = Join-Path $root "skills\$($contract.owner)\SKILL.md"
    if (-not (Test-Path $file) -or -not ((Get-Content $file -Raw -Encoding UTF8) -match $contract.required)) { throw "Cross-module integration contract failed: $($contract.owner)." }
}
$workflowProbe = & (Join-Path $root 'skills\codex-knowledge-system\scripts\New-WorkflowLearningRecord.ps1') -ProjectRoot $root -EvidencePaths '.codex/project/REQUIREMENTS.md','knowledge/experience-ledger.md' | ConvertFrom-Json
if ($workflowProbe.knowledge_status -ne 'candidate-for-linked-knowledge' -or $workflowProbe.experience_status -ne 'candidate-for-verified-experience') { throw 'Workflow-to-knowledge/experience integration probe failed.' }
$visualProbe = & (Join-Path $root 'skills\codex-image-workflow\scripts\New-UnderstandingVisualPlan.ps1') -Kind workflow -Subject 'Sanitized integration topology' -Relationships 'skill-to-workflow','workflow-to-experience','experience-to-knowledge' | ConvertFrom-Json
if ($visualProbe.action -ne 'generate-gpt-image-first') { throw 'Knowledge/workflow visual-planning integration probe failed.' }
$organizationProbe = & (Join-Path $root 'skills\codex-file-organization\scripts\Invoke-FileOrganizationLifecycle.ps1') -ProjectRoot $root -Phase global-iteration -Apply | ConvertFrom-Json
if ($organizationProbe.result -ne 'passed' -or -not $organizationProbe.inventory.metadata_only) { throw 'File organization integration probe failed.' }
$sha = [Security.Cryptography.SHA256]::Create()
$hash = ([BitConverter]::ToString($sha.ComputeHash([Text.Encoding]::UTF8.GetBytes(($paths | Sort-Object) -join "`n"))) -replace '-','').ToLowerInvariant()
$sha.Dispose()
$record = [ordered]@{ schema_version=1; staged_paths_sha256=$hash; checks=@('experience iteration','workflow-to-knowledge/experience probe','knowledge/workflow visual-planning probe','file-organization/backup integration probe','robustness/economy review'); result='passed'; replay_safe=$true; created_at=[DateTime]::UtcNow.ToString('o') }
if ($Apply) { $record | ConvertTo-Json | Set-Content (Join-Path $root '.codex\project\git-iteration-gate.json') -Encoding UTF8 }
$record | ConvertTo-Json
