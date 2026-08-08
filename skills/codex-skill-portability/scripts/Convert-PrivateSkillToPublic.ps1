[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$SourceSkillPath,
    [Parameter(Mandatory = $true)]
    [string]$PublicSkillName,
    [string]$DestinationSkillsRoot = (Join-Path (Get-Location) 'skills'),
    [string]$PrivateConfigPath = (Join-Path $HOME '.codex\private-skill-config\portable-skill.json'),
    [string[]]$EvidencePaths,
    [switch]$Apply
)

$ErrorActionPreference = 'Stop'
$source = (Resolve-Path -LiteralPath $SourceSkillPath).Path
$destination = Join-Path (Resolve-Path -LiteralPath $DestinationSkillsRoot).Path $PublicSkillName
if (Test-Path -LiteralPath $destination) { throw "Destination already exists: $destination" }
$auditScript = Join-Path $PSScriptRoot 'Test-SkillPortability.ps1'
$sourceAudit = & $auditScript -SkillPath $source | ConvertFrom-Json
$profilePresent = Test-Path -LiteralPath $PrivateConfigPath
$plan = [ordered]@{
    source_skill = $source
    public_skill = $PublicSkillName
    destination = $destination
    source_portability_findings = $sourceAudit.finding_count
    private_profile_detected = $profilePresent
    evidence_paths = @($EvidencePaths)
    public_contract = 'Generic workflow and validation only; provider, account, endpoint, path, software, and credentials remain local.'
    apply_requires = @('two independent verified use cases', 'human-readable public description', 'sanitized-copy audit with no unresolved private values')
    status = if ($sourceAudit.finding_count -gt 0) { 'candidate-needs-sanitization' } else { 'candidate-ready-for-public-review' }
}
if (-not $Apply) { $plan | ConvertTo-Json -Depth 6; exit 0 }
if (@($EvidencePaths).Count -lt 2) { throw 'Apply requires at least two independent verified evidence paths.' }
foreach ($evidencePath in $EvidencePaths) { if (-not (Test-Path -LiteralPath $evidencePath)) { throw "Evidence path does not exist: $evidencePath" } }

New-Item -ItemType Directory -Force -Path $destination | Out-Null
Get-ChildItem -LiteralPath $source -Recurse -File | ForEach-Object {
    $relative = $_.FullName.Substring($source.Length).TrimStart('\\')
    $target = Join-Path $destination $relative
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $target) | Out-Null
    if ($_.Extension -in @('.md', '.json', '.ps1', '.py', '.toml', '.yaml', '.yml')) {
        $content = Get-Content -LiteralPath $_.FullName -Raw -Encoding UTF8
        $content = $content -replace '(?i)https?://[^\s`"'']+', '<LOCAL_ENDPOINT>'
        $content = $content -replace '(?i)(?:[A-Z]:\\|/Users/|/home/)[^\s`"'']+', '<LOCAL_PATH>'
        $content = $content -replace '(?i)\b[A-Z][A-Z0-9_]*(?:API_KEY|TOKEN|SECRET|PASSWORD)\b', 'YOUR_API_KEY'
        Set-Content -LiteralPath $target -Value $content -Encoding UTF8
    } else { Copy-Item -LiteralPath $_.FullName -Destination $target }
}

$localConversionRoot = Join-Path $HOME '.codex\private-skill-config\converted-skills'
New-Item -ItemType Directory -Force -Path $localConversionRoot | Out-Null
$localProfile = [ordered]@{ schema_version = 1; public_skill = $PublicSkillName; source_profile_detected = $profilePresent; provider = @{}; software = @{}; notes = 'Local-only conversion profile. It contains no secrets; configure credentials through the normal secure flow.' }
if ($profilePresent) {
    $original = Get-Content -LiteralPath $PrivateConfigPath -Raw -Encoding UTF8 | ConvertFrom-Json
    $localProfile.provider = [ordered]@{ display_name = "$($original.provider.display_name)"; base_url = "$($original.provider.base_url)"; auth_preference = "$($original.provider.auth_preference)"; api_key_environment_variable = "$($original.provider.api_key_environment_variable)"; preferred_model = "$($original.provider.preferred_model)" }
    $localProfile.software = [ordered]@{ archive_root = "$($original.software.archive_root)"; install_root = "$($original.software.install_root)"; selected_tools = @($original.software.selected_tools) }
}
$localProfilePath = Join-Path $localConversionRoot "$PublicSkillName.json"
$localProfile | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $localProfilePath -Encoding UTF8
$templatePath = Join-Path $destination 'templates\portable-skill.private.example.json'
New-Item -ItemType Directory -Force -Path (Split-Path -Parent $templatePath) | Out-Null
@{ schema_version = 1; provider = @{ display_name = 'test-provider'; base_url = ''; auth_preference = 'both'; api_key_environment_variable = 'YOUR_API_KEY'; preferred_model = 'test-model' }; software = @{ archive_root = ''; install_root = ''; selected_tools = @('test-tool') }; notes = 'Local-only template. Do not store secrets, tokens, cookies, accounts, or browser state.' } | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $templatePath -Encoding UTF8
$sanitizedAudit = & $auditScript -SkillPath $destination | ConvertFrom-Json
if ($sanitizedAudit.finding_count -gt 0) { throw "Sanitized public candidate still has portability findings. Review '$destination' before publication." }
$plan.status = 'sanitized-public-candidate-created'
$plan.local_conversion_profile = $localProfilePath
$plan | ConvertTo-Json -Depth 6
