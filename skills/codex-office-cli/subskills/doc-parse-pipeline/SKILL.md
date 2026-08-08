---
name: codex-office-cli-doc-parse-pipeline
description: Owner-internal Agent document parsing pipeline for PDF, Office, text, and image intake into validated Document and Chunk records.
---

# Agent Document Parse Pipeline

This subskill adapts LesterYu0/feynman-build-workshop episode 03 as a local
Agent capability under `codex-office-cli`. It keeps the existing owner boundary:
Office/PDF/cross-format document work stays here, exact locked-template Word
layout still routes to `codex-exact-word-layout`, OCR/VLM/installation remains
behind `codex-tool-installation`, `codex-runtime-environments`, and
`codex-credential-management` gates.

## Contract

Use the seven-layer pipeline:

1. `Document` / `Chunk` schema: path, file type, strategy, chunks, page count,
   parse time, error, metadata, page, table id, line number, bbox, confidence.
2. Parser routing: choose by file type and complexity; do not force one parser
   across all sources.
3. PDF strategy: native text/table PDFs prefer light parsers; scan/image-heavy
   PDFs route to OCR/MinerU/VLM candidates only after the owning gates permit
   those tools.
4. OCR degradation: Tesseract, PaddleOCR, Surya, and VLM are candidate levels,
   not automatic unauthorised calls.
5. Excel path: preserve sheets, rows, merged-range metadata, formulas or values
   according to the requested operation.
6. Word path: preserve paragraphs, tables, line order, and style hints where
   available.
7. Validation: run content, structure, performance, and robustness checks before
   the parsed result can enter Agent memory, knowledge, or downstream work.

## Local executable surface

Run:

```powershell
.\skills\codex-office-cli\scripts\Invoke-AgentDocParsePipeline.ps1 -Path <file> -Keyword <keyword>
```

The script is stdlib-first and safe to run without installing optional PDF/OCR
packages. It returns JSON. For heavy PDF extraction, OCR, MinerU, or VLM use,
route the missing capability through the existing installation/runtime/credential
owners instead of adding dependencies inside this subskill.

## Acceptance

- Parsed output must expose a unified `Document` with `chunks`.
- Business keywords, if supplied, must be reported as found or missing.
- Table rows must preserve line numbers where the parser can observe them.
- Empty, encrypted, unsupported, image-only, or corrupted inputs must return a
  typed error instead of silent success.
- The parse result may be stored in Agent memory only after the validation
  result and the owner route are recorded.
