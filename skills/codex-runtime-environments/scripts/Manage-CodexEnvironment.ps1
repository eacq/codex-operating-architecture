[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [ValidateSet('status', 'init-base', 'init-project', 'profiles', 'add-profile', 'scaffold-file-tools', 'set-secret', 'test-secret', 'add', 'record-use', 'recommend')]
    [string]$Action = 'status',
    [string]$ProjectRoot = (Get-Location).Path,
    [string]$Package,
    [string]$Profile,
    [string]$SecretName,
    [string]$Requirement,
    [string]$Purpose = 'project dependency',
    [ValidateSet('success', 'failed', 'unverified')]
    [string]$Outcome = 'unverified',
    [string]$Verification = '',
    [switch]$Apply
)

$ErrorActionPreference = 'Stop'
$canonicalRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..\..\..')).Path
$catalogRoot = Join-Path $canonicalRoot 'runtime-environments'
$basePrefix = Join-Path $canonicalRoot '.runtime\envs\codex-foundation'
$ledgerPath = Join-Path $catalogRoot 'usage-ledger.json'
$profilesPath = Join-Path $catalogRoot 'tool-profiles.json'
$profilePath = if ($env:CODEX_PORTABLE_SKILL_PROFILE) { $env:CODEX_PORTABLE_SKILL_PROFILE } else { Join-Path $HOME '.codex\private-skill-config\portable-skill.json' }
$profile = $null
if (Test-Path -LiteralPath $profilePath) {
    $profile = Get-Content -LiteralPath $profilePath -Raw -Encoding UTF8 | ConvertFrom-Json
}
$softwareInstallRoot = if ($env:SOFTWARE_INSTALL_ROOT) { $env:SOFTWARE_INSTALL_ROOT } elseif ($profile -and $profile.software -and $profile.software.install_root) { $profile.software.install_root } else { '' }
$conda = if ($env:CONDA_EXE) { $env:CONDA_EXE } elseif ($softwareInstallRoot) { Join-Path $softwareInstallRoot 'miniconda\Scripts\conda.exe' } else { 'conda' }

function Assert-Conda {
    if (-not (Test-Path -LiteralPath $conda)) { throw "Miniconda not found at $conda. Route installation through codex-tool-installation." }
}

