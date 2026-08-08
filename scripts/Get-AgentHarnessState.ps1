# Compatibility adapter. The canonical implementation lives under agent/40-runtime.
$target = Join-Path (Split-Path -Parent $PSScriptRoot) 'agent\40-runtime\Get-AgentHarnessState.ps1'
if (-not (Test-Path -LiteralPath $target -PathType Leaf)) {
    throw 'Canonical global experience Agent state reader is missing.'
}
& $target @args
