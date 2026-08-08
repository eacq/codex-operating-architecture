# Exact Word Layout Rules

These rules generalize verified behavior from exact-format Word manuscript work. They are not a substitute for the target project’s own template or current-main record.

## What Generalizes

- Rendered pages, not DOCX XML alone, determine whether layout quality is acceptable.
- Whole-document high-level library saves can be unsafe for locked-template DOCX packages because they may rewrite section/header relationships.
- Targeted OOXML edits are safer when the required change is local and well understood.
- Stale pagination controls can become harmful after later figure/table/text moves.
- Prose compaction is often safer than content expansion when the goal is to remove a small page-flow spill.

## What Does Not Generalize

- Exact header XML hashes.
- Journal-specific font sizes, caption hierarchy, and reference punctuation.
- Which figure/table should be full-width.
- Page numbers and object locations.
- Any manuscript-specific scientific claim or quantitative result.

## Decision Tree

1. Confirm authority:
   - user-designated latest DOCX;
   - project current-main index;
   - SHA-256 match when there are competing copies.
2. Classify the requested change:
   - page-flow repair;
   - object sizing/full-width conversion;
   - caption-object pairing;
   - conclusion/reference or end-matter transition;
   - orphan-line repair;
   - header/template fidelity repair.
3. Choose the smallest edit:
   - remove stale `pageBreakBefore` or manual break;
   - insert local continuous section breaks;
   - patch drawing extent;
   - compact target paragraph text;
   - move a complete semantic paragraph only when compaction cannot preserve integrity.
4. Render and inspect.
5. Run machine QA.
6. If machine QA passes but render looks wrong, trust the render and redesign.

## Safe Prose Compaction

Use compaction only when the content is already supported and the page-flow problem is small.

Preserve:

- all reported data and units;
- claim polarity and scope;
- citations and equation references;
- section heading hierarchy;
- paragraph role.

Remove:

- duplicated subjects;
- decorative transition words;
- redundant “this result shows” scaffolding;
- repeated method names when the paragraph context is clear.

Avoid:

- adding new mechanism claims;
- strengthening the conclusion;
- deleting limitations unless the user asks.

## Full-Width Object Island

For a full-width figure or table in a two-column document:

1. Close the preceding two-column flow with a local continuous section break.
2. Place the object and caption in a one-column island.
3. Return immediately to the original two-column flow.
4. Verify the object page, following page, and caption pairing by render.

Do not keep section breaks that no longer serve a full-width or column-regime purpose.

## Stale Pagination Control Audit

After any table, figure, section-break, manual-break, or prose-flow edit, inspect nearby:

- `w:pageBreakBefore`;
- `w:br type="page"` and `w:br type="column"`;
- empty spacer paragraphs;
- paragraph-level `sectPr`;
- object/caption adjacency.

A control that fixed an orphan in one version can create blank space after later reflow.

## Header-Frame Text-Wrap Diagnostic

This is a conservative diagnostic candidate, validated in one locked-template
manuscript. It does not make any coordinate or header part a global rule.

When the first body lines on a page form a staircase or asymmetric exclusion
shape that persists after paragraph-indent, tab, run, and section-carrier
checks:

1. Measure the rendered or Word line-start coordinates to distinguish a true
   text-exclusion region from an ordinary first-line indent.
2. Inspect all header parts used by the affected page, including empty
   paragraphs carrying `w:framePr`; an invisible frame with wrapping enabled
   can exclude body text even when body paragraph XML and ordinary shape
   inventories appear normal.
3. Map the frame to its section/header role and preserve intentional visible
   header content. Do not delete frames, disable wrapping, or change all
   headers as a blanket fix.
4. If a minimal template-specific repair is proven, record the exact exception
   policy and verify both header appearance and the formerly affected pages.

Template-specific coordinates, selected header XML parts, and any audit
exception remain project-local. A header hash difference is acceptable only
when a canonical comparison explicitly allows the single documented change
and proves all remaining content and attributes match.

## Visual Acceptance Checklist

Inspect:

- first page header;
- affected page;
- previous and next page;
- first reference/end-matter page;
- final page;
- contact sheet.

Reject:

- clipped header/footer;
- object/caption separation;
- unexpected object split;
- unexplained large blank area before the final page;
- accidental column-regime change;
- orphaned one/two-character line;
- formula or numeric condition split from its semantic paragraph.
