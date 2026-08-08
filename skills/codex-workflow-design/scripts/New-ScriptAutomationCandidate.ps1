[CmdletBinding()]
param(
    [string]$ProjectRoot = (Get-Location).Path,
    [Parameter(Mandatory = $true)][string]$Owner,
    [Parameter(Mandatory = $true)][string]$Name,
    [Parameter(Mandatory = $true)][string]$Trigger,
    [Parameter(Mandatory = $true)][ValidateRange(1, 1000)][int]$ObservedOccurrences,
    [Parameter(Mandatory = $true)][string[]]$Inputs,
    [Parameter(Mandatory = $true)][string]$Validation,
    [ValidateSet('PowerShell','Python','Node','Shell','Go','Rust','CSharp','ExistingScript')]
    [string]$Language = 'PowerShell',
    [ValidateSet('ReadOnly','LocalReversible','ExternalOrIrreversible')]
    [string]$Risk = 'ReadOnly',
    [switch]$Apply
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath $ProjectRoot).Path
if ($Inputs.Count -eq 0 -or @($Inputs | Where-Object { [string]::IsNullOrWhiteSpace($_) }).Count -gt 0) { throw 'Automation candidates require explicit stable inputs.' }
if ([string]::IsNullOrWhiteSpace($Validation)) { throw 'Automation candidates require a validation command or observable check.' }

$status = if ($Risk -eq 'ExternalOrIrreversible') {
    'requires-explicit-authorization'
} elseif ($ObservedOccurrences -ge 2) {
    'eligible-for-script-trial'
} else {
    'candidate-needs-repeat-evidence'
}
$slug = ($Name.ToLowerInvariant() -replace '[^a-z0-9]+','-').Trim('-')
if (-not $slug) { throw 'Automation candidate name must contain letters or digits.' }
$relative = ".codex/project/automation-candidates/$slug.json"
$record = [ordered]@{
    schema_version = 1
    name = $Name
    owner = $Owner
    trigger = $Trigger
    observed_occurrences = $ObservedOccurrences
    inputs = @($Inputs)
    validation = $Validation
    language = $Language
    risk = $Risk
    status = $status
    script_trial_rule = 'Treat the script as a first-class owner asset. It may be split, merged, refactored, or moved to a more suitable language only with explicit caller contracts, baseline/equivalence evidence, and the same authorization boundary. Preserve explicit authorization for external, irreversible, credential, installation, publication, or destructive actions.'
    created_at = [DateTime]::UtcNow.ToString('o')
}
if ($Apply) {
    $path = Join-Path $root $relative
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $path) | Out-Null
    $record | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $path -Encoding UTF8
    $record['path'] = $relative
}
$record | ConvertTo-Json -Depth 5
