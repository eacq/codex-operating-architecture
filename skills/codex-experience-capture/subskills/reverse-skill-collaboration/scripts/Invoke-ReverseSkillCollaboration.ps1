#Requires -Version 5.1
[CmdletBinding()]
param(
    [ValidateSet('Route','ToolchainPlan','EvolutionPlan')]
    [string] $Mode = 'Route',
    [Parameter(Mandatory = $true)]
    [string] $Task,
    [string[]] $Capabilities = @(),
    [string[]] $Evidence = @(),
    [string] $Outcome = '',
    [string] $Failure = '',
    [string] $OutputPath = '',
    [switch] $Apply,
    [switch] $ExplicitUserAuthorization
)
$ErrorActionPreference = 'Stop'

$scriptRoot = Split-Path -Parent $PSScriptRoot
$skillRoot = Split-Path -Parent $scriptRoot
$repoRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $skillRoot))
$manifestPath = Join-Path $repoRoot 'config\reverse-skill-integration.json'
$manifest = Get-Content -LiteralPath $manifestPath -Raw -Encoding UTF8 | ConvertFrom-Json
$sourceRoot = Join-Path $repoRoot $manifest.upstream.local_release
$bootstrapManifestPath = Join-Path $sourceRoot 'skills\scripts\bootstrap-manifest.json'
$bootstrap = if (Test-Path -LiteralPath $bootstrapManifestPath) {
    Get-Content -LiteralPath $bootstrapManifestPath -Raw -Encoding UTF8 | ConvertFrom-Json
} else { [pscustomobject]@{ capabilities = @() } }

function Find-Owner([string] $text) {
    $t = $text.ToLowerInvariant()
    if ($t -match '\u7ECF\u9A8C|\u590D\u76D8|\u5B66\u4E60|\u6C89\u6DC0|\u7ECF\u9A8C\u5E93|evidence|finding|path|\u4EA4\u63A5|\u56DE\u653E|evolution') { return 'codex-experience-capture' }
    if ($t -match '\u67B6\u6784|\u7ED3\u6784|skill.*(\u5408\u5E76|\u62C6\u5206|\u4F18\u5316)|agent.*(\u7ED3\u6784|\u62D3\u6251)|\u5168\u5C40\u80FD\u529B') { return 'codex-architecture-iteration' }
    if ($t -match '\u5B89\u88C5|\u4F9D\u8D56|\u5DE5\u5177\u94FE|bootstrap|mcp|cli|\u8FD0\u884C\u65F6|\u8F6F\u4EF6') { return 'codex-tool-installation' }
    if ($t -match '\u9700\u6C42|\u5DE5\u4F5C\u6D41|\u534F\u4F5C\u6D41\u7A0B|workflow|\u8BA1\u5212|\u65B9\u6848') { return 'codex-workflow-design' }
    if ($t -match '\u8D44\u6599|\u68C0\u7D22|\u7814\u7A76|\u6765\u6E90|\u6587\u732E|\u8C03\u67E5|\u7F51\u9875') { return 'codex-information-gathering' }
    if ($t -match '\u9519\u8BEF|\u5931\u8D25|\u5F02\u5E38|\u4E0D\u5DE5\u4F5C|\u56DE\u5F52|timeout|tls|connection') { return 'codex-error-feedback' }
    if ($t -match 'word|docx|\u8BBA\u6587|\u6392\u7248|\u683C\u5F0F') { return 'codex-exact-word-layout' }
    if ($t -match 'ppt|\u5E7B\u706F\u7247|\u6F14\u793A\u6587\u7A3F|diagram|\u67B6\u6784\u56FE|\u56FE\u7247|figure') { return 'codex-office-cli' }
    return 'codex-task-execution'
}

