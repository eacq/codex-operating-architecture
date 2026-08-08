[CmdletBinding()]
param(
    [string]$RepositoryRoot = 'F:\codex',
    [switch]$IncludeAgentRuntimeState
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath $RepositoryRoot).Path
$textExtensions = @(
    '.bat', '.cfg', '.cmd', '.css', '.csv', '.html', '.ini', '.js', '.json',
    '.jsonl', '.lock', '.md', '.mermaid', '.mmd', '.ps1', '.psm1', '.py',
    '.sh', '.svg', '.toml', '.ts', '.tsv', '.txt', '.xml', '.yaml', '.yml'
)
$specialNames = @('.editorconfig', '.gitattributes', '.gitignore')
$archivePrefixes = @(
    'docs/readme-presentation-audits/',
    'docs/release-notes/',
    'docs/release-readme-audits/',
    'docs/release-visual-plans/'
)

function Test-TextCandidate([string]$RelativePath) {
    $normalized = $RelativePath -replace '\\', '/'
    if (@($archivePrefixes | Where-Object { $normalized.StartsWith($_, [StringComparison]::OrdinalIgnoreCase) }).Count -gt 0) { return $false }
    $extension = [IO.Path]::GetExtension($normalized).ToLowerInvariant()
    return $extension -in $textExtensions -or [IO.Path]::GetFileName($normalized) -in $specialNames
}

$relativePaths = @(& git -C $root -c core.quotePath=false ls-files --cached --others --exclude-standard)
if ($LASTEXITCODE -ne 0) { throw 'Repository text-encoding check could not enumerate Git-managed paths.' }
$paths = New-Object System.Collections.Generic.List[string]
foreach ($relative in $relativePaths) {
    if (-not (Test-TextCandidate $relative)) { continue }
    $full = Join-Path $root $relative
    if (Test-Path -LiteralPath $full -PathType Leaf) { $paths.Add($full) }
}
if ($IncludeAgentRuntimeState) {
    $projectStateRoot = Join-Path $root '.codex\project'
    if (Test-Path -LiteralPath $projectStateRoot -PathType Container) {
        Get-ChildItem -LiteralPath $projectStateRoot -Recurse -File |
            Where-Object { $_.Extension.ToLowerInvariant() -in @('.json', '.jsonl', '.md', '.txt', '.yaml', '.yml') } |
            ForEach-Object {
                $normalized = ($_.FullName -replace '\\', '/')
                $isArchiveCopy = @($archivePrefixes | Where-Object { $normalized.Contains($_) }).Count -gt 0
                if ($isArchiveCopy) { return }
                $paths.Add($_.FullName)
            }
    }
}

$strictUtf8 = [Text.UTF8Encoding]::new($false, $true)
$bomPaths = New-Object System.Collections.Generic.List[string]
$invalidPaths = New-Object System.Collections.Generic.List[string]
$powerShellBomRequired = New-Object System.Collections.Generic.List[string]
foreach ($path in @($paths | Sort-Object -Unique)) {
    $bytes = [IO.File]::ReadAllBytes($path)
    $display = if ($path.StartsWith($root, [StringComparison]::OrdinalIgnoreCase)) {
        ($path.Substring($root.Length).TrimStart('\', '/') -replace '\\', '/')
    } else { $path }
    $hasBom = $bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF
    $extension = [IO.Path]::GetExtension($path).ToLowerInvariant()
    try {
        $text = $strictUtf8.GetString($bytes)
        if ($extension -in @('.ps1', '.psm1')) {
            $hasNonAscii = $text.ToCharArray() | Where-Object { [int]$_ -gt 127 } | Select-Object -First 1
            if ($hasNonAscii -and -not $hasBom) { $powerShellBomRequired.Add($display) }
        }
        elseif ($hasBom) { $bomPaths.Add($display) }
    }
    catch { $invalidPaths.Add($display) }
}

if ($bomPaths.Count -gt 0 -or $invalidPaths.Count -gt 0 -or $powerShellBomRequired.Count -gt 0) {
    $details = @(
        if ($bomPaths.Count -gt 0) { "Data file UTF-8 BOM: $($bomPaths -join ', ')" }
        if ($invalidPaths.Count -gt 0) { "Invalid UTF-8: $($invalidPaths -join ', ')" }
        if ($powerShellBomRequired.Count -gt 0) { "PowerShell 5.1 source with non-ASCII but no UTF-8 BOM: $($powerShellBomRequired -join ', ')" }
    ) -join [Environment]::NewLine
    throw "Repository text encoding violates the cross-runtime UTF-8 contract.$([Environment]::NewLine)$details"
}

[pscustomobject]@{
    status = 'passed'
    encoding = 'UTF-8'
    data_bom = 'forbidden'
    powershell_non_ascii_bom = 'required-for-Windows-PowerShell-5.1'
    scanned = @($paths | Sort-Object -Unique).Count
    archive_prefixes_excluded = $archivePrefixes
    agent_runtime_state_included = [bool]$IncludeAgentRuntimeState
} | ConvertTo-Json -Compress
