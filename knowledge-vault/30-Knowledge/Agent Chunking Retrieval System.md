---
title: Agent Chunking Retrieval System
type: information-unit
status: active
learning_audience: codex
codex_learning: Use the Agent chunking-retrieval policy after document parsing and before durable memory or knowledge use; start with a local L1 recursive BM25-lite baseline, measure recall/MRR, calibrate rerank confidence, apply refusal thresholds, and route external rerankers, RAPTOR, GraphRAG, embedding, or ontology paths through owner gates.
source: LesterYu0/feynman-build-workshop episodes 04 chunking-retrieval and 05 rerank-calibration
owner: codex-information-gathering
verification:
  - scripts/Test-AgentChunkingRetrieval.ps1
  - scripts/validate.ps1
links:
  - "[[Global Experience System]]"
  - "[[Agent Memory System]]"
  - "[[Agent Document Parse Pipeline]]"
  - "[[Codebase Memory MCP]]"
---

# Agent Chunking Retrieval System

The Global Experience Agent now has a retrieval layer between document parsing
and durable memory or knowledge. Episode 04 is adapted as a policy and a local
baseline rather than as a new top-level owner.

`codex-office-cli` still owns file parsing and produces the unified
`Document`/`Chunk` record. `codex-information-gathering` owns chunk strategy
selection, retrieval, metric reporting, and source-targeted evidence use.
Memory storage, knowledge promotion, GraphRAG, ontology work, external
rerankers, embeddings, and vector databases keep their existing owner gates.

## Adapted method

The Agent uses three retrieval layers:

1. L1 flat chunking, rerank, and calibration. The local baseline is recursive
   chunking plus BM25-lite lexical retrieval, deterministic rerank,
   temperature-scaled confidence calibration, and refusal thresholding. It is
   stdlib-only and safe for first-pass evidence narrowing.
2. L2 structured expansion. RAPTOR and GraphRAG are candidates when questions
   repeatedly need cross-chunk reasoning. They require explicit owner routing
   because they introduce summarization, entity extraction, graph construction,
   or extra model cost.
3. L3 ontology-constrained retrieval. Ontology RAG or OG-RAG is a candidate for
   law, compliance, medicine, industrial standards, or another domain with
   strict schema boundaries. Schema creation/import remains gated.

## Agent rule

A retrieved chunk is not final proof. It selects the next source surface. Before
the Agent stores, promotes, edits, or reports a behavior claim, it must retain
the parse strategy, chunk strategy, query, top chunks, metric result, and source
verification boundary.

Episode 05 adds a stricter production rule: retrieval is not complete until
rerank confidence has been calibrated and low-confidence results can refuse. A
high local score is only a routing signal unless it passes the calibrated
threshold. External cross-encoders, hosted rerankers, embedding providers,
FlashRank/BGE/Cohere adapters, or learned calibration models remain gated
candidates and must report calibration metrics before durable use.

## Functional unit

- `config/agent-chunking-retrieval-policy.json`
- `skills/codex-information-gathering/subskills/chunking-retrieval/SKILL.md`
- `skills/codex-information-gathering/scripts/Invoke-AgentChunkingRetrieval.ps1`
- `skills/codex-information-gathering/scripts/Invoke-AgentChunkingRetrieval.py`
- `scripts/Test-AgentChunkingRetrieval.ps1`
