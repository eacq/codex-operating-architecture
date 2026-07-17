$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
$fixture = Join-Path ([IO.Path]::GetTempPath()) ('codex-error-feedback-utf8-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Force -Path $fixture | Out-Null
try {
    $inputPath = Join-Path $fixture 'user-report.txt'
    $expected = -join @([char]0x8FED,[char]0x4EE3,[char]0x9519,[char]0x8BEF,[char]0x9700,[char]0x8981,[char]0x6301,[char]0x7EED,[char]0x4FEE,[char]0x590D)
    [IO.File]::WriteAllText($inputPath, $expected, [Text.UTF8Encoding]::new($false))
    $created = & (Join-Path $root 'skills\codex-error-feedback\scripts\New-ErrorFeedbackReport.ps1') -ProjectRoot $fixture -Module codex-self-evolution -Component 'utf8 input fixture' -UserReportFile $inputPath -ExpectedResult 'UTF-8 input is preserved.' -ActualResult 'Fixture run.'
    $report = Get-Content -LiteralPath $created.metadata -Raw -Encoding UTF8 | ConvertFrom-Json
    if ($report.user_report -ne $expected -or @($report.reported_issues)[0] -ne $expected) { throw 'UTF-8 user report file input was not preserved.' }
    Write-Host 'Error-feedback UTF-8 file-input test passed.'
}
finally {
    if (Test-Path -LiteralPath $fixture) { Remove-Item -LiteralPath $fixture -Recurse -Force }
}
