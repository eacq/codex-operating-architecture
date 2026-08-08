[CmdletBinding()]
param(
    [string]$RepositoryRoot = 'F:\codex'
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath $RepositoryRoot).Path
$classifier = Join-Path $root 'agent\40-runtime\Get-AgentTransportRecoverySignal.ps1'
$controller = Join-Path $root 'agent\40-runtime\Invoke-GlobalExperienceAgent.ps1'
$utf8NoBom = [Text.UTF8Encoding]::new($false)

function Invoke-Classifier([string]$Text, [string]$Component, [switch]$BeforeCompletion) {
    $raw = & $classifier -RepositoryRoot $root -ErrorText $Text -Component $Component -BeforeCompletion:$BeforeCompletion.IsPresent
    return $raw | ConvertFrom-Json
}

$fatal = Invoke-Classifier -Text 'stream disconnected before completion: error sending request for url (https://chatgpt.com/backend-api/codex/responses)' -Component 'codex' -BeforeCompletion
if (-not $fatal.restart_required -or $fatal.classification -ne 'transport-disconnect' -or $fatal.exit_type -ne 'restart-required') {
    throw 'Fatal transport classifier did not return restart-required.'
}

$business = Invoke-Classifier -Text 'validation failed: required artifact is missing' -Component 'child-agent' -BeforeCompletion
if ($business.restart_required -or $business.classification -ne 'not-transport-failure') {
    throw 'Business error was incorrectly classified as a transport restart.'
}

$completed = Invoke-Classifier -Text 'stream disconnected before completion' -Component 'codex'
if ($completed.restart_required) {
    throw 'A failure without a before-completion boundary was incorrectly classified as restart-required.'
}

$fixtureRoot = & (Join-Path $root 'scripts\Resolve-CodexRunRoot.ps1') -ArchitectureRoot $root -Kind tmp -ChildPath ('agent-transport-recovery-' + [guid]::NewGuid().ToString('N')) -IgnoreConfiguredRoot -Create
$stateRoot = Join-Path $fixtureRoot 'sessions'
$sessionId = 'transport-parent-' + [guid]::NewGuid().ToString('N')
try {
    $start = (& $controller -RepositoryRoot $root -Mode Run -Operation StartWork -Goal 'transport recovery parent fixture' -SessionId $sessionId -StateRoot $stateRoot -Authority 'test fixture authority' -AcceptanceCriteria 'parent state remains resumable' -Verification 'transport recovery test checks restart boundary' -Apply) | ConvertFrom-Json
    if ($start.status -ne 'passed') { throw 'Transport recovery parent fixture did not start.' }

    $delegate = (& $controller -RepositoryRoot $root -Mode Continue -Operation DelegateSubagent -SessionId $sessionId -StateRoot $stateRoot -AgentId 'visual-design-agent' -ChildId 'transport-child' -Goal 'transport recovery child fixture' -WriteSurface '.runtime/work/transport-recovery-child' -AcceptanceCriteria 'child recovery is propagated' -Verification 'parent JoinSubagent receives restart-required' -Authority 'test fixture authority' -Apply) | ConvertFrom-Json
    if ($delegate.status -ne 'passed' -or $delegate.tool_result.result -ne 'subagent-delegated') { throw 'Transport recovery child fixture was not delegated.' }

    $childSessionId = [string]$delegate.tool_result.child.session_id
    $childStatePath = Join-Path $stateRoot ($childSessionId + '\state.json')
    $childState = Get-Content -LiteralPath $childStatePath -Raw -Encoding UTF8 | ConvertFrom-Json
    $childState.status = 'blocked-restart-required'
    $childState.recovery = [pscustomobject][ordered]@{
        status = 'restart-required'
        classification = 'transport-disconnect'
        component = 'child-agent/transport-fixture'
        matched_pattern_ids = @('stream-disconnected-before-completion')
        error_sha256 = 'fixture'
        restart_required = $true
        user_message = 'Restart Codex and resume from the durable save point.'
        next_action = 'restart Codex or affected host, then Resume before Continue'
        preserve_pending_writes = $true
    }
    [IO.File]::WriteAllText($childStatePath, (($childState | ConvertTo-Json -Depth 20) + [Environment]::NewLine), $utf8NoBom)

    $join = (& $controller -RepositoryRoot $root -Mode Continue -Operation JoinSubagent -SessionId $sessionId -StateRoot $stateRoot -ChildId 'transport-child' -MergeDisposition accepted -Verification 'parent received restart-required child state' -Authority 'test fixture authority' -Apply) | ConvertFrom-Json
    if ($join.status -ne 'blocked' -or $join.exit.type -ne 'restart-required' -or $join.recovery.source -ne 'child-agent') {
        throw 'Parent did not return a restart-required exit for the child transport failure.'
    }

    $parentStatePath = Join-Path $stateRoot ($sessionId + '\state.json')
    $parentState = Get-Content -LiteralPath $parentStatePath -Raw -Encoding UTF8 | ConvertFrom-Json
    if ($parentState.status -ne 'blocked-restart-required' -or $parentState.recovery.status -ne 'restart-required') {
        throw 'Parent durable state did not preserve restart-required status.'
    }

    $resume = (& $controller -RepositoryRoot $root -Mode Resume -SessionId $sessionId -StateRoot $stateRoot -Authority 'test fixture authority' -Apply) | ConvertFrom-Json
    if ($resume.status -ne 'passed' -or $resume.phase -ne 'idle') { throw 'Resume did not restore the restart boundary.' }
    $resumedState = Get-Content -LiteralPath $parentStatePath -Raw -Encoding UTF8 | ConvertFrom-Json
    if ($resumedState.recovery.status -ne 'armed' -or $resumedState.recovery.resumed_from -ne 'restart-required') {
        throw 'Resume did not re-arm the transport recovery boundary.'
    }
}
finally {
    if (Test-Path -LiteralPath $fixtureRoot) {
        Remove-Item -LiteralPath $fixtureRoot -Recurse -Force
    }
}

[pscustomobject]@{
    status = 'passed'
    fatal_classifier = $fatal.exit_type
    business_classifier = $business.classification
    completed_classifier = if ($completed.restart_required) { 'restart-required' } else { 'not-transport-failure' }
    child_propagation = 'restart-required'
    resume = 're-armed-from-durable-state'
} | ConvertTo-Json -Compress