function Get-RuntimePaths([string]$Root) {
    $resolved = [IO.Path]::GetFullPath($Root).TrimEnd('\')
    $runtime = Join-Path $resolved '.codex\runtime'
    return [pscustomobject]@{
        Root = $resolved
        Runtime = $runtime
        Prefix = Join-Path $runtime 'env'
        Manifest = Join-Path $runtime 'environment.json'
        Requirements = Join-Path $runtime 'requirements.in'
        Lock = Join-Path $runtime 'requirements.lock.txt'
    }
}

function Write-JsonFile($Value, [string]$Path) {
    $Value | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $Path -Encoding UTF8
}

function Get-ToolProfiles {
    if (-not (Test-Path -LiteralPath $profilesPath)) { throw "Tool profile catalog is missing: $profilesPath" }
    return Get-Content -LiteralPath $profilesPath -Raw -Encoding UTF8 | ConvertFrom-Json
}

function Get-ToolProfile([string]$Name) {
    if (-not $Name) { throw '-Profile is required.' }
    $catalog = Get-ToolProfiles
    $match = @($catalog.profiles | Where-Object name -eq $Name)
    if ($match.Count -ne 1) { throw "Unknown tool profile: $Name" }
    return $match[0]
}

function Add-RequirementLine([string]$Path, [string]$Requested) {
    $existing = if (Test-Path -LiteralPath $Path) { @(Get-Content -LiteralPath $Path) } else { @('# Project-only direct dependencies') }
    if ($existing -notcontains $Requested) { @($existing) + $Requested | Set-Content -LiteralPath $Path -Encoding UTF8 }
}

function Initialize-Ledger {
    New-Item -ItemType Directory -Force -Path $catalogRoot | Out-Null
    if (-not (Test-Path -LiteralPath $ledgerPath)) {
        Write-JsonFile ([ordered]@{ schema_version = 1; promotion_policy = @{ minimum_successes = 3; minimum_projects = 2 }; events = @() }) $ledgerPath
    }
}

function Initialize-Project([string]$Root) {
    Assert-Conda
    $p = Get-RuntimePaths $Root
    New-Item -ItemType Directory -Force -Path $p.Runtime | Out-Null
    if (-not (Test-Path -LiteralPath $p.Prefix)) {
        if (-not (Test-Path -LiteralPath (Join-Path $basePrefix 'python.exe'))) { throw 'Initialize the canonical base environment first.' }
        & $conda create --yes --prefix $p.Prefix --clone $basePrefix
        if ($LASTEXITCODE -ne 0) { throw 'Project environment creation failed.' }
    }
    if (-not (Test-Path -LiteralPath $p.Requirements)) { Set-Content -LiteralPath $p.Requirements -Value '# Project-only direct dependencies' -Encoding UTF8 }
    $python = Join-Path $p.Prefix 'python.exe'
    & $python -m pip freeze | Set-Content -LiteralPath $p.Lock -Encoding UTF8
    Write-JsonFile ([ordered]@{ schema_version = 1; backend = 'conda-prefix'; python = '3.12'; prefix = '.codex/runtime/env'; requirements = '.codex/runtime/requirements.in'; lock = '.codex/runtime/requirements.lock.txt'; updated_at = [DateTime]::UtcNow.ToString('o') }) $p.Manifest
    $ps = "`$python = Join-Path `$PSScriptRoot 'env\python.exe'`nif (-not (Test-Path -LiteralPath `$python)) { throw 'Run runtime environment initialization first.' }`n& `$python @args`nexit `$LASTEXITCODE`n"
    Set-Content -LiteralPath (Join-Path $p.Runtime 'python.ps1') -Value $ps -Encoding UTF8
    $cmd = "@echo off`r`nset `"PYTHON=%~dp0env\python.exe`"`r`nif not exist `"%PYTHON%`" (echo Run runtime environment initialization first. 1>&2 & exit /b 1)`r`n`"%PYTHON%`" %*`r`n"
    Set-Content -LiteralPath (Join-Path $p.Runtime 'python.cmd') -Value $cmd -Encoding ASCII
    Write-Host "Project environment ready: $($p.Prefix)"
}

function Write-FileToolTemplate([string]$Path) {
    $content = @'
#!/usr/bin/env python
"""Project-local file processing helper generated by codex-runtime-environments.

Dependencies are intentionally imported only by the command that needs them.
Run `file_ops.py probe` before using a project file workflow.
"""
from __future__ import annotations

import argparse
import json
from pathlib import Path


def write_text(path: str, text: str) -> None:
    Path(path).parent.mkdir(parents=True, exist_ok=True)
    Path(path).write_text(text, encoding="utf-8")


def probe(_: argparse.Namespace) -> int:
    modules = {
        "docx": "python-docx",
        "pptx": "python-pptx",
        "pypdf": "pypdf",
        "PIL": "Pillow",
        "fitz": "PyMuPDF",
        "markitdown": "markitdown",
        "docling": "docling",
    }
    result = {}
    for module_name, package_name in modules.items():
        try:
            __import__(module_name)
            result[package_name] = "available"
        except Exception as exc:
            result[package_name] = f"missing: {exc.__class__.__name__}"
    print(json.dumps(result, ensure_ascii=False, indent=2))
    return 0


def docx_text(args: argparse.Namespace) -> int:
    from docx import Document

    document = Document(args.input)
    parts = [paragraph.text for paragraph in document.paragraphs]
    write_text(args.output, "\n".join(parts))
    return 0


def pptx_text(args: argparse.Namespace) -> int:
    from pptx import Presentation

    presentation = Presentation(args.input)
    lines = []
    for index, slide in enumerate(presentation.slides, start=1):
        lines.append(f"# Slide {index}")
        for shape in slide.shapes:
            if hasattr(shape, "text") and shape.text:
                lines.append(shape.text)
    write_text(args.output, "\n".join(lines))
    return 0


def pdf_text(args: argparse.Namespace) -> int:
    from pypdf import PdfReader

    reader = PdfReader(args.input)
    lines = []
    for index, page in enumerate(reader.pages, start=1):
        lines.append(f"# Page {index}")
        lines.append(page.extract_text() or "")
    write_text(args.output, "\n".join(lines))
    return 0


def image_info(args: argparse.Namespace) -> int:
    from PIL import Image

    with Image.open(args.input) as image:
        data = {
            "path": str(Path(args.input).resolve()),
            "format": image.format,
            "mode": image.mode,
            "width": image.width,
            "height": image.height,
        }
    write_text(args.output, json.dumps(data, ensure_ascii=False, indent=2))
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description="Project file processing helper")
    sub = parser.add_subparsers(dest="command", required=True)
    sub.add_parser("probe").set_defaults(func=probe)

    for name, handler in [
        ("docx-text", docx_text),
        ("pptx-text", pptx_text),
        ("pdf-text", pdf_text),
        ("image-info", image_info),
    ]:
        command = sub.add_parser(name)
        command.add_argument("input")
        command.add_argument("output")
        command.set_defaults(func=handler)

    args = parser.parse_args()
    return args.func(args)


if __name__ == "__main__":
    raise SystemExit(main())
'@
    Set-Content -LiteralPath $Path -Value $content -Encoding UTF8
}

