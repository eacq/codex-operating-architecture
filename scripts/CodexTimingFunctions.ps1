function ConvertTo-CodexUtcTimestamp {
    param([object]$Value)

    if ($null -eq $Value -or [string]::IsNullOrWhiteSpace([string]$Value)) { return $null }
    $text = [string]$Value
    $number = 0.0
    if ([double]::TryParse($text, [Globalization.NumberStyles]::Float, [Globalization.CultureInfo]::InvariantCulture, [ref]$number)) {
        if ([math]::Abs($number) -ge 100000000000) {
            return [DateTimeOffset]::FromUnixTimeMilliseconds([long]$number).ToUniversalTime()
        }
        if ([math]::Abs($number) -ge 1000000000) {
            return [DateTimeOffset]::FromUnixTimeSeconds([long]$number).ToUniversalTime()
        }
    }

    $parsed = [DateTimeOffset]::MinValue
    if ([DateTimeOffset]::TryParse($text, [Globalization.CultureInfo]::InvariantCulture, [Globalization.DateTimeStyles]::AssumeUniversal, [ref]$parsed)) {
        return $parsed.ToUniversalTime()
    }
    return $null
}

function Read-CodexTimingSnapshot {
    param([string]$ClientTimingJson)

    if ([string]::IsNullOrWhiteSpace($ClientTimingJson)) { return $null }
    $raw = $ClientTimingJson
    if (Test-Path -LiteralPath $ClientTimingJson -PathType Leaf) {
        $raw = [IO.File]::ReadAllText((Resolve-Path -LiteralPath $ClientTimingJson).Path, [Text.UTF8Encoding]::new($false))
    }
    try { return ($raw | ConvertFrom-Json) } catch { throw 'Client timing snapshot is not valid JSON.' }
}

