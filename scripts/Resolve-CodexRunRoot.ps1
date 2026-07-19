[CmdletBinding()]
param(
    [string]$ArchitectureRoot = '',
    [ValidateSet('tmp','work','cache','installers','software')]
    [string]$Kind = 'tmp',
    [string]$ChildPath = '',
    [switch]$IgnoreConfiguredRoot,
    [switch]$Create
)

$ErrorActionPreference = 'Stop'

if (-not $ArchitectureRoot) {
    $ArchitectureRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
} else {
    $ArchitectureRoot = (Resolve-Path -LiteralPath $ArchitectureRoot).Path
}

function Resolve-ProfileRoot([string]$KindName) {
    $profilePath = if ($env:CODEX_PORTABLE_SKILL_PROFILE) { $env:CODEX_PORTABLE_SKILL_PROFILE } else { Join-Path $HOME '.codex\private-skill-config\portable-skill.json' }
    if (-not (Test-Path -LiteralPath $profilePath -PathType Leaf)) { return '' }
    try {
        $profile = Get-Content -LiteralPath $profilePath -Raw -Encoding UTF8 | ConvertFrom-Json
    } catch {
        return ''
    }
    if (-not $profile.software) { return '' }
    $fieldNames = @{
        tmp = 'temporary_root'
        work = 'work_root'
        cache = 'cache_root'
        installers = 'archive_root'
        software = 'install_root'
    }
    $fieldName = $fieldNames[$KindName]
    if (-not $fieldName) { return '' }
    $value = $profile.software.$fieldName
    if ($value) { return [string]$value }
    return ''
}

function Resolve-ConfiguredRoot([string]$EnvironmentName, [string]$KindName, [string]$Fallback, [bool]$IgnoreConfigured) {
    if ($IgnoreConfigured) { return $Fallback }
    $configured = [Environment]::GetEnvironmentVariable($EnvironmentName, 'Process')
    if (-not $configured) { $configured = [Environment]::GetEnvironmentVariable($EnvironmentName, 'User') }
    if (-not $configured) { $configured = [Environment]::GetEnvironmentVariable($EnvironmentName, 'Machine') }
    if ($configured) { return $configured }
    $profileRoot = Resolve-ProfileRoot $KindName
    if ($profileRoot) { return $profileRoot }
    return $Fallback
}

$defaults = @{
    tmp = Join-Path $ArchitectureRoot '.runtime\tmp'
    work = Join-Path $ArchitectureRoot '.runtime\work'
    cache = Join-Path $ArchitectureRoot '.runtime\cache'
    installers = Join-Path $ArchitectureRoot '.runtime\installers'
    software = Join-Path $ArchitectureRoot '.runtime\software'
}

$environmentNames = @{
    tmp = 'CODEX_RUN_TMP_ROOT'
    work = 'CODEX_RUN_WORK_ROOT'
    cache = 'CODEX_RUN_CACHE_ROOT'
    installers = 'SOFTWARE_ARCHIVE_ROOT'
    software = 'SOFTWARE_INSTALL_ROOT'
}

$root = Resolve-ConfiguredRoot $environmentNames[$Kind] $Kind $defaults[$Kind] ([bool]$IgnoreConfiguredRoot)
if (-not [IO.Path]::IsPathRooted($root)) {
    $root = Join-Path $ArchitectureRoot $root
}

$fullRoot = [IO.Path]::GetFullPath($root)
$architectureFull = [IO.Path]::GetFullPath($ArchitectureRoot).TrimEnd('\')
$runtimeFull = [IO.Path]::GetFullPath((Join-Path $ArchitectureRoot '.runtime')).TrimEnd('\')
$allowedByDefault = $fullRoot.TrimEnd('\').StartsWith($runtimeFull + '\', [StringComparison]::OrdinalIgnoreCase) -or
    ($fullRoot.TrimEnd('\') -eq $runtimeFull)

if (-not $allowedByDefault -and $IgnoreConfiguredRoot) {
    throw "Default $Kind root must stay under $architectureFull\.runtime."
}
if (-not $allowedByDefault -and -not [Environment]::GetEnvironmentVariable($environmentNames[$Kind], 'Process') -and -not [Environment]::GetEnvironmentVariable($environmentNames[$Kind], 'User') -and -not [Environment]::GetEnvironmentVariable($environmentNames[$Kind], 'Machine')) {
    throw "Default $Kind root must stay under $architectureFull\.runtime."
}

if ($ChildPath) {
    $candidate = [IO.Path]::GetFullPath((Join-Path $fullRoot $ChildPath))
    if (-not ($candidate.TrimEnd('\').StartsWith($fullRoot.TrimEnd('\') + '\', [StringComparison]::OrdinalIgnoreCase) -or $candidate.TrimEnd('\') -eq $fullRoot.TrimEnd('\'))) {
        throw "Child path escapes the $Kind root: $ChildPath"
    }
    $fullRoot = $candidate
}

if ($Create) {
    New-Item -ItemType Directory -Force -Path $fullRoot | Out-Null
}

Write-Output $fullRoot
