---
name: codex-exact-word-layout
description: Repair exact-format Word/DOCX layout, pagination, sections, headers, captions, references, and rendered-page fidelity.
---

# Codex Exact Word Layout

Use this skill with the document-editing skill available in the current environment. It owns the cross-project workflow for fragile Word layout edits where the visible PDF/page render is the acceptance authority.

Route ordinary document creation, review, comments, and conventional style edits
to `documents`. Use this skill when a retained DOCX/template has fragile
package parts or render-sensitive pagination that a broad save cycle could
change. Read `references/locked-template-package-diagnostics.md` whenever
headers, sections, page flow, references, captions, or package fidelity matter.

## Core Contract

1. Identify the user-authoritative DOCX before editing. Prefer a project `current-main` index or an explicit user-designated final file over timestamps.
2. Create a named output version and keep the source immutable.
3. Snapshot the source package before editing: document hash, critical-part hashes, media hashes, and the intended edit surface. Treat the snapshot as a regression boundary, not as a substitute for rendering.
4. Preserve template-critical package parts. Avoid broad whole-document save cycles through high-level libraries when prior evidence shows they rewrite headers, sections, relationships, or style inheritance.
5. Patch the smallest viable surface:
   - paragraph text fragments for prose compaction;
   - drawing extents for figure sizing;
   - local section breaks for full-width islands;
   - specific `pageBreakBefore` or manual break controls for page-flow repair.
6. Do not change data, equations, citations, references, figure evidence, or table values unless the user explicitly asks for content changes.

## PDF And Raster Fidelity Branch

Use this branch only when an existing PDF, scan, screenshot-derived document,
or fixed-layout export is the authoritative visual source and exact fidelity is
the acceptance boundary. Ordinary PDF extraction remains with the PDF/document
tooling owner.

1. Before editing, record the authoritative source hash and inspect page count,
   page boxes, embedded image dimensions, effective DPI, font inventory, and
   whether each page is vector/text, raster, or hybrid. Prefer structured tools
   such as `pdfinfo`, `pdfimages -list`, and `pdffonts` when available.
2. Never reconstruct a production PDF from a preview, browser screenshot, or
   low-resolution derivative when the original source is available. If the
   only source is raster, edit at its native pixel dimensions and preserve or
   improve its encoding; do not silently downsample.
3. Match typography from source evidence. Use embedded font information when
   reliable; otherwise compare same-scale glyph boxes, baselines, stroke
   weight, color, and visual center. Do not choose a font by appearance alone
   and then compensate with arbitrary image scaling.
4. Keep coordinate-sensitive edits narrow and deterministic. In browser or
   contenteditable surfaces, prefer stable text/HTML readback and exact-range
   edits over repeated mouse selection when selection drift can move or restyle
   unrelated content.
5. Run dependent visual stages serially: generate or save, rerender, crop,
   magnify, then inspect. Do not run a crop or screenshot from an output whose
   render has not completed.
6. Treat file size only as a diagnostic clue. It is not proof of quality;
   dimensions, DPI, encoding, page geometry, font/glyph evidence, and visual
   comparison are the acceptance evidence.

## Layout Decision Rules

- If a table or figure should move but is otherwise correct, inspect caption paragraph properties and nearby section/page controls before changing object geometry.
- If a figure/table must be full-width, create a local one-column island and immediately return to the original column regime; verify both the object page and the following page.
- If only a few conclusion or body lines spill onto a later page, prefer targeted prose compaction over adding unsupported content or inserting blind page breaks.
- If a previous orphan-control or caption-control break becomes harmful after a layout move, remove only that stale control after rendering proves the semantic unit still stays intact.
- If multiple single-column/full-width layouts are plausible, prepare candidates and let the user choose before writing back a structurally different layout.
- If page-top body lines form an unexplained staircase that survives paragraph-format repairs, inspect every affected header for empty `w:framePr` paragraphs and text-wrapping behavior before altering body indentation. This is a diagnostic branch, not a license to delete or globally reposition header objects; preserve visible header structure and keep template-specific coordinates in the project record.

## Verification Gate

Machine checks are necessary but not sufficient.

Run the project’s strongest available combined QA gate. It should include, when applicable:

- Word open/export or Word COM PDF export;
- rendered PDF/PNG pages;
- template/header audit;
- citation/reference audit;
- equation/OMML audit;
- table-span and caption-object audit;
- deep format audit;
- short-line/orphan audit.

Then inspect the rendered pages:

- first page header;
- edited page;
- preceding and following pages;
- reference-start page;
- final page;
- contact sheet.

For the PDF/raster branch, also compare the authoritative source and final
rerender at the same scale and location. Verify page count and page dimensions,
embedded/native image dimensions, effective DPI, local glyph boxes and
baselines, and edited-region crops at high magnification. Preserve a serial
`source -> saved output -> final rerender` evidence chain.

Reject output with clipped headers, detached captions, unexpected table splits, accidental one-column/two-column regime changes, non-terminal large blank areas, or one/two-character orphans.

## Version and Experience Capture

For repeatable projects, store each verified output with:

```text
<archive>/<date>_<version>/
  01_DOCX/
  02_PDF/
  03_AUDIT/
  04_RENDER/ or merged QA render folder
  VERSION_MANIFEST.json
```

Record hashes, QA summary paths, patch reports, rendered page count, visual pages inspected, and the next source-of-truth pointer.

Promote only generic lessons globally. Keep journal-specific templates, table numbers, figure numbers, page numbers, author data, and manuscript-specific claims in the project.

## Reference

Read `references/exact-word-layout-rules.md` for the layout decision tree and
`references/locked-template-package-diagnostics.md` for package snapshots,
round-trip risk, diagnostic order, and two-tier QA.

Imported local compatibility modes live under `subskills/imported-codex-home/`; they do not relax the authoritative-template or rendered-QA requirements.
