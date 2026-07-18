[CmdletBinding()]
param(
    [string]$RepositoryRoot = (Get-Location).Path
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath $RepositoryRoot).Path
$designSystemPath = Join-Path $root 'docs/readme-design-system.json'
if (-not (Test-Path -LiteralPath $designSystemPath)) { throw 'Reader-facing visual delivery requires docs/readme-design-system.json.' }
$designSystem = Get-Content -LiteralPath $designSystemPath -Raw -Encoding UTF8 | ConvertFrom-Json
if ([string]::IsNullOrWhiteSpace($designSystem.in_image_text.decision_rule) -or
    [string]::IsNullOrWhiteSpace($designSystem.in_image_text.typography) -or
    [string]::IsNullOrWhiteSpace($designSystem.in_image_text.language_policy) -or
    @($designSystem.in_image_text.quality_gate).Count -lt 3) {
    throw 'Reader-facing visual delivery requires a complete in-image-text contract in the README design system.'
}

$readerDocuments = New-Object System.Collections.Generic.List[string]
foreach ($name in @('README.md','README.en.md','CHANGELOG.md')) {
    $path = Join-Path $root $name
    if (Test-Path -LiteralPath $path) { $readerDocuments.Add($path) }
}
if (Test-Path -LiteralPath (Join-Path $root 'docs')) {
    Get-ChildItem -LiteralPath (Join-Path $root 'docs') -Recurse -File -Filter '*.md' | Where-Object {
        $_.FullName -notmatch '[\\/](assets|release-visual-plans|readme-presentation-audits|release-readme-audits)[\\/]'
    } | ForEach-Object { $readerDocuments.Add($_.FullName) }
}

$violations = New-Object System.Collections.Generic.List[string]
foreach ($document in @($readerDocuments | Sort-Object -Unique)) {
    $content = Get-Content -LiteralPath $document -Raw -Encoding UTF8
    if ($content -match '(?im)!?\[[^\]]*\]\([^\)]*\.(mmd|svg)(?:[?#][^\)]*)?\)' -or
        $content -match '(?im)<(?:img|object|embed)[^>]+(?:src|data)=["''][^"'']*\.(mmd|svg)(?:[?#][^"'']*)?["'']') {
        $violations.Add((Resolve-Path -LiteralPath $document).Path)
    }
}
if ($violations.Count -gt 0) {
    throw ('Reader-facing Markdown links to an unsupported editable visual format: ' + (($violations | Sort-Object -Unique) -join '; '))
}

[ordered]@{
    result = 'reader-facing-visual-delivery-passed'
    documents_checked = @($readerDocuments | Sort-Object -Unique).Count
    reader_delivery = 'PNG/JPG/WebP only; Mermaid and SVG are maintainer sources.'
    in_image_text_contract = 'present'
} | ConvertTo-Json -Depth 4