function Find-Stage([string] $text) {
    $t = $text.ToLowerInvariant()
    if ($t -match '\u9A8C\u8BC1|\u6D4B\u8BD5|review|\u5BA1\u67E5|\u6838\u9A8C|\u9A8C\u6536') { return 'verify' }
    if ($t -match '\u590D\u76D8|\u603B\u7ED3|\u5B66\u4E60|\u6C89\u6DC0|\u8FDB\u5316|experience|evolution') { return 'capture-and-evolve' }
    if ($t -match '\u89C4\u5212|\u8BBE\u8BA1|\u62C6\u89E3|\u65B9\u6848|plan') { return 'plan' }
    return 'inspect-route-execute'
}

function Get-Capability([string] $name) {
    $item = @($bootstrap.capabilities) | Where-Object { $_.name -eq $name } | Select-Object -First 1
    $commandName = if ($item.verifyCommand) { [string]$item.verifyCommand } else { $name }
    $cmd = Get-Command $commandName -ErrorAction SilentlyContinue | Select-Object -First 1
    [ordered]@{
        name = $name
        present = ($null -ne $cmd)
        verify_command = $commandName
        bootstrap_kind = if ($item.bootstrapKind) { $item.bootstrapKind } else { 'unknown' }
        source_defined = ($null -ne $item)
        can_auto_install_upstream = if ($null -ne $item.canAutoInstall) { [bool]$item.canAutoInstall } else { $false }
        install_owner = 'codex-tool-installation'
        install_authorization = 'explicit-user-or-owner-gate-required'
        apply_requested = [bool]$Apply
        apply_allowed = ([bool]$Apply -and [bool]$ExplicitUserAuthorization)
    }
}

$owner = Find-Owner $Task
$stage = Find-Stage $Task
$result = [ordered]@{
    schema_version = 1
    adapter = 'reverse-skill-collaboration'
    mode = $Mode
    task = $Task
    owner = $owner
    stage = $stage
    source_commit = $manifest.upstream.commit
    execution = 'route-and-plan-only'
    authority = 'canonical owner gates remain authoritative'
}

switch ($Mode) {
    'Route' {
        $result.route = [ordered]@{
            primary_owner = $owner
            supporting_owners = @('codex-self-evolution','codex-experience-capture')
            next = @('load project authority','retrieve relevant experience','create bounded work items','execute through owner','verify','capture candidate and decide promotion')
            upstream_reference_only = $true
        }
    }
    'ToolchainPlan' {
        if ($Capabilities.Count -eq 0) { throw 'ToolchainPlan requires -Capabilities.' }
        $result.toolchain = @($Capabilities | ForEach-Object { Get-Capability $_ })
        $result.next = if ($Apply -and $ExplicitUserAuthorization) {
            'handoff each missing capability to codex-tool-installation, then verify location/import/help and rollback'
        } else {
            'inspect readiness only; if a missing capability is material, request explicit authorization before owner-gated installation'
        }
    }
    'EvolutionPlan' {
        $result.evolution = [ordered]@{
            trigger = if ($Failure) { 'failure' } elseif ($Outcome) { 'completed-or-partial-outcome' } else { 'insufficient-outcome' }
            evidence = @($Evidence)
            outcome = $Outcome
            failure = $Failure
            candidate_status = if ($Evidence.Count -gt 0 -and ($Outcome -or $Failure)) { 'candidate-awaiting-verification' } else { 'do-not-promote' }
            owner = 'codex-experience-capture'
            linked_owner = 'codex-knowledge-system'
            structural_change_owner = 'codex-architecture-iteration'
            required_checks = @('redact secrets and private detail','deduplicate','verify positive and negative trigger behavior','verify cross-context transfer','preserve rollback and invalidation')
            next = @('write bounded workflow-learning or experience candidate','route owner review','promote only after evidence gate')
        }
    }
}

$json = $result | ConvertTo-Json -Depth 10
if ($OutputPath) {
    $parent = Split-Path -Parent $OutputPath
    New-Item -ItemType Directory -Force -Path $parent | Out-Null
    [IO.File]::WriteAllText((Resolve-Path -LiteralPath $parent).Path + '\' + (Split-Path -Leaf $OutputPath), $json, (New-Object Text.UTF8Encoding($false)))
}
Write-Output $json
