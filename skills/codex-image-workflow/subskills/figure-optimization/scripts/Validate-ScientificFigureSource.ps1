[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Path,
    [switch]$Strict,
    [switch]$Json
)

$ErrorActionPreference = 'Stop'
$resolved = Resolve-Path -LiteralPath $Path
$sourcePath = $resolved.Path
$content = Get-Content -LiteralPath $sourcePath -Raw -Encoding UTF8
$extension = [IO.Path]::GetExtension($sourcePath).ToLowerInvariant()

$findings = New-Object System.Collections.Generic.List[object]
function Add-Finding([string]$Level, [string]$Code, [string]$Message) {
    $findings.Add([ordered]@{
        level = $Level
        code = $Code
        message = $Message
    }) | Out-Null
}

$isPython = $extension -in @('.py', '.ipy')
$isR = $extension -in @('.r', '.rmd', '.qmd')

if (-not $isPython -and -not $isR) {
    Add-Finding 'warn' 'unknown-extension' 'Source is not a recognized Python/R plotting file; only generic text checks were run.'
}

if ($isPython) {
    if ($content -match '(?m)^\s*(library|require)\s*\(') {
        Add-Finding 'fail' 'cross-backend-r-in-python' 'Python figure source appears to invoke R plotting libraries.'
    }
    if ($content -notmatch "svg\.fonttype.+none" -and $content -notmatch "rcParams\[['""]svg\.fonttype['""]\]\s*=\s*['""]none['""]") {
        Add-Finding 'warn' 'editable-svg-text' 'Matplotlib source does not clearly set svg.fonttype = none for editable SVG text.'
    }
    if ($content -match "cmap\s*=\s*['""](jet|rainbow|turbo)['""]" -or $content -match "plt\.get_cmap\(['""](jet|rainbow|turbo)['""]\)") {
        Add-Finding 'warn' 'unsafe-colormap' 'Rainbow-style colormap detected; verify it is scientifically justified and accessible.'
    }
    if ($content -notmatch 'savefig\s*\(') {
        Add-Finding 'warn' 'no-savefig' 'No matplotlib savefig call detected.'
    }
    if ($content -match 'savefig\s*\([^)]*\.png' -and $content -notmatch 'savefig\s*\([^)]*\.(svg|pdf)') {
        Add-Finding 'warn' 'png-only-export' 'PNG export detected without obvious SVG/PDF vector export.'
    }
}

if ($isR) {
    if ($content -match '(?m)^\s*import\s+(matplotlib|seaborn)|^\s*from\s+matplotlib') {
        Add-Finding 'fail' 'cross-backend-python-in-r' 'R figure source appears to invoke Python plotting libraries.'
    }
    if ($content -notmatch 'svglite|cairo_pdf|ggsave\s*\([^)]*\.svg|ggsave\s*\([^)]*\.pdf') {
        Add-Finding 'warn' 'vector-export-missing' 'R source does not clearly export editable SVG/PDF output.'
    }
    if ($content -match 'scale_(fill|color|colour)_.*(rainbow|jet|turbo)') {
        Add-Finding 'warn' 'unsafe-colormap' 'Rainbow-style palette detected; verify it is scientifically justified and accessible.'
    }
}

if ($content -match '(random|randn|normal|runif|rnorm|sample)\s*\(' -and $content -notmatch '(demo|fixture|synthetic|simulated|example)') {
    Add-Finding 'warn' 'possible-simulated-data' 'Random/sampling call detected without an obvious simulated/demo-data disclosure.'
}

if ($content -match 'dropna|na\.omit|filter\s*\(|subset\s*\(|query\s*\(' -and $content -notmatch '(excluded|exclusion|before|after|missing|drop rule|filter rule|NA rule)') {
    Add-Finding 'warn' 'exclusion-disclosure' 'Data filtering or missing-data handling detected without an obvious before/after or exclusion-rule note.'
}

if ($content -notmatch '(n\s*=|sample size|replicate|independent unit|biological replicate|technical replicate)') {
    Add-Finding 'warn' 'n-definition' 'No obvious sample-size or independent-unit annotation found in source comments/text.'
}

if ($content -notmatch '(dpi\s*=|res\s*=|width\s*=|height\s*=|figsize|width_mm|height_mm)') {
    Add-Finding 'warn' 'size-resolution-contract' 'No obvious size, resolution, or physical-dimension contract found.'
}

$failed = @($findings | Where-Object { $_.level -eq 'fail' })
$warnings = @($findings | Where-Object { $_.level -eq 'warn' })
$status = if ($failed.Count -gt 0) { 'failed' } elseif ($Strict -and $warnings.Count -gt 0) { 'failed' } else { 'passed' }

$result = [ordered]@{
    status = $status
    source = $sourcePath
    strict = $Strict.IsPresent
    findings = @($findings.ToArray())
}

if ($Json) {
    $result | ConvertTo-Json -Depth 6
} else {
    "Scientific figure source preflight: $status"
    foreach ($finding in $findings) {
        "[{0}] {1}: {2}" -f $finding.level.ToUpperInvariant(), $finding.code, $finding.message
    }
}

if ($status -ne 'passed') { exit 1 }
