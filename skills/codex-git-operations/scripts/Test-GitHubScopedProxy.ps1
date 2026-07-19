[CmdletBinding()]
param(
    [string]$RepositoryRoot = (Get-Location).Path
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath $RepositoryRoot).Path
$helperPath = Join-Path $root 'skills\codex-git-operations\scripts\Invoke-GitHubNetworkCommand.ps1'
$helper = Get-Content -LiteralPath $helperPath -Raw -Encoding UTF8

foreach ($required in @(
    'C:\Users\Public\Desktop\YouTu.lnk',
    '127.0.0.1:7892',
    'HTTP_PROXY',
    'HTTPS_PROXY',
    'NO_PROXY',
    'Start-Process',
    'WindowStyle'
)) {
    if ($helper -notmatch [regex]::Escape($required)) {
        throw "Scoped proxy helper is missing required behavior: $required"
    }
}

foreach ($forbidden in @(
    'netsh winhttp set proxy',
    'git config --global http.proxy',
    'shared_preferences.json',
    'config.yaml'
)) {
    if ($helper -match [regex]::Escape($forbidden)) {
        throw "Scoped proxy helper must not mutate global or YouTu application configuration: $forbidden"
    }
}

$scriptPaths = @(
    'skills/codex-git-operations/scripts/Invoke-VerifiedPrivateCommit.ps1',
    'skills/codex-git-operations/scripts/Invoke-ExperienceRelease.ps1',
    'skills/codex-git-operations/scripts/Get-ExperienceVersion.ps1',
    'scripts/Test-PublicReleaseSafety.ps1',
    'skills/codex-git-operations/scripts/Test-CodexScopedProxyIsolation.ps1'
)
foreach ($relative in $scriptPaths) {
    $content = Get-Content -LiteralPath (Join-Path $root $relative) -Raw -Encoding UTF8
    if ($content -notmatch 'Invoke-GitHubNetworkCommand\.ps1') {
        throw "GitHub-facing script does not route through scoped proxy helper: $relative"
    }
}

foreach ($relative in @(
    'skills/codex-git-operations/scripts/Invoke-CodexGitWorkflow.ps1',
    'skills/codex-git-operations/scripts/Invoke-ExperienceRelease.ps1',
    'skills/codex-git-operations/scripts/Invoke-VerifiedPrivateCommit.ps1'
)) {
    $content = Get-Content -LiteralPath (Join-Path $root $relative) -Raw -Encoding UTF8
    if ($content -notmatch '\[switch\]\$ForceProxy' -or $content -notmatch '-ForceProxy:\$ForceProxy') {
        throw "GitHub controller does not propagate the explicit scoped-proxy retry switch: $relative"
    }
}

[pscustomobject]@{
    helper = $helperPath
    proxy_endpoint = 'http://127.0.0.1:7892'
    result = 'github-scoped-proxy-check-passed'
} | ConvertTo-Json
