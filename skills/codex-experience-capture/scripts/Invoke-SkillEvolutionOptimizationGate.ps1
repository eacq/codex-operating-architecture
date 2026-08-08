[CmdletBinding()]
param(
    [double]$CurrentScore,
    [double]$CandidateScore,
    [double]$BestScore = [double]::NaN,
    [string[]]$Evidence = @(),
    [string[]]$SafetyChecks = @(),
    [string[]]$FailedSafetyChecks = @(),
    [double]$DryRunRatio = 0.0,
    [switch]$HumanCheckpointRequired,
    [switch]$HumanCheckpointSatisfied,
    [string]$SkillPath = '',
    [string]$CandidateId = ''
)

$ErrorActionPreference = 'Stop'

if ($CurrentScore -lt 0 -or $CandidateScore -lt 0) {
    throw 'Scores must be non-negative.'
}
if ($DryRunRatio -lt 0 -or $DryRunRatio -gt 1) {
    throw 'DryRunRatio must be between 0 and 1.'
}

$decision = 'accept'
$reasons = New-Object System.Collections.Generic.List[string]
$nextBoundary = 'adopt candidate and run owner validation'

if ($CandidateScore -le $CurrentScore) {
    $decision = 'reject'
    $reasons.Add('candidate_score is not strictly greater than current_score')
}

if (-not [double]::IsNaN($BestScore) -and $CandidateScore -lt $BestScore) {
    $decision = 'reject'
    $reasons.Add('candidate_score is lower than best_score ratchet')
}

if (@($FailedSafetyChecks).Count -gt 0) {
    $decision = 'reject'
    $reasons.Add('one or more safety checks failed')
}

if ($HumanCheckpointRequired -and -not $HumanCheckpointSatisfied) {
    $decision = 'pause'
    $reasons.Add('human checkpoint is required before adoption')
    $nextBoundary = 'record explicit human or owner authority, then rerun gate'
}

if (@($Evidence).Count -eq 0) {
    if ($decision -eq 'accept') { $decision = 'candidate-only' }
    $reasons.Add('no evidence records were supplied')
    $nextBoundary = 'collect task evidence before adoption'
}

if ($DryRunRatio -gt 0.7) {
    if ($decision -eq 'accept') { $decision = 'candidate-only' }
    $reasons.Add('dry-run evidence dominates; real validation is required')
    $nextBoundary = 'run non-dry-run validation before adoption'
}

if ($reasons.Count -eq 0) {
    $reasons.Add('candidate strictly improves score and satisfies safety gates')
}

[pscustomobject][ordered]@{
    schema_version = 1
    model = 'skill-evolution-optimization-gate'
    candidate_id = $CandidateId
    skill_path = $SkillPath
    current_score = $CurrentScore
    candidate_score = $CandidateScore
    best_score = if ([double]::IsNaN($BestScore)) { $null } else { $BestScore }
    dry_run_ratio = $DryRunRatio
    safety_checks = @($SafetyChecks)
    failed_safety_checks = @($FailedSafetyChecks)
    evidence = @($Evidence)
    human_checkpoint_required = [bool]$HumanCheckpointRequired
    human_checkpoint_satisfied = [bool]$HumanCheckpointSatisfied
    decision = $decision
    reasons = @($reasons)
    next_boundary = $nextBoundary
} | ConvertTo-Json -Depth 8
