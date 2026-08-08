[CmdletBinding()]
param([string]$RepositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..\..\..')).Path)
$ErrorActionPreference='Stop'
$root=(Resolve-Path -LiteralPath $RepositoryRoot).Path
$skill=Join-Path $root 'skills\codex-image-workflow\subskills\visual-design-agent\SKILL.md'
$planner=Join-Path $root 'skills\codex-image-workflow\subskills\visual-design-agent\scripts\New-VisualDesignPlan.ps1'
$template=Join-Path $root 'skills\codex-image-workflow\subskills\visual-design-agent\scripts\New-VisualDesignTemplate.ps1'
$referenceAnalysis=Join-Path $root 'skills\codex-image-workflow\subskills\visual-design-agent\scripts\New-ReferenceVisualAnalysis.ps1'
foreach($path in @($skill,$planner,$template,$referenceAnalysis)){if(-not(Test-Path -LiteralPath $path -PathType Leaf)){throw "Missing visual-design Agent artifact: $path"}}
$text=Get-Content -LiteralPath $skill -Raw -Encoding UTF8
foreach($term in @('visual-design-agent','editable-diagram','architecture-diagram','scientific-figure','presentation','reference-image-reverse-design','content-card-series','content-infographic','content-cover','article-illustration','content-svg-diagram','content-slide-deck','baoyu-content-design-routing.md','reference-design.json','route-improvement-candidate.json','design-template.json','typed exit','does not replace')){if($text -notmatch [regex]::Escape($term)){throw "Missing visual-design rule: $term"}}
foreach($case in @(@('Create an architecture workflow diagram','architecture-diagram'),@('Create a PowerPoint product deck','presentation'),@('Create a scientific graphical abstract','scientific-figure'),@('Create a painterly hero image','raster-image'),@('\u67b6\u6784\u56fe','architecture-diagram'))){$goal=[regex]::Unescape($case[0]);$plan=& $planner -Goal $goal -Json|ConvertFrom-Json;if($plan.selected_route -ne $case[1]){throw "Expected $($case[1]) route."};if(-not $plan.design_template_required){throw 'Expected template capture.'}}
$referencePlan=& $planner -Goal 'Reverse design this reference image' -Json|ConvertFrom-Json;if($referencePlan.selected_route -ne 'reference-image-reverse-design' -or -not $referencePlan.reference_analysis_required -or 'analysis/reference-design.json' -notin @($referencePlan.required_artifacts)){throw 'Expected reference-image reverse-design route and artifacts.'}
foreach($case in @(@('Create Xiaohongshu social cards','content-card-series'),@('Create an infographic','content-infographic'),@('Create an article cover image','content-cover'),@('Illustrate this article','article-illustration'),@('Create a content SVG diagram','content-svg-diagram'),@('Create a content slide deck','content-slide-deck'))){$plan=& $planner -Goal $case[0] -Json|ConvertFrom-Json;if($plan.selected_route -ne $case[1]){throw "Expected content route $($case[1])."}}
Write-Output 'Visual Design Agent test passed.'
