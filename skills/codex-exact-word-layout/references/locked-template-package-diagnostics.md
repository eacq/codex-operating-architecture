# Locked-Template DOCX Package Diagnostics

Use this reference for an existing Word document whose template fidelity or
rendered pagination matters more than ordinary text editing.

## Routing Boundary

- Use `documents` for ordinary authoring, comments, standard style cleanup, and
  render review.
- Use `codex-exact-word-layout` when the retained template, headers, section
  topology, field/citation runs, media relationships, or two-column page flow
  must survive a minimal repair.
- Do not create a second generic Word skill. Journal styles, page coordinates,
  author data, and document-specific QA thresholds belong in the project.

## Snapshot Before Mutation

Record enough evidence to distinguish the intended patch from collateral
round-trip damage:

1. source path, SHA-256, and immutable output location;
2. package part inventory and hashes for changed XML, headers/footers, styles,
   settings, relationships, and embedded media as applicable;
3. body text/citation or field invariants when text must remain unchanged;
4. section/column topology and the target page/render symptom;
5. the expected changed parts and the rollback source.

Use byte hashes for untouched binary parts and a canonical semantic XML
comparison for intentionally changed XML. Do not waive an entire header or
package hash because one local attribute is expected to differ.

## Edit-Surface Risk Ladder

- Read-only inspection: unzip/parse OOXML, compare parts, enumerate sections,
  and render. This is the default diagnosis surface.
- Targeted patch: change only the known paragraph, drawing extent, field/run,
  relationship, or header fragment. Preserve neighboring run children when
  citations, fields, or equations are present.
- Controlled Word automation: use only when Word itself is needed to export,
  repaginate, or normalize a known compatible feature; re-audit package parts
  after the save.
- Broad library round-trip: treat a full `python-docx` or other high-level save
  as high risk for locked templates. Use it only when its structural operation
  cannot be isolated otherwise, then compare critical parts and accept the
  result only after full render QA.

## Diagnostic Order for Visible Layout Defects

1. Confirm the authoritative source and reproduce the render symptom.
2. Inspect local paragraph mechanics: indents, tabs, line/page breaks,
   keep-with-next/keep-lines controls, and empty spacers.
3. Inspect nearby caption/object adjacency and section/column transitions.
4. Inspect inline/floating object geometry and text wrapping.
5. Inspect active header/footer parts, including empty framed paragraphs and
   their wrapping behavior.
6. Make one minimal reversible change, render again, and compare the target,
   preceding, and following pages.

Do not use spaces, global indentation resets, bulk section deletion, or broad
header replacement as a first response to a localized visible defect.

## Structural Rules That Generalize

- Preserve complete semantic paragraphs, run children, citations, fields, and
  OMML unless the requested content change explicitly permits otherwise.
- Keep a full-width figure/table and its caption as one local one-column
  island; return immediately to the original column regime.
- Re-audit forced pagination after every table, figure, section, or prose-flow
  change. A once-useful break can become the source of later blank space.
- Audit captions by rendered pairing, not only table/image page spans.
- Treat cross-page continuation defects as text-flow problems first; if a
  semantic paragraph split is necessary, preserve text and run topology and
  prove the character stream is unchanged.
- Treat visual centering and text wrapping as rendered properties. XML
  alignment or automation coordinates alone are insufficient proof.

## Two-Tier Acceptance

Hard failures are deterministic: damaged package, changed protected media,
unexpected critical-part change, lost citation/field/equation content, broken
caption/object pairing, or failed template audit. Warnings are a manual queue:
potentially redundant section breaks, empty spacer runs, short lines, local
whitespace, and aesthetic balance. A warning becomes a rejection only when the
rendered page shows a real defect.

Inspect the first page/header, edited page, adjacent pages, end-matter start,
final page, and contact sheet. Keep an explicit render limitation if the
authoritative Word renderer is unavailable; do not claim visual acceptance from
OOXML checks alone.
