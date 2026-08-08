[CmdletBinding()]
param(
    [string]$RepositoryRoot = (Get-Location).Path,
    [string]$OutputPath = '',
    [string]$MappingPath = '',
    [string]$OwnerNetworkPath = '',
    [string]$AgentRegistryPath = '',
    [ValidateSet('Current', 'Paper')]
    [string]$Style = 'Current'
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath $RepositoryRoot).Path
if (-not $OutputPath) {
    $OutputPath = Join-Path $root 'docs\assets\global-experience-agent-architecture.png'
}
if (-not $MappingPath) {
    $MappingPath = Join-Path $root 'config\agent-architecture-diagram.json'
}
if (-not $OwnerNetworkPath) {
    $OwnerNetworkPath = Join-Path $root 'config\agent-owner-connections.json'
}
if (-not $AgentRegistryPath) {
    $AgentRegistryPath = Join-Path $root 'config\global-experience-agent-registry.json'
}
if (-not (Test-Path -LiteralPath $MappingPath -PathType Leaf)) {
    throw "Architecture diagram mapping is missing: $MappingPath"
}
$map = Get-Content -LiteralPath $MappingPath -Raw -Encoding UTF8 | ConvertFrom-Json
if (-not (Test-Path -LiteralPath $OwnerNetworkPath -PathType Leaf)) {
    throw "Agent owner network is missing: $OwnerNetworkPath"
}
$ownerNetwork = Get-Content -LiteralPath $OwnerNetworkPath -Raw -Encoding UTF8 | ConvertFrom-Json
if (-not (Test-Path -LiteralPath $AgentRegistryPath -PathType Leaf)) {
    throw "Global experience Agent registry is missing: $AgentRegistryPath"
}
$agentRegistry = Get-Content -LiteralPath $AgentRegistryPath -Raw -Encoding UTF8 | ConvertFrom-Json
$interfacePolicyPath = Join-Path $root ([string]$map.interface_policy)
if (-not (Test-Path -LiteralPath $interfacePolicyPath -PathType Leaf)) {
    throw "Global experience Agent interface policy is missing: $interfacePolicyPath"
}
$interfacePolicy = Get-Content -LiteralPath $interfacePolicyPath -Raw -Encoding UTF8 | ConvertFrom-Json
$agentFilesystemPath = Join-Path $root ([string]$map.agent_filesystem)
if (-not (Test-Path -LiteralPath $agentFilesystemPath -PathType Leaf)) {
    throw "Global experience Agent filesystem is missing: $agentFilesystemPath"
}
$agentFilesystem = Get-Content -LiteralPath $agentFilesystemPath -Raw -Encoding UTF8 | ConvertFrom-Json
$script:paperStyle = $Style -eq 'Paper'
$routingLookup = @{}
foreach ($ownerNode in @($ownerNetwork.owners)) {
    $ownerName = [string]$ownerNode.owner
    $routingLookup[$ownerName] = [pscustomobject]@{
        incoming = @($ownerNetwork.connections | Where-Object to -eq $ownerName).Count
        outgoing = @($ownerNetwork.connections | Where-Object from -eq $ownerName).Count
        gate = if ($null -ne $ownerNode.tool_gate -and -not [string]::IsNullOrWhiteSpace([string]$ownerNode.tool_gate)) { [string]$ownerNode.tool_gate } else { 'internal' }
    }
}
$outputDirectory = Split-Path -Parent $OutputPath
if (-not (Test-Path -LiteralPath $outputDirectory)) {
    New-Item -ItemType Directory -Force -Path $outputDirectory | Out-Null
}

Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Windows.Forms

