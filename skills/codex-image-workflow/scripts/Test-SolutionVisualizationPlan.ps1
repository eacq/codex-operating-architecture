[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$planner = Join-Path $PSScriptRoot 'New-SolutionVisualizationPlan.ps1'

function Assert-Equal([string]$Name, $Actual, $Expected) {
    if ($Actual -ne $Expected) { throw "$Name expected '$Expected' but got '$Actual'." }
}

$relationship = & $planner -Subject 'Gift exchange elimination' -ProblemType relationship -Complexity 4 -Relationships 'maximum-to-all-allowed','zero-to-none','remove-pair' | ConvertFrom-Json
Assert-Equal 'relationship format' $relationship.format 'mermaid'
Assert-Equal 'relationship action' $relationship.action 'embed-reviewable-text-diagram'

$geometry = & $planner -Subject 'Triangle similarity proof' -ProblemType geometry -Complexity 3 -Relationships 'angle-equality','side-ratio' | ConvertFrom-Json
Assert-Equal 'geometry format' $geometry.format 'svg'

$quantitative = & $planner -Subject 'Rate comparison' -ProblemType quantitative -Complexity 3 -Relationships 'series-a','series-b' | ConvertFrom-Json
Assert-Equal 'quantitative format' $quantitative.format 'png'

$simple = & $planner -Subject 'One-step percentage' -ProblemType simple -Complexity 1 | ConvertFrom-Json
Assert-Equal 'simple format' $simple.format 'none'
Assert-Equal 'simple action' $simple.action 'keep-written-solution'

'Solution visualization planner checks passed.'
