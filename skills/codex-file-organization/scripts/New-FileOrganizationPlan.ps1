[CmdletBinding()]
param(
  [Parameter(Mandatory=$true)][string]$Root,
  [string]$OutputPath,
  [switch]$Apply
)
$ErrorActionPreference='Stop'
$root=(Resolve-Path -LiteralPath $Root).Path
$protected='(^|\\)(\.git|\.codex|\.env[^\\]*|\.sandbox-secrets|private-skill-config)(\\|$)|(^|\\)(auth\.json)$'
$files=@(Get-ChildItem -LiteralPath $root -File -Recurse -Force | Where-Object { $_.FullName -notmatch $protected })
$rows=@(foreach($file in $files){
  $bucket=if($file.Extension -in '.md','.pdf','.docx','.txt'){ '20-reference' }elseif($file.Extension -in '.png','.jpg','.jpeg','.svg','.mmd'){ '30-output/assets' }elseif($file.Extension -in '.zip','.7z','.bak'){ '40-archive' }else{'00-inbox'}
  [ordered]@{source=$file.FullName.Substring($root.Length).TrimStart('\'); proposed=Join-Path $bucket $file.Name; reason='extension-and-lifecycle'; privacy='uninspected-metadata-only'}
})
$plan=[ordered]@{schema_version=2;root='user-selected-root';apply=[bool]$Apply;items=$rows;generated_at=[DateTime]::UtcNow.ToString('o')}
if($Apply){ throw 'Apply is intentionally disabled until a user-approved move executor is supplied.' }
if($OutputPath){
  $destination = [IO.Path]::GetFullPath($OutputPath)
  if($destination -match $protected){ throw 'Refusing to write a plan inside a protected path.' }
  $plan | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $destination -Encoding UTF8
}
$plan|ConvertTo-Json -Depth 5
