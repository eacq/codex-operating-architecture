---
id: concept-xlw1-template-header-visual-object-fidelity
type: concept
status: active
source: source-xlw1-supplied-jme-template
verified: true
learning_audience: codex
codex_learning: For XLW1, inspect the supplied JME template's actual header parts and editable table cells before changing typography; use the template's unpublished-manuscript header state and do not alter fonts embedded inside source images.
---

# XLW1 Template Header and Visual Object Fidelity

## Verified template rules

- The supplied JME submission template enables `首页不同` and `奇偶页不同`.
- Its unpublished-manuscript convention leaves the first and odd page headers blank and places `机  械  工  程  学  报` in the even-page running header. The page-header and footer distances are 1.35 cm and 1.27 cm.
- Volume, issue, and date material belongs to the publication header and is not manuscript metadata. It must not be invented for this draft.
- Editable table cells use regular 宋体/Times New Roman 六号字 (7.5 pt); table captions have their own hierarchy. This is ordinary text, not a special display font.
- Figure captions are Word text and follow the caption hierarchy. Text already rasterized inside a figure is source evidence and must remain untouched.

## Validation boundary

- Confirm header state and table-run typography in OOXML/Word, then inspect a Word-to-PDF render for clipping, pagination, and whitespace. A successful DOCX open is necessary but does not replace rendered visual QA.

## Links

- Constraint: [[XLW1 JME Formatting Guardrails]]
- Evidence: [[XLW1 Source Figure Integrity]]
- Applied by: [[XLW1 Manuscript Refinement Workflow]]
- Map: [[XLW1 Manuscript Knowledge Map]]
