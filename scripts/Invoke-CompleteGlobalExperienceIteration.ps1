[CmdletBinding()]
param(
    [string]$RepositoryRoot = (Get-Location).Path,
    [switch]$Staged,
    [switch]$Apply
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath $RepositoryRoot).Path
$gitArgs = if ($Staged) { @('diff','--cached','--name-only') } else { @('diff','--name-only') }
$paths = @(& git -C $root @gitArgs | Where-Object { $_ } | Sort-Object -Unique)
if ($paths.Count -eq 0) { throw 'A complete global iteration requires changed paths to assess.' }

function Get-Sha256([string[]]$Values) {
    $sha = [Security.Cryptography.SHA256]::Create()
    try {
        $bytes = [Text.Encoding]::UTF8.GetBytes(($Values | Sort-Object) -join "`n")
        $hex = [BitConverter]::ToString($sha.ComputeHash($bytes))
        return ($hex -replace '-','').ToLowerInvariant()
    }
    finally { $sha.Dispose() }
}

$requiredLifecycle = @('.codex/project/REQUIREMENTS.md','.codex/project/WORKFLOWS.md','.codex/project/EXPERIENCE.md','.codex/project/RETROSPECTIVES.md','.codex/project/state.json')
foreach ($relative in $requiredLifecycle) { if (-not (Test-Path -LiteralPath (Join-Path $root $relative))) { throw "Global iteration missing lifecycle authority: $relative" } }

$catalogPath = Join-Path $root 'knowledge/history-catalog.json'
$catalog = Get-Content -LiteralPath $catalogPath -Raw -Encoding UTF8 | ConvertFrom-Json
if ($catalog.privacy -notmatch 'Release-safe' -or [int]$catalog.session_count -ne 0) { throw 'Global iteration requires a release-safe metadata-only conversation catalog.' }
$graphPath = Join-Path $root 'knowledge-vault/00-Home/graph.json'
$graph = Get-Content -LiteralPath $graphPath -Raw -Encoding UTF8 | ConvertFrom-Json
if (@($graph.nodes).Count -eq 0 -or @($graph.edges).Count -eq 0) { throw 'Linked knowledge graph is empty or invalid.' }
if (-not (Test-Path -LiteralPath (Join-Path $root 'knowledge/experience-ledger.md'))) { throw 'Global experience ledger is missing.' }
& (Join-Path $root 'scripts/Test-ReadmeIterationAlignment.ps1') -RepositoryRoot $root | Out-Null

$errorReports = @(Get-ChildItem -LiteralPath (Join-Path $root '.codex/errors') -Filter report.json -Recurse -File | ForEach-Object { Get-Content -LiteralPath $_.FullName -Raw -Encoding UTF8 | ConvertFrom-Json })
$blockingErrors = @($errorReports | Where-Object { $_.severity -in @('high','critical') -and $_.status -notin @('fixed','verified') })
$unresolvedGitErrors = @($errorReports | Where-Object { $_.module -eq 'codex-git-operations' -and $_.status -notin @('fixed','verified') })
if ($blockingErrors.Count -gt 0) { throw "Global iteration has $($blockingErrors.Count) unresolved high-severity error report(s)." }
if ($unresolvedGitErrors.Count -gt 0) { throw "Git recovery is incomplete: $($unresolvedGitErrors.Count) Git-process error report(s) must be fixed or verified before any Git action." }

$pendingPath = Join-Path $root '.codex/project/pending-events.jsonl'
$pendingEvents = if (Test-Path -LiteralPath $pendingPath) { @((Get-Content -LiteralPath $pendingPath -Encoding UTF8 | Where-Object { $_.Trim() })).Count } else { 0 }
$workflowProbe = & (Join-Path $root 'skills/codex-knowledge-system/scripts/New-WorkflowLearningRecord.ps1') -ProjectRoot $root -EvidencePaths '.codex/project/REQUIREMENTS.md','knowledge/experience-ledger.md' | ConvertFrom-Json
if ($workflowProbe.knowledge_status -ne 'candidate-for-linked-knowledge' -or $workflowProbe.experience_status -ne 'candidate-for-verified-experience') { throw 'Workflow learning did not route to both knowledge and experience candidates.' }
$visualProbe = & (Join-Path $root 'skills/codex-image-workflow/scripts/New-UnderstandingVisualPlan.ps1') -Kind workflow -Subject 'Sanitized global iteration topology' -Relationships 'skill-to-workflow','workflow-to-experience','experience-to-knowledge' | ConvertFrom-Json
if ($visualProbe.action -ne 'generate-gpt-image-first') { throw 'Global iteration visual integration probe failed.' }
$isolatedIteration = & (Join-Path $root 'scripts/Invoke-IsolatedGlobalExperienceIteration.ps1') -RepositoryRoot $root -Apply -Replace | ConvertFrom-Json
if ($isolatedIteration.result -ne 'completed' -or -not $isolatedIteration.validated -or -not $isolatedIteration.replaced) { throw 'Isolated global iteration did not validate and replace the active architecture.' }

$record = [ordered]@{
    schema_version = 1
    head_at_start = (& git -C $root rev-parse HEAD).Trim()
    staged = [bool]$Staged
    staged_paths_sha256 = Get-Sha256 $paths
    changed_paths = $paths
    sources = [ordered]@{
        lifecycle_authority = 'validated'
        pending_events = $pendingEvents
        error_reports_reviewed = $errorReports.Count
        unresolved_high_severity_errors = $blockingErrors.Count
        unresolved_git_process_errors = $unresolvedGitErrors.Count
        conversation_catalog = 'release-safe-metadata-only'
        experience_ledger = 'validated'
        linked_knowledge_graph = [ordered]@{ nodes=@($graph.nodes).Count; edges=@($graph.edges).Count }
        workflow_learning = 'knowledge-and-experience-candidates'
        visual_decision = $visualProbe.action
        file_organization = [ordered]@{ result = $isolatedIteration.result; sandbox = $isolatedIteration.sandbox; validated = $isolatedIteration.validated; replaced = $isolatedIteration.replaced }
    }
    checks = @('global source review','README iteration alignment','all Git-process errors closed','error feedback review','workflow-to-knowledge/experience integration','GPT-first visual decision','isolated backup-organize-restore-validate-replace iteration','robustness and economy review')
    result = 'passed'
    completed_at = [DateTime]::UtcNow.ToString('o')
}
if ($Apply) { $record | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath (Join-Path $root '.codex/project/global-experience-iteration.json') -Encoding UTF8 }
$record | ConvertTo-Json -Depth 6
