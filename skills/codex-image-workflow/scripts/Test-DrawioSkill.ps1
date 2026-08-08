[CmdletBinding()]
param(
    [string]$ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path,
    [switch]$KeepArtifacts
)

$ErrorActionPreference = 'Stop'
$runtime = & (Join-Path $PSScriptRoot 'Resolve-DrawioRuntime.ps1') -ProjectRoot $ProjectRoot -RequireGraphviz | ConvertFrom-Json
$workRoot = Join-Path $ProjectRoot ('.runtime\work\drawio-skill-test-' + [Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Force -Path $workRoot | Out-Null
$sourcePath = Join-Path $workRoot 'smoke.drawio'
$outputPath = Join-Path $workRoot 'smoke.png'
@'
<mxfile host="app.diagrams.net" version="31.0.2"><diagram id="smoke" name="Page-1"><mxGraphModel><root><mxCell id="0"/><mxCell id="1" parent="0"/><mxCell id="a" value="Global Experience Agent" style="rounded=1;whiteSpace=wrap;html=1;" vertex="1" parent="1"><mxGeometry x="40" y="40" width="220" height="60" as="geometry"/></mxCell></root></mxGraphModel></diagram></mxfile>
'@ | Set-Content -LiteralPath $sourcePath -Encoding UTF8

try {
    $dot = Start-Process -FilePath $runtime.graphviz_executable -ArgumentList @('-V') -Wait -PassThru -NoNewWindow
    if ($dot.ExitCode -ne 0) { throw "Graphviz returned exit code $($dot.ExitCode)." }
    $lint = & $runtime.python_executable -s (Join-Path $ProjectRoot 'skills\codex-image-workflow\subskills\drawio-skill\scripts\validate.py') $sourcePath 2>&1
    if ($LASTEXITCODE -ne 0) { throw "drawio-skill lint failed: $lint" }
    $export = Start-Process -FilePath $runtime.drawio_executable -ArgumentList @('-x','-f','png','--width','1200','-o',$outputPath,$sourcePath,'--disable-gpu','--no-sandbox') -Wait -PassThru -NoNewWindow
    if ($export.ExitCode -ne 0) { throw "draw.io export returned exit code $($export.ExitCode)." }
    if (-not (Test-Path -LiteralPath $outputPath -PathType Leaf)) { throw "draw.io exited without creating $outputPath." }
    $result = [ordered]@{ status = 'passed'; png = $outputPath; bytes = (Get-Item -LiteralPath $outputPath).Length; lint = ($lint -join [Environment]::NewLine) }
    $result | ConvertTo-Json -Depth 3
}
finally {
    if (-not $KeepArtifacts -and (Test-Path -LiteralPath $workRoot)) { Remove-Item -LiteralPath $workRoot -Recurse -Force }
}
