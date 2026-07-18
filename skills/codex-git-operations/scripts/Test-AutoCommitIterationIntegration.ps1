$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
$iteration = Get-Content -LiteralPath (Join-Path $root 'scripts\Invoke-CompleteGlobalExperienceIteration.ps1') -Raw -Encoding UTF8
$commit = Get-Content -LiteralPath (Join-Path $root 'skills\codex-git-operations\scripts\Invoke-VerifiedPrivateCommit.ps1') -Raw -Encoding UTF8
if ($iteration -notmatch '\[switch\]\$AutoCommit') { throw 'Complete global iteration does not expose the AutoCommit gate.' }
if ($iteration -notmatch 'AutoCommit requires -Staged') { throw 'AutoCommit does not require an explicit staged scope.' }
if ($iteration -notmatch '-SkipCompleteIteration -CommitOnly') { throw 'AutoCommit does not reuse the verified iteration proof for local-only commit.' }
if ($commit -notmatch '\[switch\]\$CommitOnly') { throw 'Verified private commit does not expose local-only commit mode.' }
if ($commit -notmatch 'if \(-not \$CommitOnly\)') { throw 'Local-only commit mode does not protect the push boundary.' }
if ($commit -notmatch 'mixed worktree') { throw 'Verified private commit does not reject mixed worktrees.' }
Write-Host 'Auto-commit iteration integration test passed.'
