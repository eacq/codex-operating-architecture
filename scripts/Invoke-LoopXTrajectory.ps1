[CmdletBinding(PositionalBinding = $false)]
param(
    [ValidateSet('doctor', 'start', 'inspect', 'checkpoint', 'worker-turn')]
    [string]$Action = 'inspect',
    [ValidateSet('issue-fix', 'auto-ml', 'auto-research')]
    [string]$TrajectoryKind,
    [string]$ProjectRoot = 'F:\codex',
    [string]$GoalId,
    [string]$AgentId = 'global-experience-agent',
    [string]$GoalText,
    [string]$Question,
    [string]$RuntimeRoot,
    [string]$RegistryPath,
    [string]$EvidencePath,
    [string[]]$CommandArgs = @(),
    [int]$MaxRounds = 1,
    [ValidateSet('economy', 'balanced', 'full')]
    [string]$ResourceMode = 'balanced',
    [switch]$EnableHighCost,
    [switch]$AllowAutoWake,
    [switch]$Execute,
    [switch]$Apply
)

$ErrorActionPreference = 'Stop'
$resolvedProject = (Resolve-Path -LiteralPath $ProjectRoot).Path
$runtimeRepositoryRoot = if ($env:CODEX_VALIDATION_RUNTIME_ROOT) { (Resolve-Path -LiteralPath $env:CODEX_VALIDATION_RUNTIME_ROOT).Path } else { $resolvedProject }
if (-not $RuntimeRoot) { $RuntimeRoot = Join-Path $resolvedProject '.runtime\loopx-trajectory' }
if (-not $RegistryPath) { $RegistryPath = Join-Path $RuntimeRoot 'registry.json' }
$runtimeDirectory = Split-Path -Parent $RegistryPath
New-Item -ItemType Directory -Force -Path $RuntimeRoot, $runtimeDirectory | Out-Null
$commandWorkspace = Join-Path $RuntimeRoot 'workspace'
New-Item -ItemType Directory -Force -Path $commandWorkspace | Out-Null

$loopx = Join-Path $resolvedProject 'scripts\Invoke-LoopX.ps1'
if (-not (Test-Path -LiteralPath $loopx -PathType Leaf)) { throw "LoopX adapter is missing: $loopx" }
$installManifestPath = Join-Path $runtimeRepositoryRoot '.runtime\software\loopx\current.json'
if (Test-Path -LiteralPath $installManifestPath -PathType Leaf) {
    $installManifest = Get-Content -LiteralPath $installManifestPath -Raw -Encoding UTF8 | ConvertFrom-Json
    $releaseScripts = Join-Path ([string]$installManifest.release_root) 'scripts'
    if (Test-Path -LiteralPath $releaseScripts -PathType Container) {
        $env:PATH = "$releaseScripts$([IO.Path]::PathSeparator)$env:PATH"
    }
}

function Invoke-LoopXJson([string[]]$Arguments) {
    $full = @('--registry', $RegistryPath, '--runtime-root', $RuntimeRoot, '--format', 'json') + $Arguments
    # LoopX worker commands use the process CWD as their lightweight workspace.
    # Keep that workspace bounded instead of making a worker turn rescan the
    # whole architecture checkout.
    Push-Location $commandWorkspace
    try { $output = & $loopx @full 2>&1 }
    finally { Pop-Location }
    $exitCode = $LASTEXITCODE
    $text = ($output | ForEach-Object { [string]$_ }) -join [Environment]::NewLine
    if ($exitCode -ne 0) { throw "LoopX command failed ($exitCode): $text" }
    # Windows PowerShell 5.1 has no ConvertFrom-Json -Depth parameter.
    try { return ($text | ConvertFrom-Json) }
    catch { return [ordered]@{ ok = $true; raw_output = $text } }
}

function New-LocalRoute([string]$Kind) {
    $effectiveMode = if ($EnableHighCost) { 'full' } else { $ResourceMode }
    $common = @{
        resource_policy = 'desktop_bounded'
        resource_mode = $effectiveMode
        execution_version = $effectiveMode
        speed_metric = 'time_to_decidable_next_action'
        speed_secondary_metrics = @('elapsed_turn_time', 'model_and_tool_round_trips', 'user_wait_time', 'quota_consumption')
        quality_floor = @('required_function_set', 'owner_route', 'authority_check', 'privacy_redaction', 'evidence_boundary', 'rollback_boundary', 'required_validation', 'typed_exit')
        speed_selection_rule = 'choose the fastest version that preserves the required function set and quality floor'
        max_parallel_lanes = if ($effectiveMode -eq 'full') { 3 } else { 1 }
        default_poll = 'on_turn_or_material_event'
        auto_wake = [bool]$AllowAutoWake
        high_cost_enabled = ($effectiveMode -eq 'full')
        raw_trajectory_recorded = $false
        external_launch_authority = $false
        external_publication_authority = $false
    }
    if ($Kind -eq 'issue-fix') {
        $common.owner = 'codex-git-operations'
        $common.route = 'workflow-plan -> feasibility -> current-checkout validation -> PR lifecycle monitor'
        $common.authority_order = @('current checkout', 'repo-scoped memory', 'external advice')
    } elseif ($Kind -eq 'auto-ml') {
        $common.owner = 'codex-task-execution'
        $common.route = 'hypothesis -> matched windows -> replicate -> guardrail -> promote/retire'
        $common.domain_state = '.loopx/domain-state/<goal-id>/ml_experiment/ledger.jsonl'
    } elseif ($Kind -eq 'auto-research') {
        $common.owner = 'codex-information-gathering'
        $common.route = 'proposer -> executor -> evaluator/promoter -> evidence frontier'
        $common.worker_mode = 'headless one-turn default; visible lanes opt-in'
    }
    return [pscustomobject]$common
}

