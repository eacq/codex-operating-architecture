[CmdletBinding()]
param(
    [string]$ProjectRoot = (Get-Location).Path,
    [string]$ArchitectureRoot = (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))),
    [switch]$Apply
)

$ErrorActionPreference = 'Stop'
$project = (Resolve-Path -LiteralPath $ProjectRoot).Path
$architecture = (Resolve-Path -LiteralPath $ArchitectureRoot).Path
$policyPath = Join-Path $architecture 'config\owner-self-iteration-policy.json'
$registryPath = Join-Path $architecture 'module-registry.json'
$namingPolicyPath = Join-Path $architecture 'config\skill-name-migrations.json'

foreach ($path in @($policyPath, $registryPath, $namingPolicyPath)) {
    if (-not (Test-Path -LiteralPath $path)) { throw "Owner self-iteration review is missing authority: $path" }
}

$policy = Get-Content -LiteralPath $policyPath -Raw -Encoding UTF8 | ConvertFrom-Json
$registry = Get-Content -LiteralPath $registryPath -Raw -Encoding UTF8 | ConvertFrom-Json
$namingPolicy = Get-Content -LiteralPath $namingPolicyPath -Raw -Encoding UTF8 | ConvertFrom-Json
if ([int]$policy.schema_version -ne 1 -or -not $policy.automatic_local_optimization.enabled -or -not $policy.automatic_rename.enabled -or -not $namingPolicy.policy.top_owner_rename_authority.enabled) {
    throw 'Owner self-iteration policy is invalid or disabled.'
}

$activeOwners = @($registry.modules | Where-Object { $_.status -eq 'active' } | ForEach-Object { [string]$_.name } | Sort-Object)
if ($activeOwners.Count -eq 0) { throw 'Owner self-iteration review found no active owners.' }

$review = [ordered]@{
    schema_version = 1
    result = 'analyzed'
    asset_class = [string]$policy.asset_class
    automatic_review = [string]$policy.automatic_review
    active_owner_count = $activeOwners.Count
    active_owners = $activeOwners
    automatic_local_optimization = [ordered]@{
        enabled = [bool]$policy.automatic_local_optimization.enabled
        allowed_classes = @('documentation-only', 'owner-internal-subskill-refinement', 'read-only-script-refactor', 'local-reversible-workflow-refactor')
        required_conditions = @($policy.automatic_local_optimization.conditions)
    }
    automatic_rename = [ordered]@{
        enabled = [bool]$policy.automatic_rename.enabled
        scope = [string]$policy.automatic_rename.scope
        required_conditions = @($policy.automatic_rename.conditions)
        exclusions = @($policy.automatic_rename.exclusions)
        migration_authority = 'config/skill-name-migrations.json'
        required_validation = @('scripts/Test-SkillNameMigrations.ps1', 'scripts/validate-global-install.ps1')
    }
    authorization_required = @($policy.requires_explicit_authorization)
    required_evidence = @($policy.required_evidence)
    candidate_disposition = 'No mutation is authorized by this review alone except a naming-only owner or skill migration that meets every automatic-rename condition and passes the required migration validation. Apply all other candidates only after their separate evidence and authority checks.'
    rollback = 'Retain the current owner and restore the changed owner-scoped files when equivalent validation fails.'
    generated_at = [DateTime]::UtcNow.ToString('o')
}

if ($Apply) {
    $outputDirectory = Join-Path $project '.codex\project'
    New-Item -ItemType Directory -Path $outputDirectory -Force | Out-Null
    $output = Join-Path $outputDirectory 'owner-self-iteration-review.json'
    $review | ConvertTo-Json -Depth 7 | Set-Content -LiteralPath $output -Encoding UTF8
    $review['output'] = '.codex/project/owner-self-iteration-review.json'
}

$review | ConvertTo-Json -Depth 7
