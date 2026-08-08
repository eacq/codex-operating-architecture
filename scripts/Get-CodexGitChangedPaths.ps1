[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$RepositoryRoot
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath $RepositoryRoot).Path
$rawStatus = [string](@(& git -C $root status --porcelain=v1 -z --untracked-files=all) -join '')
if ($LASTEXITCODE -ne 0) { throw "Unable to read Git status for '$root'." }

$paths = New-Object System.Collections.Generic.List[string]
$records = @($rawStatus.Split([char]0, [StringSplitOptions]::RemoveEmptyEntries) | Where-Object { $_.Length -gt 0 })
for ($index = 0; $index -lt $records.Count; $index++) {
    $record = $records[$index]
    if ($record.Length -lt 4 -or $record[2] -ne ' ') { throw "Unexpected Git porcelain record: '$record'." }

    $path = $record.Substring(3).Replace('\', '/')
    if (-not $path -or [IO.Path]::IsPathRooted($path) -or $path -match '(^|/)\.\.(/|$)') { throw "Invalid repository-relative path from Git status: '$path'." }
    [void]$paths.Add($path)

    if ($record[0] -in @('R', 'C')) {
        if ($index + 1 -ge $records.Count) { throw "Missing original path for Git rename/copy record: '$record'." }
        $index++
    }
}

$paths | Sort-Object -Unique
