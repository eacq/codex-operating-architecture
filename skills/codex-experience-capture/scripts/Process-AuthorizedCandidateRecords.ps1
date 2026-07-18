[CmdletBinding()]
param([string]$ProjectRoot = (Get-Location).Path, [string]$AuthorizationPath = '', [switch]$Apply)
$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath $ProjectRoot).Path
if (-not $AuthorizationPath) { $AuthorizationPath = Join-Path $root '.codex\project\candidate-processing-authorization.json' }
function Write-Utf8($Path, $Text) { $parent = Split-Path -Parent $Path; if ($parent) { New-Item -ItemType Directory -Force -Path $parent | Out-Null }; [IO.File]::WriteAllText($Path, $Text, [Text.UTF8Encoding]::new($false)) }
function Rel($Path) { ($Path.Substring($root.Length).TrimStart([char]'\', [char]'/') -replace '\\', '/') }
function Archive($Path, $ArchiveRoot) { $r = Rel $Path; $d = Join-Path $ArchiveRoot ($r -replace '/', [string][IO.Path]::DirectorySeparatorChar); New-Item -ItemType Directory -Force -Path (Split-Path -Parent $d) | Out-Null; Copy-Item -LiteralPath $Path -Destination $d -Force; $r }
function Promote-Sections($Path, $ArchiveRoot, $Heading) {
  if (-not (Test-Path -LiteralPath $Path)) { return $null }
  $old = Get-Content -LiteralPath $Path -Raw -Encoding UTF8
  $zh = [string]([char]0x5019) + [char]0x9009 + [char]0x7ECF + [char]0x9A8C
  $new = [regex]::Replace($old, '(?m)^## Candidates\s*$', "## $Heading")
  $new = [regex]::Replace($new, "(?m)^## $zh\s*$", "## $Heading")
  if ($new -eq $old) { return $null }
  $relative = Archive $Path $ArchiveRoot
  $note = '> Processed under explicit user authorization. Original wording is preserved in the local archive; this is guarded guidance, not independently verified.'
  $new = [regex]::Replace($new, "(?m)^## $([regex]::Escape($Heading))\s*$", "## $Heading`n`n$note", 1)
  Write-Utf8 $Path $new; return $relative
}
$result = [ordered]@{ result='skipped-no-authorization'; processed=@(); archive=$null; authorization=(Rel $AuthorizationPath) }
if (-not (Test-Path -LiteralPath $AuthorizationPath)) { $result | ConvertTo-Json -Depth 6; return }
$auth = Get-Content -LiteralPath $AuthorizationPath -Raw -Encoding UTF8 | ConvertFrom-Json
if ($auth.status -ne 'authorized' -or $auth.scope -ne 'all-candidate-records') { $result.result='skipped-authorization-not-active'; $result | ConvertTo-Json -Depth 6; return }
if (-not $Apply) { $result.result='ready'; $result | ConvertTo-Json -Depth 6; return }
$archiveRoot = Join-Path $root ('.codex\project\candidate-archive\' + [DateTime]::UtcNow.ToString('yyyyMMddTHHmmssZ') + '-' + $auth.authorization_id); New-Item -ItemType Directory -Force -Path $archiveRoot | Out-Null; $processed=@()
$item = Promote-Sections (Join-Path $root '.codex\project\EXPERIENCE.md') $archiveRoot 'Promoted guarded experience'; if ($item) { $processed += @{source=$item;action='promoted-guarded-section'} }
$ledgerHeading = [string]([char]0x5DF2) + [char]0x63A8 + [char]0x5E7F + [char]0x7684 + [char]0x53D7 + [char]0x9650 + [char]0x7ECF + [char]0x9A8C
$item = Promote-Sections (Join-Path $root 'knowledge\experience-ledger.md') $archiveRoot $ledgerHeading; if ($item) { $processed += @{source=$item;action='promoted-guarded-section'} }
$vault=Join-Path $root 'knowledge-vault'; if (Test-Path -LiteralPath $vault) { Get-ChildItem -LiteralPath $vault -Recurse -Filter '*.md' -File | ForEach-Object { $r=Rel $_.FullName; if ($r -match '^knowledge-vault/Templates/') { return }; $text=Get-Content -LiteralPath $_.FullName -Raw -Encoding UTF8; if ($text -notmatch '(?m)^status:\s*candidate\s*$') { return }; Archive $_.FullName $archiveRoot | Out-Null; $text=[regex]::Replace($text,'(?m)^status:\s*candidate\s*$','status: promoted-guarded',1); if ($text -notmatch '(?m)^promotion_authority:') { $text=[regex]::Replace($text,'(?m)^(status:\s*promoted-guarded\s*)$',"$1`npromotion_authority: $($auth.authorization_id)`npromotion_status: guarded",1) }; Write-Utf8 $_.FullName $text; $processed += @{source=$r;action='promoted-guarded-linked-knowledge'} } }
$workflow=Join-Path $root '.codex\project\workflow-learning.json'; if (Test-Path -LiteralPath $workflow) { $r=Archive $workflow $archiveRoot; Remove-Item -LiteralPath $workflow -Force; $processed += @{source=$r;action='archived-and-cleared-derived-candidate-record'} }
$errors=Join-Path $root '.codex\errors'; if (Test-Path -LiteralPath $errors) { Get-ChildItem -LiteralPath $errors -Recurse -Filter 'report.json' -File | ForEach-Object { $rawReport=Get-Content -LiteralPath $_.FullName -Raw -Encoding UTF8; if ($rawReport -notmatch '"status"\s*:\s*"candidate"') { return }; $report=$rawReport|ConvertFrom-Json; if ($report.status -ne 'candidate') { return }; $r=Archive $_.FullName $archiveRoot; $markdownPath=Join-Path $_.DirectoryName 'report.md'; if (Test-Path -LiteralPath $markdownPath) { Archive $markdownPath $archiveRoot | Out-Null; Remove-Item -LiteralPath $markdownPath -Force }; Remove-Item -LiteralPath $_.FullName -Force; $processed += @{source=$r;action='archived-and-cleared-candidate-error-record'} } }
$decision=[ordered]@{schema_version=1;authorization_id=$auth.authorization_id;authorization_source=$auth.authorization_source;processed_at=[DateTime]::UtcNow.ToString('o');scope=$auth.scope;external_actions='not authorized by candidate processing';actions=$processed}; Write-Utf8 (Join-Path $archiveRoot 'decision.json') (($decision|ConvertTo-Json -Depth 8)+[Environment]::NewLine)
$auth.status='consumed'; $auth|Add-Member processed_at $decision.processed_at -Force; $auth|Add-Member archive (Rel $archiveRoot) -Force; Write-Utf8 $AuthorizationPath (($auth|ConvertTo-Json -Depth 6)+[Environment]::NewLine)
$result.result='processed';$result.processed=$processed;$result.archive=Rel $archiveRoot;$result.processed_at=$decision.processed_at;$result|ConvertTo-Json -Depth 8