function Test-LocalGoalPresent([string]$Id) {
    if (-not (Test-Path -LiteralPath $RegistryPath -PathType Leaf)) { return $false }
    try {
        $status = Invoke-LoopXJson @('status', '--goal-id', $Id)
        return (@($status.goals | Where-Object { [string]$_.id -eq $Id }).Count -gt 0)
    } catch { return $false }
}

function Start-DurableRoute([string]$Kind, [string]$Domain, [string]$WriteScope, [string]$ActionKind, [string]$TodoText) {
    $effectiveMode = if ($EnableHighCost) { 'full' } else { $ResourceMode }
    $maxChildren = if ($effectiveMode -eq 'full') { '3' } else { '1' }
    $goalPresent = Test-LocalGoalPresent $GoalId
    if ($goalPresent) {
        return [pscustomobject]@{
            schema_version = 'codex_loopx_durable_start_v0'
            control_plane = 'local_durable_registry'
            reused = $true
            status = Invoke-LoopXJson @('status', '--goal-id', $GoalId)
        }
    }
    $bootstrap = Invoke-LoopXJson @(
        'bootstrap', '--project', $resolvedProject, '--goal-id', $GoalId,
        '--objective', $GoalText, '--domain', $Domain, '--role', 'controller',
        '--adapter-kind', $Kind, '--adapter-status', 'ready', '--spawn-allowed',
        '--max-children', $maxChildren, '--allowed-domain', $Domain,
        '--write-scope', $WriteScope, '--state-file',
        (Join-Path $RuntimeRoot (Join-Path 'goals' ($GoalId + '.md'))), '--no-onboarding-scan',
        '--begin-autonomous-advance', '--codex-app-heartbeat', 'no', '--no-global-sync'
    )
    $configure = Invoke-LoopXJson @(
        'configure-goal', '--goal-id', $GoalId, '--orchestration-mode', 'multi_subagent',
        '--spawn-allowed', '--max-children', $maxChildren, '--allowed-domain', $Domain,
        '--registered-agent', $AgentId, '--agent-model', 'peer_v1', '--execute'
    )
    $todo = Invoke-LoopXJson @(
        'todo', 'add', '--goal-id', $GoalId, '--role', 'agent',
        '--task-class', 'advancement_task', '--action-kind', $ActionKind,
        '--claimed-by', $AgentId, '--text', $TodoText, '--project', $resolvedProject, '--execute'
    )
    return [pscustomobject]@{
        schema_version = 'codex_loopx_durable_start_v0'
        control_plane = 'local_durable_registry'
        reused = $false
        bootstrap = $bootstrap
        configure = $configure
        seed_todo = $todo
    }
}

if ($Action -in @('start', 'inspect', 'worker-turn') -and [string]::IsNullOrWhiteSpace($TrajectoryKind)) {
    throw '-TrajectoryKind is required for start, inspect, and worker-turn.'
}

