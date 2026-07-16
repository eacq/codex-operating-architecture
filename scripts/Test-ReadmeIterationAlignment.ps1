[CmdletBinding()]
param([string]$RepositoryRoot = (Get-Location).Path)
$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath $RepositoryRoot).Path
$zh = Get-Content -LiteralPath (Join-Path $root 'README.md') -Raw -Encoding UTF8
$en = Get-Content -LiteralPath (Join-Path $root 'README.en.md') -Raw -Encoding UTF8
if ($zh -notmatch '\(CHANGELOG\.md\)' -or $en -notmatch '\(CHANGELOG\.md\)') { throw 'Both README files must link to CHANGELOG.md.' }
if ($zh -notmatch 'ITERATION-STATUS\.md' -or $en -notmatch 'ITERATION-STATUS\.md') { throw 'Both README files must link to iteration status.' }
if ($zh -notmatch 'GPT' -or $en -notmatch 'GPT-first') { throw 'Both README files must state the GPT-first visual policy.' }
foreach ($asset in @('docs/assets/file-organization-concept.png','docs/assets/file-organization-architecture.mmd')) {
  if (-not (Test-Path -LiteralPath (Join-Path $root $asset))) { throw "README-linked organization visual is missing: $asset" }
}
if ($zh -notmatch 'file-organization-concept\.png' -or $en -notmatch 'file-organization-concept\.png') { throw 'Both README files must link to the GPT-first file-organization visual.' }
[pscustomobject]@{ readmes = @('README.md','README.en.md'); checks = @('changelog link','iteration status link','GPT-first visual policy','file-organization visual assets'); result = 'readme-iteration-alignment-passed' } | ConvertTo-Json
