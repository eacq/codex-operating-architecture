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
if ($iteration -notmatch 'AutoCommit requires -Staged') { throw 'AutoCommit does not require an explicit staged scope.' }
if ($iteration -notmatch '-SkipCompleteIteration -CommitOnly') { throw 'AutoCommit does not reuse the verified iteration proof for local-only commit.' }
$gate = Get-Content -LiteralPath (Join-Path $root 'scripts\Test-ExperienceIterationGate.ps1') -Raw -Encoding UTF8
if ($gate -notmatch 'Candidate-only global iteration proof cannot satisfy the Git publication gate') { throw 'Git publication gate does not reject candidate-only proof.' }
if ($gate -notmatch 'ls-files --others --exclude-standard') { throw 'Git publication gate does not consider untracked paths in non-staged mode.' }
if ($commit -notmatch '\[switch\]\$CommitOnly') { throw 'Verified private commit does not expose local-only commit mode.' }
if ($commit -notmatch 'if \(-not \$CommitOnly\)') { throw 'Local-only commit mode does not protect the push boundary.' }
if ($commit -notmatch 'mixed worktree') { throw 'Verified private commit does not reject mixed worktrees.' }
Write-Host 'Auto-commit iteration integration test passed.'
