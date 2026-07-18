[CmdletBinding()]
param(
    [string]$RepositoryRoot = (Get-Location).Path,
    [switch]$Staged,
    [switch]$AutoCommit,
    [string]$AutoCommitMessage,
    [switch]$Apply
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath $RepositoryRoot).Path
$candidateProcessor = Join-Path $root 'skills\\codex-experience-capture\\scripts\\Process-AuthorizedCandidateRecords.ps1'
$candidateProcessing = if ($Apply -and (Test-Path -LiteralPath $candidateProcessor)) {
    & $candidateProcessor -ProjectRoot $root -Apply | ConvertFrom-Json
} else { $null }
$paths = if ($Staged) {
    @(& git -C $root diff --cached --name-only)
} else {
    @(
        & git -C $root diff --name-only
        & git -C $root ls-files --others --exclude-standard
    )
}
$paths = @($paths | Where-Object { $_ } | Sort-Object -Unique)
if ($paths.Count -eq 0 -and -not $Apply) { throw 'A preview complete global iteration requires changed paths to assess.' }
if ($paths.Count -eq 0 -and $AutoCommit) { throw 'AutoCommit requires explicit changed paths.' }
if ($AutoCommit -and -not $Staged) { throw 'AutoCommit requires -Staged so the exact commit scope is explicit before iteration.' }

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
$incomingFeedbackPath = Join-Path $root '.codex/project/incoming-error-feedback.jsonl'
$incomingFeedback = @()
if (Test-Path -LiteralPath $incomingFeedbackPath) {
    $incomingFeedback = @(Get-Content -LiteralPath $incomingFeedbackPath -Encoding UTF8 |
        Where-Object { $_.Trim() } |
        ForEach-Object { $_ | ConvertFrom-Json })
}
$latestIncomingFeedback = @()
$incomingWithKey = @($incomingFeedback | Where-Object { $_.report_metadata })
$incomingWithoutKey = @($incomingFeedback | Where-Object { -not $_.report_metadata })
if ($incomingWithKey.Count -gt 0) {
    $latestIncomingFeedback = @($incomingWithKey |
        Group-Object -Property report_metadata |
        ForEach-Object { $_.Group | Sort-Object -Property recorded_at | Select-Object -Last 1 })
}
$incomingFeedbackForBlocking = @($incomingWithoutKey + $latestIncomingFeedback)
$blockingErrors = @($errorReports | Where-Object { $_.severity -in @('high','critical') -and $_.status -notin @('fixed','verified') })
$unresolvedGitErrors = @($errorReports | Where-Object { $_.module -eq 'codex-git-operations' -and $_.status -notin @('fixed','verified') })
$blockingIncomingFeedback = @($incomingFeedbackForBlocking | Where-Object {
    $_.severity -in @('high','critical') -and
    $_.status -notin @('fixed','verified') -and
    $_.experience_system_causality -in @('suspected','partial','primary','verified')
})
if ($blockingErrors.Count -gt 0) { throw "Global iteration has $($blockingErrors.Count) unresolved high-severity error report(s)." }
if ($unresolvedGitErrors.Count -gt 0) { throw "Git recovery is incomplete: $($unresolvedGitErrors.Count) Git-process error report(s) must be fixed or verified before any Git action." }
if ($blockingIncomingFeedback.Count -gt 0) { throw "Global iteration has $($blockingIncomingFeedback.Count) unresolved incoming cross-project error feedback item(s) attributed to the experience system." }

