$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
$fixture = & (Join-Path $root 'scripts\Resolve-CodexRunRoot.ps1') -ArchitectureRoot $root -Kind tmp -ChildPath ('candidate-processing-' + [guid]::NewGuid().ToString('N')) -Create
try {
  New-Item -ItemType Directory -Force -Path "$fixture\.codex\project", "$fixture\knowledge", "$fixture\knowledge-vault\01-Test" | Out-Null
  $zh = [string]([char]0x5019) + [char]0x9009 + [char]0x7ECF + [char]0x9A8C
  [IO.File]::WriteAllText("$fixture\.codex\project\EXPERIENCE.md", "# Experience`n`n## Candidates`n`n- Fixture experience candidate.`n", [Text.UTF8Encoding]::new($false))
  [IO.File]::WriteAllText("$fixture\knowledge\experience-ledger.md", "# Ledger`n`n## $zh`n`n- Fixture ledger candidate.`n", [Text.UTF8Encoding]::new($false))
  [IO.File]::WriteAllText("$fixture\knowledge-vault\01-Test\note.md", "---`nstatus: candidate`ncodex_learning: fixture`n---`n# Fixture note`n", [Text.UTF8Encoding]::new($false))
  [IO.File]::WriteAllText("$fixture\.codex\project\workflow-learning.json", '{"knowledge_status":"candidate","experience_status":"candidate"}', [Text.UTF8Encoding]::new($false))
  New-Item -ItemType Directory -Force -Path "$fixture\.codex\errors\fixture" | Out-Null
  [IO.File]::WriteAllText("$fixture\.codex\errors\fixture\report.json", '{"status":"candidate","module":"fixture"}', [Text.UTF8Encoding]::new($false))
  [IO.File]::WriteAllText("$fixture\.codex\errors\fixture\report.md", '# fixture', [Text.UTF8Encoding]::new($false))
  [IO.File]::WriteAllText("$fixture\.codex\project\candidate-processing-authorization.json", '{"authorization_id":"fixture-auth","authorization_source":"test","status":"authorized","scope":"all-candidate-records"}', [Text.UTF8Encoding]::new($false))
  $outcome = & (Join-Path $root 'skills\codex-experience-capture\scripts\Process-AuthorizedCandidateRecords.ps1') -ProjectRoot $fixture -Apply | ConvertFrom-Json
  if ($outcome.result -ne 'processed' -or @($outcome.processed).Count -lt 5) { throw 'Candidate processor did not process every fixture source.' }
  if ((Get-Content -Raw "$fixture\.codex\project\EXPERIENCE.md") -match '(?m)^## Candidates\s*$') { throw 'Project candidate heading survived processing.' }
  if ((Get-Content -Raw "$fixture\knowledge\experience-ledger.md") -match "(?m)^## $zh\s*$") { throw 'Ledger candidate heading survived processing.' }
  if ((Get-Content -Raw "$fixture\knowledge-vault\01-Test\note.md") -match '(?m)^status:\s*candidate\s*$') { throw 'Linked knowledge candidate status survived processing.' }
  if (Test-Path -LiteralPath "$fixture\.codex\project\workflow-learning.json") { throw 'Derived workflow candidate record was not cleared.' }
  if (Test-Path -LiteralPath "$fixture\.codex\errors\fixture\report.json") { throw 'Candidate error record was not cleared after archiving.' }
  if (-not (Test-Path -LiteralPath (Join-Path $fixture ($outcome.archive -replace '/', [string][IO.Path]::DirectorySeparatorChar)))) { throw 'Candidate archive was not created.' }
  $report = & (Join-Path $root 'skills\codex-experience-capture\scripts\New-GlobalIterationCandidateReport.ps1') -ProjectRoot $fixture | ConvertFrom-Json
  if ($report.candidate_count -ne 0) { throw "Candidate report should be empty after authorized processing; got $($report.candidate_count)." }
  Write-Host 'Authorized candidate processing test passed.'
} finally { if (Test-Path -LiteralPath $fixture) { Remove-Item -LiteralPath $fixture -Recurse -Force } }
