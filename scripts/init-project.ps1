[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)]
    [string]$ProjectRoot,
    [switch]$InstallGitHook
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath $ProjectRoot).Path
$initializer = Join-Path $PSScriptRoot '..\skills\codex-project-optimization\scripts\initialize_project.py'
$python = if ($env:CODEX_PYTHON) { $env:CODEX_PYTHON } else { 'python' }
if (-not (Test-Path -LiteralPath $python)) { $python = 'python' }
$arguments = @($initializer, '--project-root', $root)
if ($InstallGitHook) { $arguments += '--install-git-hook' }
if ($PSCmdlet.ShouldProcess($root, 'Initialize Codex project lifecycle')) {
    & $python @arguments
    if ($LASTEXITCODE -ne 0) { throw 'Project initialization failed.' }
}