$width = 3840
$height = 2400
$bitmap = New-Object Drawing.Bitmap $width, $height
$graphics = [Drawing.Graphics]::FromImage($bitmap)
$graphics.SmoothingMode = [Drawing.Drawing2D.SmoothingMode]::AntiAlias
$graphics.TextRenderingHint = [Drawing.Text.TextRenderingHint]::ClearTypeGridFit
$graphics.InterpolationMode = [Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$graphics.PixelOffsetMode = [Drawing.Drawing2D.PixelOffsetMode]::HighQuality

function New-Color([string]$Hex) {
    [Drawing.ColorTranslator]::FromHtml($Hex)
}

function New-Brush([string]$Hex) {
    New-Object Drawing.SolidBrush (New-Color $Hex)
}

function New-PenEx([string]$Hex, [float]$Width = 2, [string]$Dash = 'Solid') {
    $pen = New-Object Drawing.Pen (New-Color $Hex), $Width
    $pen.StartCap = [Drawing.Drawing2D.LineCap]::Round
    $pen.EndCap = [Drawing.Drawing2D.LineCap]::Round
    $pen.DashStyle = [Drawing.Drawing2D.DashStyle]::$Dash
    $pen
}

function New-RoundRectPath([Drawing.RectangleF]$Rect, [float]$Radius) {
    $path = New-Object Drawing.Drawing2D.GraphicsPath
    $diameter = $Radius * 2
    $path.AddArc($Rect.X, $Rect.Y, $diameter, $diameter, 180, 90)
    $path.AddArc($Rect.Right - $diameter, $Rect.Y, $diameter, $diameter, 270, 90)
    $path.AddArc($Rect.Right - $diameter, $Rect.Bottom - $diameter, $diameter, $diameter, 0, 90)
    $path.AddArc($Rect.X, $Rect.Bottom - $diameter, $diameter, $diameter, 90, 90)
    $path.CloseFigure()
    $path
}

function Fill-RoundRect(
    [Drawing.RectangleF]$Rect,
    [string]$Fill,
    [string]$Stroke = '#D8E0E8',
    [float]$Radius = 22,
    [float]$StrokeWidth = 2
) {
    $path = New-RoundRectPath $Rect $Radius
    $brush = New-Brush $Fill
    $pen = New-PenEx $Stroke $StrokeWidth
    $graphics.FillPath($brush, $path)
    if ($StrokeWidth -gt 0) { $graphics.DrawPath($pen, $path) }
    $brush.Dispose()
    $pen.Dispose()
    $path.Dispose()
}

function Draw-TextBox(
    [string]$Text,
    [Drawing.RectangleF]$Rect,
    [Drawing.Font]$Font,
    [string]$Color = '#172033',
    [string]$Align = 'Near',
    [string]$Vertical = 'Near',
    [switch]$NoLimit
) {
    $format = New-Object Drawing.StringFormat
    $format.Alignment = [Drawing.StringAlignment]::$Align
    $format.LineAlignment = [Drawing.StringAlignment]::$Vertical
    $format.Trimming = [Drawing.StringTrimming]::EllipsisWord
    if (-not $NoLimit) { $format.FormatFlags = [Drawing.StringFormatFlags]::LineLimit }
    $brush = New-Brush $Color
    $graphics.DrawString($Text, $Font, $brush, $Rect, $format)
    $brush.Dispose()
    $format.Dispose()
}

function Draw-Chip(
    [string]$Text,
    [float]$X,
    [float]$Y,
    [float]$W,
    [float]$H,
    [string]$Fill,
    [string]$TextColor,
    [string]$Stroke = $Fill,
    [Drawing.Font]$Font = $script:fontChip
) {
    Fill-RoundRect ([Drawing.RectangleF]::new($X, $Y, $W, $H)) $Fill $Stroke ($H / 2) 1.5
    Draw-TextBox $Text ([Drawing.RectangleF]::new($X + 10, $Y, $W - 20, $H)) $Font $TextColor 'Center' 'Center'
}

function Draw-Arrow(
    [float]$X1,
    [float]$Y1,
    [float]$X2,
    [float]$Y2,
    [string]$Color = '#8FA5B8',
    [float]$Width = 4
) {
    $pen = New-PenEx $Color $Width
    $cap = New-Object Drawing.Drawing2D.AdjustableArrowCap 8, 11, $true
    $pen.CustomEndCap = $cap
    $graphics.DrawLine($pen, $X1, $Y1, $X2, $Y2)
    $cap.Dispose()
    $pen.Dispose()
}

function Draw-RuntimeStep([object]$Step, [float]$X, [float]$Y, [float]$W, [string]$Accent) {
    $stepFill = if ($script:paperStyle) { '#FFFFFF' } else { '#17314C' }
    $stepStroke = if ($script:paperStyle) { '#304153' } else { '#31516E' }
    $stepTitle = if ($script:paperStyle) { '#10253B' } else { '#FFFFFF' }
    $stepSubtitle = if ($script:paperStyle) { '#607184' } else { '#AFC2D2' }
    Fill-RoundRect ([Drawing.RectangleF]::new($X, $Y, $W, 126)) $stepFill $stepStroke 22 1.5
    $circleBrush = New-Brush $Accent
    $graphics.FillEllipse($circleBrush, $X + 18, $Y + 28, 66, 66)
    $circleBrush.Dispose()
    Draw-TextBox ([string]$Step.index) ([Drawing.RectangleF]::new($X + 18, $Y + 28, 66, 66)) $script:fontStepIndex '#10253B' 'Center' 'Center'
    Draw-TextBox ([string]$Step.label_zh) ([Drawing.RectangleF]::new($X + 102, $Y + 23, $W - 120, 48)) $script:fontStepZh $stepTitle
    Draw-TextBox ([string]$Step.label_en) ([Drawing.RectangleF]::new($X + 104, $Y + 74, $W - 120, 30)) $script:fontStepEn $stepSubtitle
}

function Draw-PlaneLegend([object]$Plane, [float]$X, [float]$Y, [float]$W) {
    Fill-RoundRect ([Drawing.RectangleF]::new($X, $Y, $W, 142)) ([string]$Plane.fill) '#D9E1E8' 24 1.5
    Draw-Chip ([string]$Plane.index) ($X + 24) ($Y + 24) 58 42 ([string]$Plane.color) '#FFFFFF'
    Draw-TextBox ([string]$Plane.title_zh) ([Drawing.RectangleF]::new($X + 100, $Y + 18, $W - 126, 48)) $script:fontPlaneZh '#10253B'
    Draw-TextBox ([string]$Plane.title_en) ([Drawing.RectangleF]::new($X + 102, $Y + 64, $W - 126, 28)) $script:fontPlaneEn ([string]$Plane.color)
    Draw-TextBox ([string]$Plane.correspondence_zh) ([Drawing.RectangleF]::new($X + 26, $Y + 100, $W - 52, 30)) $script:fontLegendBody '#556477'
}

function Draw-ModuleCard(
    [object]$Module,
    [float]$X,
    [float]$Y,
    [float]$W,
    [float]$H,
    [string]$Accent,
    [hashtable]$StageLookup,
    [hashtable]$RoutingLookup
) {
    Fill-RoundRect ([Drawing.RectangleF]::new($X, $Y, $W, $H)) '#FFFFFF' '#D7DFE7' 18 1.5
    $barBrush = New-Brush $Accent
    $graphics.FillRectangle($barBrush, [Drawing.RectangleF]::new($X + 18, $Y, $W - 36, 7))
    $barBrush.Dispose()
    Draw-TextBox ([string]$Module.owner) ([Drawing.RectangleF]::new($X + 18, $Y + 20, $W - 36, 38)) $script:fontOwner '#10253B'
    Draw-TextBox ([string]$Module.responsibility_zh) ([Drawing.RectangleF]::new($X + 18, $Y + 66, $W - 36, 46)) $script:fontModuleZh '#2E3E51' 'Near' 'Near' -NoLimit
    Draw-TextBox ('OUTPUT  ' + [string]$Module.durable_output_zh) ([Drawing.RectangleF]::new($X + 18, $Y + 120, $W - 36, 44)) $script:fontModuleOutput '#6A7686' 'Near' 'Near' -NoLimit
    $route = $RoutingLookup[[string]$Module.owner]
    if ($route) {
        $routeLabel = 'ROUTES  ' + [string]$route.incoming + ' IN / ' + [string]$route.outgoing + ' OUT  ·  ' + ([string]$route.gate).ToUpperInvariant()
        Draw-TextBox $routeLabel ([Drawing.RectangleF]::new($X + 18, $Y + 168, $W - 36, 26)) $script:fontRoute $Accent
    }
    $stageKey = [string]$Module.stage
    $stageLabel = if ($StageLookup.ContainsKey($stageKey)) { [string]$StageLookup[$stageKey] } else { $stageKey.ToUpperInvariant() }
    $chipWidth = [Math]::Min([Math]::Max(116, 18 + ($stageLabel.Length * 11)), $W - 36)
    Draw-Chip $stageLabel ($X + 18) ($Y + $H - 44) $chipWidth 28 '#EFF3F6' $Accent '#D7DFE7' $script:fontStageChip
}

function Draw-PlaneRow([object]$Plane, [float]$Y, [float]$H, [hashtable]$StageLookup, [hashtable]$RoutingLookup) {
    $rowX = 80
    $rowW = 3680
    Fill-RoundRect ([Drawing.RectangleF]::new($rowX, $Y, $rowW, $H)) ([string]$Plane.fill) '#D9E1E8' 28 1.5
    $accentBrush = New-Brush ([string]$Plane.color)
    $graphics.FillRectangle($accentBrush, [Drawing.RectangleF]::new($rowX, $Y + 28, 12, $H - 56))
    $accentBrush.Dispose()

    Draw-Chip ([string]$Plane.index) 118 ($Y + 30) 66 46 ([string]$Plane.color) '#FFFFFF'
    Draw-TextBox ([string]$Plane.title_zh) ([Drawing.RectangleF]::new(118, $Y + 90, 326, 52)) $script:fontRowZh '#10253B'
    Draw-TextBox ([string]$Plane.title_en) ([Drawing.RectangleF]::new(120, $Y + 146, 326, 30)) $script:fontRowEn ([string]$Plane.color)
    Draw-TextBox ([string]$Plane.correspondence_zh) ([Drawing.RectangleF]::new(118, $Y + 190, 326, $H - 212)) $script:fontRowBody '#5C6978' 'Near' 'Near' -NoLimit

    $modules = @($Plane.modules)
    $gap = 18
    $cardsX = 470
    $cardsW = 3250
    $cardW = ($cardsW - (($modules.Count - 1) * $gap)) / $modules.Count
    $cardY = $Y + 30
    $cardH = $H - 60
    for ($index = 0; $index -lt $modules.Count; $index++) {
        Draw-ModuleCard $modules[$index] ($cardsX + ($index * ($cardW + $gap))) $cardY $cardW $cardH ([string]$Plane.color) $StageLookup $RoutingLookup
    }
}

$canvas = New-Brush $(if ($script:paperStyle) { '#FBFBF9' } else { '#F4F0E7' })
$graphics.FillRectangle($canvas, 0, 0, $width, $height)
$canvas.Dispose()

$script:fontEyebrow = New-Object Drawing.Font 'Segoe UI Semibold', 19, ([Drawing.FontStyle]::Bold), ([Drawing.GraphicsUnit]::Pixel)
$script:fontTitleZh = New-Object Drawing.Font 'Microsoft YaHei UI', 58, ([Drawing.FontStyle]::Bold), ([Drawing.GraphicsUnit]::Pixel)
$script:fontTitleEn = New-Object Drawing.Font 'Segoe UI Semibold', 25, ([Drawing.FontStyle]::Regular), ([Drawing.GraphicsUnit]::Pixel)
$script:fontSubtitleZh = New-Object Drawing.Font 'Microsoft YaHei UI', 25, ([Drawing.FontStyle]::Regular), ([Drawing.GraphicsUnit]::Pixel)
$script:fontHero = New-Object Drawing.Font 'Segoe UI Semibold', 33, ([Drawing.FontStyle]::Bold), ([Drawing.GraphicsUnit]::Pixel)
$script:fontHeroBody = New-Object Drawing.Font 'Microsoft YaHei UI', 22, ([Drawing.FontStyle]::Regular), ([Drawing.GraphicsUnit]::Pixel)
$script:fontChip = New-Object Drawing.Font 'Segoe UI Semibold', 16, ([Drawing.FontStyle]::Bold), ([Drawing.GraphicsUnit]::Pixel)
$script:fontStepZh = New-Object Drawing.Font 'Microsoft YaHei UI', 24, ([Drawing.FontStyle]::Bold), ([Drawing.GraphicsUnit]::Pixel)
$script:fontStepEn = New-Object Drawing.Font 'Segoe UI Semibold', 15, ([Drawing.FontStyle]::Bold), ([Drawing.GraphicsUnit]::Pixel)
$script:fontStepIndex = New-Object Drawing.Font 'Segoe UI Semibold', 18, ([Drawing.FontStyle]::Bold), ([Drawing.GraphicsUnit]::Pixel)
$script:fontPlaneZh = New-Object Drawing.Font 'Microsoft YaHei UI', 24, ([Drawing.FontStyle]::Bold), ([Drawing.GraphicsUnit]::Pixel)
$script:fontPlaneEn = New-Object Drawing.Font 'Segoe UI Semibold', 15, ([Drawing.FontStyle]::Bold), ([Drawing.GraphicsUnit]::Pixel)
$script:fontLegendBody = New-Object Drawing.Font 'Microsoft YaHei UI', 17, ([Drawing.FontStyle]::Regular), ([Drawing.GraphicsUnit]::Pixel)
$script:fontRowZh = New-Object Drawing.Font 'Microsoft YaHei UI', 29, ([Drawing.FontStyle]::Bold), ([Drawing.GraphicsUnit]::Pixel)
$script:fontRowEn = New-Object Drawing.Font 'Segoe UI Semibold', 17, ([Drawing.FontStyle]::Bold), ([Drawing.GraphicsUnit]::Pixel)
$script:fontRowBody = New-Object Drawing.Font 'Microsoft YaHei UI', 20, ([Drawing.FontStyle]::Regular), ([Drawing.GraphicsUnit]::Pixel)
$script:fontOwner = New-Object Drawing.Font 'Segoe UI Semibold', 19, ([Drawing.FontStyle]::Bold), ([Drawing.GraphicsUnit]::Pixel)
$script:fontModuleZh = New-Object Drawing.Font 'Microsoft YaHei UI', 21, ([Drawing.FontStyle]::Bold), ([Drawing.GraphicsUnit]::Pixel)
$script:fontModuleOutput = New-Object Drawing.Font 'Microsoft YaHei UI', 17, ([Drawing.FontStyle]::Regular), ([Drawing.GraphicsUnit]::Pixel)
$script:fontRoute = New-Object Drawing.Font 'Segoe UI Semibold', 12, ([Drawing.FontStyle]::Bold), ([Drawing.GraphicsUnit]::Pixel)
$script:fontStageChip = New-Object Drawing.Font 'Segoe UI Semibold', 13, ([Drawing.FontStyle]::Bold), ([Drawing.GraphicsUnit]::Pixel)
$script:fontFooter = New-Object Drawing.Font 'Microsoft YaHei UI', 22, ([Drawing.FontStyle]::Bold), ([Drawing.GraphicsUnit]::Pixel)

Draw-Chip 'CURRENT ARCHITECTURE' 80 44 280 44 '#DCEBE7' '#1D625F' '#C4DDD7'
Draw-TextBox ([string]$map.title_zh) ([Drawing.RectangleF]::new(80, 98, 2500, 78)) $fontTitleZh '#0D2238'
Draw-TextBox ([string]$map.title_en) ([Drawing.RectangleF]::new(84, 180, 2550, 42)) $fontTitleEn '#43566B'
Draw-TextBox ([string]$map.subtitle_zh) ([Drawing.RectangleF]::new(2700, 108, 1050, 44)) $fontSubtitleZh '#536275' 'Far'
Draw-TextBox ([string]$map.subtitle_en) ([Drawing.RectangleF]::new(2700, 164, 1050, 38)) $fontTitleEn '#7A8796' 'Far'

$ownerCount = @($map.planes | ForEach-Object { @($_.modules) }).Count
$conceptAgentCount = @($agentRegistry.concept_agents).Count
$specialistAgentCount = @($ownerNetwork.owners).Count
$conceptAgentLabels = @($agentRegistry.concept_agents | ForEach-Object { ([string]$_.id) -replace '-agent$', '' }) -join '  |  '
$childLifecycle = @($agentRegistry.dynamic_subagents.states) -join ' -> '
$heroFill = if ($script:paperStyle) { '#FFFFFF' } else { '#10263D' }
$heroStroke = if ($script:paperStyle) { '#0E5B60' } else { '#10263D' }
$heroTitle = if ($script:paperStyle) { '#073E48' } else { '#FFFFFF' }
$heroBody = if ($script:paperStyle) { '#3F5062' } else { '#D4DFE8' }
$heroAccent = if ($script:paperStyle) { '#0E5B60' } else { '#79C8C2' }
Fill-RoundRect ([Drawing.RectangleF]::new(80, 258, 3680, 490)) $heroFill $heroStroke 34 $(if ($script:paperStyle) { 3 } else { 0 })
Draw-TextBox 'GLOBAL EXPERIENCE AGENT' ([Drawing.RectangleF]::new(130, 286, 880, 48)) $fontHero $heroTitle
Draw-TextBox 'One durable session identity; caller, model, provider, and host labels may change at an idle save point.' ([Drawing.RectangleF]::new(130, 336, 2520, 38)) $fontHeroBody $heroBody
Draw-TextBox ('CONCEPT AGENTS  ' + $conceptAgentLabels) ([Drawing.RectangleF]::new(130, 374, 2520, 34)) $fontTitleEn $heroAccent
Draw-TextBox ('CHILD LIFECYCLE  ' + $childLifecycle) ([Drawing.RectangleF]::new(2700, 374, 980, 34)) $fontTitleEn '#C48418' 'Far'
Draw-Chip 'RUN' 2680 292 92 42 '#E5A52A' '#10263D'
Draw-Chip 'CONTINUE' 2788 292 144 42 '#79C8C2' '#10263D'
Draw-Chip 'RESUME' 2948 292 128 42 '#69B5AF' '#10263D'
Draw-Chip 'ABORT' 3092 292 106 42 '#D47B68' '#10263D'
Draw-Chip ($conceptAgentCount.ToString() + ' CONCEPT') 3214 292 174 42 '#DCEBE7' '#1D625F'
Draw-Chip ($specialistAgentCount.ToString() + ' SPECIALIST') 3404 292 250 42 '#E8ECF7' '#405A8A'

$stageLookup = @{'harness' = 'HARNESS'}
foreach ($step in @($map.runtime_steps)) { $stageLookup[[string]$step.id] = [string]$step.label_en }
$stepColors = @('#E5A52A', '#69B5AF', '#7E8FC2', '#69B5AF', '#E5A52A', '#D47B68', '#69B5AF', '#E5A52A')
$stepX = 145
$stepY = 416
$stepW = 392
$stepGap = 58
for ($index = 0; $index -lt @($map.runtime_steps).Count; $index++) {
    $step = @($map.runtime_steps)[$index]
    Draw-RuntimeStep $step $stepX $stepY $stepW $stepColors[$index]
    if ($index -lt @($map.runtime_steps).Count - 1) {
        Draw-Arrow ($stepX + $stepW + 8) ($stepY + 63) ($stepX + $stepW + $stepGap - 8) ($stepY + 63) '#8FA5B8' 3
    }
    $stepX += $stepW + $stepGap
}

Fill-RoundRect ([Drawing.RectangleF]::new(145, 576, 3510, 112)) $(if ($script:paperStyle) { '#FFFFFF' } else { '#17314C' }) $(if ($script:paperStyle) { '#304153' } else { '#31516E' }) 22 1.5
Draw-Chip ([string]$map.interface_band.title_en) 177 590 286 38 '#DCEBE7' '#1D625F'
$interfaceX = 500
$interfaceWidths = @(500, 410, 510, 720)
$interfaceIndex = 0
foreach ($interfaceMap in @($map.interface_band.interfaces)) {
    $policyEntry = @($interfacePolicy.interfaces | Where-Object id -eq $interfaceMap.id)
    if ($policyEntry.Count -ne 1) { throw "Diagram interface is not registered in policy: $($interfaceMap.id)" }
    $interfaceWidth = $interfaceWidths[$interfaceIndex]
    Draw-Chip ([string]$interfaceMap.label_en) $interfaceX 590 $interfaceWidth 38 ([string]$interfaceMap.color) '#FFFFFF'
    Draw-TextBox ([string]$interfaceMap.scope_en) ([Drawing.RectangleF]::new($interfaceX, 630, $interfaceWidth, 28)) $script:fontRoute $(if ($script:paperStyle) { '#405164' } else { '#D4DFE8' }) 'Center' 'Center'
    $interfaceX += $interfaceWidth + 28
    $interfaceIndex++
}
Draw-Chip ('EXITS ' + @($interfacePolicy.exits).Count) 3240 590 170 38 '#D47B68' '#FFFFFF'
Draw-TextBox ([string]$map.interface_band.default_rule_en) ([Drawing.RectangleF]::new(177, 658, 2100, 24)) $script:fontRoute $(if ($script:paperStyle) { '#607184' } else { '#AFC2D2' })
Draw-TextBox ([string]$map.interface_band.exit_summary_en) ([Drawing.RectangleF]::new(2240, 658, 1380, 24)) $script:fontRoute $(if ($script:paperStyle) { '#607184' } else { '#AFC2D2' }) 'Far'

$legendX = 80
$legendY = 786
$legendGap = 20
$legendW = 905
foreach ($plane in @($map.planes)) {
    Draw-PlaneLegend $plane $legendX $legendY $legendW
    $legendX += $legendW + $legendGap
}

Draw-PlaneRow @($map.planes)[0] 964 306 $stageLookup $routingLookup
Draw-PlaneRow @($map.planes)[1] 1288 306 $stageLookup $routingLookup
Draw-PlaneRow @($map.planes)[2] 1612 306 $stageLookup $routingLookup
Draw-PlaneRow @($map.planes)[3] 1936 364 $stageLookup $routingLookup

$footerBrush = New-Brush $(if ($script:paperStyle) { '#FFFFFF' } else { '#10263D' })
$graphics.FillRectangle($footerBrush, 0, 2320, $width, 80)
$footerBrush.Dispose()
Draw-TextBox ([string]$map.completion.label_zh) ([Drawing.RectangleF]::new(90, 2320, 3000, 80)) $fontFooter $(if ($script:paperStyle) { '#203547' } else { '#F4F0E7' }) 'Near' 'Center'
Draw-TextBox 'AGENT FILESYSTEM  |  REGISTRY  |  OWNER NETWORK  |  INTERFACE POLICY' ([Drawing.RectangleF]::new(2140, 2320, 1610, 80)) $fontPlaneEn '#79C8C2' 'Far' 'Center'

$bitmap.Save($OutputPath, [Drawing.Imaging.ImageFormat]::Png)

$graphics.Dispose()
$bitmap.Dispose()
@(
    $fontEyebrow, $fontTitleZh, $fontTitleEn, $fontSubtitleZh, $fontHero,
    $fontHeroBody, $fontChip, $fontStepZh, $fontStepEn, $fontStepIndex,
    $fontPlaneZh, $fontPlaneEn, $fontLegendBody, $fontRowZh, $fontRowEn,
    $fontRowBody, $fontOwner, $fontModuleZh, $fontModuleOutput,
    $fontRoute, $fontStageChip, $fontFooter
) | ForEach-Object { $_.Dispose() }

[ordered]@{
    result = 'generated'
    path = (Resolve-Path -LiteralPath $OutputPath).Path
    mapping = (Resolve-Path -LiteralPath $MappingPath).Path
    owner_network = (Resolve-Path -LiteralPath $OwnerNetworkPath).Path
    agent_registry = (Resolve-Path -LiteralPath $AgentRegistryPath).Path
    interface_policy = (Resolve-Path -LiteralPath $interfacePolicyPath).Path
    agent_filesystem = (Resolve-Path -LiteralPath $agentFilesystemPath).Path
    width = $width
    height = $height
    format = 'png'
    planes = @($map.planes).Count
    mapped_owners = $ownerCount
    concept_agents = $conceptAgentCount
    specialist_agents = $specialistAgentCount
    child_lifecycle = @($agentRegistry.dynamic_subagents.states)
    style = $Style
    handoffs = @($ownerNetwork.connections).Count
    layout = "one physical Agent filesystem with $(@($agentFilesystem.zones).Count) lifecycle zones, one durable root Agent, four permission interfaces, typed exits, concept agents, specialist agents, executable child lifecycle, and four responsibility planes"
    theme = if ($script:paperStyle) { 'academic paper white, thin navy outlines, teal, red, indigo, green, and amber accents' } else { 'warm ivory, deep navy, teal, violet, green, amber, and coral' }
} | ConvertTo-Json -Depth 4
