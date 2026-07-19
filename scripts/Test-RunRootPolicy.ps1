$ErrorActionPreference = 'Stop'

$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$runtimeRoot = [IO.Path]::GetFullPath((Join-Path $root '.runtime')).TrimEnd('\')

foreach ($kind in @('tmp','work','cache','installers','software')) {
    $resolved = & (Join-Path $root 'scripts\Resolve-CodexRunRoot.ps1') -ArchitectureRoot $root -Kind $kind -IgnoreConfiguredRoot
    $full = [IO.Path]::GetFullPath($resolved).TrimEnd('\')
    if (-not ($full -eq $runtimeRoot -or $full.StartsWith($runtimeRoot + '\', [StringComparison]::OrdinalIgnoreCase))) {
        throw "Default $kind root escapes .runtime: $full"
    }
}

$policy = Get-Content -LiteralPath (Join-Path $root 'config\software-install-policy.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$exceptionText = (@($policy.exceptions_requiring_report_before_install) -join ' ')
if ($exceptionText -notmatch 'WindowsApps') {
    throw 'Software install policy must preserve WindowsApps as an installer-controlled exception.'
}

$fixture = & (Join-Path $root 'scripts\Resolve-CodexRunRoot.ps1') -ArchitectureRoot $root -Kind tmp -ChildPath ('run-root-policy-' + [guid]::NewGuid().ToString('N')) -IgnoreConfiguredRoot -Create
try {
    if (-not ([IO.Path]::GetFullPath($fixture).StartsWith($runtimeRoot + '\', [StringComparison]::OrdinalIgnoreCase))) {
        throw "Fixture root escaped .runtime: $fixture"
    }
} finally {
    if (Test-Path -LiteralPath $fixture) { Remove-Item -LiteralPath $fixture -Recurse -Force }
}

$profileFixture = & (Join-Path $root 'scripts\Resolve-CodexRunRoot.ps1') -ArchitectureRoot $root -Kind tmp -ChildPath ('run-root-profile-' + [guid]::NewGuid().ToString('N')) -IgnoreConfiguredRoot -Create
$previousProfile = $env:CODEX_PORTABLE_SKILL_PROFILE
try {
    $profileWorkRoot = Join-Path $profileFixture 'profile-work'
    $profilePath = Join-Path $profileFixture 'portable-skill.json'
    @{
        schema_version = 1
        software = @{
            temporary_root = ''
            work_root = $profileWorkRoot
            cache_root = ''
            archive_root = ''
            install_root = ''
        }
    } | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath $profilePath -Encoding UTF8
    $env:CODEX_PORTABLE_SKILL_PROFILE = $profilePath
    $resolvedProfileWork = & (Join-Path $root 'scripts\Resolve-CodexRunRoot.ps1') -ArchitectureRoot $root -Kind work
    if ([IO.Path]::GetFullPath($resolvedProfileWork).TrimEnd('\') -ine [IO.Path]::GetFullPath($profileWorkRoot).TrimEnd('\')) {
        throw 'Portable profile work_root was not honored.'
    }
} finally {
    $env:CODEX_PORTABLE_SKILL_PROFILE = $previousProfile
    if (Test-Path -LiteralPath $profileFixture) { Remove-Item -LiteralPath $profileFixture -Recurse -Force }
}

$forbidden = '\[IO\.Path\]::GetTempPath\(\)|New-TemporaryFile|\$env:TEMP|\$env:TMP|tempfile\.gettempdir\(\)|os\.tmpdir\(\)'
$scanRoots = @(
    (Join-Path $root 'scripts'),
    (Join-Path $root 'skills')
)
$violations = @()
foreach ($scanRoot in $scanRoots) {
    Get-ChildItem -LiteralPath $scanRoot -Recurse -File -Include *.ps1,*.psm1,*.py,*.js,*.mjs |
        Where-Object {
            $relative = $_.FullName.Substring($root.Length + 1) -replace '\\','/'
            $relative -notmatch '/subskills/imported-codex-home/' -and
            $relative -ne 'scripts/Test-RunRootPolicy.ps1'
        } |
        ForEach-Object {
            $content = Get-Content -LiteralPath $_.FullName -Raw -Encoding UTF8
            if ($content -match $forbidden) {
                $violations += ($_.FullName.Substring($root.Length + 1) -replace '\\','/')
            }
        }
}
if ($violations.Count -gt 0) {
    throw "First-party scripts must use Resolve-CodexRunRoot.ps1 instead of system temp roots: $($violations -join ', ')"
}

Write-Host 'Codex run-root policy test passed.'
