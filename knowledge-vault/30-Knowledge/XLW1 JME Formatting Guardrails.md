---
id: concept-xlw1-jme-formatting-guardrails
type: concept
status: active
source: source-xlw1-api-conversation-evidence
verified: true
learning_audience: codex
codex_learning: In XLW1, preserve black headings, Word-native single-column equations, superscript body citations with baseline references, template first-odd-even header behavior, and ordinary table-cell fonts; validate by Word-to-PDF rendering rather than DOCX inspection alone.
---

# XLW1 JME Formatting Guardrails

The manuscript uses a Journal of Mechanical Engineering style in which formula objects, citation placement, and visual page composition are part of the scholarly deliverable.

## Evidence

- Historical decisions required black headings and direct Word equation objects rather than equation tables.
- Formulae must remain within one column; figures and tables default to one column unless legibility makes a full-width layout necessary.
- Citation and reference formatting require body citations as superscripts while the bibliography remains baseline text.
- The 2026-07-14 condensation required PDF-render review to catch cross-reference labels split across Word XML runs.
- Author biographies that follow the bibliography must be inserted before the template's terminal section break; otherwise Word moves them to a default one-column section and produces an unbalanced last page.
- The supplied JME template requires a differentiated front-matter hierarchy, not uniform bold text: title/author/affiliation and Chinese/English abstract labels use separate fonts and weights. Remove a table-caption forced page break only when rendering proves it causes avoidable whitespace and the caption remains paired with its table.
- The supplied submission template enables both `首页不同` and `奇偶页不同`. Its manuscript pages use a blank first/odd header and an even-page `机  械  工  程  学  报` masthead; the 1.35 cm header and 1.27 cm footer distances are part of that geometry. Publication-only volume, issue, and date placeholders must remain absent from an unpublished manuscript.
- Editable table-cell text is ordinary regular 宋体/Times New Roman 六号字 (7.5 pt). Caption hierarchy is separate from table text. Fonts, labels, axes, and annotations already embedded in source figure bitmaps are evidence and must not be restyled as though they were editable Word text.
- Treat `表2  标题` and `表2数据…` as different roles. A real caption requires the numbering separator; prose beginning with a table or figure reference retains body alignment, 10.5 pt text, and body paragraph spacing. Strong checks must flag prefix-only misclassification before PDF review.

## Invalidation

- Recheck against an explicitly supplied new journal template or formatting requirement.

## Links

- Evidence: [[XLW1 API Conversation Evidence]]
- Applied by: [[XLW1 Manuscript Refinement Workflow]]
- Related: [[XLW1 Source Figure Integrity]]
