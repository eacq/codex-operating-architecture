---
name: codex-information-gathering-chunking-retrieval
description: Owner-internal Global Experience Agent chunking and retrieval baseline for parsed documents, Agent memory candidates, and source-targeted evidence retrieval.
---

# Agent Chunking Retrieval

This subskill adapts `LesterYu0/feynman-build-workshop` episodes 04 and 05 as
an owner-internal capability under `codex-information-gathering`.

Use it after document parsing, before durable Agent memory/knowledge storage,
or whenever retrieval quality affects a source, behavior, absence, or ownership
claim.

## Contract

1. Prefer `codex-office-cli`'s Agent Document Parse Pipeline as the input
   producer. It owns file parsing. This subskill owns retrieval strategy and
   evidence narrowing.
2. Start with L1 unless the task proves a higher layer is needed:
   - recursive or fixed chunking;
   - BM25-lite lexical retrieval;
   - deterministic phrase/coverage rerank;
   - temperature-scaled confidence calibration;
   - refusal thresholding when confidence is too low;
   - recall@k, MRR, answer-accuracy, ECE, Brier score, false-accept, and
     false-refusal measurement when queries are supplied.
3. Treat L2 as gated candidates:
   - RAPTOR for overview-to-detail reasoning;
   - GraphRAG for entity relationship traversal.
4. Treat L3 as gated candidates:
   - ontology/schema-constrained RAG for compliance, law, medical, industrial,
     or other strict-domain work.
5. Retrieved chunks route attention; source files, parsed-document validation,
   owner gates, and tests remain final proof.

## Local executable surface

Run:

```powershell
.\skills\codex-information-gathering\scripts\Invoke-AgentChunkingRetrieval.ps1 -InputPath <text-or-json> -Query <query>
```

For evaluation:

```powershell
.\skills\codex-information-gathering\scripts\Invoke-AgentChunkingRetrieval.ps1 -ChunksPath chunks.jsonl -QueriesPath queries.jsonl -OutputPath results.json
```

The local implementation uses only the Python standard library. Do not add
embedding providers, vector databases, reranker APIs, cross-encoder models,
GraphRAG, RAPTOR, or ontology tools inside this subskill without routing
through the owning gates.

## Acceptance

- Output includes `strategy`, `chunks`, `retrieval`, and optional `evaluation`.
- Queries return ranked chunk ids and scores.
- Evaluation reports recall@1/3/5, MRR, substring baseline answer accuracy,
  expected calibration error, Brier score, false accept rate, and false refusal
  rate.
- Low-confidence queries expose `decision=refuse` instead of silently accepting
  the top chunk as answerable.
- L2/L3 requests remain declared candidates unless their external/model-backed
  dependencies are explicitly authorized and verified.
