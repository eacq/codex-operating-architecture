[CmdletBinding(PositionalBinding = $false)]
param(
    [string]$RepositoryRoot = 'F:\codex',
    [ValidateSet('StartWork', 'Continue', 'Resume', 'SearchMemory', 'StoreMemory', 'RenderMemorySnapshot', 'RouteOwner', 'CandidateReport', 'DescribeInterfaces', 'EvaluateAccess')]
    [string]$Access = 'StartWork',
    [string]$SessionId,
    [string]$Goal = 'Global Experience Agent access',
    [string]$Authority = 'current caller has bounded functional authority',
    [ValidateSet('human', 'llm', 'internal-functional-unit', 'global-control')]
    [string]$Interface = 'human',
    [ValidateSet('none', 'functional', 'gated', 'global-structure')]
    [string]$AuthorityScope = 'functional',
    [switch]$GlobalStructure,
    [string]$Query,
    [string]$Owner,
    [string]$ResultSummary,
    [string[]]$ResultEvidence = @(),
    [string[]]$WriteSurface = @(),
    [string[]]$AcceptanceCriteria = @(),
    [string[]]$NextTurn = @(),
    [string]$RequestedOperation,
    [string[]]$RequestedSurfaces = @(),
    [ValidateSet('context', 'lesson', 'procedure', 'decision', 'error')]
    [string]$MemoryType = 'context',
    [ValidateSet('episodic', 'semantic', 'procedural')]
    [string]$MemoryLayer = 'episodic',
    [int]$Priority = 5,
    [switch]$Apply
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath $RepositoryRoot).Path
$controller = Join-Path $root 'agent\40-runtime\Invoke-GlobalExperienceAgent.ps1'
if (-not (Test-Path -LiteralPath $controller -PathType Leaf)) {
    throw 'Global Experience Agent controller is missing.'
}

if ($GlobalStructure) {
    $Interface = 'global-control'
    $AuthorityScope = 'global-structure'
}

$mode = 'Continue'
$operation = $Access
switch ($Access) {
    'StartWork' { $mode = 'Run'; $operation = 'StartWork' }
    'Continue' { $mode = 'Continue'; $operation = 'RetrieveContext' }
    'Resume' { $mode = 'Resume'; $operation = 'RetrieveContext' }
    'SearchMemory' { $mode = 'Continue'; $operation = 'SearchMemory' }
    'StoreMemory' { $mode = 'Continue'; $operation = 'StoreMemory' }
    'RenderMemorySnapshot' { $mode = 'Continue'; $operation = 'RenderMemorySnapshot' }
    'RouteOwner' { $mode = 'Continue'; $operation = 'RouteOwner' }
    'CandidateReport' { $mode = 'Continue'; $operation = 'CandidateReport' }
    'DescribeInterfaces' { $mode = 'Inspect'; $operation = 'DescribeInterfaces' }
    'EvaluateAccess' { $mode = 'Continue'; $operation = 'EvaluateAccess' }
}

if ($Access -ne 'StartWork' -and $Access -ne 'DescribeInterfaces' -and [string]::IsNullOrWhiteSpace($SessionId)) {
    throw "$Access requires -SessionId."
}
if ($Access -eq 'SearchMemory' -and [string]::IsNullOrWhiteSpace($Query)) {
    throw 'SearchMemory requires -Query.'
}
if ($Access -eq 'StoreMemory' -and [string]::IsNullOrWhiteSpace($ResultSummary)) {
    throw 'StoreMemory requires -ResultSummary.'
}
if ($Access -eq 'RouteOwner' -and [string]::IsNullOrWhiteSpace($Owner)) {
    throw 'RouteOwner requires -Owner.'
}
if ($Access -eq 'EvaluateAccess' -and [string]::IsNullOrWhiteSpace($RequestedOperation)) {
    throw 'EvaluateAccess requires -RequestedOperation.'
}

& $controller `
    -RepositoryRoot $root `
    -Mode $mode `
    -Operation $operation `
    -SessionId $SessionId `
    -Goal $Goal `
    -Authority $Authority `
    -Interface $Interface `
    -AuthorityScope $AuthorityScope `
    -Query $Query `
    -Owner $Owner `
    -ResultSummary $ResultSummary `
    -ResultEvidence $ResultEvidence `
    -WriteSurface $WriteSurface `
    -AcceptanceCriteria $AcceptanceCriteria `
    -NextTurn $NextTurn `
    -RequestedOperation $RequestedOperation `
    -RequestedSurfaces $RequestedSurfaces `
    -MemoryType $MemoryType `
    -MemoryLayer $MemoryLayer `
    -Priority $Priority `
    -Apply:$Apply
