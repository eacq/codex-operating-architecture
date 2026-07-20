[CmdletBinding()]
param(
    [string]$ProjectRoot = (Get-Location).Path,
    [Parameter(Mandatory = $true)] [string]$ReportDirectory,
    [ValidateSet('fixed', 'verified')] [string]$Status = 'verified',
    [Parameter(Mandatory = $true)] [string]$RepairAttempt,
    [Parameter(Mandatory = $true)] [string]$RepairResult,
    [Parameter(Mandatory = $true)] [string]$Verification,
    [string]$ArchitectureRoot = '',
    [switch]$Apply
)

$ErrorActionPreference = 'Stop'
$stopwatch = [Diagnostics.Stopwatch]::StartNew()
$root = (Resolve-Path -LiteralPath $ProjectRoot).Path
$reportDirectoryFull = (Resolve-Path -LiteralPath $ReportDirectory).Path
$architecture = if ($ArchitectureRoot) {
    (Resolve-Path -LiteralPath $ArchitectureRoot).Path
} elseif ((Test-Path -LiteralPath (Join-Path $root 'module-registry.json')) -and (Test-Path -LiteralPath (Join-Path $root 'skills\codex-self-evolution\SKILL.md'))) {
    $root
} else {
    'F:\codex'
}

$plan = [ordered]@{
    result = 'error-feedback-closeout-planned'
    report_directory = $reportDirectoryFull
    status = $Status
    architecture_root = $architecture
    apply = [bool]$Apply
}
if (-not $Apply) {
    $stopwatch.Stop()
    $plan['duration_ms'] = [math]::Round($stopwatch.Elapsed.TotalMilliseconds, 1)
    $plan | ConvertTo-Json -Depth 4
    return
}

$closed = & (Join-Path $PSScriptRoot 'New-ErrorFeedbackReport.ps1') `
    -ProjectRoot $root `
    -ArchitectureRoot $architecture `
    -ReportDirectory $reportDirectoryFull `
    -Status $Status `
    -RepairAttempt $RepairAttempt `
    -RepairResult $RepairResult `
    -Verification $Verification
$review = & (Join-Path $PSScriptRoot 'Invoke-WorkflowErrorReview.ps1') -ProjectRoot $root -ReportDirectory $reportDirectoryFull -Apply | ConvertFrom-Json
$report = Get-Content -LiteralPath (Join-Path $reportDirectoryFull 'report.json') -Raw -Encoding UTF8 | ConvertFrom-Json

$inboxPath = Join-Path $architecture '.codex\project\incoming-error-feedback.jsonl'
$incoming = @()
if (Test-Path -LiteralPath $inboxPath) {
    $incoming = @(Get-Content -LiteralPath $inboxPath -Encoding UTF8 |
        Where-Object { $_.Trim() } |
        ForEach-Object { $_ | ConvertFrom-Json })
}
$withKey = @($incoming | Where-Object { $_.report_metadata })
$withoutKey = @($incoming | Where-Object { -not $_.report_metadata })
$latest = @($withKey | Group-Object report_metadata | ForEach-Object { $_.Group | Sort-Object recorded_at | Select-Object -Last 1 })
$blocking = @($withoutKey + $latest | Where-Object {
    $_.severity -in @('high', 'critical') -and
    $_.status -notin @('fixed', 'verified') -and
    $_.experience_system_causality -in @('suspected', 'partial', 'primary', 'verified')
})
$stopwatch.Stop()

[ordered]@{
    result = 'error-feedback-closed'
    report = $closed.metadata
    status = $report.status
    global_inbox_updated = [bool]$closed.global_inbox_updated
    blocking_incoming_count = $blocking.Count
    scripted_steps = @('report-status-update', 'workflow-error-review', 'utf8-global-inbox-audit')
    duration_ms = [math]::Round($stopwatch.Elapsed.TotalMilliseconds, 1)
    workflow_review = $review
} | ConvertTo-Json -Depth 6
