[CmdletBinding()]
param(
    [string]$RepositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..\..\..')).Path,
    [string]$WorkspacePath,
    [string]$ExpectedCommit = '10f0adc0600ff28a470d55992133b1992c56968a',
    [switch]$Json
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath $RepositoryRoot).Path
$runtimeRoot = $root
if ($env:CODEX_VALIDATION_RUNTIME_ROOT) {
    $runtimeRoot = (Resolve-Path -LiteralPath $env:CODEX_VALIDATION_RUNTIME_ROOT).Path
}
if (-not $WorkspacePath) {
    $WorkspacePath = Join-Path $runtimeRoot '.runtime\work\network-learning-ppt-master'
}
$releaseMaterialWorkspace = Join-Path $runtimeRoot '.runtime\work\network-learning\ppt-master\release-v4.1.0\ppt-master\skills\ppt-master'
$fullRepositoryArchive = Join-Path $runtimeRoot '.runtime\work\network-learning\ppt-master\full-repo\releases\ppt-master-main.zip'
$fullRepositoryWorkspace = Join-Path $runtimeRoot '.runtime\work\network-learning\ppt-master\full-repo\workspace\ppt-master-main'

$exists = Test-Path -LiteralPath $WorkspacePath -PathType Container
$releaseMaterialExists = Test-Path -LiteralPath $releaseMaterialWorkspace -PathType Container
$fullRepositoryArchiveExists = Test-Path -LiteralPath $fullRepositoryArchive -PathType Leaf
$fullRepositoryExists = Test-Path -LiteralPath $fullRepositoryWorkspace -PathType Container
$fullRepositorySkillPath = Join-Path $fullRepositoryWorkspace 'skills\ppt-master\SKILL.md'
$fullRepositoryRequirementsPath = Join-Path $fullRepositoryWorkspace 'skills\ppt-master\requirements.txt'
$fullRepositoryDocsPath = Join-Path $fullRepositoryWorkspace 'docs'
$fullRepositoryArchiveHash = if ($fullRepositoryArchiveExists) { (Get-FileHash -Algorithm SHA256 -LiteralPath $fullRepositoryArchive).Hash.ToLowerInvariant() } else { $null }
$head = $null
$skillPath = Join-Path $WorkspacePath 'skills\ppt-master\SKILL.md'
$requirementsPath = Join-Path $WorkspacePath 'skills\ppt-master\requirements.txt'
$scriptRoot = Join-Path $WorkspacePath 'skills\ppt-master\scripts'
$entryScripts = @(
    'project_manager.py',
    'source_to_md.py',
    'svg_quality_checker.py',
    'finalize_svg.py',
    'svg_to_pptx.py',
    'template_fill_pptx.py',
    'native_enhance_pptx.py'
)

if ($exists) {
    $head = (& git -C $WorkspacePath rev-parse HEAD 2>$null)
    if ($LASTEXITCODE -ne 0) { $head = $null }
}

$missing = New-Object System.Collections.Generic.List[string]
if (-not $exists) { $missing.Add('workspace') | Out-Null }
if ($exists -and -not (Test-Path -LiteralPath $skillPath -PathType Leaf)) { $missing.Add('skills/ppt-master/SKILL.md') | Out-Null }
if ($exists -and -not (Test-Path -LiteralPath $requirementsPath -PathType Leaf)) { $missing.Add('skills/ppt-master/requirements.txt') | Out-Null }
foreach ($script in $entryScripts) {
    $path = Join-Path $scriptRoot $script
    if ($exists -and -not (Test-Path -LiteralPath $path -PathType Leaf)) { $missing.Add("scripts/$script") | Out-Null }
}

$status = if (-not $exists -or $missing.Count -gt 0) {
    'missing'
} elseif ($head -ne $ExpectedCommit) {
    'commit-drift'
} else {
    'ready'
}

$result = [ordered]@{
    status = $status
    workspace = $WorkspacePath
    expected_commit = $ExpectedCommit
    head = $head
    missing = @($missing.ToArray())
    skill = if (Test-Path -LiteralPath $skillPath -PathType Leaf) { $skillPath } else { $null }
    requirements = if (Test-Path -LiteralPath $requirementsPath -PathType Leaf) { $requirementsPath } else { $null }
    release_material_status = if ($releaseMaterialExists) { 'ready' } else { 'missing' }
    release_material_workspace = if ($releaseMaterialExists) { $releaseMaterialWorkspace } else { $null }
    full_repository_status = if ($fullRepositoryExists -and (Test-Path -LiteralPath $fullRepositorySkillPath -PathType Leaf) -and (Test-Path -LiteralPath $fullRepositoryRequirementsPath -PathType Leaf)) { 'ready' } else { 'missing' }
    full_repository_kind = 'local-runtime-corpus'
    full_repository_archive = if ($fullRepositoryArchiveExists) { $fullRepositoryArchive } else { $null }
    full_repository_archive_sha256 = $fullRepositoryArchiveHash
    full_repository_workspace = if ($fullRepositoryExists) { $fullRepositoryWorkspace } else { $null }
    full_repository_skill = if (Test-Path -LiteralPath $fullRepositorySkillPath -PathType Leaf) { $fullRepositorySkillPath } else { $null }
    full_repository_requirements = if (Test-Path -LiteralPath $fullRepositoryRequirementsPath -PathType Leaf) { $fullRepositoryRequirementsPath } else { $null }
    full_repository_docs = if (Test-Path -LiteralPath $fullRepositoryDocsPath -PathType Container) { $fullRepositoryDocsPath } else { $null }
}

if ($Json) {
    $result | ConvertTo-Json -Depth 4
} else {
    "PPT Master workspace: $($result.status)"
    "Path: $($result.workspace)"
    "HEAD: $($result.head)"
    "Release material: $($result.release_material_status) $($result.release_material_workspace)"
    "Full repository: $($result.full_repository_status) $($result.full_repository_workspace)"
    "Full repository archive SHA256: $($result.full_repository_archive_sha256)"
    if ($missing.Count -gt 0) { "Missing: $($missing -join ', ')" }
}

if ($status -eq 'missing') { exit 1 }
