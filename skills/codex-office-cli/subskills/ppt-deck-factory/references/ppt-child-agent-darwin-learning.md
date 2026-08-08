# PPT Child Agent Darwin Learning Contract

Source corpus: local `hugohe3/ppt-master` main repository at
`.runtime/work/network-learning/ppt-master/full-repo/workspace/ppt-master-main`.

This reference hardens `ppt-deck-factory-agent` after real delivery feedback.
It applies the Darwin-style keep/revert ratchet from
`codex-experience-capture/subskills/skill-evolution-optimization`: retain only
rules that improve observable deck quality, authority separation, or validation
without expanding the child Agent's gates.

## Fitness target

The child Agent is fit when a future deck is:

- readable when projected or viewed in a screenshot contact sheet;
- natively editable as a PowerPoint deck, not a flattened image-only artifact;
- selected from the user's complete request and source boundary by the child,
  not pre-themed by the parent Agent;
- grounded in the local PPT Master main corpus, including routing, native-depth,
  template-boundary, examples, style catalogs, and validation rules;
- evidence-returning: route plan, design contract, export, validation, and
  visual proof or residual-risk note.

## Parent-to-child demand transfer

The Global Experience Agent must pass the whole demand packet to the child:

- original user request;
- source files or pasted source boundary;
- requested page count, language, audience, deadline, and output format when
  present;
- style likes/dislikes stated by the user;
- hard constraints and authority boundaries;
- available local resources and runtime status.

The parent must not choose the topic, narrative thesis, slide outline, visual
style, template, or route on behalf of the child unless the user explicitly
fixed that decision. The child owns those decisions and records them in
`route_plan.json` and `design_contract.md`.

## Main-corpus study pass

Before planning a non-trivial deck, the child must study the local main corpus
through progressive disclosure:

1. `README.md` for product positioning: native PowerPoint depth, argument-first
   design, local execution, no platform lock-in, and route variety.
2. `skills/ppt-master/SKILL.md` for mandatory load order, selected-authority
   discipline, blocking gates, and owning-source recovery.
3. `skills/ppt-master/workflows/routing.md` and the selected route authority.
4. `docs/templates-guide.md` when template or reusable structure is relevant.
5. `examples/examples.json` and only the matching example folders for style or
   structure references.
6. `references/visual-styles/` and `references/image-type-templates/` for
   style and diagram decisions.

The child should cite the studied corpus paths in the design contract. It
should not copy large example projects or upstream runtime files into Git.

## Readability gate

Every generated deck must prefer legibility over density.

- Title text: default 34-44 pt.
- Section title: default 26-34 pt.
- Body text: default 18-24 pt.
- Caption, source, footnote, or axis text: default 10-14 pt.
- Do not place essential content below 18 pt unless it is a non-essential
  footnote/source line.
- If a contact-sheet screenshot makes body text hard to read, regenerate the
  owning authoring source with fewer words, stronger hierarchy, or larger type.
- When language rendering is unreliable in validation screenshots, switch the
  visible validation draft to a supported font/language while preserving the
  user's requested final-language boundary in the design contract.
- Use actual PPTX rendering for final readability proof when available:
  PowerPoint COM export, LibreOffice export, OfficeCLI renderer, or another
  renderer that lays out the saved PPTX. A PIL/SVG/manual redraw can guide
  authoring, but it cannot prove final text wrapping, overflow, cropping, or
  font substitution.
- If only a surrogate preview exists, report `visual_proof: residual-risk` and
  do not mark the visual readability gate as fully passed.
- **CLI-render agreement for text-bearing ellipses/ovals:** when an ellipse or
  oval contains text, `OfficeCLI view issues` and an actual PPTX render must
  both show no overflow before acceptance. If they disagree, repair the
  authoring source and rerun both checks; prefer a rounded rectangle or a
  decoupled text container when it keeps the intended meaning.

## Darwin ratchet

For each deck attempt, the child records:

- `current_failure`: what looked worse or failed, such as small text, generic
  AI cards, missing corpus study, or parent-selected theme leakage;
- `candidate_rule`: the one rule being tried;
- `fitness_signal`: rendered screenshot readability, issue count, validation
  result, editability, and user feedback;
- `keep_or_revert`: keep only when the signal improves the deck without
  violating owner gates.

The first accepted rules are:

1. Use larger default type than ordinary dense templates.
2. Transfer full demand to the child; do not let the parent choose the deck's
   topic or thesis.
3. Require a main-corpus study pass before non-trivial planning.
4. Treat actual-render screenshot/contact-sheet readability as a validation
   signal, not an optional polish step.
5. Reject surrogate-only contact sheets as final evidence for overflow-sensitive
   decks.
6. Require paired CLI-render agreement before accepting a text-bearing ellipse
   or oval; replace the text-bearing ellipse or decouple its text on a mismatch.
