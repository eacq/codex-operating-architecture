[CmdletBinding()]
param([string]$RepositoryRoot = 'F:\codex')

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath $RepositoryRoot).Path
$controller = Get-Content -LiteralPath (Join-Path $root 'agent\40-runtime\Invoke-GlobalExperienceAgent.ps1') -Raw -Encoding UTF8
$runtime = Get-Content -LiteralPath (Join-Path $root 'agent\40-runtime\Invoke-GlobalExperienceAgentRuntime.ps1') -Raw -Encoding UTF8
foreach ($term in @('TaskStartedAt','HostWorkedSeconds')) {
    if ($controller -notmatch [regex]::Escape($term) -or $runtime -notmatch [regex]::Escape($term)) { throw "GEA timing input missing: $term" }
}
foreach ($term in @('task_wall_clock_seconds','host_reported_worked_seconds','operation_wall_clock_seconds','agent_session_wall_clock_seconds','task_time_status')) {
    if ($runtime -notmatch [regex]::Escape($term)) { throw "GEA layered timing field missing: $term" }
}
if ($runtime -notmatch 'Child Agent host Worked for is not inferred') { throw 'Child Agent timing boundary is missing.' }
$lastPath = Join-Path $root '.codex\project\global-experience-agent-last-run.json'
if (Test-Path -LiteralPath $lastPath -PathType Leaf) {
    $last = Get-Content -LiteralPath $lastPath -Raw -Encoding UTF8 | ConvertFrom-Json
    if ($last.status -eq 'passed' -and $null -eq $last.timing) { throw 'Latest GEA run lacks layered timing evidence.' }
}
Write-Host 'Global experience agent timing contract test passed.'
