$ErrorActionPreference = 'Stop'
$fixture = Join-Path ([IO.Path]::GetTempPath()) ("codex-candidate-report-" + [guid]::NewGuid().ToString('N'))
try {
    New-Item -ItemType Directory -Force -Path (Join-Path $fixture '.codex\project'), (Join-Path $fixture 'knowledge'), (Join-Path $fixture 'knowledge-vault\30-Knowledge'), (Join-Path $fixture 'knowledge-vault\Templates') | Out-Null
    @('# Project Experience', '', '## Candidates', '', '- Install candidate needs a runtime check.') | Set-Content -LiteralPath (Join-Path $fixture '.codex\project\EXPERIENCE.md') -Encoding UTF8
    $candidateChineseHeading = [string]([char]0x5019) + [char]0x9009 + [char]0x7ECF + [char]0x9A8C
    @('# Experience Ledger', '', ('## ' + $candidateChineseHeading), '', '- Keep this candidate under review.') | Set-Content -LiteralPath (Join-Path $fixture 'knowledge\experience-ledger.md') -Encoding UTF8
    @('---', 'id: test-candidate', 'status: candidate', 'codex_learning: Verify a candidate before adoption.', '---', '', '# Fixture Candidate') | Set-Content -LiteralPath (Join-Path $fixture 'knowledge-vault\30-Knowledge\Fixture Candidate.md') -Encoding UTF8
    @('---', 'status: candidate', '---', '', '# Template Candidate') | Set-Content -LiteralPath (Join-Path $fixture 'knowledge-vault\Templates\Template Candidate.md') -Encoding UTF8
    @{ knowledge_status = 'candidate-for-linked-knowledge'; experience_status = 'candidate-for-verified-experience' } | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $fixture '.codex\project\workflow-learning.json') -Encoding UTF8
    $result = & (Join-Path $PSScriptRoot 'New-GlobalIterationCandidateReport.ps1') -ProjectRoot $fixture -Apply | ConvertFrom-Json
    if ($result.result -ne 'generated' -or $result.candidate_count -lt 4) { throw 'Candidate report did not collect every expected candidate source.' }
    $markdownPath = Join-Path $fixture '.codex\project\candidate-reports\latest.md'
    if (-not (Test-Path -LiteralPath $markdownPath)) { throw 'Candidate Markdown report was not created.' }
    if (($result.candidates | Where-Object { $_.category -eq 'project-experience' }).recommended_action -notmatch 'authorization') { throw 'Install-like candidate did not retain its authorization boundary.' }
    if ($result.schema_version -ne 2) { throw 'Candidate report schema was not upgraded for bilingual views.' }
    if ($result.candidates.source -contains 'knowledge-vault/Templates/Template Candidate.md') { throw 'Candidate report must not collect knowledge-vault templates.' }
    if (-not (($result.candidates | Where-Object { $_.category -eq 'project-experience' }).user_view.recommended_action -match ([string]([char]0x6388) + [char]0x6743))) { throw 'Candidate report does not contain the Chinese user decision view.' }
    $markdown = Get-Content -LiteralPath $markdownPath -Raw -Encoding UTF8
    $chineseTitle = [string]([char]0x5168) + [char]0x5C40 + [char]0x8FED + [char]0x4EE3 + [char]0x5019 + [char]0x9009 + [char]0x62A5 + [char]0x544A
    if ($markdown -notmatch $chineseTitle -or $markdown -notmatch 'English appendix for the experience system') { throw 'Candidate Markdown report does not contain the required Chinese-primary and English appendix structure.' }
    if ($markdown -notmatch 'Codex-chat delivery: render this report directly' -or $markdown -match 'Launch the current report') { throw 'Candidate report does not declare the correct in-chat delivery behavior.' }
    if ($result.vscode_uri -notmatch '^vscode://file/') { throw 'Candidate report does not retain a VS Code URI for manual local tooling.' }
    Write-Host 'Global iteration candidate report test passed.'
}
finally {
    if (Test-Path -LiteralPath $fixture) { Remove-Item -LiteralPath $fixture -Recurse -Force }
}
