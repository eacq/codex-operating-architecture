# Academic Report Style Contract

Source basis: local `ppt-master-skill-v4.1.0` release material package stored
under `.runtime/work/network-learning/ppt-master/`, plus the existing
`hugohe3/ppt-master` route workflow adaptation.

This contract is the default style realism gate when the Global Experience
Agent creates academic, research, engineering, thesis, group-meeting, defense,
technical-review, or evidence-report decks. It exists because a generic AI deck
often overuses rounded cards, glass panels, gradients, glow, and decorative KPI
blocks; those marks make slides look generated rather than argued.

## Default visual direction

For academic/report decks, prefer this style family in order:

1. `data-journalism` for evidence-dense research, metrics, evaluations,
   benchmark reports, and method/result comparisons.
2. `editorial` for literature review, conceptual exposition, architecture
   explanation, and long-form analytical reports.
3. `swiss-minimal` for high-level thesis defense, proposal, architecture, or
   method overview slides where sparse structure is more valuable than density.

Do not default to `soft-rounded`, `glassmorphism`, `dark-tech`, or large
illustration-led styles unless the user explicitly asks for that look or the
delivery context is a product/marketing demo rather than an academic report.

## Design lock fields

Every academic/report route plan should expose:

- `style_realism_gate: academic-report`
- `recommended_visual_styles: data-journalism, editorial, swiss-minimal`
- `avoid_visual_styles_by_default: soft-rounded, glassmorphism, dark-tech`
- `anti_ai_style_rules`
- `academic_report_style_rules`

The generated design contract must state the selected style and why it serves
the content. If no style is selected yet, author a conservative default:
`editorial` for analysis, `data-journalism` for data-heavy material, or
`swiss-minimal` for sparse architecture/method summaries.

## Anti-AI style rules

- Use hairline rules, tables, grids, axes, matrix boundaries, and flow arrows as
  semantic structure; avoid card grids as the default page language.
- Use color for role, evidence class, status, comparison, or emphasis. Do not
  assign a different decorative hue to every module.
- Avoid decorative glassmorphism, glow, floating shadows, translucent panels,
  inflated rounded rectangles, gradient blobs, and oversized meaningless
  numerals.
- Keep one boundary treatment for each information unit: whitespace, a rule, a
  light fill, or a line. Use two layers only when parent/child hierarchy is
  real.
- Prefer real PowerPoint tables, charts, diagrams, and editable shapes over
  screenshot-like decorative composites.
- Use footnotes, citations, source lines, figure/table captions, assumptions,
  and limitations where they clarify evidence.
- Preserve final wording, data, units, source labels, sequence, and relation.
  Reduce visual noise by simplifying effects, not by rewriting content.

## Academic/report page patterns

Use these patterns before marketing-style KPI cards:

- title + contribution + evidence boundary;
- method pipeline with inputs, processing stages, outputs, and validation;
- experiment/evaluation matrix;
- comparison table or ablation table;
- data-journalism small multiples;
- architecture diagram with owner/module correspondence;
- claim/evidence/limitation triad;
- result figure with caption, source, and interpretation;
- decision table with criteria and residual risk;
- conclusion slide with findings, implications, and next work.

## Validation heuristic

Before export, reject the draft style if most pages could be described as
"rounded cards with generic icons and decorative gradients" and no academic
evidence structure is visible. A valid academic/report deck should look like it
can enter a group meeting, thesis defense, technical review, or paper-style
research briefing without visual re-interpretation.
