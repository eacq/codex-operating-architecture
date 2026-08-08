[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Tag,
    [string]$RepositoryRoot = (Get-Location).Path,
    [bool]$RemoteTagExists = $false,
    [bool]$ReleaseExists = $false,
    [switch]$Apply
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath $RepositoryRoot).Path
$tagRef = "refs/tags/$Tag"
& git check-ref-format $tagRef
if ($LASTEXITCODE -ne 0) { throw "Invalid release tag ref: $tagRef" }

$localTag = [string]@(& git -C $root rev-parse -q --verify $tagRef 2>$null)[0]
$localTag = $localTag.Trim()
if (-not $localTag) {
    [pscustomobject]@{ tag = $Tag; result = 'no-local-tag-collision' } | ConvertTo-Json
    return
}
if ($RemoteTagExists -or $ReleaseExists) {
    throw "Release tag already has published evidence and cannot be reconciled locally: $Tag"
}

$tagTarget = (& git -C $root rev-parse "$tagRef^{}" 2>$null).Trim()
if (-not $tagTarget) { throw "Cannot resolve local release tag target: $Tag" }
& git -C $root merge-base --is-ancestor $tagTarget HEAD 2>$null
$ancestorExit = $LASTEXITCODE
if ($ancestorExit -eq 0) {
    throw "Release tag already exists on the current history: $Tag"
}
if ($ancestorExit -ne 1) {
    throw "Cannot determine whether local release tag belongs to the current history: $Tag"
}

$shortObject = (& git -C $root rev-parse --short=12 $tagRef).Trim()
$archiveRef = "refs/tags/codex-archive/$Tag-$shortObject"
$existingArchive = [string]@(& git -C $root rev-parse -q --verify $archiveRef 2>$null)[0]
$existingArchive = $existingArchive.Trim()
if ($existingArchive -and $existingArchive -ne $localTag) {
    throw "Local release-tag archive collision: $archiveRef"
}

if ($Apply) {
    if (-not $existingArchive) {
        & git -C $root update-ref $archiveRef $localTag ('0' * 40)
        if ($LASTEXITCODE -ne 0) { throw "Failed to archive stale local release tag: $Tag" }
    }
    & git -C $root update-ref -d $tagRef $localTag
    if ($LASTEXITCODE -ne 0) { throw "Failed to clear stale local release tag: $Tag" }
}

[pscustomobject]@{
    tag = $Tag
    tag_target = $tagTarget
    archive_ref = $archiveRef
    applied = [bool]$Apply
    result = if ($Apply) { 'detached-local-tag-archived' } else { 'detached-local-tag-archive-ready' }
} | ConvertTo-Json
