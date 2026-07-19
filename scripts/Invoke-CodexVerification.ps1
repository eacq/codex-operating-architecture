[CmdletBinding()]
param(
    [string]$RepositoryRoot = (Get-Location).Path,
    [ValidateSet('Fast','Full')]
    [string]$Mode = 'Fast',
    [string[]]$ChangedPaths = @(),
    [switch]$NoRecord
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath $RepositoryRoot).Path
$timings = New-Object System.Collections.Generic.List[object]

function Invoke-TimedCheck {
    param([string]$Name, [scriptblock]$Check)
    $started = [DateTime]::UtcNow
    & $Check
    [void]$timings.Add([pscustomobject]@{
        name = $Name
        duration_seconds = [math]::Round(([DateTime]::UtcNow - $started).TotalSeconds, 3)
    })
}

function Get-RepositoryChanges {
    $pathCollector = Join-Path $root 'scripts\Get-CodexGitChangedPaths.ps1'
    @(& $pathCollector -RepositoryRoot $root)
}

$paths = @($ChangedPaths | Where-Object { $_ } | ForEach-Object { $_.Replace('\','/') } | Sort-Object -Unique)
if ($paths.Count -eq 0) { $paths = @(Get-RepositoryChanges) }

Invoke-TimedCheck 'codebase-memory-ui-preflight' {
    $starter = Join-Path $root 'scripts\Start-CodebaseMemoryGraphUi.ps1'
    if (-not (Test-Path -LiteralPath $starter)) { throw 'Codebase Memory graph UI starter is missing.' }
    & $starter -RepositoryRoot $root -ProjectName 'F-codex' -Port 9750 | ConvertFrom-Json | Out-Null
}

if ($Mode -eq 'Fast') {
    if ($paths.Count -eq 0) { throw 'Fast verification requires changed paths or a non-clean worktree.' }
    Invoke-TimedCheck 'changed-script-syntax' {
        foreach ($relative in $paths) {
            $fullPath = [IO.Path]::GetFullPath((Join-Path $root $relative))
            if (-not $fullPath.StartsWith($root + '\', [StringComparison]::OrdinalIgnoreCase) -or -not (Test-Path -LiteralPath $fullPath -PathType Leaf)) { continue }
            switch -Regex ($relative) {
                '\.ps1$' {
                    $tokens = $null; $errors = $null
                    [void][System.Management.Automation.Language.Parser]::ParseFile($fullPath, [ref]$tokens, [ref]$errors)
                    if ($errors) { throw "PowerShell syntax errors in ${relative}: $($errors | Out-String)" }
                }
                '\.mjs$' {
                    & node --check $fullPath
                    if ($LASTEXITCODE -ne 0) { throw "Node syntax errors in $relative." }
                }
                '\.json$' { Get-Content -LiteralPath $fullPath -Raw -Encoding UTF8 | ConvertFrom-Json | Out-Null }
            }
        }
    }
    if (@($paths | Where-Object { $_ -match '(^README|^ARCHITECTURE\.md$|^docs/.*(design-system|provenance)|^scripts/(Render-CodebaseMemoryGraph|capture_codebase_memory_graph_canvas|Test-CodebaseMemoryGraphRenderPolicy))' }).Count -gt 0) {
        Invoke-TimedCheck 'reader-facing-graph-contracts' {
            & (Join-Path $root 'scripts\Test-ReadmeIterationAlignment.ps1') -RepositoryRoot $root | Out-Null
            & (Join-Path $root 'scripts\Test-CodebaseMemoryGraphRenderPolicy.ps1') -RepositoryRoot $root | Out-Null
        }
    }
} else {
    Invoke-TimedCheck 'repository-validation' {
        & (Join-Path $root 'scripts\validate.ps1')
        if ($LASTEXITCODE -ne 0) { throw 'Repository validation failed.' }
    }
    Invoke-TimedCheck 'global-interface-validation' {
        & (Join-Path $root 'scripts\validate-global-install.ps1')
        if ($LASTEXITCODE -ne 0) { throw 'Global interface validation failed.' }
    }
    Invoke-TimedCheck 'diff-whitespace-check' {
        & git -C $root diff --check
        if ($LASTEXITCODE -ne 0) { throw 'Git whitespace check failed.' }
    }
}

$result = [ordered]@{
    schema_version = 1
    mode = $Mode
    changed_path_count = $paths.Count
    changed_paths = $paths
    step_timings = @($timings.ToArray())
    result = 'passed'
    completed_at = [DateTime]::UtcNow.ToString('o')
}
if (-not $NoRecord) {
    $recordPath = Join-Path $root '.codex\project\verification-last-run.json'
    $result | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $recordPath -Encoding UTF8
    $result['record'] = '.codex/project/verification-last-run.json'
}
$result | ConvertTo-Json -Depth 5
