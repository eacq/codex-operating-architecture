$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
$fixture = & (Join-Path $root 'scripts\Resolve-CodexRunRoot.ps1') -ArchitectureRoot $root -Kind tmp -ChildPath ('candidate-processing-' + [guid]::NewGuid().ToString('N')) -Create
try {
  New-Item -ItemType Directory -Force -Path "$fixture\.codex\project", "$fixture\knowledge", "$fixture\knowledge-vault\01-Test" | Out-Null
  $zh = [string]([char]0x5019) + [char]0x9009 + [char]0x7ECF + [char]0x9A8C
  [IO.File]::WriteAllText("$fixture\.codex\project\EXPERIENCE.md", "# Experience`n`n## Candidates`n`n- Fixture experience candidate.`n", [Text.UTF8Encoding]::new($false))
  [IO.File]::WriteAllText("$fixture\knowledge\experience-ledger.md", "# Ledger`n`n## $zh`n`n- Fixture ledger candidate.`n", [Text.UTF8Encoding]::new($false))
  [IO.File]::WriteAllText("$fixture\knowledge-vault\01-Test\note.md", "---`nstatus: candidate`ncodex_learning: fixture`n---`n# Fixture note`n", [Text.UTF8Encoding]::new($false))
  [IO.File]::WriteAllText("$fixture\.codex\project\workflow-learning.json", '{"schema_version":1,"workflow_path":".codex/project/WORKFLOWS.md","workflow_sha256":"fixture","related_owners":["codex-experience-capture","codex-architecture-iteration"],"evidence_paths":["fixture-a","fixture-b"],"knowledge_status":"candidate","experience_status":"candidate","architecture_action":"compare triggers and owner boundaries"}', [Text.UTF8Encoding]::new($false))
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

  $structuralFixture = Join-Path $fixture 'structural'
  New-Item -ItemType Directory -Force -Path "$structuralFixture\.codex\project" | Out-Null
  [IO.File]::WriteAllText("$structuralFixture\.codex\project\workflow-learning.json", '{"schema_version":1,"workflow_path":".codex/project/WORKFLOWS.md","workflow_sha256":"fixture-structural","related_owners":["codex-experience-capture","codex-knowledge-system","codex-architecture-iteration"],"evidence_paths":["skills/codex-learning/SKILL.md","knowledge-vault/30-Knowledge/Learning Governance.md"],"knowledge_status":"candidate-for-linked-knowledge","experience_status":"candidate-for-verified-experience","architecture_action":"revise existing owner contracts before adding a top-level owner"}', [Text.UTF8Encoding]::new($false))
  [IO.File]::WriteAllText("$structuralFixture\.codex\project\candidate-processing-authorization.json", '{"authorization_id":"fixture-structural-auth","authorization_source":"test","status":"authorized","scope":"all-candidate-records","processing_mode":"structural-optimization"}', [Text.UTF8Encoding]::new($false))
  $structuralOutcome = & (Join-Path $root 'skills\codex-experience-capture\scripts\Process-AuthorizedCandidateRecords.ps1') -ProjectRoot $structuralFixture -Apply | ConvertFrom-Json
  $structuralActions = @($structuralOutcome.processed | Where-Object { $_.action -eq 'recorded-structural-optimization-input' })
  if ($structuralOutcome.result -ne 'processed' -or $structuralActions.Count -ne 1) { throw 'Structural authorization did not record workflow-learning as architecture input.' }
  $recordPath = Join-Path $structuralFixture ($structuralActions[0].output -replace '/', [string][IO.Path]::DirectorySeparatorChar)
  if (-not (Test-Path -LiteralPath $recordPath)) { throw 'Structural optimization record was not created.' }
  $record = Get-Content -LiteralPath $recordPath -Raw -Encoding UTF8 | ConvertFrom-Json
  if ($record.processing_mode -ne 'structural-optimization' -or $record.structural_disposition -ne 'accepted-as-architecture-iteration-input') { throw 'Structural optimization record has the wrong disposition.' }
  if (Test-Path -LiteralPath "$structuralFixture\.codex\project\workflow-learning.json") { throw 'Structural workflow candidate record was not cleared after recording architecture input.' }

  $formalFixture = Join-Path $fixture 'formal'
  New-Item -ItemType Directory -Force -Path "$formalFixture\.codex\project", "$formalFixture\.codex\errors\proof" | Out-Null
  [IO.File]::WriteAllText("$formalFixture\.codex\project\EXPERIENCE.md", "# Experience`n`n## Candidates`n`n- Fixture formally verified candidate.`n", [Text.UTF8Encoding]::new($false))
  [IO.File]::WriteAllText("$formalFixture\.codex\errors\proof\report.json", '{"status":"verified","verification":"fixture proof"}', [Text.UTF8Encoding]::new($false))
  $formalAuthorization = [ordered]@{authorization_id='fixture-formal-auth';authorization_source='test';status='authorized';scope='all-candidate-records';processing_mode='formal-promotion';verification_records=@([ordered]@{source='.codex/project/EXPERIENCE.md';summary='Fixture formally verified candidate.';status='verified';verification='fixture proof';evidence_paths=@('.codex/errors/proof/report.json')})}
  [IO.File]::WriteAllText("$formalFixture\.codex\project\candidate-processing-authorization.json", (($formalAuthorization | ConvertTo-Json -Depth 8) + [Environment]::NewLine), [Text.UTF8Encoding]::new($false))
  $formalOutcome = & (Join-Path $root 'skills\codex-experience-capture\scripts\Process-AuthorizedCandidateRecords.ps1') -ProjectRoot $formalFixture -Apply | ConvertFrom-Json
  if ($formalOutcome.result -ne 'processed' -or @($formalOutcome.processed | Where-Object action -eq 'promoted-verified-section').Count -ne 1) { throw 'Formal authorization did not promote the verified candidate section.' }
  $formalText = Get-Content -LiteralPath "$formalFixture\.codex\project\EXPERIENCE.md" -Raw -Encoding UTF8
  if ($formalText -notmatch '(?m)^## Promoted verified experience\s*$' -or $formalText -match '(?m)^## Candidates\s*$') { throw 'Formal promotion did not replace the candidate heading.' }
  $formalProofAction = @($formalOutcome.processed | Where-Object action -eq 'recorded-formal-promotion-proof')
  if ($formalProofAction.Count -ne 1 -or -not (Test-Path -LiteralPath (Join-Path $formalFixture ($formalProofAction[0].output -replace '/', [string][IO.Path]::DirectorySeparatorChar)))) { throw 'Formal promotion proof was not created.' }

  $rejectedFixture = Join-Path $fixture 'formal-rejected'
  New-Item -ItemType Directory -Force -Path "$rejectedFixture\.codex\project" | Out-Null
  [IO.File]::WriteAllText("$rejectedFixture\.codex\project\EXPERIENCE.md", "# Experience`n`n## Candidates`n`n- Missing formal evidence.`n", [Text.UTF8Encoding]::new($false))
  [IO.File]::WriteAllText("$rejectedFixture\.codex\project\candidate-processing-authorization.json", '{"authorization_id":"fixture-formal-rejected","authorization_source":"test","status":"authorized","scope":"all-candidate-records","processing_mode":"formal-promotion"}', [Text.UTF8Encoding]::new($false))
  $rejected = $false
  try { & (Join-Path $root 'skills\codex-experience-capture\scripts\Process-AuthorizedCandidateRecords.ps1') -ProjectRoot $rejectedFixture -Apply | Out-Null } catch { $rejected = $_.Exception.Message -match 'verification_records' }
  if (-not $rejected) { throw 'Formal promotion without verification records was not rejected.' }
  Write-Host 'Authorized candidate processing test passed.'
} finally { if (Test-Path -LiteralPath $fixture) { Remove-Item -LiteralPath $fixture -Recurse -Force } }