function Get-CodexClientTimingRecord {
    param([string]$ClientTimingJson)

    $snapshot = Read-CodexTimingSnapshot $ClientTimingJson
    if ($null -eq $snapshot) {
        return [ordered]@{
            available = $false
            source = $null
            thread_id = $null
            turn_count = 0
            completed_turn_count = 0
            client_turn_duration_sum_seconds = $null
            client_task_wall_clock_seconds = $null
            validation_tolerance_seconds = 1.5
            timestamp_duration_mismatch_count = 0
            timestamp_duration_mismatch_seconds = @()
            turn_ids = @()
            intervals = @()
            status = 'not-provided'
        }
    }

    $turns = if ($snapshot.turns) { @($snapshot.turns) } elseif ($snapshot.thread -and $snapshot.thread.turns) { @($snapshot.thread.turns) } else { @() }
    $turnCount = @($turns).Count
    $source = if ($snapshot.source) { [string]$snapshot.source } else { 'codex_app__read_thread' }
    $threadId = if ($snapshot.thread_id) { [string]$snapshot.thread_id } elseif ($snapshot.thread.id) { [string]$snapshot.thread.id } else { $null }
    $selectedTurnIds = @($snapshot.selected_turn_ids | ForEach-Object { [string]$_ } | Where-Object { $_ })
    $hasExplicitScope = $selectedTurnIds.Count -gt 0 -or @($turns | Where-Object { $_.PSObject.Properties.Name -contains 'in_scope' }).Count -gt 0
    if (-not $hasExplicitScope) {
        return [ordered]@{
            available = $false
            source = $source
            thread_id = $threadId
            turn_count = $turnCount
            completed_turn_count = 0
            client_turn_duration_sum_seconds = $null
            client_task_wall_clock_seconds = $null
            validation_tolerance_seconds = 1.5
            timestamp_duration_mismatch_count = 0
            timestamp_duration_mismatch_seconds = @()
            turn_ids = @()
            intervals = @()
            status = 'scope-required'
        }
    }
    $intervals = New-Object System.Collections.Generic.List[object]
    $turnDurations = New-Object System.Collections.Generic.List[double]
    $mismatches = New-Object System.Collections.Generic.List[object]
    $turnIds = New-Object System.Collections.Generic.List[string]
    $completedCount = 0
    $tolerance = 1.5

    foreach ($turn in $turns) {
        $turnIdCandidate = if ($turn.id) { [string]$turn.id } else { $null }
        if ($turn.in_scope -ne $true -and $selectedTurnIds -notcontains $turnIdCandidate) { continue }
        $start = ConvertTo-CodexUtcTimestamp $turn.startedAt
        $end = ConvertTo-CodexUtcTimestamp $turn.completedAt
        if ($null -eq $start -or $null -eq $end) { continue }
        if ($end -lt $start) { throw "Client turn has completedAt earlier than startedAt: $($turn.id)" }
        $completedCount++
        $turnId = if ($turn.id) { [string]$turn.id } else { 'unnamed-turn-' + $completedCount }
        [void]$turnIds.Add($turnId)
        $timestampSeconds = [math]::Round(($end - $start).TotalSeconds, 3)
        $durationSeconds = $timestampSeconds
        if ($null -ne $turn.durationMs) {
            $durationSeconds = [math]::Round(([double]$turn.durationMs / 1000), 3)
            if ($durationSeconds -lt 0) { throw "Client turn durationMs cannot be negative: $turnId" }
            $difference = [math]::Round([math]::Abs($durationSeconds - $timestampSeconds), 3)
            if ($difference -gt $tolerance) {
                [void]$mismatches.Add([ordered]@{ turn_id=$turnId; duration_ms=[double]$turn.durationMs; timestamp_seconds=$timestampSeconds; difference_seconds=$difference })
            }
        }
        [void]$turnDurations.Add([double]$durationSeconds)
        [void]$intervals.Add([pscustomobject]@{ turn_id=$turnId; start=$start; end=$end; duration_seconds=$durationSeconds })
    }

    $sumSeconds = if ($turnDurations.Count -gt 0) { [math]::Round((($turnDurations | Measure-Object -Sum).Sum), 3) } else { $null }
    $merged = New-Object System.Collections.Generic.List[object]
    if ($intervals.Count -gt 0) {
        $sorted = @($intervals | Sort-Object start, end)
        $currentStart = $sorted[0].start
        $currentEnd = $sorted[0].end
        foreach ($row in @($sorted | Select-Object -Skip 1)) {
            if ($row.start -le $currentEnd) {
                if ($row.end -gt $currentEnd) { $currentEnd = $row.end }
            } else {
                [void]$merged.Add([pscustomobject]@{ start=$currentStart; end=$currentEnd; duration_seconds=[math]::Round(($currentEnd - $currentStart).TotalSeconds, 3) })
                $currentStart = $row.start
                $currentEnd = $row.end
            }
        }
        [void]$merged.Add([pscustomobject]@{ start=$currentStart; end=$currentEnd; duration_seconds=[math]::Round(($currentEnd - $currentStart).TotalSeconds, 3) })
    }
    # Customer wall clock is the interval union; durationMs sum remains active-work only.
    $wallSeconds = if ($merged.Count -gt 0) { [math]::Round((($merged | ForEach-Object { [double]$_.duration_seconds } | Measure-Object -Sum).Sum), 3) } else { $null }
    $mismatchArray = $mismatches.ToArray()
    $turnIdArray = $turnIds.ToArray()
    $intervalPayload = @($merged | ForEach-Object { [ordered]@{ start=$_.start.ToString('o'); end=$_.end.ToString('o'); duration_seconds=$_.duration_seconds } })
    $status = if ($completedCount -eq 0) { 'no-completed-turns' } elseif ($mismatches.Count -gt 0) { 'available-with-timestamp-duration-warning' } else { 'available-and-consistent' }

    return [ordered]@{
        available = $completedCount -gt 0
        source = $source
        thread_id = $threadId
        turn_count = $turnCount
        completed_turn_count = $completedCount
        client_turn_duration_sum_seconds = $sumSeconds
        client_task_wall_clock_seconds = $wallSeconds
        validation_tolerance_seconds = $tolerance
        timestamp_duration_mismatch_count = $mismatches.Count
        timestamp_duration_mismatch_seconds = $mismatchArray
        turn_ids = $turnIdArray
        intervals = $intervalPayload
        status = $status
    }
}

