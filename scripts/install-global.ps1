[CmdletBinding(SupportsShouldProcess)]
param(
    [string]$CodexHome = (Join-Path $HOME '.codex'),
    [ValidateSet('Junction', 'Copy')]
    [string]$Mode = 'Junction'
)

$ErrorActionPreference = 'Stop'
$sourceRoot = Join-Path $PSScriptRoot '..\skills'
$targetRoot = Join-Path $CodexHome 'skills'
New-Item -ItemType Directory -Force -Path $targetRoot | Out-Null

Get-ChildItem -LiteralPath $sourceRoot -Directory | ForEach-Object {
    $source = (Resolve-Path -LiteralPath $_.FullName).Path
    $target = Join-Path $targetRoot $_.Name
    if ($PSCmdlet.ShouldProcess($target, "Install skill from $source using $Mode mode")) {
        $alreadyLinked = $false
        if (Test-Path -LiteralPath $target) {
            $existing = Get-Item -LiteralPath $target -Force
            $existingTarget = if ($existing.LinkType -eq 'Junction') { [string]$existing.Target } else { '' }
            if ($Mode -eq 'Junction' -and $existing.LinkType -eq 'Junction' -and $existingTarget.TrimEnd('\') -ieq $source.TrimEnd('\')) {
                Write-Host "Linked $($_.Name) -> $source"
                $alreadyLinked = $true
            } else {
                if ($existing.LinkType) {
                    Remove-Item -LiteralPath $target -Force
                } else {
                    Remove-Item -LiteralPath $target -Recurse -Force
                }
            }
        }
        if (-not $alreadyLinked) {
            if ($Mode -eq 'Junction') {
                New-Item -ItemType Junction -Path $target -Target $source | Out-Null
                Write-Host "Linked $($_.Name) -> $source"
            } else {
                Copy-Item -LiteralPath $source -Destination $target -Recurse
                Write-Host "Copied $($_.Name)"
            }
        }
    }
}

$guidanceSource = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..\config\global-AGENTS.md')).Path
$guidanceTarget = Join-Path $CodexHome 'AGENTS.md'
if ($PSCmdlet.ShouldProcess($guidanceTarget, "Link global project lifecycle guidance to $guidanceSource")) {
    $createGuidanceLink = $true
    if (Test-Path -LiteralPath $guidanceTarget) {
        $existingGuidance = Get-Item -LiteralPath $guidanceTarget -Force
        $existingGuidanceTarget = if ($existingGuidance.LinkType -eq 'SymbolicLink') { [string]$existingGuidance.Target } else { '' }
        if ($existingGuidance.LinkType -eq 'SymbolicLink' -and $existingGuidanceTarget.TrimEnd('\') -ieq $guidanceSource.TrimEnd('\')) {
            $createGuidanceLink = $false
        } elseif (-not $existingGuidance.LinkType) {
            $existingContent = Get-Content -LiteralPath $guidanceTarget -Raw -Encoding UTF8
            $isManagedGuidance = $existingContent.StartsWith('<!-- managed-source:') -and $existingContent.Contains('\config\global-AGENTS.md -->')
            if ($existingGuidance.Length -eq 0 -or $isManagedGuidance) {
                Remove-Item -LiteralPath $guidanceTarget -Force
            } else {
                throw "Refusing to replace non-empty user global guidance: $guidanceTarget"
            }
        } else {
            throw "Refusing to replace non-empty or unrelated global guidance: $guidanceTarget"
        }
    }
    if ($createGuidanceLink) {
        try {
            New-Item -ItemType SymbolicLink -Path $guidanceTarget -Target $guidanceSource -ErrorAction Stop | Out-Null
        } catch [System.UnauthorizedAccessException] {
            Copy-Item -LiteralPath $guidanceSource -Destination $guidanceTarget
            Write-Warning 'File symbolic links require unavailable privileges; installed a managed global-guidance interface copy instead.'
        }
    }
    Write-Host "Installed global guidance interface -> $guidanceSource"
}

& (Join-Path $PSScriptRoot 'validate-global-install.ps1') -CodexHome $CodexHome
if (-not $?) { throw 'Global skill installation validation failed.' }
Write-Host "Global skills installed in $Mode mode. Restart Codex tasks to refresh the catalog and global guidance."
