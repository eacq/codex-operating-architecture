[CmdletBinding()]
param([switch]$Uninstall)
$ErrorActionPreference = 'Stop'
$scheme = 'codex-report'
$key = "HKCU:\Software\Classes\$scheme"
if ($Uninstall) {
    if (Test-Path -LiteralPath $key) { Remove-Item -LiteralPath $key -Recurse -Force }
    [pscustomobject]@{ result='uninstalled'; scheme=$scheme } | ConvertTo-Json
    return
}
$launcher = Join-Path $PSScriptRoot 'Open-LatestGlobalIterationCandidateReport.cmd'
if (-not (Test-Path -LiteralPath $launcher)) { throw "Candidate report launcher is missing: $launcher" }
New-Item -Path $key -Force | Out-Null
New-ItemProperty -Path $key -Name '(Default)' -Value 'URL:Codex Candidate Report' -Force | Out-Null
New-ItemProperty -Path $key -Name 'URL Protocol' -Value '' -Force | Out-Null
$commandKey = Join-Path $key 'shell\open\command'
New-Item -Path $commandKey -Force | Out-Null
# The URI handler is a compatibility path only.  Codex's Markdown renderer is
# not guaranteed to dispatch custom schemes, so user-facing reports must link
# to the CMD launcher itself as the primary path.
$command = '"' + $env:ComSpec + '" /d /s /c ""' + $launcher + '" "%1""'
New-ItemProperty -Path $commandKey -Name '(Default)' -Value $command -Force | Out-Null
[pscustomobject]@{ result='installed'; scheme=$scheme; uri='codex-report://latest'; command=$command } | ConvertTo-Json -Depth 3
