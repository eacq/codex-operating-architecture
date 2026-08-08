[CmdletBinding()]
param(
    [string]$RepositoryRoot = 'F:\codex'
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath $RepositoryRoot).Path
$runner = Join-Path $root 'skills\codex-office-cli\scripts\Invoke-AgentDocParsePipeline.ps1'
if (-not (Test-Path -LiteralPath $runner -PathType Leaf)) { throw 'Agent document parse pipeline runner is missing.' }

$tmp = Join-Path $root ('.runtime\tmp\agent-doc-parse-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Force -Path $tmp | Out-Null
try {
    $textPath = Join-Path $tmp 'sample.md'
    Set-Content -LiteralPath $textPath -Encoding UTF8 -Value @(
        '# Contract'
        'Global Experience Agent'
        '营业收入 and ROE are required keywords.'
    )
    $json = & $runner -RepositoryRoot $root -Path $textPath -Keyword @('营业收入', 'ROE')
    $textDoc = $json | ConvertFrom-Json
    if ($LASTEXITCODE -ne 0 -or $textDoc.file_type -ne 'text' -or @($textDoc.chunks).Count -lt 2) {
        throw 'Text document did not parse into chunks.'
    }
    if (-not $textDoc.metadata.validation.passed -or $textDoc.metadata.validation.content.found_keywords -ne 2) {
        throw 'Keyword validation did not pass for parsed text.'
    }

    $csvPath = Join-Path $tmp 'sheet.csv'
    Set-Content -LiteralPath $csvPath -Encoding UTF8 -Value @(
        '股东名称,持股比例'
        'A公司,30%'
    )
    $csvJson = & $runner -RepositoryRoot $root -Path $csvPath -Keyword '持股比例'
    $csvDoc = $csvJson | ConvertFrom-Json
    if ($LASTEXITCODE -ne 0 -or $csvDoc.file_type -ne 'csv' -or @($csvDoc.chunks | Where-Object table_id).Count -ne 2) {
        throw 'CSV table parse did not preserve table chunks.'
    }
    if (@($csvDoc.chunks | Where-Object { $_.line_no -ge 1 }).Count -ne 2) {
        throw 'CSV table parse did not preserve line numbers.'
    }

    $emptyPath = Join-Path $tmp 'empty.pdf'
    New-Item -ItemType File -Path $emptyPath | Out-Null
    $emptyJson = & $runner -RepositoryRoot $root -Path $emptyPath
    $emptyExit = $LASTEXITCODE
    $emptyDoc = $emptyJson | ConvertFrom-Json
    if ($emptyExit -eq 0 -or $emptyDoc.error -ne 'empty_file' -or -not $emptyDoc.metadata.validation.robustness.handled_boundary) {
        throw 'Empty file did not fail with a typed robustness boundary.'
    }

    $fakePdf = Join-Path $tmp 'native.pdf'
    [IO.File]::WriteAllBytes($fakePdf, [Text.Encoding]::ASCII.GetBytes('%PDF-1.7 /Type /Page /Font BT /ToUnicode'))
    $pdfJson = & $runner -RepositoryRoot $root -Path $fakePdf
    $pdfDoc = $pdfJson | ConvertFrom-Json
    if ($LASTEXITCODE -ne 0 -or $pdfDoc.file_type -ne 'pdf' -or $pdfDoc.strategy -ne 'pdfplumber_optional') {
        throw 'PDF preflight did not route native-like PDF to the light optional parser strategy.'
    }

    [pscustomobject]@{
        status = 'passed'
        model = 'agent-doc-parse-pipeline'
        text_chunks = @($textDoc.chunks).Count
        csv_chunks = @($csvDoc.chunks).Count
        pdf_strategy = $pdfDoc.strategy
    } | ConvertTo-Json -Compress
} finally {
    if (Test-Path -LiteralPath $tmp) {
        Remove-Item -LiteralPath $tmp -Recurse -Force
    }
}