function Write-SecretScripts([pscustomobject]$Paths) {
    $secretsDir = Join-Path $Paths.Runtime 'secrets'
    New-Item -ItemType Directory -Force -Path $secretsDir | Out-Null
    $setSecret = @'
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^[A-Za-z][A-Za-z0-9_.-]{0,80}$')]
    [string]$Name,
    [string]$Scope = 'project'
)

$ErrorActionPreference = 'Stop'
$secretsDir = Join-Path $PSScriptRoot 'secrets'
New-Item -ItemType Directory -Force -Path $secretsDir | Out-Null
$secret = Read-Host "Enter secret value for $Name" -AsSecureString
$cipherPath = Join-Path $secretsDir "$Name.dpapi"
$metaPath = Join-Path $secretsDir "$Name.json"
$secret | ConvertFrom-SecureString | Set-Content -LiteralPath $cipherPath -Encoding ASCII
[ordered]@{
    schema_version = 1
    name = $Name
    scope = $Scope
    storage = 'Windows DPAPI via ConvertFrom-SecureString'
    cipher_file = ".codex/runtime/secrets/$Name.dpapi"
    updated_at = [DateTime]::UtcNow.ToString('o')
} | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $metaPath -Encoding UTF8
Write-Host "Stored encrypted secret metadata for $Name"
'@
    $testSecret = @'
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^[A-Za-z][A-Za-z0-9_.-]{0,80}$')]
    [string]$Name
)

$ErrorActionPreference = 'Stop'
$cipherPath = Join-Path (Join-Path $PSScriptRoot 'secrets') "$Name.dpapi"
if (-not (Test-Path -LiteralPath $cipherPath)) { throw "Secret is missing: $Name" }
$secure = Get-Content -LiteralPath $cipherPath -Raw -Encoding ASCII | ConvertTo-SecureString
if (-not $secure) { throw "Secret cannot be read: $Name" }
Write-Host "Secret is present and decryptable for the current Windows user: $Name"
'@
    Set-Content -LiteralPath (Join-Path $Paths.Runtime 'Set-CodexRuntimeSecret.ps1') -Value $setSecret -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $Paths.Runtime 'Test-CodexRuntimeSecret.ps1') -Value $testSecret -Encoding UTF8
}

