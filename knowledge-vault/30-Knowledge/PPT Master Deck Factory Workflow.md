# PPT Master Deck Factory Workflow

Status: source-grounded adaptation.

Source: `hugohe3/ppt-master`, commit
`10f0adc0600ff28a470d55992133b1992c56968a`.

Additional material source: local `ppt-master-skill-v4.1.0` release package
stored under `.runtime/work/network-learning/ppt-master/`. It is a style,
template, icon, and reference-material source; the full route runtime still
comes from the learned upstream worktree and must be verified separately.

Full local repository corpus: `.runtime/work/network-learning/ppt-master/full-repo/workspace/ppt-master-main`.
Its archive is `.runtime/work/network-learning/ppt-master/full-repo/releases/ppt-master-main.zip`
with SHA256 `34283c7d885b71bac4d9c07b950dc2ac9ac3e5bf3621288ec3b1c308e5940dcf`.
The corpus is ignored runtime material for `ppt-deck-factory-agent`; it is not
canonical Git content.

## Local interpretation

The useful unit is a routed PPT manufacturing workflow for the Global Experience
Agent, not a new top-level global owner. The capability belongs under
`codex-office-cli`, with `ppt-deck-factory` as an owner-internal subskill and
bounded child-Agent profile.

## Learned method

1. Select exactly one artifact route before implementation:
   `generate-pptx`, `create-template`, `fill-native-pptx`, or
   `enhance-native-pptx`.
2. Treat a deck as a sequence of contracts and artifacts, not as a one-shot
   conversion.
3. Keep source facts, machine analysis, design contract, authoring state,
   derived preview, exported PPTX, and validation evidence separate.
4. Prefer editable PowerPoint depth over flattened slide screenshots.
5. Do not claim full runtime availability until the local worktree,
   dependencies, route scripts, and optional credentials are verified.
6. Let the Global Experience Agent delegate deck production as a bounded child
   task under `delivery-agent`, returning only evidence-bearing outputs.
7. Preserve PPT Master's route discipline locally: selected-route-only
   execution, serial phases, and no cross-phase artifact preparation before a
   gate closes.
8. Treat upstream blocking gates as local Agent exits for user taste,
   provider/paid calls, dependency installation, irreversible source mutation,
   Git, release, or publication.
9. Keep visual style, image rendering, and argument mode as separate locks.
10. For academic/report decks, default away from AI-looking product deck
    aesthetics. Prefer `data-journalism`, `editorial`, or `swiss-minimal`;
    emphasize semantic grids, tables, charts, method pipelines, captions,
    source lines, assumptions, and limitations; avoid generic rounded card
    grids, glass panels, glow, gradient blobs, and decorative icon tiles unless
    explicitly requested.
11. Preserve the parent-child decision boundary: the parent passes the complete
    demand packet and authority boundary, while the child selects topic
    framing, route, narrative thesis, slide outline, visual style, and
    template/materials unless the user explicitly fixed a decision.
12. Use larger default type for projected readability: titles 34-44 pt, section
    titles 26-34 pt, body text 18-24 pt, and non-essential source/footnote text
    10-14 pt. Hard-to-read screenshot/contact-sheet output is a failure signal.
13. Apply Darwin-style keep/revert learning after each deck: record the visual
    or workflow failure, the candidate rule, the fitness signal, and whether to
    keep or revert the rule.

## Agent use

The Global Experience Agent should retrieve this note and
`skills/codex-office-cli/subskills/ppt-deck-factory/SKILL.md` when a user asks
for AI-made PPT, native PowerPoint generation, deck regeneration, template fill,
template creation, narration, transitions, or PPT Master behavior.

For non-trivial PPT work, the parent Agent should delegate to
`ppt-deck-factory-agent` rather than performing the whole deck workflow inline.
The parent owns the durable session, authority snapshot, memory retrieval,
save-point alignment, and final join decision. The child owns the PPT route
plan, design contract, editable authoring workspace, export, validation, and
evidence report under `.runtime/work/agent-ppt-decks/<task-id>`.

The parent-child relation is intentionally asymmetric:

- Parent can delegate, complete, join, cancel, store memory, and route gated
  follow-up work.
- Child can read the PPT Master corpus and write deck artifacts inside its
  isolated surface.
- Child should study local main corpus files before non-trivial planning:
  `README.md`, `skills/ppt-master/SKILL.md`, routing workflow, selected route
  workflow, template guide when relevant, examples index, and style/diagram
  references.
- Child cannot commit, push, release, publish, install dependencies, use
  credentials, call paid external APIs, or mutate Agent structure.
- Merge is evidence-based: exported PPTX alone is insufficient without route,
  design, validation, and visual proof or residual-risk evidence.

## Boundaries

- Do not copy upstream examples, `.env`, credentials, or large runtime assets
  into Git.
- Do not auto-install dependencies or call external image/model/TTS services
  without the owning gate.
- Do not confuse raw PPTX template filling with full deck regeneration.
- Do not report success from an exported path alone; Office/PPT validation is
  part of delivery.
- Do not patch derived previews or exported PPTX when the authoring source is
  wrong; repair the owning source artifact and regenerate downstream outputs.
