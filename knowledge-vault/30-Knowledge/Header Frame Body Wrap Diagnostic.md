---
id: concept-header-frame-body-wrap-diagnostic
type: concept

promotion_authority: user-candidate-processing-20260718
promotion_status: guarded
source: XLW1 verified error-feedback repair 2026-07-16;codex-exact-word-layout
verified: false
learning_audience: codex
codex_learning: When a locked-template DOCX has a persistent staircase-shaped page-top body exclusion, inspect empty wrapping frames in the active header parts before changing body indentation; treat any repair coordinate as project-local until independently reproduced.
---

# Header Frame Body Wrap Diagnostic

An apparently invisible header frame can create a body-text exclusion region.
The symptom may resemble a malformed first-line indent even when body
paragraph properties are correct.

## Evidence

- One XLW1 locked-template repair isolated empty `w:framePr` paragraphs with
  `wrap="around"` in active even-page headers after body indentation, tabs,
  run structure, carrier paragraphs, and ordinary header VML wrapping did not
  explain the rendered line starts.
- A minimal frame-position change restored equal body line starts while keeping
  the visible header and the full render/QA result intact.

## Boundary

- Status is `candidate`: the diagnosis has one verified project instance, not
  independent cross-project replication.
- Do not generalize header XML parts, positions, or accepted hash differences.
- Require line-coordinate evidence, active-header mapping, canonical semantic
  comparison, and rendered-page review before accepting a repair.

## Links

- Workflow: [[Exact Word Layout Workflow]]
- Promotion boundary: [[Verified Experience Promotion]]
- Project application: [[XLW1 JME Formatting Guardrails]]