function New-CodexTimingAssessment {
    param(
        [string]$ClientTimingJson,
        [Nullable[double]]$LifecycleSeconds,
        [Nullable[double]]$HostWorkedSeconds,
        [Nullable[double]]$ExternalElapsedSeconds,
        [Nullable[double]]$ScreenshotCaptureSeconds
    )

    $client = Get-CodexClientTimingRecord $ClientTimingJson
    $comparisons = New-Object System.Collections.Generic.List[object]
    $clientSeconds = $client.client_task_wall_clock_seconds
    if ($null -ne $clientSeconds -and $null -ne $ExternalElapsedSeconds) {
        $delta = [math]::Round(([double]$clientSeconds - [double]$ExternalElapsedSeconds), 3)
        [void]$comparisons.Add([ordered]@{ left='codex-client-task-wall-clock'; right='external-monotonic'; delta_seconds=$delta; status=if ([math]::Abs($delta) -le 2) { 'consistent' } else { 'needs-review' } })
    }
    if ($null -ne $clientSeconds -and $null -ne $HostWorkedSeconds) {
        $delta = [math]::Round(([double]$clientSeconds - [double]$HostWorkedSeconds), 3)
        [void]$comparisons.Add([ordered]@{ left='codex-client-task-wall-clock'; right='host-worked'; delta_seconds=$delta; status=if ([math]::Abs($delta) -le 2) { 'consistent' } else { 'different-view-or-needs-review' } })
    }

    $customerSeconds = $null
    $customerSource = $null
    if ($null -ne $clientSeconds -and $client.available) {
        $customerSeconds = [double]$clientSeconds
        $customerSource = 'codex-client-task-wall-clock'
    } elseif ($null -ne $HostWorkedSeconds) {
        $customerSeconds = [double]$HostWorkedSeconds
        $customerSource = 'codex-host-worked-fallback'
    } elseif ($null -ne $ExternalElapsedSeconds) {
        $customerSeconds = [double]$ExternalElapsedSeconds
        $customerSource = 'external-monotonic-fallback'
    } elseif ($null -ne $LifecycleSeconds) {
        $customerSeconds = [double]$LifecycleSeconds
        $customerSource = 'task-lifecycle-fallback'
    }

    $comparisonArray = $comparisons.ToArray()
    $crossStatus = if (@($comparisonArray | Where-Object { $_.status -eq 'needs-review' }).Count -gt 0) { 'needs-review' } elseif ($comparisonArray.Count -gt 0) { 'consistent' } else { 'not-available' }
    $externalValue = if ($null -ne $ExternalElapsedSeconds) { [math]::Round([double]$ExternalElapsedSeconds, 3) } else { $null }
    $screenshotValue = if ($null -ne $ScreenshotCaptureSeconds) { [math]::Round([double]$ScreenshotCaptureSeconds, 3) } else { $null }
    $screenshotStatus = if ($null -ne $ScreenshotCaptureSeconds) { 'independent-suboperation-stopwatch' } else { 'not-provided' }
    [ordered]@{
        client = $client
        customer_visible_complete_seconds = if ($null -ne $customerSeconds) { [math]::Round($customerSeconds, 3) } else { $null }
        customer_visible_time_source = $customerSource
        external_monotonic_seconds = $externalValue
        screenshot_capture_seconds = $screenshotValue
        screenshot_timing_status = $screenshotStatus
        cross_validation = $comparisonArray
        cross_validation_status = $crossStatus
    }
}
