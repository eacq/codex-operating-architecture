# Academic Manuscript Revision Pipeline

Use this reference for revising an existing paper, thesis, abstract,
introduction, method, result discussion, conclusion, caption, or response.

## Scope and Ownership

- `codex-text-style` owns expression, cohesion, register, terminology, and
  bounded argument diagnosis.
- The author owns new data, new interpretation, changes to causal strength,
  scientific decisions, and unresolved evidence.
- Citation verification belongs to the citation/evidence workflow.
- Locked-template DOCX mutation and rendered page flow belong to
  `codex-exact-word-layout` after the textual revision is approved.

## Whole-to-Local Order

1. Identify the paper's question, method, evidence, result, and boundary.
2. Diagnose section roles: abstract claim chain; introduction gap/contribution;
   method reproducibility; result evidence; discussion interpretation;
   conclusion scope and limitation.
3. Repair paragraph logic before wording: context or problem -> method or
   evidence -> result -> interpretation/transition, using only relationships
   already supported by the source.
4. Revise sentences for concrete subjects, technical verbs, calibrated claims,
   necessary modifiers, and consistent terminology.
5. Recheck protected content and, for DOCX work, hand the approved text to the
   layout owner for run-safe insertion and rendered QA.

Do not force every paragraph into the same pattern. Use the role and evidence
available in that paragraph.

## Protected Content Contract

Preserve unless the user explicitly authorizes a substantive change:

- numerical values, units, conditions, comparison bases, and result direction;
- equations, symbols, variable definitions, figure/table references, and OMML;
- citation keys/numbers, field codes, hyperlinks, bookmarks, and crossrefs;
- technical terms, abbreviations, claim scope, causal strength, uncertainty,
  limitations, and author-approved conclusions.

If a sentence is ambiguous or unsupported, flag it rather than inventing a
mechanism, explanation, comparison, or stronger conclusion.

## Academic Expression Checks

Prefer an evidence-tethered statement over decorative academic language.

- Give the sentence a concrete subject: method, model, parameter, result,
  experiment, mechanism, limitation, or prior study; do not overuse a generic
  "this paper" subject.
- Use technical verbs that describe the actual operation or evidence:
  formulate, derive, construct, quantify, compare, validate, indicate, or
  constrain. Do not replace a precise verb merely to sound elevated.
- State the relation that earns the transition: cause, condition, contrast,
  sequence, or implication. Remove connector chains that add no relation.
- Replace vague success/value language with the supported metric, comparison,
  boundary condition, or engineering decision.
- Keep novelty and applicability claims proportional to the reported evidence.

Do not call prose AI-generated from style alone. Report observable symptoms:
generic value claims, vague agents, decorative modifiers, stacked nouns,
mechanical transitions, uniform sentence cadence, or symmetrical lists that do
not express a real hierarchy or relation.

## DOCX-Safe Revision Handoff

When text is inside an exact-format Word document:

1. Work from a text extract plus the immediate paragraph context.
2. Classify paragraphs as safe text, citation/field-bearing, equation-bearing,
   caption/reference, or layout-sensitive.
3. For safe text, apply a minimal fragment replacement. For protected markup,
   edit only the non-protected text nodes or preserve and verify the complete
   run structure.
4. Compare protected tokens and package invariants after insertion.
5. Run the strongest project QA and inspect the re-rendered pages before
   accepting a compaction or flow improvement.

Never use content polishing as a pretext to erase citations, flatten
superscripts, alter equations, or add unsupported technical detail merely to
fill a page.

## Delivery

For a bounded revision, provide revised text, concise change categories, and
unresolved meaning/evidence risks. For a whole manuscript, provide a
diagnostic map first unless the user has clearly authorized a staged revision.
