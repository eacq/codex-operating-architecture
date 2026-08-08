[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$ProjectPath,
    [Parameter(Mandatory = $true)][string]$ImagePath,
    [Parameter(Mandatory = $true)][string]$RecommendedRoute,
    [string[]]$ObservedLayout = @(),
    [string[]]$ObservedHierarchy = @(),
    [string[]]$ObservedStyle = @(),
    [string[]]$EditableBoundaries = @(),
    [string[]]$ImprovementCandidates = @(),
    [switch]$Apply,
    [switch]$Json
)
$ErrorActionPreference='Stop'
$project=(Resolve-Path -LiteralPath $ProjectPath).Path
$image=(Resolve-Path -LiteralPath $ImagePath).Path
$analysis=[ordered]@{schema_version=1;kind='reference-visual-analysis';reference_image=$image;inference_status='visual inference, not original-source reconstruction';recommended_route=$RecommendedRoute;layout=@($ObservedLayout);hierarchy=@($ObservedHierarchy);style=@($ObservedStyle);editable_boundaries=@($EditableBoundaries);privacy_rule='do not retain private wording, credentials, session data, or unlicensed artwork in reusable templates';verification_rule='route improvement remains a candidate until the recreated artifact passes route-specific validation'}
$candidate=[ordered]@{schema_version=1;kind='visual-route-improvement-candidate';recommended_route=$RecommendedRoute;candidates=@($ImprovementCandidates);status='candidate';promotion_rule='promote only after route-specific render and format validation'}
if($Apply){$dir=Join-Path $project 'analysis';New-Item -ItemType Directory -Force -Path $dir|Out-Null;$analysis|ConvertTo-Json -Depth 8|Set-Content -LiteralPath (Join-Path $dir 'reference-design.json') -Encoding UTF8;$candidate|ConvertTo-Json -Depth 8|Set-Content -LiteralPath (Join-Path $dir 'route-improvement-candidate.json') -Encoding UTF8}
if($Json){[ordered]@{analysis=$analysis;candidate=$candidate}|ConvertTo-Json -Depth 10}else{[pscustomobject]@{analysis=$analysis;candidate=$candidate}}
