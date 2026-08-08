function Get-AgentHostTransportRecoveryPolicy {
    param([string]$RepositoryRoot)
    $path = Join-Path $RepositoryRoot 'config\agent-transport-recovery-policy.json'
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        throw "Transport recovery policy is missing: $path"
    }
    return Get-Content -LiteralPath $path -Raw -Encoding UTF8 | ConvertFrom-Json
}

function ConvertTo-AgentHostEpochSeconds {
    param([object]$Value)
    if ($null -eq $Value) { return $null }
    $number = 0L
    if ([long]::TryParse([string]$Value, [ref]$number)) { return $number }
    $parsed = [DateTimeOffset]::MinValue
    if ([DateTimeOffset]::TryParse([string]$Value, [ref]$parsed)) {
        return $parsed.ToUnixTimeSeconds()
    }
    return $null
}

function Get-AgentHostThreadStatus {
    param([object]$Thread)
    if ($Thread.status -is [string]) { return [string]$Thread.status }
    if ($Thread.status.type) { return [string]$Thread.status.type }
    return [string]$Thread.status
}

function Get-AgentHostLatestTurn {
    param([object]$Thread)
    if ($Thread.latestTurn) { return $Thread.latestTurn }
    if ($Thread.turns) { return @($Thread.turns)[0] }
    return $null
}

