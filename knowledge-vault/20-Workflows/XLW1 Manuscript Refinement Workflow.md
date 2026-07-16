---
id: workflow-xlw1-manuscript-refinement
type: workflow
status: active
source: source-xlw1-api-conversation-evidence;$EXTERNAL_WORKSPACE/xlw1/.codex/project/WORKFLOWS.md
verified: true
learning_audience: codex
codex_learning: Execute XLW1 refinement in the order source authority, structure, technical evidence chain, natural Chinese academic prose, JME formatting, and rendered PDF QA; preserve references and source evidence unless the user explicitly changes them.
---

# XLW1 Manuscript Refinement Workflow

## Inputs

- Author-designated current DOCX and its SHA-256.
- Thesis, author-owned comparison paper, JME template requirements, and traceable source figures.

## Steps

1. Confirm the authority document using [[XLW1 Version Authority]].
2. Preserve the technical chain: discrete geometry and STL slicing, profile solution, error or feasibility evidence, then verification; compress generic CAM narration.
3. Revise prose for precise Chinese mechanical-engineering logic without generic AI phrasing or unsupported claims.
4. Apply [[XLW1 JME Formatting Guardrails]] and [[XLW1 Source Figure Integrity]].
5. Add user-provided author, funding, and correspondence metadata using the supplied sample as the layout authority; keep end-matter author paragraphs before the terminal section break.
6. Apply the supplied JME template hierarchy and use rendered page whitespace to target only avoidable forced breaks.
7. Export through Word COM, render the PDF pages, run targeted citation/equation/layout audits, and retain a named backup/output.

## Verification

- Word-native equation objects are present and readable in one column.
- Citations and bibliography follow the required superscript/baseline distinction.
- No abnormal whitespace, unintended cross-page break, unreadable single-column element, or broken figure border remains in the rendered PDF.

## Recovery

- Restore the adjacent named DOCX backup, then repeat from source-authority confirmation.

## Links

- Evidence: [[XLW1 API Conversation Evidence]]
- Project map: [[XLW1 Manuscript Knowledge Map]]
