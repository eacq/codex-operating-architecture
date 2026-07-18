[CmdletBinding()]
param(
    [string]$ProjectRoot = (Get-Location).Path,
    [switch]$Open,
    [switch]$NoRefresh
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath $ProjectRoot).Path
$reportPath = Join-Path $root '.codex\project\candidate-reports\latest.md'
$generator = Join-Path $root 'skills\codex-experience-capture\scripts\New-GlobalIterationCandidateReport.ps1'
if (-not $NoRefresh) {
    if (-not (Test-Path -LiteralPath $generator)) { throw "Candidate report generator was not found: $generator" }
    & $generator -ProjectRoot $root -Apply | Out-Null
}
if (-not (Test-Path -LiteralPath $reportPath)) { throw "Candidate report was not found: $reportPath." }
$code = Get-Command code -ErrorAction SilentlyContinue
if (-not $code) { throw 'Visual Studio Code command `code` is unavailable. Install or expose VS Code command-line support, then retry.' }
$result = [ordered]@{ report = $reportPath; editor = $code.Source; command = "code --reuse-window --goto `"${reportPath}:1`""; opened = [bool]$Open }
if ($Open) { & $code.Source --reuse-window --goto "${reportPath}:1" }
$result | ConvertTo-Json -Depth 3
