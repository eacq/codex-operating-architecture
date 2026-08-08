# PPT Master Route Contract

Source: `hugohe3/ppt-master` at commit
`10f0adc0600ff28a470d55992133b1992c56968a`.

Additional local material source: `ppt-master-skill-v4.1.0` release package
stored under `.runtime/work/network-learning/ppt-master/`. This package is used
as a style/template/material learning source, not as proof that the full
upstream workflow runtime is installed.

Full local repository corpus: `.runtime/work/network-learning/ppt-master/full-repo/workspace/ppt-master-main`,
with archive `.runtime/work/network-learning/ppt-master/full-repo/releases/ppt-master-main.zip`
and SHA256 `34283c7d885b71bac4d9c07b950dc2ac9ac3e5bf3621288ec3b1c308e5940dcf`.
This corpus is a controlled runtime/reference surface for
`ppt-deck-factory-agent`, not tracked canonical architecture content.

This is a local adaptation for the Global Experience Agent. It preserves the
useful method without copying the upstream runtime into the canonical skill
tree.

## Adopted principles

1. A deck is an Agent workflow, not a single file conversion.
2. Route selection is the first correctness boundary.
3. Editable PowerPoint depth matters more than decorative slide screenshots.
4. Source facts, design plan, authored slide state, derived preview, and final
   PPTX must remain separate artifacts.
5. The selected model affects quality, but deterministic tools own conversion,
   packaging, validation, and recovery.
6. A generated deck is a high-quality editable draft; final taste judgment
   remains reviewable.
7. The selected route is the only active authority. Do not load or execute a
   second top-level route after routing unless the user changes the task.
8. Blocking upstream gates become local Agent exits. The Agent may continue
   through non-blocking deterministic steps, but it must stop before user
   taste, credential, paid/external, installation, or irreversible boundaries.
9. Deck-wide visual style, image rendering, and argument mode are separate
   locks. Do not let palette, illustration rendering, or decorative material
   override the content's report style.
10. Academic/report decks use a style realism gate: evidence structure first,
    decoration second.

## Route matrix

| User request | Route | Mutation boundary |
|---|---|---|
| Create a new deck from topic/material | `generate-pptx` | Re-outline and redesign into a new deck |
| Create a reusable brand/layout/deck system | `create-template` | Build a reusable workspace, do not mutate references |
| Fill a provided PPTX template with new content | `fill-native-pptx` | Clone/fill native slide shells |
| Add notes, narration, timings, or transitions to finished PPTX | `enhance-native-pptx` | Preserve visible slides and patch native behavior |
| Beautify but preserve page count/order/wording | `generate-pptx` with `beautify` profile | Regenerate visual design with content lock |

## Artifact model

Use these roles even when a local implementation is lighter than upstream:

- `sources/`: factual source material.
- `analysis/`: machine-readable facts and import/intake evidence.
- `design_contract.md` or `design_spec.md`: human-readable deck strategy.
- `spec_lock.md` or route plan JSON: execution anchor.
- `authoring/` or `svg_output/`: visible slide author source.
- `preview/` or `svg_final/`: derived visual preview.
- `exports/`: final PPTX deliverables.
- `validation/`: source, visual, package, and Office validation evidence.

Never repair a derived preview when the authoring source is wrong. Never treat
an exported `.pptx` path alone as proof of delivery.

## Gate model

Route work proceeds serially:

- `routing`: select one route from the current request and available inputs.
- `contract`: write the design or template contract before slide authoring.
- `authoring`: produce editable source slides or native PPTX mutations.
- `preview`: derive SVG/screenshot/visual review artifacts from the authoring
  source.
- `export`: package editable `.pptx`.
- `validation`: run OfficeCLI validation and record residual risks.

Do not bundle a later phase across an unresolved gate. When a gate is blocked,
return the blocking decision and next authority boundary to the root Agent save
point.

## Style realism gate

For academic, research, technical-review, thesis, defense, group-meeting, and
evidence-heavy decks, read
`references/academic-report-style-contract.md` and expose the following in the
route plan:

- `style_realism_gate: academic-report`
- `recommended_visual_styles: data-journalism, editorial, swiss-minimal`
- `avoid_visual_styles_by_default: soft-rounded, glassmorphism, dark-tech`
- `anti_ai_style_rules`
- `academic_report_style_rules`

The route may still use another visual style when the user explicitly requests
it, but the design contract must state that choice and its tradeoff. The default
academic/report deck should use editorial rules, dense but legible data
structures, real tables/charts/diagrams, citations or source lines where
needed, and restrained boundaries. It should not be dominated by generic
rounded cards, gradient glass panels, glow, or decorative icon tiles.

## Global Experience Agent adaptation

The Agent should pass the complete demand packet to the child and then let the
child call the route planner. If the task is large or long-running, it may
delegate a bounded `ppt-deck-factory-agent` child with:

- original user request and full demand packet;
- source paths and source boundary;
- output root and page-count/output constraints;
- user-stated style preferences and dislikes;
- hard constraints and unresolved decisions;
- authority and dependency state;
- validation expectations;
- merge disposition for produced files.

The parent must not pre-select the deck topic, narrative thesis, slide outline,
visual style, template, or route unless the user explicitly fixed that choice.
Those decisions belong to the child and must be written into `route_plan.json`
and `design_contract.md`.

Before non-trivial planning, the child studies the local PPT Master main
corpus: `README.md`, `skills/ppt-master/SKILL.md`,
`skills/ppt-master/workflows/routing.md`, the selected route authority,
`docs/templates-guide.md` when relevant, `examples/examples.json`, matching
example folders, and style/diagram references under `references/`. It cites the
studied corpus paths in the design contract.

The child also applies a readability gate before export: titles default to
34-44 pt, section titles 26-34 pt, body text 18-24 pt, and captions/sources may
use 10-14 pt only when non-essential. A hard-to-read contact sheet requires
authoring-source repair and regeneration.

The child returns only evidence-bearing outputs. It must not commit, publish,
install dependencies, call paid external APIs, or mutate unrelated Agent
structure unless a separate owner gate authorizes that operation.

## Parent-child delegation protocol

The parent Global Experience Agent owns session identity, authority snapshot,
caller/model continuity, memory retrieval, save point, and final merge decision.
The `ppt-deck-factory-agent` child owns only deck-production execution inside
the delegated write surface. The required handoff is:

1. `DelegateSubagent` with `AgentId ppt-deck-factory-agent`, complete demand
   packet, isolated write surface, acceptance criteria, and merge verification
   rule. The parent passes constraints and evidence boundaries, not a preferred
   theme or outline.
2. Child reads this route contract, the PPT Deck Factory skill, the academic
   style contract when applicable, the Darwin learning contract, and the full
   PPT Master repository only as a local corpus.
3. Child writes route/design/authoring/export/validation evidence under the
   delegated surface.
4. Parent calls `CompleteSubagent` with repository-relative evidence and then
   `JoinSubagent` to accept or reject it.

Denied child actions are Git, release, publication, credentials, dependency
installation, Agent structure mutation, paid external APIs, and unbounded web
enrichment. These remain owner-gated parent-level actions.

## Rejected or guarded upstream behavior

- Do not surface sponsor/provider recommendations unless the user asks.
- Do not install upstream dependencies automatically from a global task.
- Do not copy large examples, credentials, `.env`, or local projects into Git.
- Do not claim arbitrary SVG-to-PPTX or arbitrary OOXML support; the supported
  route is constrained by the active implementation and validation evidence.
- Do not default web research, image generation, narration, or visual review
  into every deck. Trigger them only from user intent or route necessity.
