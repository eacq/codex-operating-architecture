[CmdletBinding()]
param(
    [string]$RepositoryRoot = 'F:\codex'
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath $RepositoryRoot).Path
$runner = Join-Path $root 'skills\codex-information-gathering\scripts\Invoke-AgentChunkingRetrieval.ps1'
if (-not (Test-Path -LiteralPath $runner -PathType Leaf)) { throw 'Agent chunking retrieval runner is missing.' }

$policyPath = Join-Path $root 'config\agent-chunking-retrieval-policy.json'
if (-not (Test-Path -LiteralPath $policyPath -PathType Leaf)) { throw 'Agent chunking retrieval policy is missing.' }
$policy = Get-Content -LiteralPath $policyPath -Raw -Encoding UTF8 | ConvertFrom-Json
if ($policy.model -ne 'agent-chunking-retrieval-policy') { throw 'Agent chunking retrieval policy model mismatch.' }
if ($policy.owner -ne 'codex-information-gathering') { throw 'Agent chunking retrieval must be owned by codex-information-gathering.' }
if ($policy.local_executable.dependencies -ne 'python standard library only') { throw 'Agent chunking retrieval baseline must remain stdlib-only.' }

$tmp = Join-Path $root ('.runtime\tmp\agent-chunking-retrieval-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Force -Path $tmp | Out-Null
try {
    $chunksPath = Join-Path $tmp 'chunks.jsonl'
    @(
        '{"id":"c1","text":"The Global Experience Agent stores typed workflow memory in SQLite FTS5 and exposes SearchMemory.","metadata":{"section":"memory"}}',
        '{"id":"c2","text":"The document parser preserves tables, line numbers, and parser strategy before storage.","metadata":{"section":"parse"}}',
        '{"id":"c3","text":"Codebase Memory indexes F-codex as structural graph evidence and must not create aliases.","metadata":{"section":"graph"}}'
    ) | Set-Content -LiteralPath $chunksPath -Encoding UTF8

    $queriesPath = Join-Path $tmp 'queries.jsonl'
    @(
        '{"id":"q1","question":"sqlite fts5 memory search","relevant_chunk_ids":["c1"],"expected_answer":"SQLite FTS5"}',
        '{"id":"q2","question":"tables line numbers parser strategy","relevant_chunk_ids":["c2"],"expected_answer":"line numbers"}',
        '{"id":"q3","question":"F-codex structural graph aliases","relevant_chunk_ids":["c3"],"expected_answer":"F-codex"}',
        '{"id":"q4","question":"unrelated weather forecast tomorrow","relevant_chunk_ids":[],"expected_answer":""}'
    ) | Set-Content -LiteralPath $queriesPath -Encoding UTF8

    $json = & $runner -RepositoryRoot $root -ChunksPath $chunksPath -QueriesPath $queriesPath -Query 'sqlite fts5 memory search' -TopK 3 -RefusalThreshold 0.35
    $result = $json | ConvertFrom-Json
    if ($LASTEXITCODE -ne 0) { throw 'Agent chunking retrieval runner failed.' }
    if ($result.model -ne 'agent-chunking-retrieval' -or $result.strategy -ne 'recursive') { throw 'Unexpected Agent chunking retrieval result model or strategy.' }
    if (@($result.retrieval).Count -lt 1 -or $result.retrieval[0].id -ne 'c1') { throw 'Single-query retrieval did not rank the memory chunk first.' }
    if ($result.retrieval[0].decision -ne 'accept' -or $result.retrieval[0].calibrated_confidence -lt 0.35) {
        throw 'Known answerable query did not pass calibrated rerank threshold.'
    }
    if (-not $result.evaluation -or $result.evaluation.recall_at_3 -lt 1.0 -or $result.evaluation.mrr -lt 1.0) {
        throw 'Agent chunking retrieval evaluation did not meet the local baseline.'
    }
    if ($result.evaluation.false_accept_rate -ne 0.0 -or $result.evaluation.false_refusal_rate -ne 0.0) {
        throw 'Agent chunking retrieval calibration produced an unsafe accept/refusal rate.'
    }

    $unknownJson = & $runner -RepositoryRoot $root -ChunksPath $chunksPath -Query 'unrelated weather forecast tomorrow' -TopK 3 -RefusalThreshold 0.35
    $unknown = $unknownJson | ConvertFrom-Json
    if ($LASTEXITCODE -ne 0 -or $unknown.decision -ne 'refuse') {
        throw 'Unanswerable query did not produce a refusal decision.'
    }

    $stateReader = Join-Path $root 'agent\40-runtime\Get-AgentHarnessState.ps1'
    $state = (& $stateReader -RepositoryRoot $root) | ConvertFrom-Json
    if (-not $state.agent_chunking_retrieval) { throw 'Agent harness state does not expose agent_chunking_retrieval.' }
    if ($state.agent_chunking_retrieval.owner -ne 'codex-information-gathering') { throw 'Agent chunking retrieval state has the wrong owner.' }
    if ('L1' -notin @($state.agent_chunking_retrieval.layers)) { throw 'Agent chunking retrieval state does not expose L1.' }
    if ('recall_at_3' -notin @($state.agent_chunking_retrieval.metrics)) { throw 'Agent chunking retrieval state does not expose recall_at_3.' }
    if ('expected_calibration_error' -notin @($state.agent_chunking_retrieval.metrics)) { throw 'Agent chunking retrieval state does not expose calibration metrics.' }
    if ($state.agent_chunking_retrieval.calibration.default_refusal_threshold -ne 0.35) { throw 'Agent chunking retrieval state does not expose the default refusal threshold.' }

    [pscustomobject]@{
        status = 'passed'
        model = 'agent-chunking-retrieval'
        chunks = @($result.chunks).Count
        top_query_result = $result.retrieval[0].id
        recall_at_3 = $result.evaluation.recall_at_3
        mrr = $result.evaluation.mrr
        false_accept_rate = $result.evaluation.false_accept_rate
        unknown_decision = $unknown.decision
    } | ConvertTo-Json -Compress
} finally {
    if (Test-Path -LiteralPath $tmp) {
        Remove-Item -LiteralPath $tmp -Recurse -Force
    }
}
