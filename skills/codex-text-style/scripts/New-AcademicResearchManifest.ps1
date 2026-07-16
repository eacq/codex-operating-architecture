[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$ProjectRoot,

    [Parameter(Mandatory)]
    [ValidateSet('PaperRead', 'EvidenceSynthesis', 'ManuscriptDraft', 'ResearchCode', 'FigurePlan')]
    [string]$Mode,

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$Goal,

    [string[]]$Source = @(),
    [string[]]$Deliverable = @(),
    [string]$OutputPath
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath $ProjectRoot).Path
$createdAt = (Get-Date).ToUniversalTime().ToString('o')

if (-not $OutputPath) {
    $name = "{0}-{1}.json" -f (Get-Date).ToUniversalTime().ToString('yyyyMMddTHHmmssZ'), $Mode
    $OutputPath = Join-Path $root (Join-Path '.codex\academic-work' $name)
}

if (Test-Path -LiteralPath $OutputPath) {
    throw "Manifest already exists: $OutputPath"
}

$directory = Split-Path -Parent $OutputPath
New-Item -ItemType Directory -Path $directory -Force | Out-Null

$manifest = [ordered]@{
    schema_version = 1
    created_at = $createdAt
    mode = $Mode
    goal = $Goal
    sources = @($Source)
    deliverables = @($Deliverable)
    status = 'planned'
    evidence_contract = [ordered]@{
        requires_source_locator = $true
        requires_claim_status = $true
        allowed_statuses = @('supported', 'disputed', 'pending', 'out-of-scope')
        prohibits_invented_claims = $true
    }
    routing = [ordered]@{
        paper_and_pdf = 'paper or PDF reading workflow'
        citations = 'literature search or reference verification workflow'
        prose = 'codex-text-style'
        code = 'codex-information-gathering and codex-task-execution'
        figures = 'codex-image-workflow'
    }
}

$json = $manifest | ConvertTo-Json -Depth 5
[System.IO.File]::WriteAllText($OutputPath, $json + [Environment]::NewLine, (New-Object System.Text.UTF8Encoding($false)))
Write-Output $OutputPath
