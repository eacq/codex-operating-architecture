[CmdletBinding(PositionalBinding = $false)]
param(
    [string]$RepositoryRoot = 'F:\codex',
    [string]$WorkRoot
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath $RepositoryRoot).Path
if (-not $WorkRoot) { $WorkRoot = Join-Path $root '.runtime\work\loopx-trajectory-fixture' }
$registry = Join-Path $WorkRoot 'registry.json'
$runtime = Join-Path $WorkRoot 'runtime'
New-Item -ItemType Directory -Force -Path $WorkRoot | Out-Null

function Invoke-LocalLoopX([string[]]$Args) {
    $full = @('--registry', $registry, '--runtime-root', $runtime, '--format', 'json') + $Args
    $result = & (Join-Path $root 'scripts\Invoke-LoopX.ps1') @full 2>&1
    if ($LASTEXITCODE -ne 0) { throw (($result | ForEach-Object { [string]$_ }) -join [Environment]::NewLine) }
    return ($result | ForEach-Object { [string]$_ }) -join [Environment]::NewLine
}

$doctor = & (Join-Path $root 'scripts\Invoke-LoopXTrajectory.ps1') -Action doctor -ProjectRoot $root
$ml = & (Join-Path $root 'scripts\Invoke-LoopXTrajectory.ps1') -Action checkpoint -TrajectoryKind auto-ml -GoalId trajectory-fixture -RuntimeRoot $runtime -RegistryPath $registry -CommandArgs @('ml-experiment','preview','--experiment-id','exp_fixture','--primary-metric','offline_auc','--baseline-value','0.421','--candidate-value','0.437','--guardrail-status','clean','--train-window','train_fixture','--eval-window','eval_fixture','--hypothesis-id','h_fixture','--mechanism-family','fixture_route','--route','local_replicate')
$issue = & (Join-Path $root 'scripts\Invoke-LoopXTrajectory.ps1') -Action start -TrajectoryKind issue-fix -GoalText 'Fixture issue-fix route preview.' -GoalId trajectory-issue-fixture -AgentId issue-fix-agent -ProjectRoot $root -RuntimeRoot $runtime -RegistryPath $registry -ResourceMode economy
$issueInspect = & (Join-Path $root 'scripts\Invoke-LoopXTrajectory.ps1') -Action inspect -TrajectoryKind issue-fix -GoalId trajectory-issue-fixture -AgentId issue-fix-agent -ProjectRoot $root -RuntimeRoot $runtime -RegistryPath $registry -ResourceMode economy
$mlStart = & (Join-Path $root 'scripts\Invoke-LoopXTrajectory.ps1') -Action start -TrajectoryKind auto-ml -GoalText 'Fixture ML route preview.' -GoalId trajectory-ml-fixture -AgentId auto-ml-experiment-agent -ProjectRoot $root -RuntimeRoot $runtime -RegistryPath $registry -ResourceMode economy
$mlInspect = & (Join-Path $root 'scripts\Invoke-LoopXTrajectory.ps1') -Action inspect -TrajectoryKind auto-ml -GoalId trajectory-ml-fixture -AgentId auto-ml-experiment-agent -ProjectRoot $root -RuntimeRoot $runtime -RegistryPath $registry -ResourceMode economy
$research = & (Join-Path $root 'scripts\Invoke-LoopXTrajectory.ps1') -Action start -TrajectoryKind auto-research -Question 'How should a local trajectory retain compact evidence?' -GoalId trajectory-research-fixture -AgentId auto-research-operator -ProjectRoot $root -RuntimeRoot $runtime -RegistryPath $registry -ResourceMode economy
$researchInspect = & (Join-Path $root 'scripts\Invoke-LoopXTrajectory.ps1') -Action inspect -TrajectoryKind auto-research -GoalId trajectory-research-fixture -AgentId auto-research-operator -ProjectRoot $root -RuntimeRoot $runtime -RegistryPath $registry -ResourceMode economy

foreach ($route in @($issue, $issueInspect, $mlStart, $mlInspect, $research, $researchInspect)) {
    if ($route.route.speed_metric -ne 'time_to_decidable_next_action') { throw 'LoopX route did not expose the speed metric.' }
    if (@($route.route.quality_floor).Count -lt 8) { throw 'LoopX route quality floor is incomplete.' }
    if ([string]::IsNullOrWhiteSpace([string]$route.route.execution_version)) { throw 'LoopX route did not expose its execution version.' }
}
$researchWorker = & (Join-Path $root 'scripts\Invoke-LoopXTrajectory.ps1') -Action worker-turn -TrajectoryKind auto-research -GoalId trajectory-research-fixture -AgentId auto-research-operator -ProjectRoot $root -RuntimeRoot $runtime -RegistryPath $registry -ResourceMode economy -Execute

[pscustomobject][ordered]@{
    status = if ($doctor.status -eq 'passed' -and $ml.status -eq 'passed' -and $issue.status -eq 'passed' -and $issueInspect.status -eq 'passed' -and $mlStart.status -eq 'passed' -and $mlInspect.status -eq 'passed' -and $research.status -eq 'passed' -and $researchInspect.status -eq 'passed' -and $researchWorker.result.mode -eq 'manual_research_required') { 'passed' } else { 'failed' }
    doctor = $doctor.status
    ml_preview = $ml.status
    issue_fix_start = $issue.status
    issue_fix_inspect = $issueInspect.status
    auto_ml_start = $mlStart.status
    auto_ml_inspect = $mlInspect.status
    auto_research = $research.status
    auto_research_inspect = $researchInspect.status
    auto_research_worker_boundary = $researchWorker.result.mode
    auto_research_goal = $research.goal_id
    resource_policy = 'economy/balanced/full selectable; no background wake by default'
    work_root = $WorkRoot
} | ConvertTo-Json -Depth 8
