[CmdletBinding()]
param([string]$RepositoryRoot = 'F:\codex')

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath $RepositoryRoot).Path
$skill = Join-Path $root 'skills\codex-experience-capture\subskills\experience-agent-access\SKILL.md'
$script = Join-Path $root 'skills\codex-experience-capture\scripts\Invoke-ExperienceAgentAccess.ps1'

foreach ($path in @($skill, $script)) {
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        throw "Required experience Agent access file is missing: $path"
    }
}

$text = Get-Content -LiteralPath $skill -Raw -Encoding UTF8
foreach ($required in @(
    'name: codex-experience-capture-experience-agent-access',
    'description:',
    'not a new Agent, owner, or controller',
    'Invoke-ExperienceAgentAccess.ps1',
    'RouteOwner',
    'GlobalStructure'
)) {
    if ($text -notmatch [regex]::Escape($required)) {
        throw "Experience Agent access skill is missing required text: $required"
    }
}

$parseErrors = $null
[System.Management.Automation.Language.Parser]::ParseFile($script, [ref]$null, [ref]$parseErrors) | Out-Null
if ($parseErrors) {
    throw "Experience Agent access script has PowerShell syntax errors: $($parseErrors | Out-String)"
}

$result = & $script -RepositoryRoot $root -Access DescribeInterfaces | ConvertFrom-Json
if ($result.status -ne 'passed' -or $result.model -ne 'global-experience-agent') {
    throw 'Experience Agent access DescribeInterfaces smoke check did not return the Agent response.'
}
if ($result.authorization_decision.decision -ne 'allow') {
    throw 'Experience Agent access smoke check did not preserve interface authorization.'
}

[pscustomobject][ordered]@{
    status = 'passed'
    model = 'experience-agent-access'
    skill = 'skills/codex-experience-capture/subskills/experience-agent-access/SKILL.md'
    script = 'skills/codex-experience-capture/scripts/Invoke-ExperienceAgentAccess.ps1'
    smoke = 'DescribeInterfaces'
} | ConvertTo-Json -Compress
