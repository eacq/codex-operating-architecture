[CmdletBinding()]
param(
    [string]$RepositoryRoot = (Get-Location).Path,
    [ValidateSet('Feature', 'Refinement')]
    [string]$ChangeClass = 'Refinement',
    [string]$Message = '',
    [string[]]$Paths = @(),
    [switch]$SkipFastVerification,
    [switch]$Push,
    [switch]$Apply
)

$ErrorActionPreference = 'Stop'
$root = [IO.Path]::GetFullPath((Resolve-Path -LiteralPath $RepositoryRoot).Path).TrimEnd('\')
$gitRoot = [IO.Path]::GetFullPath(((& git -C $root rev-parse --show-toplevel).Trim() -replace '/', '\')).TrimEnd('\')
if ($gitRoot -ne $root) { throw "Repository root mismatch: expected '$root', got '$gitRoot'." }

function Convert-JsonOutput([object[]]$Raw, [string]$Source) {
    $text = ([string]::Join([Environment]::NewLine, @($Raw))).Trim()
    if (-not $text) { throw "Script produced no JSON output: $Source" }
    try {
        return ($text | ConvertFrom-Json)
    } catch {
        $start = $text.LastIndexOf("`n{")
        if ($start -ge 0) {
            $json = $text.Substring($start + 1).Trim()
            try { return ($json | ConvertFrom-Json) } catch {}
        }
        throw "Script output did not end with parseable JSON: $Source"
    }
}

if (-not $Paths -or $Paths.Count -eq 0) {
    $pathCollector = Join-Path $root 'scripts\Get-CodexGitChangedPaths.ps1'
    $Paths = @(& $pathCollector -RepositoryRoot $root)
}
$selected = @($Paths | Where-Object { $_ } | ForEach-Object { $_.Replace('\','/') } | Sort-Object -Unique)

$result = [ordered]@{
    schema_version = 1
    result = 'planned'
    repository_root = $root
    branch = (& git -C $root branch --show-current).Trim()
    selected_paths = $selected
    change_class = $ChangeClass
    commit_mode = if ($Push) { 'commit-and-push-origin' } else { 'commit-local-only' }
    economy = [ordered]@{
        avoids_manual_duplicate_full_validation = $true
        retained_gates = @('changed-script fast verification', 'git diff --check', 'verified private commit controller', 'complete iteration gate', 'publication metadata gate')
        boundary = 'This wrapper never replaces the verified commit controller and never pushes unless -Push is explicitly set.'
    }
}

if ($selected.Count -eq 0) {
    $result.result = 'no-changes'
    $result | ConvertTo-Json -Depth 6
    return
}

if (-not $SkipFastVerification) {
    $fastScript = Join-Path $root 'scripts\Invoke-CodexVerification.ps1'
    $fast = Convert-JsonOutput (& $fastScript -RepositoryRoot $root -Mode Fast -ChangedPaths $selected -NoRecord) $fastScript
    $result['fast_verification'] = $fast
}

& git -C $root diff --check
if ($LASTEXITCODE -ne 0) { throw 'Git whitespace check failed.' }
$result['whitespace_check'] = 'passed'

$candidateScript = Join-Path $root 'skills\codex-experience-capture\scripts\New-GlobalIterationCandidateReport.ps1'
$candidateReport = Convert-JsonOutput (& $candidateScript -ProjectRoot $root -Apply) $candidateScript
$result['candidate_report'] = [ordered]@{
    result = $candidateReport.result
    candidate_count = $candidateReport.candidate_count
    output = $candidateReport.output
}

$graphPath = Join-Path $root 'knowledge-vault\00-Home\graph.json'
if (Test-Path -LiteralPath $graphPath -PathType Leaf) {
    $graph = Get-Content -LiteralPath $graphPath -Raw -Encoding UTF8 | ConvertFrom-Json
    $changedKnowledgePaths = @($selected | Where-Object { $_ -match '^knowledge-vault/.+\.md$' } | ForEach-Object { ($_ -replace '^knowledge-vault/', '') -replace '/', '\' })
    $unknownNodes = @($graph.nodes | Where-Object { $_.status -eq 'unknown' -and $_.path -in $changedKnowledgePaths })
    $result['knowledge_status_check'] = [ordered]@{
        unknown_node_count = $unknownNodes.Count
        sample = @($unknownNodes | Select-Object -First 5 name, path, type)
    }
    if ($unknownNodes.Count -gt 0) {
        throw "Knowledge graph contains $($unknownNodes.Count) unknown-status node(s); fix front matter before closeout."
    }
}

$commitScript = Join-Path $root 'skills\codex-git-operations\scripts\Invoke-VerifiedPrivateCommit.ps1'
if ($Push) {
    if ($Apply) {
        $commitPlan = Convert-JsonOutput (& $commitScript -RepositoryRoot $root -Paths $selected -ChangeClass $ChangeClass -Message $Message -Apply) $commitScript
    } else {
        $commitPlan = Convert-JsonOutput (& $commitScript -RepositoryRoot $root -Paths $selected -ChangeClass $ChangeClass -Message $Message) $commitScript
    }
} else {
    if ($Apply) {
        $commitPlan = Convert-JsonOutput (& $commitScript -RepositoryRoot $root -Paths $selected -ChangeClass $ChangeClass -Message $Message -CommitOnly -Apply) $commitScript
    } else {
        $commitPlan = Convert-JsonOutput (& $commitScript -RepositoryRoot $root -Paths $selected -ChangeClass $ChangeClass -Message $Message -CommitOnly) $commitScript
    }
}
$result['verified_commit'] = $commitPlan
$commitEligible = $false
if ($null -ne $commitPlan.eligible) {
    $commitEligible = [bool]$commitPlan.eligible
} elseif ($commitPlan.decision -in @('eligible-for-private-commit', 'committed-locally-no-push', 'committed-and-pushed-private-origin')) {
    $commitEligible = $true
}
if (-not $Apply -and -not $commitEligible) {
    $result.result = 'needs-metadata-or-authorization'
    $result | ConvertTo-Json -Depth 8
    return
}
$result.result = if ($Apply) { 'closed-out' } else { 'ready' }
$result | ConvertTo-Json -Depth 8