function Get-AgentHostRecoverySignal {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][object]$Snapshot,
        [Parameter(Mandatory)][object]$Policy,
        [int]$StallThresholdSeconds = 0,
        [datetime]$NowUtc = ([DateTime]::UtcNow)
    )

    $threshold = if ($StallThresholdSeconds -gt 0) {
        $StallThresholdSeconds
    } elseif ($Policy.detection.host_watchdog.stall_threshold_seconds) {
        [int]$Policy.detection.host_watchdog.stall_threshold_seconds
    } else { 180 }
    $nowEpoch = [DateTimeOffset]$NowUtc.ToUniversalTime()
    $threads = if ($Snapshot.threads) {
        @($Snapshot.threads)
    } elseif ($Snapshot.polls) {
        @($Snapshot.polls | ForEach-Object {
            $base = $_.thread
            [pscustomobject][ordered]@{
                id = $base.id
                title = $base.title
                status = $base.status
                preview = $base.preview
                error = $base.error
                latestTurn = $_.latestTurn
                latestAssistantMessageId = $_.latestAssistantMessageId
                latestToolMarkerId = $_.latestToolMarkerId
                latestToolMarker = $_.latestToolMarker
            }
        })
    } else { @($Snapshot) }
    $signals = @()

    foreach ($thread in $threads) {
        $latestTurn = Get-AgentHostLatestTurn $thread
        $threadStatus = Get-AgentHostThreadStatus $thread
        $turnStatus = if ($latestTurn) { [string]$latestTurn.status } else { '' }
        $errorText = @(
            [string]$thread.error,
            [string]$latestTurn.error,
            [string]$thread.preview
        ) | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Select-Object -First 1
        $beforeCompletion = $threadStatus -eq 'active' -and $turnStatus -eq 'inProgress'
        $transportSignal = $null
        if ($errorText) {
            $transportSignal = Get-AgentTransportRecoverySignal -Policy $Policy -ErrorText $errorText -Component "codex-thread/$($thread.id)" -BeforeCompletion:$beforeCompletion
        }

        $startedEpoch = if ($latestTurn) { ConvertTo-AgentHostEpochSeconds $latestTurn.startedAt } else { $null }
        $ageSeconds = if ($null -ne $startedEpoch) { [int][Math]::Max(0, $nowEpoch.ToUnixTimeSeconds() - $startedEpoch) } else { $null }
        $hasAssistantMessage = $null -ne $thread.latestAssistantMessageId -or @($latestTurn.items | Where-Object { $_.type -eq 'agentMessage' }).Count -gt 0
        $toolMarkers = @(
            if ($thread.latestToolMarker) { $thread.latestToolMarker }
            @($latestTurn.items | Where-Object { $_.type -eq 'mcpToolCall' -or $_.type -eq 'toolCall' })
        )
        $hasToolMarker = $null -ne $thread.latestToolMarkerId -or $toolMarkers.Count -gt 0
        $hasInProgressToolMarker = @($toolMarkers | Where-Object { [string]$_.status -eq 'inProgress' }).Count -gt 0
        $oldEnough = $null -ne $ageSeconds -and $ageSeconds -ge $threshold
        $silentStale = $beforeCompletion -and (-not $hasAssistantMessage) -and (-not $hasToolMarker) -and $oldEnough
        $toolStale = $beforeCompletion -and $hasInProgressToolMarker -and $oldEnough
        $stale = $silentStale -or $toolStale

        if ($transportSignal -and $transportSignal.restart_required -eq $true) {
            $signals += [ordered]@{
                thread_id = [string]$thread.id
                title = [string]$thread.title
                detected = $true
                restart_required = $true
                classification = [string]$transportSignal.classification
                source = 'codex-host-error'
                age_seconds = $ageSeconds
                error_sha256 = [string]$transportSignal.error_sha256
                user_message = [string]$transportSignal.user_message
                next_action = [string]$transportSignal.next_action
            }
            continue
        }

        if ($stale) {
            $signals += [ordered]@{
                thread_id = [string]$thread.id
                title = [string]$thread.title
                detected = $true
                restart_required = $true
                classification = [string]$Policy.detection.host_watchdog.classification
                source = 'codex-host-watchdog'
                age_seconds = $ageSeconds
                threshold_seconds = $threshold
                evidence = if ($toolStale) { @('thread_active', 'turn_in_progress', 'stale_in_progress_tool_marker') } else { @('thread_active', 'turn_in_progress', 'no_assistant_message', 'no_tool_marker') }
                user_message = [string]$Policy.detection.host_watchdog.user_message
                next_action = [string]$Policy.detection.host_watchdog.next_action
            }
        } else {
            $signals += [ordered]@{
                thread_id = [string]$thread.id
                title = [string]$thread.title
                detected = $false
                restart_required = $false
                classification = if ($beforeCompletion -and $null -eq $ageSeconds) { 'insufficient-host-snapshot' } else { 'not-stalled' }
                source = 'codex-host-watchdog'
                age_seconds = $ageSeconds
                threshold_seconds = $threshold
                has_assistant_message = $hasAssistantMessage
                has_tool_marker = $hasToolMarker
                has_in_progress_tool_marker = $hasInProgressToolMarker
            }
        }
    }

    $restartSignals = @($signals | Where-Object { $_.restart_required -eq $true })
    return [ordered]@{
        schema_version = 1
        detected = $restartSignals.Count -gt 0
        restart_required = $restartSignals.Count -gt 0
        retry_allowed = $false
        classification = if ($restartSignals.Count -gt 0) { [string]$restartSignals[0].classification } else { 'not-stalled' }
        source = 'codex-host-watchdog'
        checked_at = $nowEpoch.ToString('o')
        threshold_seconds = $threshold
        threads = $signals
        restart_threads = $restartSignals
        user_message = if ($restartSignals.Count -gt 0) { [string]$restartSignals[0].user_message } else { $null }
        next_action = if ($restartSignals.Count -gt 0) { [string]$restartSignals[0].next_action } else { 'continue normal host monitoring' }
        automatic_action = 'persist-marker-and-prompt; never force-kill the task'
    }
}

function Write-AgentHostRecoveryMarker {
    param(
        [Parameter(Mandatory)][string]$MarkerPath,
        [Parameter(Mandatory)][object]$Signal
    )
    $directory = Split-Path -Parent $MarkerPath
    New-Item -ItemType Directory -Force -Path $directory | Out-Null
    $tempPath = "$MarkerPath.$([guid]::NewGuid().ToString('N')).tmp"
    try {
        [IO.File]::WriteAllText($tempPath, ($Signal | ConvertTo-Json -Depth 20), [Text.UTF8Encoding]::new($false))
        Move-Item -LiteralPath $tempPath -Destination $MarkerPath -Force
    } finally {
        if (Test-Path -LiteralPath $tempPath) { Remove-Item -LiteralPath $tempPath -Force }
    }
    return $MarkerPath
}
