[CmdletBinding()]
param(
    [string]$ProjectRoot = (Get-Location).Path,
    [string]$Prompt,
    [string]$PromptFile,
    [string]$Template,
    [string[]]$Set = @(),
    [string]$Purpose = 'project visual',
    [string]$AspectRatio = 'unspecified',
    [string]$Destination = 'unspecified',
    [string]$ChatGPTUrl = 'https://chatgpt.com/',
    [switch]$OpenBrowser,
    [switch]$CopyPromptToClipboard,
    [switch]$InvokeCodexCli
)

$ErrorActionPreference = 'Stop'

function Get-SafeFileName([string]$Value) {
    $name = ($Value -replace '[^\p{L}\p{Nd}\._-]+', '-').Trim('-')
    if (-not $name) { return 'chatgpt-image-request' }
    if ($name.Length -gt 64) { return $name.Substring(0, 64).Trim('-') }
    return $name
}

function Get-TemplatePath([string]$TemplateName) {
    $templateRoot = Join-Path $PSScriptRoot '..\prompt-templates'
    $candidate = Join-Path $templateRoot "$TemplateName.md"
    if (Test-Path -LiteralPath $candidate) { return (Resolve-Path -LiteralPath $candidate).Path }
    throw "Template not found: $TemplateName"
}

function ConvertTo-VariableMap([string[]]$Assignments) {
    $map = @{}
    foreach ($assignment in $Assignments) {
        $parts = $assignment -split '=', 2
        if ($parts.Count -ne 2 -or -not $parts[0]) {
            throw "Template variables must use key=value syntax: $assignment"
        }
        $map[$parts[0]] = $parts[1]
    }
    return $map
}

function Expand-Template([string]$TemplateText, [hashtable]$Variables) {
    $expanded = $TemplateText
    foreach ($key in $Variables.Keys) {
        $pattern = '{{' + [regex]::Escape($key) + '}}'
        $value = [string]$Variables[$key]
        $expanded = [regex]::Replace($expanded, $pattern, { param($match) $value })
    }
    return $expanded
}

function Resolve-PromptText {
    if ($PromptFile) {
        if (-not (Test-Path -LiteralPath $PromptFile)) { throw "Prompt file not found: $PromptFile" }
        return Get-Content -Raw -LiteralPath $PromptFile -Encoding UTF8
    }
    if ($Template) {
        $templatePath = Get-TemplatePath $Template
        $templateText = Get-Content -Raw -LiteralPath $templatePath -Encoding UTF8
        return Expand-Template $templateText (ConvertTo-VariableMap $Set)
    }
    if ($Prompt) { return $Prompt }
    throw 'Provide one of -Prompt, -PromptFile, or -Template.'
}

function Invoke-CodexImageHandoff([string]$HandoffPath) {
    $command = Get-Command codex.exe -ErrorAction SilentlyContinue
    if (-not $command) { $command = Get-Command codex -ErrorAction SilentlyContinue }
    if (-not $command) { return 'codex-cli-not-found' }

    $handoff = Get-Content -Raw -LiteralPath $HandoffPath -Encoding UTF8
    try {
        & $command.Source exec --skip-git-repo-check --ask-for-approval never $handoff
        if ($LASTEXITCODE -eq 0) { return 'codex-cli-invoked' }
        return "codex-cli-exit-$LASTEXITCODE"
    }
    catch {
        return "codex-cli-error: $($_.Exception.Message)"
    }
}

$root = [IO.Path]::GetFullPath($ProjectRoot).TrimEnd('\')
$timestamp = [DateTime]::UtcNow.ToString('yyyyMMddTHHmmssZ')
$requestName = Get-SafeFileName $Purpose
$requestDir = Join-Path $root ".codex\images\chatgpt-plus\$timestamp-$requestName"
New-Item -ItemType Directory -Force -Path $requestDir | Out-Null

$resolvedPrompt = Resolve-PromptText
$promptPath = Join-Path $requestDir 'prompt.md'
$requestPath = Join-Path $requestDir 'request.json'
$handoffPath = Join-Path $requestDir 'codex-handoff.md'

$promptText = @"
# ChatGPT Plus Image Prompt

Purpose: $Purpose
Aspect ratio: $AspectRatio
Destination: $Destination
Template: $Template
Source prompt file: $PromptFile

## Prompt

$resolvedPrompt
"@
Set-Content -LiteralPath $promptPath -Value $promptText -Encoding UTF8

$handoffText = @"
# Codex Image Generation Handoff

Use the logged-in OpenAI/ChatGPT state available to this Codex environment. Read the prompt below, generate one raster image, and save the selected output to:

$Destination

Do not read, export, copy, or store browser cookies, access tokens, passwords, browser profile files, or ChatGPT conversation exports.

Prompt file:

$promptPath

## Prompt

$resolvedPrompt
"@
Set-Content -LiteralPath $handoffPath -Value $handoffText -Encoding UTF8

$codexCliStatus = 'not-requested'
if ($InvokeCodexCli) {
    $codexCliStatus = Invoke-CodexImageHandoff $handoffPath
}

[ordered]@{
    schema_version = 1
    provider = 'chatgpt-plus-visible-session'
    project_root = $root
    purpose = $Purpose
    aspect_ratio = $AspectRatio
    destination = $Destination
    template = $Template
    source_prompt_file = $PromptFile
    prompt_file = $promptPath
    handoff_file = $handoffPath
    credential_boundary = 'use existing visible ChatGPT browser login only; do not read or store cookies, tokens, passwords, or account files'
    codex_cli_status = $codexCliStatus
    created_at = [DateTime]::UtcNow.ToString('o')
    status = 'requested'
} | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $requestPath -Encoding UTF8

if ($CopyPromptToClipboard) {
    Set-Clipboard -Value $resolvedPrompt
}

if ($OpenBrowser) {
    Start-Process $ChatGPTUrl
}

[pscustomobject]@{
    request = $requestPath
    prompt = $promptPath
    handoff = $handoffPath
    opened_browser = [bool]$OpenBrowser
    copied_prompt = [bool]$CopyPromptToClipboard
    codex_cli_status = $codexCliStatus
}