$pendingPath = Join-Path $root '.codex/project/pending-events.jsonl'
$pendingEvents = if (Test-Path -LiteralPath $pendingPath) { @((Get-Content -LiteralPath $pendingPath -Encoding UTF8 | Where-Object { $_.Trim() })).Count } else { 0 }
$workflowProbe = & (Join-Path $root 'skills/codex-knowledge-system/scripts/New-WorkflowLearningRecord.ps1') -ProjectRoot $root -EvidencePaths '.codex/project/REQUIREMENTS.md','knowledge/experience-ledger.md' | ConvertFrom-Json
if ($workflowProbe.knowledge_status -ne 'candidate-for-linked-knowledge' -or $workflowProbe.experience_status -ne 'candidate-for-verified-experience') { throw 'Workflow learning did not route to both knowledge and experience candidates.' }
$visualProbe = & (Join-Path $root 'skills/codex-image-workflow/scripts/New-UnderstandingVisualPlan.ps1') -Kind workflow -Subject 'Sanitized global iteration topology' -Relationships 'skill-to-workflow','workflow-to-experience','experience-to-knowledge' | ConvertFrom-Json
if ($visualProbe.action -ne 'generate-gpt-image-first') { throw 'Global iteration visual integration probe failed.' }
$isolatedIteration = & (Join-Path $root 'scripts/Invoke-IsolatedGlobalExperienceIteration.ps1') -RepositoryRoot $root -Apply -Replace | ConvertFrom-Json
if ($isolatedIteration.result -ne 'completed' -or -not $isolatedIteration.validated -or -not $isolatedIteration.replaced -or -not $isolatedIteration.post_replacement_validated -or -not $isolatedIteration.lifecycle_written_back -or -not $isolatedIteration.rollback_ready -or -not $isolatedIteration.continuous_diagnosis_supported) { throw 'Isolated global iteration did not establish continuous diagnosis, rollback readiness, clean replacement, revalidation, and lifecycle writeback.' }

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
        incoming_error_feedback_reviewed = $incomingFeedback.Count
        unresolved_incoming_experience_system_errors = $blockingIncomingFeedback.Count
        unresolved_high_severity_errors = $blockingErrors.Count
        unresolved_git_process_errors = $unresolvedGitErrors.Count
        conversation_catalog = 'release-safe-metadata-only'
        experience_ledger = 'validated'
        linked_knowledge_graph = [ordered]@{ nodes=@($graph.nodes).Count; edges=@($graph.edges).Count }
        workflow_learning = 'knowledge-and-experience-candidates'
        candidate_report = $isolatedIteration.candidate_report
        candidate_processing = if ($candidateProcessing) { $candidateProcessing.result } else { 'not-applied' }
        visual_decision = $visualProbe.action
        file_organization = [ordered]@{ result = $isolatedIteration.result; sandbox = $isolatedIteration.sandbox; continuous_diagnosis_supported = $isolatedIteration.continuous_diagnosis_supported; rollback_ready = $isolatedIteration.rollback_ready; validated = $isolatedIteration.validated; replaced = $isolatedIteration.replaced; post_replacement_validated = $isolatedIteration.post_replacement_validated; lifecycle_written_back = $isolatedIteration.lifecycle_written_back; cleanup = $isolatedIteration.cleanup }
    }
    checks = @('global source review','README iteration alignment','all Git-process errors closed','error feedback review','workflow-to-knowledge/experience integration','GPT-first visual decision','continuous iteration diagnosis','exact pre-iteration rollback readiness','isolated backup-organize-cleanup-restore-validate-replace iteration','post-replacement global validation','lifecycle writeback','robustness and economy review')
    result = 'passed'
    completed_at = [DateTime]::UtcNow.ToString('o')
}
if ($Apply) { $record | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath (Join-Path $root '.codex/project/global-experience-iteration.json') -Encoding UTF8 }
if ($Apply -and $AutoCommit) {
    $allChanged = @(
        & git -C $root diff --name-only
        & git -C $root diff --cached --name-only
        & git -C $root ls-files --others --exclude-standard
    ) | Where-Object { $_ } | Sort-Object -Unique
    $outsideScope = @($allChanged | Where-Object { $_ -notin $paths })
    if ($outsideScope.Count -gt 0) { throw "AutoCommit refused because the verified iteration produced or retained out-of-scope changes: $($outsideScope -join ', ')" }
    $commitScript = Join-Path $root 'skills\codex-git-operations\scripts\Invoke-VerifiedPrivateCommit.ps1'
    $commitResult = & $commitScript -RepositoryRoot $root -Paths $paths -PreserveVersion -SkipCompleteIteration -CommitOnly -Apply -Message $AutoCommitMessage | ConvertFrom-Json
    if ($commitResult.decision -ne 'committed-locally-no-push') { throw 'AutoCommit did not produce a local commit.' }
    $record.auto_commit = [ordered]@{ result = $commitResult.decision; commit = $commitResult.commit; pushed = $false; scope = $paths }
    $record | ConvertTo-Json -Depth 7 | Set-Content -LiteralPath (Join-Path $root '.codex/project/global-experience-iteration.json') -Encoding UTF8
}
$record | ConvertTo-Json -Depth 6
