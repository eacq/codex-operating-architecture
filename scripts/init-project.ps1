[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)]
    [string]$ProjectRoot,
    [switch]$InstallGitHook
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath $ProjectRoot).Path
$initializer = Join-Path $PSScriptRoot '..\skills\codex-project-optimization\scripts\initialize_project.py'
$organizationLifecycle = Join-Path $PSScriptRoot '..\skills\codex-file-organization\scripts\Invoke-FileOrganizationLifecycle.ps1'
$python = $env:CODEX_PYTHON
$pythonPrefix = @()
if (-not $python) {
    # The WindowsApps python shim can silently exit without running a script.
    & py -3 -c 'import sys' 2>$null
    if ($LASTEXITCODE -eq 0) { $python = 'py'; $pythonPrefix = @('-3') }
    else { $python = 'python' }
}
$arguments = @($initializer, '--project-root', $root)
if ($InstallGitHook) { $arguments += '--install-git-hook' }
if ($PSCmdlet.ShouldProcess($root, 'Initialize Codex project lifecycle')) {
    & $python @pythonPrefix @arguments
    if ($LASTEXITCODE -ne 0) { throw 'Project initialization failed.' }
    & $organizationLifecycle -ProjectRoot $root -Phase project-initialization -Apply
    if ($LASTEXITCODE -ne 0) { throw 'Project file-organization lifecycle review failed.' }
}
