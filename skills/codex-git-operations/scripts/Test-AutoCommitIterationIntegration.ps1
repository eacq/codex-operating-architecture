$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
$iteration = Get-Content -LiteralPath (Join-Path $root 'scripts\Invoke-CompleteGlobalExperienceIteration.ps1') -Raw -Encoding UTF8
$commit = Get-Content -LiteralPath (Join-Path $root 'skills\codex-git-operations\scripts\Invoke-VerifiedPrivateCommit.ps1') -Raw -Encoding UTF8
if ($iteration -notmatch '\[switch\]\$AutoCommit') { throw 'Complete global iteration does not expose the AutoCommit gate.' }
if ($iteration -notmatch '\[switch\]\$CandidateOnly') { throw 'Complete global iteration does not expose the candidate-only fast path.' }
if ($iteration -notmatch 'full Git worktree has no tracked, staged, or untracked repository changes') { throw 'Candidate-only mode does not reject repository changes.' }
if ($iteration -notmatch 'step_timings') { throw 'Complete global iteration does not record timing telemetry.' }
$isolated = Get-Content -LiteralPath (Join-Path $root 'scripts\Invoke-IsolatedGlobalExperienceIteration.ps1') -Raw -Encoding UTF8
if ($isolated -notmatch 'step_timings') { throw 'Isolated global iteration does not record internal timing telemetry.' }
if ($isolated -notmatch 'validate replaced global system pass 1') { throw 'Isolated global iteration does not split post-replacement validation timing.' }
if ($isolated -notmatch 'LightweightDirectoryCleanup') { throw 'Isolated global iteration does not use lightweight active cleanup.' }
if ($isolated -notmatch 'Copy-ChangedPathOverlay') { throw 'Isolated global iteration does not use changed-path sandbox overlay.' }
if ($isolated -match 'robocopy \$root \$sandbox') { throw 'Isolated global iteration still overlays the full active tree into the sandbox.' }
if ($iteration -notmatch 'AutoCommit requires -Staged') { throw 'AutoCommit does not require an explicit staged scope.' }
if ($iteration -notmatch '-SkipCompleteIteration -CommitOnly') { throw 'AutoCommit does not reuse the verified iteration proof for local-only commit.' }
$cleanup = Get-Content -LiteralPath (Join-Path $root 'skills\codex-file-organization\scripts\Remove-UnnecessaryOrganizationArtifacts.ps1') -Raw -Encoding UTF8
if ($cleanup -notmatch 'ls-files --others --ignored --exclude-standard') { throw 'Cleanup does not consider ignored disposable cache files.' }
if ($cleanup -notmatch 'candidate-parents-only') { throw 'Cleanup does not expose candidate-parent directory cleanup telemetry.' }
$rollback = Get-Content -LiteralPath (Join-Path $root 'skills\codex-file-organization\scripts\New-PreIterationRollbackSnapshot.ps1') -Raw -Encoding UTF8
if ($rollback -notmatch 'git-tracked-untracked-ignored') { throw 'Rollback snapshot does not record Git-backed file inventory.' }
if ($rollback -notmatch 'robocopy-filtered-tree') { throw 'Rollback snapshot does not record filtered robocopy copy engine.' }
if ($rollback -notmatch 'private-skill-config') { throw 'Rollback snapshot does not exclude private local profile roots.' }
$gate = Get-Content -LiteralPath (Join-Path $root 'scripts\Test-ExperienceIterationGate.ps1') -Raw -Encoding UTF8
if ($gate -notmatch 'Candidate-only global iteration proof cannot satisfy the Git publication gate') { throw 'Git publication gate does not reject candidate-only proof.' }
if ($gate -notmatch 'ls-files --others --exclude-standard') { throw 'Git publication gate does not consider untracked paths in non-staged mode.' }
if ($commit -notmatch '\[switch\]\$CommitOnly') { throw 'Verified private commit does not expose local-only commit mode.' }
if ($commit -notmatch 'if \(-not \$CommitOnly\)') { throw 'Local-only commit mode does not protect the push boundary.' }
if ($commit -notmatch 'mixed worktree') { throw 'Verified private commit does not reject mixed worktrees.' }
if ($commit -notmatch 'publication-envelope\.json') { throw 'Verified private commit does not write a publication envelope.' }
if ($commit -notmatch 'Test-CurrentCompleteIterationProof') { throw 'Verified private commit cannot reuse a current complete iteration proof.' }
if ($commit -notmatch 'staged-git-paths-only') { throw 'Publication envelope does not define a staged-only publication surface.' }
$metadata = Get-Content -LiteralPath (Join-Path $root 'scripts\Test-GitPublicationMetadata.ps1') -Raw -Encoding UTF8
if ($metadata -notmatch 'publication-envelope\.json') { throw 'Publication metadata gate does not require the publication envelope.' }
if ($metadata -notmatch 'local/private-state boundary') { throw 'Publication metadata gate does not verify the publication privacy boundary.' }
$validate = Get-Content -LiteralPath (Join-Path $root 'scripts\validate.ps1') -Raw -Encoding UTF8
if ($validate -notmatch 'validate_skills\.py') { throw 'Repository validation does not use the batch skill validator.' }
$scan = Get-Content -LiteralPath (Join-Path $root 'scripts\scan_repository.py') -Raw -Encoding UTF8
if ($scan -notmatch 'ls-files') { throw 'Repository scan does not use Git path authority.' }
if ($scan -notmatch 'iter_filesystem_candidate_files') { throw 'Repository scan does not keep a filesystem fallback.' }
if ($scan -notmatch 'EXCLUDED') { throw 'Repository scan does not preserve protected-root exclusions.' }
Write-Host 'Auto-commit iteration integration test passed.'
