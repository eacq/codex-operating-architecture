[CmdletBinding()]
param(
    [string]$RepositoryRoot = (Get-Location).Path,
    [ValidateSet('file-organization','global-iteration')]
    [string]$Target,
    [string]$RepairScript,
    [string]$ProbeScript = '',
    [string]$EvidencePath = '',
    [ValidateRange(0, 1000)]
    [int]$MaxRepairAttempts = 0,
    [switch]$SkipErrorReportForTest,
    [switch]$Apply
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath $RepositoryRoot).Path.TrimEnd('\')
if (-not $EvidencePath) {
    $EvidencePath = Join-Path $root '.codex\project\continuous-iteration-diagnosis.json'
}

function Write-DiagnosisEvidence([string]$Status, [object[]]$Attempts, [string]$Blocker = '') {
    $record = [ordered]@{
        schema_version = 1
        mode = 'continuous-diagnosis'
        target = $Target
        status = $Status
        attempts = @($Attempts)
        blocker = $Blocker
        updated_at = [DateTime]::UtcNow.ToString('o')
    }
    $parent = Split-Path -Parent $EvidencePath
    if ($parent) { New-Item -ItemType Directory -Force -Path $parent | Out-Null }
    [IO.File]::WriteAllText($EvidencePath, ($record | ConvertTo-Json -Depth 8), [Text.UTF8Encoding]::new($false))
}

function Invoke-DiagnosisProbe {
    if ($ProbeScript) {
        & $ProbeScript -RepositoryRoot $root -Target $Target
        if (-not $?) { throw 'Custom diagnosis probe returned failure.' }
        return
    }
    if ($Target -eq 'file-organization') {
        & (Join-Path $root 'skills\codex-file-organization\scripts\Test-FileOrganizationCleanup.ps1')
        if (-not $?) { throw 'File-organization cleanup probe failed.' }
        & (Join-Path $root 'skills\codex-file-organization\scripts\Test-PreIterationRollback.ps1')
        if (-not $?) { throw 'File-organization rollback probe failed.' }
        return
    }
    & (Join-Path $root 'scripts\Invoke-IsolatedGlobalExperienceIteration.ps1') -RepositoryRoot $root -Apply -Replace
    if (-not $?) { throw 'Complete global-iteration probe failed.' }
}

if (-not $Apply) {
    [pscustomobject]@{
        mode = 'continuous-diagnosis'
        target = $Target
        probe = if ($ProbeScript) { 'custom' } else { 'owner-default' }
        repair = if ($RepairScript) { 'configured' } else { 'required-before-apply' }
        max_repair_attempts = if ($MaxRepairAttempts -eq 0) { 'unlimited-safe-attempts' } else { $MaxRepairAttempts }
        result = 'plan-only'
    } | ConvertTo-Json
    exit 0
}

if (-not $RepairScript -or -not (Test-Path -LiteralPath $RepairScript -PathType Leaf)) {
    throw 'Continuous diagnosis requires an explicit existing -RepairScript; automatic repair must never be guessed.'
}
if ($ProbeScript -and -not (Test-Path -LiteralPath $ProbeScript -PathType Leaf)) {
    throw 'The configured diagnosis probe does not exist.'
}

$attempts = [Collections.Generic.List[object]]::new()
$repairCount = 0
$reportDirectory = ''
while ($true) {
    $probeNumber = $attempts.Count + 1
    try {
        Invoke-DiagnosisProbe | Out-Host
        $attempts.Add([ordered]@{
            probe = $probeNumber
            result = 'passed'
            checked_at = [DateTime]::UtcNow.ToString('o')
        })
        Write-DiagnosisEvidence -Status 'completed' -Attempts $attempts
        if ($reportDirectory) {
            & (Join-Path $root 'skills\codex-error-feedback\scripts\New-ErrorFeedbackReport.ps1') -ReportDirectory $reportDirectory -Status verified -RepairAttempt "$repairCount explicit owner repair action(s)" -RepairResult 'The selected owner probe passed from the beginning.' -Verification "Continuous diagnosis completed after $($attempts.Count) probe(s)." | Out-Null
        }
        [pscustomobject]@{
            schema_version = 1
            mode = 'continuous-diagnosis'
            target = $Target
            probes = $attempts.Count
            repairs = $repairCount
            evidence = $EvidencePath
            result = 'completed'
        } | ConvertTo-Json
        exit 0
    }
    catch {
        $message = $_.Exception.Message
        $failureRecord = Join-Path $root '.codex\project\last-iteration-failure.json'
        $rollbackCritical = $false
        if ($Target -eq 'global-iteration' -and (Test-Path -LiteralPath $failureRecord)) {
            try {
                $failure = Get-Content -LiteralPath $failureRecord -Raw -Encoding UTF8 | ConvertFrom-Json
                $rollbackCritical = ($failure.rollback_result -eq 'rollback-failed')
            } catch {
                $message = "$message; failure evidence could not be parsed: $($_.Exception.Message)"
            }
        }
        $attempts.Add([ordered]@{
            probe = $probeNumber
            result = 'failed'
            owner = if ($Target -eq 'file-organization') { 'codex-file-organization' } else { 'codex-self-evolution' }
            failure = $message
            rollback_critical = $rollbackCritical
            checked_at = [DateTime]::UtcNow.ToString('o')
        })
        if (-not $reportDirectory -and -not $SkipErrorReportForTest) {
            $owner = if ($Target -eq 'file-organization') { 'codex-file-organization' } else { 'codex-self-evolution' }
            $createdReport = & (Join-Path $root 'skills\codex-error-feedback\scripts\New-ErrorFeedbackReport.ps1') -ProjectRoot $root -Module $owner -Component 'continuous-diagnosis probe' -UserReport "Continuous diagnosis detected a $Target probe failure." -ExpectedResult 'The complete selected owner probe passes.' -ActualResult $message -Features 'Failure occurred inside the named continuous-diagnosis loop and will be repaired only through the explicit repair action.' -SuspectedCauses 'Unresolved until the owner repair is verified.' -PossibleOutcomes 'The selected iteration capability remains incomplete and Git gates must not accept it.' -Solutions 'Run the configured safe owner repair and restart the complete probe.' -Verification 'The same continuous-diagnosis run must finish with a clean complete probe.' -Severity medium -Confidence medium
            $reportDirectory = Split-Path -Parent ([string]$createdReport.metadata)
        }
        if ($rollbackCritical) {
            Write-DiagnosisEvidence -Status 'blocked' -Attempts $attempts -Blocker 'rollback-failed'
            if ($reportDirectory) { & (Join-Path $root 'skills\codex-error-feedback\scripts\New-ErrorFeedbackReport.ps1') -ReportDirectory $reportDirectory -Status triaged -RepairAttempt 'No automatic repair attempted after rollback failure.' -RepairResult 'Blocked to preserve exact active state.' -Verification 'last-iteration-failure.json reports rollback-failed.' | Out-Null }
            throw 'Continuous diagnosis stopped because exact rollback failed; further automatic mutation is unsafe.'
        }
        if ($MaxRepairAttempts -gt 0 -and $repairCount -ge $MaxRepairAttempts) {
            Write-DiagnosisEvidence -Status 'blocked' -Attempts $attempts -Blocker 'repair-attempt-limit'
            throw "Continuous diagnosis reached the configured repair-attempt limit ($MaxRepairAttempts)."
        }
        $repairCount++
        Write-DiagnosisEvidence -Status 'repairing' -Attempts $attempts
        try {
            & $RepairScript -RepositoryRoot $root -Target $Target -Attempt $repairCount -FailureRecordPath $EvidencePath
            if (-not $?) { throw 'Repair script returned failure.' }
        } catch {
            $attempts.Add([ordered]@{
                repair = $repairCount
                result = 'blocked'
                failure = $_.Exception.Message
                checked_at = [DateTime]::UtcNow.ToString('o')
            })
            Write-DiagnosisEvidence -Status 'blocked' -Attempts $attempts -Blocker 'repair-action-failed'
            if ($reportDirectory) { & (Join-Path $root 'skills\codex-error-feedback\scripts\New-ErrorFeedbackReport.ps1') -ReportDirectory $reportDirectory -Status triaged -RepairAttempt "Explicit repair action $repairCount" -RepairResult $_.Exception.Message -Verification 'Repair action failed before the next owner probe.' | Out-Null }
            throw "Continuous diagnosis repair action failed safely: $($_.Exception.Message)"
        }
    }
}
