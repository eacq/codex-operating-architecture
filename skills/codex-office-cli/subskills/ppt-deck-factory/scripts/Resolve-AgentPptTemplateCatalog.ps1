[CmdletBinding()]
param(
    [string]$RepositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..\..\..')).Path,
    [switch]$Json
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath $RepositoryRoot).Path
$runtimeRoot = $root
if ($env:CODEX_VALIDATION_RUNTIME_ROOT) {
    $runtimeRoot = (Resolve-Path -LiteralPath $env:CODEX_VALIDATION_RUNTIME_ROOT).Path
}

function Resolve-CatalogPath([string]$RelativePath) {
    if ($RelativePath -match '^\.runtime[\\/]') {
        return Join-Path $runtimeRoot $RelativePath
    }
    return Join-Path $root $RelativePath
}

function Test-TemplateFile([string]$Path) {
    if ([string]::IsNullOrWhiteSpace($Path)) { return $false }
    Test-Path -LiteralPath (Resolve-CatalogPath $Path) -PathType Leaf
}

$templates = @(
    [ordered]@{
        id = 'general-group-meeting-template'
        title = 'General group meeting PPT template'
        kind = 'academic-group-meeting'
        route = 'fill-native-pptx'
        workspace = '.runtime/work/agent-ppt-decks/group-meeting-template-20260724'
        pptx = '.runtime/work/agent-ppt-decks/group-meeting-template-20260724/exports/general-group-meeting-template.pptx'
        potx = '.runtime/work/agent-ppt-decks/group-meeting-template-20260724/exports/general-group-meeting-template.potx'
        authoring = '.runtime/work/agent-ppt-decks/group-meeting-template-20260724/authoring/build_group_meeting_template.py'
        potx_exporter = '.runtime/work/agent-ppt-decks/group-meeting-template-20260724/authoring/Export-TemplatePotx.ps1'
        preview = '.runtime/work/agent-ppt-decks/group-meeting-template-20260724/preview/contact-sheet-v3.png'
        use_when = @('group meeting', 'lab meeting', 'academic report', 'research progress', 'technical report')
        style = 'academic-report editorial/data-journalism'
        notes = 'PowerPoint-openable PPTX and POTX; readable logo/page-number revision verified by actual PPTX render.'
    }
)

$resolved = @()
foreach ($template in $templates) {
    $checks = [ordered]@{
        workspace = Test-Path -LiteralPath (Resolve-CatalogPath $template.workspace) -PathType Container
        pptx = Test-TemplateFile $template.pptx
        potx = Test-TemplateFile $template.potx
        authoring = Test-TemplateFile $template.authoring
        potx_exporter = Test-TemplateFile $template.potx_exporter
        preview = Test-TemplateFile $template.preview
    }
    $status = if (@($checks.Values | Where-Object { -not $_ }).Count -eq 0) { 'ready' } else { 'incomplete' }
    $resolved += [pscustomobject][ordered]@{
        id = $template.id
        title = $template.title
        kind = $template.kind
        route = $template.route
        workspace = $template.workspace
        pptx = $template.pptx
        potx = $template.potx
        authoring = $template.authoring
        potx_exporter = $template.potx_exporter
        preview = $template.preview
        use_when = @($template.use_when)
        style = $template.style
        notes = $template.notes
        status = $status
        checks = $checks
    }
}

$result = [pscustomobject][ordered]@{
    schema_version = 1
    model = 'agent-ppt-template-catalog'
    repository_root = $root
    templates = $resolved
    ready_count = @($resolved | Where-Object status -eq 'ready').Count
}

if ($Json) {
    $result | ConvertTo-Json -Depth 6
} else {
    $result.templates | Format-Table id, kind, route, status, pptx, potx -AutoSize
}
