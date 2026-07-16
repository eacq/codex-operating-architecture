[CmdletBinding()]
param(
  [Parameter(Mandatory=$true)][string]$Root,
  [string]$OutputPath,
  [string[]]$ManagedRoots = @('00-inbox')
)
$ErrorActionPreference='Stop'
$root=(Resolve-Path -LiteralPath $Root).Path
$protected='(^|\\)(\.git|\.codex|\.env[^\\]*|\.sandbox-secrets|private-skill-config)(\\|$)|(^|\\)(auth\.json)$'
$buckets = @('00-inbox','10-active','20-reference','30-output','40-archive','90-private-local')
$files = @($ManagedRoots | ForEach-Object {
  $managed = Join-Path $root $_
  if (Test-Path -LiteralPath $managed) { Get-ChildItem -LiteralPath $managed -File -Recurse -Force | Where-Object { $relative=$_.FullName.Substring($root.Length).TrimStart('\\'); $relative -notmatch $protected -and $relative -notmatch '^(00-inbox|10-active|20-reference|30-output|40-archive|90-private-local)(\\|$)' } }
})
$rows=@(foreach($file in $files){
  $bucket=if($file.Extension -in '.md','.pdf','.docx','.txt'){ '20-reference' }elseif($file.Extension -in '.png','.jpg','.jpeg','.svg','.mmd'){ '30-output/assets' }elseif($file.Extension -in '.zip','.7z','.bak'){ '40-archive' }else{'00-inbox'}
  $source=$file.FullName.Substring($root.Length).TrimStart('\\')
  [ordered]@{source=$source; proposed=Join-Path $bucket $source; reason='extension-and-lifecycle'; privacy='uninspected-metadata-only'}
})
$plan=[ordered]@{schema_version=4;root='user-selected-root';managed_roots=$ManagedRoots;items=$rows;generated_at=[DateTime]::UtcNow.ToString('o')}
if($OutputPath){
  $destination = [IO.Path]::GetFullPath($OutputPath)
  if($destination -match $protected){ throw 'Refusing to write a plan inside a protected path.' }
  $plan | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $destination -Encoding UTF8
}
$plan|ConvertTo-Json -Depth 5
