[CmdletBinding()]
param(
    [string]$RepositoryRoot = (Get-Location).Path,
    [string]$CandidateRef = 'HEAD',
    [string]$PublicRemote = 'public',
    [string]$PrivateRemote = 'origin'
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath $RepositoryRoot).Path
function Get-RepoName([string]$Remote) {
    $url = (& git -C $root remote get-url $Remote 2>$null).Trim()
    if (-not $url) { throw "Required remote '$Remote' is unavailable." }
    $match = [regex]::Match($url, 'github\.com[:/](?<name>[^/]+/[^/.]+)')
    if (-not $match.Success) { throw "Remote '$Remote' is not a supported GitHub remote." }
    return $match.Groups['name'].Value
}

$publicRepo = Get-RepoName $PublicRemote
$privateRepo = Get-RepoName $PrivateRemote
if ($publicRepo -eq $privateRepo) { throw 'Public and private remotes must be different repositories.' }
if (-not (Get-Command gh -ErrorAction SilentlyContinue)) { throw 'GitHub CLI is required for public-release safety verification.' }
$githubCommand = Join-Path $root 'skills\codex-git-operations\scripts\Invoke-GitHubNetworkCommand.ps1'
if ((& $githubCommand -RepositoryRoot $root -Tool gh repo view $publicRepo --json isPrivate --jq .isPrivate).Trim() -ne 'false') { throw 'The public remote is not confirmed public.' }
if ((& $githubCommand -RepositoryRoot $root -Tool gh repo view $privateRepo --json isPrivate --jq .isPrivate).Trim() -ne 'true') { throw 'The private remote is not confirmed private.' }

$paths = @(& git -C $root ls-tree -r --name-only $CandidateRef)
$forbiddenPath = '(^|/)(\.codex|\.runtime|\.history-cache|\.sandbox-secrets|private-skill-config)(/|$)|(^|/)(\.env($|\.)|auth\.json$|.*\.dpapi$)'
if (@($paths | Where-Object { $_ -match $forbiddenPath }).Count -gt 0) { throw 'Public release snapshot contains a forbidden private-state path.' }

$patterns = @(
    'ghp_[A-Za-z0-9]{20,}', 'github_pat_[A-Za-z0-9_]{20,}', '\bsk-[A-Za-z0-9_-]{20,}',
    'Bearer[[:space:]]+[A-Za-z0-9._-]{12,}', 'https?://[^/[:space:]]+@',
    '[A-Za-z]:\\Users\\'
)
$patterns += [regex]::Escape($privateRepo)
foreach ($pattern in $patterns) {
    & git -C $root grep -I -q -E $pattern $CandidateRef -- 2>$null
    if ($LASTEXITCODE -eq 0) { throw 'Public release snapshot matched a private-connection or secret-content rule.' }
    if ($LASTEXITCODE -gt 1) { throw 'Public release content scan failed.' }
}
[pscustomobject]@{ candidate = $CandidateRef; public_repository = $publicRepo; private_repository_checked = $true; result = 'public-release-safety-passed' } | ConvertTo-Json
