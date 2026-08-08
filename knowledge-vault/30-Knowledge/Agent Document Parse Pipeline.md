---
title: Agent Document Parse Pipeline
type: information-unit
status: active
learning_audience: codex
codex_learning: Route Agent document intake through codex-office-cli's seven-layer Document/Chunk parse pipeline; require parser strategy and content, structure, performance, and robustness validation before storing parsed content in Agent memory or knowledge.
source: LesterYu0/feynman-build-workshop episode 03 doc-parse-pipeline
owner: codex-office-cli
verification:
  - scripts/Test-AgentDocParsePipeline.ps1
  - scripts/validate.ps1
links:
  - "[[Global Experience System]]"
  - "[[Agent Memory System]]"
  - "[[Agent Intent Recognition System]]"
---

# Agent Document Parse Pipeline

The Global Experience Agent uses an owner-routed document intake path before
documents are stored in Agent memory, converted into knowledge, or handed to a
specialist Agent. The governing owner is `codex-office-cli` because the surface
is cross-format Office/PDF/document automation. Locked-template Word pagination
still routes to `codex-exact-word-layout`; OCR, MinerU, VLM, installation,
runtime, and credential choices still route through their existing gates.

## Adapted method

The episode 03 method is adapted as seven layers:

1. Unified `Document` and `Chunk` schema.
2. Parser routing by file type and complexity.
3. PDF strategy selection from light native/table extraction through complex
   layout and scan/OCR candidates.
4. OCR degradation chain as a gated candidate path, not an automatic hidden
   dependency.
5. Excel multi-sheet parsing with table/row preservation.
6. Word paragraph/table/style parsing.
7. Validation across content, structure, performance, and robustness.

## Agent rule

A parsed document is not ready for durable Agent use merely because a parser
returned text. The Agent must also record the owner route, parser strategy,
validation result, unresolved gated capability, and robustness boundary. Missing
business keywords, absent table row numbers, unusual chunk counts, encrypted
inputs, corrupted containers, image-only files, or unsupported formats must be
visible in the typed result instead of being silently accepted.

## Functional unit

- `skills/codex-office-cli/subskills/doc-parse-pipeline/SKILL.md`
- `skills/codex-office-cli/scripts/Invoke-AgentDocParsePipeline.ps1`
- `skills/codex-office-cli/scripts/Invoke-AgentDocParsePipeline.py`
- `scripts/Test-AgentDocParsePipeline.ps1`
