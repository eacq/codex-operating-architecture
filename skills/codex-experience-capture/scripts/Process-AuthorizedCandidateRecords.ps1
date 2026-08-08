[CmdletBinding()]
param([string]$ProjectRoot = (Get-Location).Path, [string]$AuthorizationPath = '', [switch]$Apply)
$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath $ProjectRoot).Path
if (-not $AuthorizationPath) { $AuthorizationPath = Join-Path $root '.codex\project\candidate-processing-authorization.json' }
function Write-Utf8($Path, $Text) { $parent = Split-Path -Parent $Path; if ($parent) { New-Item -ItemType Directory -Force -Path $parent | Out-Null }; [IO.File]::WriteAllText($Path, $Text, [Text.UTF8Encoding]::new($false)) }
function Rel($Path) { ($Path.Substring($root.Length).TrimStart([char]'\', [char]'/') -replace '\\', '/') }
function Archive($Path, $ArchiveRoot) { $r = Rel $Path; $d = Join-Path $ArchiveRoot ($r -replace '/', [string][IO.Path]::DirectorySeparatorChar); New-Item -ItemType Directory -Force -Path (Split-Path -Parent $d) | Out-Null; Copy-Item -LiteralPath $Path -Destination $d -Force; $r }
function Get-AuthorizationMode($Authorization) {
  if ($Authorization.PSObject.Properties.Name -contains 'processing_mode' -and $Authorization.processing_mode) { return [string]$Authorization.processing_mode }
  if ($Authorization.PSObject.Properties.Name -contains 'mode' -and $Authorization.mode) { return [string]$Authorization.mode }
  return 'guarded'
}
function Confirm-FormalPromotionAuthorization($Authorization) {
  if (-not ($Authorization.PSObject.Properties.Name -contains 'verification_records')) {
    throw 'Formal promotion requires verification_records in the authorization.'
  }
  $records = @($Authorization.verification_records)
  $reportScript = Join-Path $PSScriptRoot 'New-GlobalIterationCandidateReport.ps1'
  $candidateReport = & $reportScript -ProjectRoot $root | ConvertFrom-Json
  if ([int]$candidateReport.candidate_count -le 0) { throw 'Formal promotion requires at least one current candidate.' }
  if ($records.Count -ne [int]$candidateReport.candidate_count) {
    throw "Formal promotion verification count does not match current candidates: expected $($candidateReport.candidate_count), got $($records.Count)."
  }
  $verifiedEvidence = New-Object System.Collections.Generic.List[string]
  foreach ($candidate in @($candidateReport.candidates)) {
    $matching = @($records | Where-Object {
      [string]$_.source -eq [string]$candidate.source -and
      [string]$_.summary -eq [string]$candidate.summary
    })
    if ($matching.Count -ne 1) { throw "Formal promotion requires one exact verification record for candidate: $($candidate.summary)" }
    $record = $matching[0]
    if ([string]$record.status -ne 'verified' -or -not [string]$record.verification) {
      throw "Formal promotion verification record is not verified: $($candidate.summary)"
    }
    $evidencePaths = @($record.evidence_paths)
    if ($evidencePaths.Count -eq 0) { throw "Formal promotion requires evidence paths for candidate: $($candidate.summary)" }
    foreach ($evidencePathValue in $evidencePaths) {
      $evidencePath = [string]$evidencePathValue
      if ([IO.Path]::IsPathRooted($evidencePath)) { throw "Formal promotion evidence must be project-relative: $evidencePath" }
      $fullEvidencePath = [IO.Path]::GetFullPath((Join-Path $root $evidencePath))
      $rootPrefix = $root.TrimEnd([char]'\', [char]'/') + [IO.Path]::DirectorySeparatorChar
      if (-not $fullEvidencePath.StartsWith($rootPrefix, [StringComparison]::OrdinalIgnoreCase)) {
        throw "Formal promotion evidence escapes the project root: $evidencePath"
      }
      if (-not (Test-Path -LiteralPath $fullEvidencePath -PathType Leaf)) {
        throw "Formal promotion evidence does not exist: $evidencePath"
      }
      if (-not $verifiedEvidence.Contains($evidencePath)) { $verifiedEvidence.Add($evidencePath) }
    }
  }
  return [pscustomobject][ordered]@{
    candidate_count = [int]$candidateReport.candidate_count
    records = $records
    evidence_paths = @($verifiedEvidence)
  }
}
function New-StructuralOptimizationRecord($WorkflowPath, $ArchiveRoot, $Authorization) {
  if (-not (Test-Path -LiteralPath $WorkflowPath)) { return $null }
  $relative = Archive $WorkflowPath $ArchiveRoot
  $workflow = Get-Content -LiteralPath $WorkflowPath -Raw -Encoding UTF8 | ConvertFrom-Json
  $recordRoot = Join-Path $root '.codex\project\structural-optimization-records'
  $recordName = [DateTime]::UtcNow.ToString('yyyyMMddTHHmmssZ') + '-' + $Authorization.authorization_id + '.json'
  $recordPath = Join-Path $recordRoot $recordName
  $record = [ordered]@{
    schema_version = 1
    authorization_id = $Authorization.authorization_id
    authorization_source = $Authorization.authorization_source
    processing_mode = 'structural-optimization'
    processed_at = [DateTime]::UtcNow.ToString('o')
    source = $relative
    workflow_path = $workflow.workflow_path
    workflow_sha256 = $workflow.workflow_sha256
    related_owners = @($workflow.related_owners)
    evidence_paths = @($workflow.evidence_paths)
    knowledge_status = $workflow.knowledge_status
    experience_status = $workflow.experience_status
    architecture_action = $workflow.architecture_action
    structural_disposition = 'accepted-as-architecture-iteration-input'
    required_handoff = @(
      'codex-experience-capture',
      'codex-knowledge-system',
      'codex-architecture-iteration'
    )
    validation = @(
      'authorized-candidate-processing-test',
      'knowledge-build',
      'global-validation'
    )
    rollback_boundary = 'recorded source archive plus local repository diff'
  }
  Write-Utf8 $recordPath (($record | ConvertTo-Json -Depth 8) + [Environment]::NewLine)
  return @{ source=$relative; action='recorded-structural-optimization-input'; output=(Rel $recordPath) }
}
function Promote-Sections($Path, $ArchiveRoot, $Heading, $Note) {
  if (-not (Test-Path -LiteralPath $Path)) { return $null }
  $old = Get-Content -LiteralPath $Path -Raw -Encoding UTF8
  $zh = [string]([char]0x5019) + [char]0x9009 + [char]0x7ECF + [char]0x9A8C
  $new = [regex]::Replace($old, '(?m)^## Candidates\s*$', "## $Heading")
  $new = [regex]::Replace($new, "(?m)^## $zh\s*$", "## $Heading")
  if ($new -eq $old) { return $null }
  $relative = Archive $Path $ArchiveRoot
  $new = [regex]::Replace($new, "(?m)^## $([regex]::Escape($Heading))\s*$", "## $Heading`n`n$Note", 1)
  Write-Utf8 $Path $new; return $relative
}
$result = [ordered]@{ result='skipped-no-authorization'; processed=@(); archive=$null; authorization=(Rel $AuthorizationPath) }
if (-not (Test-Path -LiteralPath $AuthorizationPath)) { $result | ConvertTo-Json -Depth 6; return }
$auth = Get-Content -LiteralPath $AuthorizationPath -Raw -Encoding UTF8 | ConvertFrom-Json
if ($auth.status -ne 'authorized' -or $auth.scope -ne 'all-candidate-records') { $result.result='skipped-authorization-not-active'; $result | ConvertTo-Json -Depth 6; return }
if (-not $Apply) { $result.result='ready'; $result | ConvertTo-Json -Depth 6; return }
$mode = Get-AuthorizationMode $auth
$allowedModes = @('guarded', 'structural-optimization', 'formal-promotion')
if ($mode -notin $allowedModes) { throw "Unsupported candidate processing mode: $mode" }
$formalProof = if ($mode -eq 'formal-promotion') { Confirm-FormalPromotionAuthorization $auth } else { $null }
$archiveRoot = Join-Path $root ('.codex\project\candidate-archive\' + [DateTime]::UtcNow.ToString('yyyyMMddTHHmmssZ') + '-' + $auth.authorization_id); New-Item -ItemType Directory -Force -Path $archiveRoot | Out-Null; $processed=@()
$sectionHeading = if ($mode -eq 'formal-promotion') { 'Promoted verified experience' } else { 'Promoted guarded experience' }
$sectionNote = if ($mode -eq 'formal-promotion') {
  '> Formally promoted under explicit user authorization after exact candidate-to-evidence matching. Original wording is preserved in the local archive. This is verified reusable experience; owner, safety, and external-action gates still apply.'
} else {
  '> Processed under explicit user authorization. Original wording is preserved in the local archive; this is guarded guidance, not independently verified.'
}
$sectionAction = if ($mode -eq 'formal-promotion') { 'promoted-verified-section' } else { 'promoted-guarded-section' }
$item = Promote-Sections (Join-Path $root '.codex\project\EXPERIENCE.md') $archiveRoot $sectionHeading $sectionNote; if ($item) { $processed += @{source=$item;action=$sectionAction} }
$ledgerHeading = [string]([char]0x5DF2) + [char]0x63A8 + [char]0x5E7F + [char]0x7684 + [char]0x53D7 + [char]0x9650 + [char]0x7ECF + [char]0x9A8C
$ledgerPromotionHeading = if ($mode -eq 'formal-promotion') { 'Formally promoted verified experience' } else { $ledgerHeading }
$item = Promote-Sections (Join-Path $root 'knowledge\experience-ledger.md') $archiveRoot $ledgerPromotionHeading $sectionNote; if ($item) { $processed += @{source=$item;action=$sectionAction} }
$vault=Join-Path $root 'knowledge-vault'; if (Test-Path -LiteralPath $vault) { Get-ChildItem -LiteralPath $vault -Recurse -Filter '*.md' -File | ForEach-Object { $r=Rel $_.FullName; if ($r -match '^knowledge-vault/Templates/') { return }; $text=Get-Content -LiteralPath $_.FullName -Raw -Encoding UTF8; if ($text -notmatch '(?m)^status:\s*candidate\s*$') { return }; Archive $_.FullName $archiveRoot | Out-Null; $promotionStatus = if ($mode -eq 'formal-promotion') { 'promoted-verified' } else { 'promoted-guarded' }; $verificationStatus = if ($mode -eq 'formal-promotion') { 'verified' } else { 'guarded' }; $text=[regex]::Replace($text,'(?m)^status:\s*candidate\s*$',"status: $promotionStatus",1); if ($text -notmatch '(?m)^promotion_authority:') { $text=[regex]::Replace($text,"(?m)^(status:\s*$([regex]::Escape($promotionStatus))\s*)$","$1`npromotion_authority: $($auth.authorization_id)`npromotion_status: $verificationStatus",1) }; Write-Utf8 $_.FullName $text; $knowledgeAction = if ($mode -eq 'formal-promotion') { 'promoted-verified-linked-knowledge' } else { 'promoted-guarded-linked-knowledge' }; $processed += @{source=$r;action=$knowledgeAction} } }
$workflow=Join-Path $root '.codex\project\workflow-learning.json'; if (Test-Path -LiteralPath $workflow) { if ($mode -eq 'structural-optimization') { $processed += New-StructuralOptimizationRecord $workflow $archiveRoot $auth } else { $r=Archive $workflow $archiveRoot; $processed += @{source=$r;action='archived-and-cleared-derived-candidate-record'} }; Remove-Item -LiteralPath $workflow -Force }
$errors=Join-Path $root '.codex\errors'; if (Test-Path -LiteralPath $errors) { Get-ChildItem -LiteralPath $errors -Recurse -Filter 'report.json' -File | ForEach-Object { $rawReport=Get-Content -LiteralPath $_.FullName -Raw -Encoding UTF8; if ($rawReport -notmatch '"status"\s*:\s*"candidate"') { return }; $report=$rawReport|ConvertFrom-Json; if ($report.status -ne 'candidate') { return }; $r=Archive $_.FullName $archiveRoot; $markdownPath=Join-Path $_.DirectoryName 'report.md'; if (Test-Path -LiteralPath $markdownPath) { Archive $markdownPath $archiveRoot | Out-Null; Remove-Item -LiteralPath $markdownPath -Force }; Remove-Item -LiteralPath $_.FullName -Force; $processed += @{source=$r;action='archived-and-cleared-candidate-error-record'} } }
$externalActions = if ($mode -eq 'structural-optimization') { 'local structure optimization authorized by this record; external irreversible actions still require their owning controller proof' } else { 'not authorized by candidate processing' }
if ($mode -eq 'formal-promotion') {
  $promotionRoot = Join-Path $root '.codex\project\formal-promotion-records'
  $promotionPath = Join-Path $promotionRoot ([DateTime]::UtcNow.ToString('yyyyMMddTHHmmssZ') + '-' + $auth.authorization_id + '.json')
  $promotionRecord = [ordered]@{schema_version=1;authorization_id=$auth.authorization_id;authorization_source=$auth.authorization_source;processing_mode=$mode;promoted_at=[DateTime]::UtcNow.ToString('o');candidate_count=$formalProof.candidate_count;verification_records=$formalProof.records;evidence_paths=$formalProof.evidence_paths;archive=(Rel $archiveRoot);source_actions=@($processed);external_actions=$externalActions}
  Write-Utf8 $promotionPath (($promotionRecord | ConvertTo-Json -Depth 10) + [Environment]::NewLine)
  $processed += @{source='.codex/project/candidate-processing-authorization.json';action='recorded-formal-promotion-proof';output=(Rel $promotionPath)}
}
$decision=[ordered]@{schema_version=2;authorization_id=$auth.authorization_id;authorization_source=$auth.authorization_source;processed_at=[DateTime]::UtcNow.ToString('o');scope=$auth.scope;processing_mode=$mode;external_actions=$externalActions;formal_verification=$formalProof;actions=$processed}; Write-Utf8 (Join-Path $archiveRoot 'decision.json') (($decision|ConvertTo-Json -Depth 12)+[Environment]::NewLine)
$auth.status='consumed'; $auth|Add-Member processed_at $decision.processed_at -Force; $auth|Add-Member archive (Rel $archiveRoot) -Force; Write-Utf8 $AuthorizationPath (($auth|ConvertTo-Json -Depth 6)+[Environment]::NewLine)
$result.result='processed';$result.processed=$processed;$result.archive=Rel $archiveRoot;$result.processed_at=$decision.processed_at;$result|ConvertTo-Json -Depth 8
