[CmdletBinding()]
param([string]$RepositoryRoot = (Get-Location).Path)
$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath $RepositoryRoot).Path
$zh = Get-Content -LiteralPath (Join-Path $root 'README.md') -Raw -Encoding UTF8
$en = Get-Content -LiteralPath (Join-Path $root 'README.en.md') -Raw -Encoding UTF8
if ($zh -notmatch '\(CHANGELOG\.md\)' -or $en -notmatch '\(CHANGELOG\.md\)') { throw 'Both README files must link to CHANGELOG.md.' }
if ($zh -notmatch 'ITERATION-STATUS\.md' -or $en -notmatch 'ITERATION-STATUS\.md') { throw 'Both README files must link to iteration status.' }
if ($zh -notmatch 'readme-collaboration-loop-labeled\.png' -or $en -notmatch '## How it works') { throw 'Both README files must explain the collaboration model.' }
foreach ($asset in @('docs/assets/readme-collaboration-loop-labeled.png','docs/assets/readme-architecture-overview-labeled.png','docs/assets/file-organization-architecture-labeled.png','docs/assets/file-organization-concept-labeled.png')) {
  if (-not (Test-Path -LiteralPath (Join-Path $root $asset))) { throw "README-linked organization visual is missing: $asset" }
}
if ($zh -notmatch 'file-organization-concept-labeled\.png' -or $en -notmatch 'file-organization-concept-labeled\.png') { throw 'Both README files must link to the labeled file-organization visual.' }
[pscustomobject]@{ readmes = @('README.md','README.en.md'); checks = @('changelog link','iteration status link','collaboration model','reader-facing labeled visual assets'); result = 'readme-iteration-alignment-passed' } | ConvertTo-Json
