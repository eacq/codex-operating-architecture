[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$ReleaseNotePath,
    [Parameter(Mandatory = $true)]
    [string]$PublicTag
)

$ErrorActionPreference = 'Stop'
$path = (Resolve-Path -LiteralPath $ReleaseNotePath).Path
$content = Get-Content -LiteralPath $path -Raw -Encoding UTF8
if ($content -notmatch "(?m)^#\s+$([regex]::Escape($PublicTag))\s*$") { throw "Public release note must have exactly '$PublicTag' as its title." }
foreach ($pattern in @('\b\d+\.\d+\.\d+\.\d+\b', '(?i)\b(private|origin|error report|republish|retry|staged)\b', '私有|错误报告|重新发布|重试|暂存')) {
    if ($content -match $pattern) { throw 'Public release note contains private operational or non-public version information.' }
}
[pscustomobject]@{ public_tag = $PublicTag; note = $path; result = 'public-release-metadata-passed' } | ConvertTo-Json
