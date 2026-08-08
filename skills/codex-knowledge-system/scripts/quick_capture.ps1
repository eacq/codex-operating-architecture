[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$Title,
    [Parameter(Mandatory)]
    [string]$Content,
    [string]$Vault = $(Join-Path (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path 'knowledge-vault')
)

$ErrorActionPreference = 'Stop'
$inbox = Join-Path $Vault '01-Inbox'
New-Item -ItemType Directory -Force -Path $inbox | Out-Null
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$safeTitle = ($Title -replace '[<>:"/\\|?*]', '-').Trim()
if (-not $safeTitle) { $safeTitle = 'untitled' }
$path = Join-Path $inbox "$stamp-$safeTitle.md"
$body = @"
---
id: inbox-$stamp
type: inbox
status: candidate
source: quick-capture
verified: false
---

# $Title

$Content

## Processing

- Owning module:
- Related workflow:
- Evidence:
- Promote, merge, or discard:
"@
$body | Set-Content -LiteralPath $path -Encoding UTF8
Write-Output $path
