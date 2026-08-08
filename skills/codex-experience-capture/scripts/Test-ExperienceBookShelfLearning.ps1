param(
    [string]$RepositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
)

$ErrorActionPreference = 'Stop'
# Information unit: Agent Skill Evolution Optimization.
$root = (Resolve-Path -LiteralPath $RepositoryRoot).Path
$script = Join-Path $root 'skills/codex-experience-capture/scripts/Invoke-ExperienceBookShelfLearning.ps1'
if (-not (Test-Path -LiteralPath $script -PathType Leaf)) {
    throw "Missing book shelf learning script: $script"
}

$fixtureRoot = Join-Path $root '.runtime\test\book-shelf-learning'
if (Test-Path -LiteralPath $fixtureRoot -PathType Container) {
    $resolvedFixture = [IO.Path]::GetFullPath($fixtureRoot)
    $allowedPrefix = [IO.Path]::GetFullPath((Join-Path $root '.runtime\test')).TrimEnd('\') + '\'
    if (-not $resolvedFixture.StartsWith($allowedPrefix, [StringComparison]::OrdinalIgnoreCase)) {
        throw "Refusing to clean unsafe fixture path: $fixtureRoot"
    }
    Remove-Item -LiteralPath $fixtureRoot -Recurse -Force
}
New-Item -ItemType Directory -Path $fixtureRoot -Force | Out-Null
$fixture = Join-Path $fixtureRoot 'Model Thinker fixture.txt'
Set-Content -LiteralPath $fixture -Encoding UTF8 -Value '模型 思考 决策 复杂 系统 反馈 结构 原理 证据 风险 模型 思考 决策'
$out = Join-Path $fixtureRoot 'result.json'
$result = & $script -RepositoryRoot $root -BookRoot $fixtureRoot -OutputPath $out | ConvertFrom-Json
if ($result.model -ne 'experience-book-shelf-learning') { throw 'Book shelf learning model header is invalid.' }
if ($result.books_total -ne 1 -or $result.parsed_books -ne 1 -or $result.readable_chars -le 0) { throw 'Book shelf learning fixture was not parsed.' }
if ('multi-model-triangulation' -notin @($result.cross_book_agent_lenses)) { throw 'Expected model-thinking lens is missing.' }
if (-not (Test-Path -LiteralPath $out -PathType Leaf)) { throw 'Book shelf learning output was not written.' }

[pscustomobject]@{
    status = 'passed'
    model = 'experience-book-shelf-learning'
    script = 'skills/codex-experience-capture/scripts/Invoke-ExperienceBookShelfLearning.ps1'
    fixture_books = $result.books_total
    lenses = @($result.cross_book_agent_lenses).Count
} | ConvertTo-Json -Depth 4