switch ($Action) {
    'doctor' {
        $doctor = Invoke-LoopXJson @('doctor', '--deep')
        [pscustomobject]@{ status = 'passed'; action = 'doctor'; doctor = $doctor }
        break
    }
    'start' {
        if ([string]::IsNullOrWhiteSpace($GoalId)) { $GoalId = "loopx-$TrajectoryKind-$(Get-Date -Format yyyyMMddHHmmss)" }
        if ($TrajectoryKind -eq 'auto-research') {
            if ([string]::IsNullOrWhiteSpace($Question)) { $Question = $GoalText }
            if ([string]::IsNullOrWhiteSpace($Question)) { throw '-Question or -GoalText is required for auto-research.' }
            $effectiveMode = if ($EnableHighCost) { 'full' } else { $ResourceMode }
            $maxLanes = if ($effectiveMode -eq 'full') { '3' } else { '1' }
            $goalPresent = Test-LocalGoalPresent $GoalId
            if (-not $goalPresent) {
                $bootstrap = Invoke-LoopXJson @(
                    'bootstrap', '--project', $resolvedProject, '--goal-id', $GoalId,
                    '--objective', $Question, '--domain', 'auto-research', '--role', 'controller',
                    '--adapter-kind', 'other-agent', '--adapter-status', 'ready', '--spawn-allowed',
                    '--max-children', $maxLanes, '--allowed-domain', 'research',
                    '--write-scope', '.runtime/work/auto-research-agent/**', '--state-file',
                    (Join-Path $RuntimeRoot (Join-Path 'goals' ($GoalId + '.md'))), '--no-onboarding-scan',
                    '--begin-autonomous-advance', '--codex-app-heartbeat', 'no', '--no-global-sync'
                )
                $configure = Invoke-LoopXJson @(
                    'configure-goal', '--goal-id', $GoalId, '--orchestration-mode', 'multi_subagent',
                    '--spawn-allowed', '--max-children', $maxLanes, '--allowed-domain', 'research',
                    '--registered-agent', $AgentId, '--agent-model', 'peer_v1', '--execute'
                )
                $todo = Invoke-LoopXJson @(
                    'todo', 'add', '--goal-id', $GoalId, '--role', 'agent',
                    '--task-class', 'advancement_task', '--action-kind', 'write_research_contract',
                    '--claimed-by', $AgentId, '--text', 'Write a bounded public-safe research contract.',
                    '--project', $resolvedProject, '--execute'
                )
                $result = [pscustomobject]@{
                    schema_version = 'codex_loopx_auto_research_persistent_start_v0'
                    control_plane = 'local_durable_registry'
                    bootstrap = $bootstrap
                    configure = $configure
                    seed_todo = $todo
                }
            } else {
                $result = Invoke-LoopXJson @('status', '--goal-id', $GoalId)
            }
        } else {
            if ([string]::IsNullOrWhiteSpace($GoalText)) { throw '-GoalText is required for issue-fix and auto-ml.' }
            if ($TrajectoryKind -eq 'issue-fix') {
                $result = Start-DurableRoute 'issue-fix' 'issue-fix' '.runtime/work/issue-fix-agent/**' 'issue_fix_workflow_plan' 'Create a bounded issue-fix route plan and repository evidence packet.'
            } else {
                $result = Start-DurableRoute 'auto-ml' 'auto-ml' '.runtime/work/auto-ml-experiment-agent/**' 'run_eval' 'Prepare one matched-window ML evaluation checkpoint with guardrails.'
            }
        }
        $actualGoalId = if ($result.goal_id) { [string]$result.goal_id } else { $GoalId }
        [pscustomobject]@{ status = 'passed'; action = 'start'; trajectory_kind = $TrajectoryKind; goal_id = $actualGoalId; requested_goal_id = $GoalId; route = New-LocalRoute $TrajectoryKind; result = $result }
        break
    }
    'inspect' {
        if ([string]::IsNullOrWhiteSpace($GoalId)) { throw '-GoalId is required for inspect.' }
        $status = Invoke-LoopXJson @('status', '--goal-id', $GoalId)
        $quota = Invoke-LoopXJson @('quota', 'should-run', '--goal-id', $GoalId, '--agent-id', $AgentId, '--host-surface', 'generic_cli', '--scheduler-owner', 'agent_cli_loop', '--execution-mode', 'isolated_headless', '--turn-envelope', '--use-projection-cache', '--projection-cache-ttl-seconds', '120')
        [pscustomobject]@{ status = 'passed'; action = 'inspect'; trajectory_kind = $TrajectoryKind; goal_id = $GoalId; route = New-LocalRoute $TrajectoryKind; loopx_status = $status; quota = $quota }
        break
    }
    'worker-turn' {
        if ($TrajectoryKind -ne 'auto-research') { throw 'worker-turn is currently only supported for auto-research.' }
        if ([string]::IsNullOrWhiteSpace($GoalId)) { throw '-GoalId is required for worker-turn.' }
        $objective = if ([string]::IsNullOrWhiteSpace($GoalText)) { 'bounded local research turn' } else { $GoalText }
        $args = @('auto-research', 'worker-turn', '--goal-id', $GoalId, '--agent-id', $AgentId, '--objective', $objective)
        if ($Execute) { $args += '--execute' }
        $result = Invoke-LoopXJson $args
        [pscustomobject]@{ status = 'passed'; action = 'worker-turn'; trajectory_kind = $TrajectoryKind; goal_id = $GoalId; route = New-LocalRoute $TrajectoryKind; executed = [bool]$Execute; result = $result }
        break
    }
    'checkpoint' {
        if ($CommandArgs.Count -eq 0) { throw '-CommandArgs is required for checkpoint.' }
        $result = Invoke-LoopXJson $CommandArgs
        [pscustomobject]@{ status = 'passed'; action = 'checkpoint'; trajectory_kind = $TrajectoryKind; goal_id = $GoalId; route = if ($TrajectoryKind) { New-LocalRoute $TrajectoryKind } else { $null }; result = $result }
        break
    }
}
