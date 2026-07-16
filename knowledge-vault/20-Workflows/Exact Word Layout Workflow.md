---
id: workflow-exact-word-layout
type: workflow
status: active
source: xlw1-jme-layout-iterations;F:/codex/skills/codex-exact-word-layout
verified: true
learning_audience: codex
codex_learning: For locked-template DOCX layout repairs, preserve the authoritative file, patch only the smallest local OOXML or Word COM surface, then trust rendered page QA over structural checks when they disagree.
---

# Exact Word Layout Workflow

## Inputs

- User-designated or project-indexed authoritative DOCX.
- Target template or prior verified output.
- Requested layout issue: page flow, full-width figure/table, caption-object pairing, conclusion/reference transition, orphan-line repair, or header-sensitive formatting.

## Steps

1. Confirm source authority and create a new named archive version.
2. Snapshot critical package parts, protected media, section topology, and the intended edit surface.
3. Classify the layout failure through paragraph, pagination, section/object, and active-header layers.
4. Choose the smallest local edit: paragraph compaction, drawing extent patch, local section-break island, or stale page-break removal.
5. Avoid broad whole-document high-level-library saves when exact headers, sections, or package relationships matter; if unavoidable, compare the resulting package against the snapshot.
6. Export through the most faithful renderer available and inspect page images.
7. Run template, citation/reference, equation, table-span, caption-object, deep-format, and orphan-line audits when available.
8. Write a manifest with hashes, QA paths, patch reports, and visual pages inspected.
9. Update the project source-of-truth pointer only after verification.

## Verification

- Rendered pages show no clipped headers, detached captions, accidental column-regime changes, avoidable non-terminal blank areas, or one/two-character orphans.
- Machine QA reports no hard failures relevant to the document type.
- The final page and reference/end-matter start page are visually coherent.

## Recovery

- Restore the prior archived DOCX and rerun from source-authority confirmation.

## Links

- Module: [[Exact Word Layout Module]]
- Boundary: [[Verified Experience Promotion]]
- Related project-specific guardrails: [[XLW1 JME Formatting Guardrails]]
