[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$SkillPath,
    [string]$OutputPath = ''
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath $SkillPath).Path
$patterns = @(
    @{ category = 'machine_path'; regex = '(?i)(?:[A-Z]:\\|/Users/|/home/)'; action = 'Move to local software or machine profile.' },
    @{ category = 'endpoint'; regex = '(?i)https?://[^\s`"'']+'; action = 'Keep only protocol examples; move personal provider endpoints to a profile.' },
    @{ category = 'credential_variable'; regex = '(?i)\b(?!(?:YOUR|TEST)_(?:API_KEY|TOKEN|SECRET|PASSWORD)\b)[A-Z][A-Z0-9_]*(?:API_KEY|TOKEN|SECRET|PASSWORD)\b'; action = 'Keep a generic key name or profile field; never store a value.' }
)
$findings = @()
Get-ChildItem -LiteralPath $root -Recurse -File | Where-Object { $_.Extension -in @('.md', '.json', '.ps1', '.py', '.toml', '.yaml', '.yml') } | ForEach-Object {
    $file = $_
    $lineNumber = 0
    Get-Content -LiteralPath $file.FullName -Encoding UTF8 | ForEach-Object {
        $lineNumber++
        foreach ($pattern in $patterns) {
            if ($_ -match $pattern.regex) {
                $findings += [ordered]@{
                    category = $pattern.category
                    file = $file.FullName.Replace($root, '.').TrimStart('\\')
                    line = $lineNumber
                    action = $pattern.action
                }
            }
        }
    }
}
$result = [ordered]@{
    schema_version = 1
    skill_path = $root
    finding_count = $findings.Count
    findings = $findings
    safe_next_step = 'Review findings, move personal choices to a local profile, then rerun this audit.'
}
if ($OutputPath) {
    $result | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $OutputPath -Encoding UTF8
}
$result | ConvertTo-Json -Depth 5
