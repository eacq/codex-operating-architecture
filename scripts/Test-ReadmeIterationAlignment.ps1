[CmdletBinding()]
param([string]$RepositoryRoot = (Get-Location).Path)
$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath $RepositoryRoot).Path
$zh = Get-Content -LiteralPath (Join-Path $root 'README.md') -Raw -Encoding UTF8
$en = Get-Content -LiteralPath (Join-Path $root 'README.en.md') -Raw -Encoding UTF8
if ($zh -notmatch '\(CHANGELOG\.md\)' -or $en -notmatch '\(CHANGELOG\.md\)') { throw 'Both README files must link to CHANGELOG.md.' }
if ($zh -notmatch 'ITERATION-STATUS\.md' -or $en -notmatch 'ITERATION-STATUS\.md') { throw 'Both README files must link to iteration status.' }
if ($zh -notmatch 'GPT' -or $en -notmatch 'GPT-first') { throw 'Both README files must state the GPT-first visual policy.' }
[pscustomobject]@{ readmes = @('README.md','README.en.md'); checks = @('changelog link','iteration status link','GPT-first visual policy'); result = 'readme-iteration-alignment-passed' } | ConvertTo-Json
