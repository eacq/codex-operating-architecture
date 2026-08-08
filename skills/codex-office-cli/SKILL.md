---
name: codex-office-cli
description: Use OfficeCLI and optional MCP support for structured Word, Excel, and PowerPoint creation, inspection, rendering, and edits.
---

# Codex OfficeCLI

Use OfficeCLI as the preferred deterministic tool for ordinary Office document
creation, inspection, modification, validation, and render-feedback loops across
`.docx`, `.xlsx`, and `.pptx`.

## Tool Boundary

- Prefer OfficeCLI for cross-format Office automation, structured JSON reads,
  template merge, batch operations, document validation, `view issues`, HTML,
  SVG, screenshot, and live `watch` previews.
- For Agent document intake, use the owner-internal
  [doc-parse-pipeline](subskills/doc-parse-pipeline/SKILL.md) when a file must
  become a unified `Document`/`Chunk` record before Agent memory, knowledge, or
  downstream work. It adapts the seven-layer document-parse pipeline while
  keeping OCR, MinerU, VLM, installation, runtime, and credential decisions
  behind their existing gates.
- Use `codex-exact-word-layout` instead when the task is locked-template Word
  pagination, section/header fidelity, rendered page-flow repair, or journal
  format preservation.
- Route non-trivial PowerPoint work through the owner-internal
  [ppt-deck-factory](subskills/ppt-deck-factory/SKILL.md) and the registered
  `visual-design-agent`, which selects the visual route while this owner
  retains PPTX assembly and validation. Its primary new-deck route is the managed
  [codex-ppt adaptation](subskills/imported-codex-home/ningzimu-codex-ppt/SKILL.md)
  for visually unified image-based decks; preserve outline, style, backend,
  sample, per-slide state, QA, and assembly gates. When element-level editing
  is required, reconstruct the approved codex-ppt page into native PowerPoint
  elements; use PPT Master-derived routes for that downstream reconstruction,
  native template filling, or native enhancement. OfficeCLI remains the final
  delivery and validation owner for every route.
- Use project-local runtime helpers only when a Python library is already the
  lighter or more verified owner for the requested operation.
- Do not run OfficeCLI's upstream auto-installer from a global task unless the
  user explicitly wants it to mutate PATH and agent skill directories. The
  architecture install keeps the binary under the local software install root
  and records checksum evidence.

## Invocation

Resolve the executable with `scripts/Get-OfficeCliPath.ps1`. The local
architecture install uses:

```powershell
.\skills\codex-office-cli\scripts\Get-OfficeCliPath.ps1
```

For shell calls, set `OFFICECLI_SKIP_UPDATE=1` unless the task explicitly asks
to update OfficeCLI. Add `--json` whenever the command supports it.

Use the progressive model:

1. L1 read and inspect: `view`, `get`, `query`, `validate`, `view issues`.
2. L2 DOM edits: `set`, `add`, `remove`, `move`, `swap`, `merge`, `batch`.
3. L3 raw fallback: `raw`, `raw-set`, `add-part` only when L2 cannot express
   the needed OOXML change.

Before guessing properties, run `officecli help <format> <element>` or
`officecli help <format> <verb> <element>`.

## MCP Integration

OfficeCLI's MCP server is started with:

```powershell
officecli mcp
```

The MCP tool passes one raw command string through to the CLI. Use commands such
as `help docx paragraph`, `view report.docx text --json`, or
`validate deck.pptx --json`; do not assume a structured multi-parameter schema.

Codex exposes newly configured MCP servers only after a new task or restart. If
the OfficeCLI MCP tool is not exposed in the current task, use the local CLI
path directly and record that the MCP surface was unavailable.

When the MCP tool is exposed and the task will create or mutate a document,
first run the MCP command `load_skill <format>` for the target family:
`word`, `pptx`, or `excel`. The loaded OfficeCLI per-format skill is a
version-paired build and delivery guide; the installed CLI `help` output remains
the schema authority when the two differ. Keep these per-format guides in the
OfficeCLI MCP surface rather than splitting global Codex skills per file type
unless repeated evidence shows a separate owner, artifact, and safety boundary.

## Delivery Gate

For any Office document delivered to the user, use a real QA loop rather than a
single command success:

1. Run `officecli save <file>` before any non-OfficeCLI reader or handoff.
2. Run `officecli validate <file> --json` and reject schema failures.
3. Run `officecli view <file> issues --json`; resolve real content, overflow,
   placeholder, or accessibility issues. Format-specific advisory warnings may
   be documented only when they do not apply to the requested document type.
4. Scan `officecli view <file> text` or outline output for placeholder leaks
   such as `{{...}}`, `<TODO>`, `xxxx`, `lorem`, or literal shell escapes.
5. When layout matters, use the strongest available visual check:
   `view <file> screenshot` or `view <file> html` for Word, screenshot/SVG for
   PowerPoint, and issues/text checks for Excel unless a visual dashboard is the
   deliverable. If screenshots cannot render, state that the document was not
   visually verified.

For three or more mutations on one file, prefer `batch` or a resident
`open`/`save` session so the disk state and follow-up reads are intentional.

## Verification

After installation or upgrade, run:

```powershell
.\skills\codex-office-cli\scripts\Test-OfficeCli.ps1
```

Representative verification must cover version/help plus at least one JSON
operation for each of `.docx`, `.pptx`, and `.xlsx`. Close resident documents
before handing files to non-OfficeCLI tools.

For Agent document intake changes, run:

```powershell
.\scripts\Test-AgentDocParsePipeline.ps1
```

This verifies the stdlib-first parse surface, keyword validation, table line
number preservation, PDF strategy preflight, and typed robustness failures.

Imported local compatibility modes live under `subskills/imported-codex-home/`; choose them only after this owner has selected the document or presentation artifact and its validation path.
