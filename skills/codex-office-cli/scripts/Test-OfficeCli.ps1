[CmdletBinding()]
param(
    [string]$RepositoryRoot = ''
)

$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) {
    $RepositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
}
$officecli = & (Join-Path $PSScriptRoot 'Get-OfficeCliPath.ps1') -RepositoryRoot $RepositoryRoot
$testRoot = Join-Path $RepositoryRoot ('.codex\tool-cache\officecli-smoke-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Force -Path $testRoot | Out-Null
$env:OFFICECLI_SKIP_UPDATE = '1'

function Invoke-OfficeCliJson([string[]]$Arguments) {
    $output = & $officecli @Arguments
    if ($LASTEXITCODE -ne 0) { throw "officecli failed: $($Arguments -join ' ')" }
    return ($output | Out-String | ConvertFrom-Json)
}

& $officecli --version | Out-Null
if ($LASTEXITCODE -ne 0) { throw 'officecli --version failed.' }
& $officecli --help | Out-Null
if ($LASTEXITCODE -ne 0) { throw 'officecli --help failed.' }

$docx = Join-Path $testRoot 'smoke.docx'
$pptx = Join-Path $testRoot 'smoke.pptx'
$xlsx = Join-Path $testRoot 'smoke.xlsx'

& $officecli create $docx | Out-Null
if ($LASTEXITCODE -ne 0) { throw 'officecli docx create failed.' }
$docAdd = Invoke-OfficeCliJson @('add', $docx, '/body', '--type', 'paragraph', '--prop', 'text=OfficeCLI smoke paragraph', '--json')
if (-not $docAdd.success) { throw 'officecli docx add did not report success.' }
$docSet = Invoke-OfficeCliJson @('set', $docx, '/body/p[1]', '--prop', 'firstLineIndent=24pt', '--json')
if (-not $docSet.success) { throw 'officecli docx set did not report success.' }
& $officecli save $docx | Out-Null
if ($LASTEXITCODE -ne 0) { throw 'officecli docx save failed.' }
$docView = Invoke-OfficeCliJson @('view', $docx, 'text', '--json')
if (-not $docView.success) { throw 'officecli docx view did not report success.' }
$docIssues = Invoke-OfficeCliJson @('view', $docx, 'issues', '--json')
if (-not $docIssues.success) { throw 'officecli docx issues did not report success.' }
$docValidate = Invoke-OfficeCliJson @('validate', $docx, '--json')
if (-not $docValidate.success) { throw 'officecli docx validate did not report success.' }

& $officecli create $pptx | Out-Null
if ($LASTEXITCODE -ne 0) { throw 'officecli pptx create failed.' }
$pptAdd = Invoke-OfficeCliJson @('add', $pptx, '/', '--type', 'slide', '--prop', 'title=OfficeCLI Smoke', '--json')
if (-not $pptAdd.success) { throw 'officecli pptx add did not report success.' }
& $officecli save $pptx | Out-Null
if ($LASTEXITCODE -ne 0) { throw 'officecli pptx save failed.' }
$pptView = Invoke-OfficeCliJson @('view', $pptx, 'outline', '--json')
if (-not $pptView.success) { throw 'officecli pptx view did not report success.' }
$pptIssues = Invoke-OfficeCliJson @('view', $pptx, 'issues', '--json')
if (-not $pptIssues.success) { throw 'officecli pptx issues did not report success.' }
if ($pptIssues.data.count -ne 0) { throw 'officecli pptx issues reported problems.' }
$pptValidate = Invoke-OfficeCliJson @('validate', $pptx, '--json')
if (-not $pptValidate.success) { throw 'officecli pptx validate did not report success.' }

& $officecli create $xlsx | Out-Null
if ($LASTEXITCODE -ne 0) { throw 'officecli xlsx create failed.' }
$xlsxSet = Invoke-OfficeCliJson @('set', $xlsx, '/Sheet1/A1', '--prop', 'value=OfficeCLI', '--json')
if (-not $xlsxSet.success) { throw 'officecli xlsx set did not report success.' }
& $officecli save $xlsx | Out-Null
if ($LASTEXITCODE -ne 0) { throw 'officecli xlsx save failed.' }
$xlsxGet = Invoke-OfficeCliJson @('get', $xlsx, '/Sheet1/A1', '--json')
if (-not $xlsxGet.success) { throw 'officecli xlsx get did not report success.' }
$xlsxIssues = Invoke-OfficeCliJson @('view', $xlsx, 'issues', '--json')
if (-not $xlsxIssues.success) { throw 'officecli xlsx issues did not report success.' }
if ($xlsxIssues.data.count -ne 0) { throw 'officecli xlsx issues reported problems.' }
$xlsxValidate = Invoke-OfficeCliJson @('validate', $xlsx, '--json')
if (-not $xlsxValidate.success) { throw 'officecli xlsx validate did not report success.' }

foreach ($file in @($docx, $pptx, $xlsx)) {
    & $officecli close $file 2>$null | Out-Null
}

Write-Host "OfficeCLI smoke test passed at $testRoot"