function Scaffold-FileTools([string]$Root) {
    $p = Get-RuntimePaths $Root
    New-Item -ItemType Directory -Force -Path $p.Runtime | Out-Null
    $tools = Join-Path $p.Runtime 'tools'
    New-Item -ItemType Directory -Force -Path $tools | Out-Null
    Write-FileToolTemplate (Join-Path $tools 'file_ops.py')
    Write-SecretScripts $p
    $ps = "`$python = Join-Path `$PSScriptRoot 'env\python.exe'`nif (-not (Test-Path -LiteralPath `$python)) { throw 'Run runtime environment initialization first.' }`n& `$python (Join-Path `$PSScriptRoot 'tools\file_ops.py') @args`nexit `$LASTEXITCODE`n"
    Set-Content -LiteralPath (Join-Path $p.Runtime 'file-tools.ps1') -Value $ps -Encoding UTF8
    $cmd = "@echo off`r`nset `"PYTHON=%~dp0env\python.exe`"`r`nif not exist `"%PYTHON%`" (echo Run runtime environment initialization first. 1>&2 & exit /b 1)`r`n`"%PYTHON%`" `"%~dp0tools\file_ops.py`" %*`r`n"
    Set-Content -LiteralPath (Join-Path $p.Runtime 'file-tools.cmd') -Value $cmd -Encoding ASCII
    Write-Host "File tools scaffolded: $tools"
}

function Record-Event([string]$Root, [string]$Name, [string]$Requested, [string]$Why, [string]$Result, [string]$Check) {
    Initialize-Ledger
    $ledger = Get-Content -LiteralPath $ledgerPath -Raw -Encoding UTF8 | ConvertFrom-Json
    $events = @($ledger.events)
    $events += [pscustomobject]@{ package = $Name.ToLowerInvariant(); project_root = [IO.Path]::GetFullPath($Root).TrimEnd('\'); requirement = $Requested; purpose = $Why; outcome = $Result; verification = $Check; recorded_at = [DateTime]::UtcNow.ToString('o') }
    $ledger.events = $events
    Write-JsonFile $ledger $ledgerPath
}

switch ($Action) {
    'status' {
        $p = Get-RuntimePaths $ProjectRoot
        [pscustomobject]@{ project_root = $p.Root; base_ready = Test-Path (Join-Path $basePrefix 'python.exe'); project_ready = Test-Path (Join-Path $p.Prefix 'python.exe'); manifest = Test-Path $p.Manifest; conda = Test-Path $conda }
    }
    'init-base' {
        Assert-Conda
        if (-not (Test-Path -LiteralPath $basePrefix)) {
            & $conda env create --prefix $basePrefix --file (Join-Path $catalogRoot 'base\environment.yml')
            if ($LASTEXITCODE -ne 0) { throw 'Base environment creation failed.' }
        }
        & (Join-Path $basePrefix 'python.exe') --version
    }
    'init-project' { Initialize-Project $ProjectRoot }
    'profiles' {
        $catalog = Get-ToolProfiles
        $catalog.profiles | ForEach-Object {
            [pscustomobject]@{
                name = $_.name
                purpose = $_.purpose
                packages = (@($_.packages | ForEach-Object package) -join ', ')
            }
        }
    }
    'add-profile' {
        $profileObject = Get-ToolProfile $Profile
        $p = Get-RuntimePaths $ProjectRoot
        New-Item -ItemType Directory -Force -Path $p.Runtime | Out-Null
        foreach ($item in @($profileObject.packages)) {
            Add-RequirementLine $p.Requirements $item.requirement
            Record-Event $p.Root $item.package $item.requirement "profile:$($profileObject.name); $($item.capability)" 'unverified' 'profile recorded'
        }
        if ($Apply) {
            if (-not (Test-Path (Join-Path $p.Prefix 'python.exe'))) { Initialize-Project $ProjectRoot }
            foreach ($item in @($profileObject.packages)) {
                & (Join-Path $p.Prefix 'python.exe') -m pip install $item.requirement
                if ($LASTEXITCODE -ne 0) {
                    Record-Event $p.Root $item.package $item.requirement "profile:$($profileObject.name); $($item.capability)" 'failed' 'pip install'
                    throw "Dependency installation failed for profile package: $($item.package)"
                }
                Record-Event $p.Root $item.package $item.requirement "profile:$($profileObject.name); $($item.capability)" 'success' 'pip install'
            }
            & (Join-Path $p.Prefix 'python.exe') -m pip freeze | Set-Content -LiteralPath $p.Lock -Encoding UTF8
        }
    }
    'scaffold-file-tools' { Scaffold-FileTools $ProjectRoot }
    'set-secret' {
        if (-not $SecretName) { throw '-SecretName is required.' }
        $p = Get-RuntimePaths $ProjectRoot
        New-Item -ItemType Directory -Force -Path $p.Runtime | Out-Null
        Write-SecretScripts $p
        & (Join-Path $p.Runtime 'Set-CodexRuntimeSecret.ps1') -Name $SecretName
        if ($LASTEXITCODE -ne 0) { throw 'Secret input failed.' }
    }
    'test-secret' {
        if (-not $SecretName) { throw '-SecretName is required.' }
        $p = Get-RuntimePaths $ProjectRoot
        & (Join-Path $p.Runtime 'Test-CodexRuntimeSecret.ps1') -Name $SecretName
        if ($LASTEXITCODE -ne 0) { throw 'Secret verification failed.' }
    }
    'add' {
        if (-not $Package) { throw '-Package is required.' }
        $p = Get-RuntimePaths $ProjectRoot
        New-Item -ItemType Directory -Force -Path $p.Runtime | Out-Null
        $requested = if ($Requirement) { $Requirement } else { $Package }
        Add-RequirementLine $p.Requirements $requested
        if ($Apply) {
            if (-not (Test-Path (Join-Path $p.Prefix 'python.exe'))) { Initialize-Project $ProjectRoot }
            & (Join-Path $p.Prefix 'python.exe') -m pip install $requested
            if ($LASTEXITCODE -ne 0) { Record-Event $p.Root $Package $requested $Purpose 'failed' 'pip install'; throw 'Dependency installation failed.' }
            & (Join-Path $p.Prefix 'python.exe') -m pip freeze | Set-Content -LiteralPath $p.Lock -Encoding UTF8
        }
        Record-Event $p.Root $Package $requested $Purpose $(if ($Apply) { 'success' } else { 'unverified' }) $Verification
    }
    'record-use' {
        if (-not $Package) { throw '-Package is required.' }
        Record-Event $ProjectRoot $Package $(if ($Requirement) { $Requirement } else { $Package }) $Purpose $Outcome $Verification
    }
    'recommend' {
        Initialize-Ledger
        $ledger = Get-Content -LiteralPath $ledgerPath -Raw -Encoding UTF8 | ConvertFrom-Json
        @($ledger.events) | Where-Object outcome -eq 'success' | Group-Object package | ForEach-Object {
            $projects = @($_.Group.project_root | Sort-Object -Unique)
            [pscustomobject]@{ package = $_.Name; successes = $_.Count; projects = $projects.Count; candidate = ($_.Count -ge 3 -and $projects.Count -ge 2) }
        } | Sort-Object candidate, successes -Descending
    }
}
