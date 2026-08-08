---
name: jme-word-formatting
description: Edit and audit Word manuscripts for Chinese Journal of Mechanical Engineering / Journal of Mechanical Engineering-style formatting. Use for .docx papers needing template compliance, black headings, single-column-first figures/tables/equations, Word equation format, formula references, superscript literature citations, reference-list formatting, punctuation cleanup, figure/table placement, and render-based visual QA.
---

# JME Word Formatting

## Required Workflow

Use the `documents` skill for DOCX work. Back up the current manuscript before structural OOXML edits. Preserve the user's latest manuscript and avoid regenerating from old builder scripts unless explicitly requested.

After any meaningful edit, export or render and visually inspect the pages. Text extraction alone is not enough for Word layout quality.

## Priority Rules

1. Keep headings and main text black unless the journal template explicitly requires otherwise.
2. Prefer single-column placement for equations, figures, and tables whenever readable.
3. Use double-column placement only when a visual remains unclear after reasonable scaling or relayout.
4. Use real Word equations (`OMML`) for displayed equations and inline mathematical variables where the surrounding text treats them as formulas.
5. Do not insert equations through layout tables.
6. Keep literature citations as superscript bracketed numbers in the body, but keep reference-list item numbers baseline.
7. Avoid wrapping OMML formula text in hyperlinks if it breaks Word open/export stability.

## Reference And Citation Handling

When matching a supplied reference-format sample:

- Inspect the sample paragraph properties and run properties from OOXML when `python-docx` cannot open it.
- Apply hanging indent, compact line spacing, and font size to the reference list without rewriting reference content unless requested.
- Convert only body citations such as `[1]`, `[1-3]`, `[4, 6]` to superscript.
- Do not convert reference-list labels `[1]`, table data, mathematical intervals like `[0,1]`, or bracketed non-citation values.

Use `scripts/audit_citations_refs.py` to audit citation superscripts and reference-list labels after edits.

## Formula Handling

- Check both displayed equations and inline variables.
- Confirm subscripts and superscripts are real formula structures or Word superscript/subscript formatting, not parenthesized substitutes.
- Quantity exponents and unit exponents should not contain unnecessary parentheses.
- Formula references may be ordinary text, field references, or hyperlinks only if Word export remains stable.

## Visual QA Targets

- Captions stay visually paired with figures/tables.
- No figure border is accidentally opened or removed.
- No table crosses pages awkwardly unless it is intentionally split.
- Page bottoms do not contain large avoidable blank gaps.
- Rendered PDF/PNG page count and visual layout remain stable after edits.

Use `references/docx_format_checklist.md` before final delivery.
