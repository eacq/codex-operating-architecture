$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
$script = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'Invoke-ExperienceChangeCloseout.ps1') -Raw -Encoding UTF8

if ($script -notmatch 'Get-CodexGitChangedPaths\.ps1') { throw 'Closeout wrapper does not use the shared changed-path collector.' }
if ($script -notmatch 'Invoke-CodexVerification\.ps1') { throw 'Closeout wrapper does not run the fast verification preflight.' }
if ($script -notmatch 'New-GlobalIterationCandidateReport\.ps1') { throw 'Closeout wrapper does not refresh the candidate report.' }
if ($script -notmatch 'unknown-status node') { throw 'Closeout wrapper does not block malformed knowledge front matter.' }
if ($script -notmatch 'Invoke-VerifiedPrivateCommit\.ps1') { throw 'Closeout wrapper does not delegate to the verified private commit controller.' }
if ($script -notmatch 'Convert-JsonOutput') { throw 'Closeout wrapper does not handle noisy controller output.' }
if ($script -notmatch 'if \(\$Push\)' -or $script -notmatch '-CommitOnly -Apply' -or $script -notmatch '-CommitOnly\)') { throw 'Closeout wrapper is not local-only by default.' }
if ($script -notmatch 'needs-metadata-or-authorization' -or $script -notmatch 'commitPlan\.eligible') { throw 'Closeout wrapper dry-run does not surface verified-commit readiness blockers.' }
if ($script -match 'validate\.ps1') { throw 'Closeout wrapper should not add duplicate full validation before the commit controller gate.' }
if ($script -notmatch 'avoids_manual_duplicate_full_validation') { throw 'Closeout wrapper does not document the economy boundary.' }

Write-Host 'Experience change closeout wrapper test passed.'
