[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$SourcePath,
    [Parameter(Mandatory = $true)]
    [string]$PublicPath,
    [Parameter(Mandatory = $true)]
    [string[]]$EvidencePaths,
    [switch]$Apply
)

$ErrorActionPreference = 'Stop'
$source = (Resolve-Path -LiteralPath $SourcePath).Path
$public = [IO.Path]::GetFullPath($PublicPath)
$privatePatterns = @('(?i)https?://[^\s`"'']+', '(?i)(?:[A-Z]:\\|/Users/|/home/)[^\s`"'']+', '(?i)(?:api[_-]?key|token|password|cookie)\s*[:=]')
$content = Get-Content -LiteralPath $source -Raw -Encoding UTF8
$findings = @($privatePatterns | Where-Object { $content -match $_ }).Count
$plan = [ordered]@{
    source = $source
    public_path = $public
    evidence_paths = @($EvidencePaths)
    private_pattern_count = $findings
    status = if ($findings -gt 0) { 'candidate-needs-sanitization' } else { 'candidate-ready-for-public-review' }
    apply_requires = @('two independent verified evidence paths', 'no raw history or personal data', 'sanitized content', 'knowledge link/build validation')
}
if (-not $Apply) { $plan | ConvertTo-Json -Depth 5; exit 0 }
if (@($EvidencePaths).Count -lt 2) { throw 'Apply requires at least two independent verified evidence paths.' }
foreach ($evidencePath in $EvidencePaths) { if (-not (Test-Path -LiteralPath $evidencePath)) { throw "Evidence path does not exist: $evidencePath" } }
if (Test-Path -LiteralPath $public) { throw "Public path already exists: $public" }
$sanitized = $content -replace '(?i)https?://[^\s`"'']+', '<LOCAL_ENDPOINT>'
$sanitized = $sanitized -replace '(?i)(?:[A-Z]:\\|/Users/|/home/)[^\s`"'']+', '<LOCAL_PATH>'
$sanitized = $sanitized -replace '(?i)(?:api[_-]?key|token|password|cookie)\s*[:=]\s*[^\s`"'']+', '<REDACTED_PRIVATE_VALUE>'
if ($sanitized -match '(?i)replacement_history|auth\.json|browser state') { throw 'Candidate contains raw-history or credential-state markers and cannot be published automatically.' }
New-Item -ItemType Directory -Force -Path (Split-Path -Parent $public) | Out-Null
Set-Content -LiteralPath $public -Value $sanitized -Encoding UTF8
$plan.status = 'sanitized-public-candidate-created'
$plan | ConvertTo-Json -Depth 5
