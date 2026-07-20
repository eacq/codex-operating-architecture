$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$localRuntimeConfig = Join-Path $root '.codex\project\validation-runtime.json'
$configuredPython = if (Test-Path -LiteralPath $localRuntimeConfig) {
    (Get-Content -LiteralPath $localRuntimeConfig -Raw -Encoding UTF8 | ConvertFrom-Json).python_path
} else { $null }
$pythonCandidates = @(
    $env:CODEX_PYTHON,
    $configuredPython,
    (Join-Path $root '.runtime\envs\codex-foundation\python.exe'),
    'python'
) | Where-Object { $_ } | Select-Object -Unique
$python = $null
foreach ($candidate in $pythonCandidates) {
    if ([IO.Path]::IsPathRooted($candidate) -and -not (Test-Path -LiteralPath $candidate)) { continue }
    $previousErrorAction = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    & $candidate -c "import yaml" 2>$null
    $candidateExitCode = $LASTEXITCODE
    $ErrorActionPreference = $previousErrorAction
    if ($candidateExitCode -eq 0) { $python = $candidate; break }
}
$validator = if ($env:CODEX_SKILL_VALIDATOR) { $env:CODEX_SKILL_VALIDATOR } else { Join-Path $HOME '.codex\skills\.system\skill-creator\scripts\quick_validate.py' }
$env:PYTHONUTF8 = '1'
if (-not $python) { throw 'No validation Python runtime can import PyYAML. Set CODEX_PYTHON or write a local-only .codex/project/validation-runtime.json python_path.' }

$batchSkillValidator = Join-Path $PSScriptRoot 'validate_skills.py'
if (Test-Path -LiteralPath $batchSkillValidator) {
    & $python $batchSkillValidator (Join-Path $PSScriptRoot '..\skills')
    if ($LASTEXITCODE -ne 0) { throw 'Skill validation failed.' }
} else {
    $failed = @()
    Get-ChildItem -LiteralPath (Join-Path $PSScriptRoot '..\skills') -Directory | ForEach-Object {
        & $python $validator $_.FullName
        if ($LASTEXITCODE -ne 0) { $failed += $_.Name }
    }
    if ($failed.Count -gt 0) { throw "Skill validation failed: $($failed -join ', ')" }
}
& $python (Join-Path $PSScriptRoot 'index_history.py')
if ($LASTEXITCODE -ne 0) { throw 'History indexing failed.' }
& $python (Join-Path $PSScriptRoot 'scan_repository.py')
if ($LASTEXITCODE -ne 0) { throw 'Repository placeholder or secret scan failed.' }
$registry = Get-Content -LiteralPath (Join-Path $root 'module-registry.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$registered = @($registry.modules | ForEach-Object name | Sort-Object)
$skillNames = @(Get-ChildItem -LiteralPath (Join-Path $root 'skills') -Directory | ForEach-Object Name | Sort-Object)
$delta = Compare-Object $registered $skillNames
if ($delta) { throw "Module registry differs from skill folders: $($delta | Out-String)" }
& (Join-Path $root 'scripts\Test-SkillNameMigrations.ps1') -RepositoryRoot $root
if (-not $?) { throw 'Skill-name migration validation failed.' }
$runtimeManager = Join-Path $root 'skills\codex-runtime-environments\scripts\Manage-CodexEnvironment.ps1'
$parseErrors = $null
[System.Management.Automation.Language.Parser]::ParseFile($runtimeManager, [ref]$null, [ref]$parseErrors) | Out-Null
if ($parseErrors) { throw "Runtime environment manager has PowerShell syntax errors: $($parseErrors | Out-String)" }
& $runtimeManager status | Out-Null
if ($LASTEXITCODE -ne 0) { throw 'Runtime environment status check failed.' }
Get-Content -LiteralPath (Join-Path $root 'runtime-environments\tool-profiles.json') -Raw -Encoding UTF8 | ConvertFrom-Json | Out-Null
& $runtimeManager profiles | Out-Null
if ($LASTEXITCODE -ne 0) { throw 'Runtime environment profile check failed.' }
Get-ChildItem -LiteralPath (Join-Path $root 'skills') -Recurse -Filter '*.ps1' | ForEach-Object {
    $scriptParseErrors = $null
    [System.Management.Automation.Language.Parser]::ParseFile($_.FullName, [ref]$null, [ref]$scriptParseErrors) | Out-Null
    if ($scriptParseErrors) { throw "PowerShell script has syntax errors in $($_.FullName): $($scriptParseErrors | Out-String)" }
}
& $python (Join-Path $root 'skills\codex-knowledge-system\scripts\build_knowledge.py')
if ($LASTEXITCODE -ne 0) { throw 'Knowledge graph validation failed.' }
& $python (Join-Path $root 'skills\codex-knowledge-system\scripts\build_mindmaps.py')
if ($LASTEXITCODE -ne 0) { throw 'Mind-map generation failed.' }
& $python -m unittest discover -s (Join-Path $root 'skills\codex-image-workflow\scripts') -p 'test_*.py'
if ($LASTEXITCODE -ne 0) { throw 'Image workflow tests failed.' }
& (Join-Path $root 'skills\codex-image-workflow\scripts\Test-SolutionVisualizationPlan.ps1')
if (-not $?) { throw 'Solution visualization planner test failed.' }
& $python -m unittest discover -s (Join-Path $root 'skills\codex-conversation-continuity\scripts') -p 'test_*.py'
if ($LASTEXITCODE -ne 0) { throw 'Conversation continuity tests failed.' }
& (Join-Path $root 'skills\codex-file-organization\scripts\Test-FileOrganizationCleanup.ps1')
if (-not $?) { throw 'File-organization cleanup test failed.' }
& (Join-Path $root 'skills\codex-file-organization\scripts\Test-PreIterationRollback.ps1')
if (-not $?) { throw 'Pre-iteration rollback test failed.' }
& (Join-Path $root 'scripts\Test-ContinuousIterationDiagnosis.ps1')
if (-not $?) { throw 'Continuous iteration diagnosis test failed.' }
& (Join-Path $root 'scripts\Test-ReleaseReadmeAndVisuals.ps1')
if (-not $?) { throw 'Release README and visual refresh test failed.' }
& (Join-Path $root 'scripts\Test-ExperienceReleasePathSet.ps1')
if (-not $?) { throw 'Experience release path-set test failed.' }
& (Join-Path $root 'scripts\Test-RunRootPolicy.ps1')
if (-not $?) { throw 'Run-root policy test failed.' }
& (Join-Path $root 'scripts\Test-CodexVerification.ps1')
if (-not $?) { throw 'Codex verification controller test failed.' }
& (Join-Path $root 'scripts\Test-CodebaseMemoryProjectScope.ps1')
if (-not $?) { throw 'Codebase Memory project-scope test failed.' }
& (Join-Path $root 'skills\codex-git-operations\scripts\Test-CodexGitWorkflow.ps1')
if (-not $?) { throw 'Codex Git workflow test failed.' }
& (Join-Path $root 'skills\codex-git-operations\scripts\Test-GitIndexLockRecovery.ps1')
if (-not $?) { throw 'Git index-lock recovery test failed.' }
& (Join-Path $root 'skills\codex-git-operations\scripts\Test-ExperienceVersion.ps1')
if (-not $?) { throw 'Experience version test failed.' }
& (Join-Path $root 'skills\codex-git-operations\scripts\Test-LocalReleaseTagCollision.ps1')
if (-not $?) { throw 'Local release tag collision test failed.' }
& (Join-Path $root 'skills\codex-git-operations\scripts\Test-PrivateExperienceReleaseEvidence.Fixture.ps1')
if (-not $?) { throw 'Private experience release evidence test failed.' }
& (Join-Path $root 'skills\codex-git-operations\scripts\Test-GitRecoveryFastPath.ps1')
if (-not $?) { throw 'Git recovery fast-path test failed.' }
& (Join-Path $root 'skills\codex-git-operations\scripts\Test-GitStatusNoiseRepair.ps1')
if (-not $?) { throw 'Git status-noise repair test failed.' }
& (Join-Path $root 'skills\codex-error-feedback\scripts\Test-ErrorFeedbackUtf8Input.ps1')
if (-not $?) { throw 'Error-feedback UTF-8 file-input test failed.' }
& (Join-Path $root 'skills\codex-error-feedback\scripts\Test-GlobalErrorFeedbackInbox.ps1')
if (-not $?) { throw 'Global error-feedback inbox test failed.' }
& (Join-Path $root 'skills\codex-error-feedback\scripts\Test-ErrorFeedbackCloseout.ps1')
if (-not $?) { throw 'Error-feedback closeout test failed.' }
& (Join-Path $root 'skills\codex-requirement-authoring\scripts\Test-BrainstormingLite.ps1')
if (-not $?) { throw 'Brainstorming Lite contract test failed.' }
& (Join-Path $root 'skills\codex-workflow-design\scripts\Test-WritingPlanLite.ps1')
if (-not $?) { throw 'Writing Plan Lite contract test failed.' }
& (Join-Path $root 'skills\codex-workflow-design\scripts\Test-ScriptAutomationCandidate.ps1')
if (-not $?) { throw 'Script automation candidate test failed.' }
& (Join-Path $root 'skills\codex-workflow-design\scripts\Test-ScriptAssetOptimization.ps1')
if (-not $?) { throw 'Script asset optimization test failed.' }
& (Join-Path $root 'skills\codex-architecture-iteration\scripts\Test-OwnerSelfIterationReview.ps1')
if (-not $?) { throw 'Owner self-iteration review test failed.' }
& (Join-Path $root 'skills\codex-experience-capture\scripts\Test-GlobalIterationCandidateReport.ps1')
& (Join-Path $root 'skills\codex-experience-capture\scripts\Test-AuthorizedCandidateProcessing.ps1')
& (Join-Path $root 'skills\codex-git-operations\scripts\Test-AutoCommitIterationIntegration.ps1')
if (-not $?) { throw 'Global iteration candidate report test failed.' }
Write-Host 'All skills, history indexing, module registry, knowledge graph, mind-map views, image workflow tests, cleanup tests, rollback tests, continuous diagnosis tests, Git recovery tests, error-feedback tests, brainstorming and writing-plan contract tests, and global error-feedback inbox tests validated.'
