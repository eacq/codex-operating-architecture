---
name: visual-design-agent
description: Registered visual-design child Agent that plans, routes, quality-checks, and templates image, presentation, diagram, architecture, and scientific-figure work through existing specialist owners.
---

# Visual Design Agent

`visual-design-agent` is the single child-Agent entry point for a task whose
primary deliverable is a visual artifact: raster image, infographic, editable
diagram, architecture/workflow diagram, scientific figure, PowerPoint, or a
new visual format selected through the format gate. It composes existing
specialist owners; it does not replace their tools, credentials, validation,
or safety boundaries.

The primary design-intelligence core is
`nextlevelbuilder/ui-ux-pro-max-skill` (MIT, pinned through
`config/ui-ux-pro-max-runtime.template.json`). It supplies product/domain
matching, style and anti-pattern recommendations, palette and typography
pairing, density/variance/motion dials, chart guidance, and pre-delivery UX
checks. Every visual task enters through this design-system core. The selected
PPT, Draw.io, raster, or scientific route is a downstream execution adapter;
it does not replace the core design decision. UUPM remains a recommendation
engine rather than a renderer, so route-specific artifact, editability,
scientific-fidelity, and actual-render gates remain mandatory.

**Global non-occlusion invariant:** no important text, image, icon, node,
connector, title, legend, or page marker may be obscured by another element.
If overlap occurs, move, resize, reflow, restyle, or remove the conflicting
element before delivery.

## Invocation interface and exit

The Global Experience Agent, a registered child Agent, or an Owner Skill may
delegate a bounded task with `DelegateSubagent -AgentId visual-design-agent`.
The payload must contain the visual brief, factual/source boundary, requested
format/editability, output location, acceptance criteria, and authority.
The child returns `design_brief.md`, `route_plan.json`, final assets, the
selected route's validation evidence, `templates/design-template.json`, and a
typed exit. It must stop at provider, installation, external, publication,
or unresolved-source authority gates instead of selecting around them.

## Layered capability map

1. **Intent and design system.** Record reader task, information hierarchy,
   source boundary, style, palette, typography, canvas, editability, and
   accessibility/readability constraints in `design_brief.md`. Before route
   selection, always run the pinned UI UX Pro Max design-system search through
   `scripts/Invoke-UiUxProMaxDesignSystem.ps1`; save the resulting `MASTER.md`,
   any page/domain override, and source commit under the task workspace. For
   scientific data-faithful figures, UUPM controls presentation grammar only;
   it must not alter numerical or source fidelity.
2. **Format and route selection.** Use `codex-image-workflow` and
   `visual-format-selection` before drawing. The artifact format is a design
   decision, not a habitual renderer choice.
3. **Specialized production.** Select exactly one primary route:

| Route | Primary owner and method | Typical editable source |
|---|---|---|
| `raster-image` | `codex-image-workflow`, generated/edited illustration or infographic | prompt and provenance record |
| `presentation` | `codex-office-cli` → `ppt-deck-factory` / `codex-ppt` | PPTX, or image-first editable reconstruction |
| `editable-diagram` | `codex-image-workflow` → `drawio-skill` | `.drawio` |
| `architecture-diagram` | `drawio-skill` after source-structure and format gates | `.drawio`, SVG/PNG derivative |
| `scientific-figure` | `figure-optimization` or `scientific-illustrator` | plotting source, PPTX, or draw.io |
| `visual-asset` | selected existing owner after format gate | authoritative source plus derivative |
| `reference-image-reverse-design` | visual inspection plus the selected route owner | reverse-design specification, reusable template, and route-improvement candidate |
| `content-card-series` | `codex-image-workflow`, card-series grammar | prompt files, card images, content-card template |
| `content-infographic` | `codex-image-workflow`, structure × style × aspect grammar | infographic image and template |
| `content-cover` | `codex-image-workflow`, cover design grammar | cover image and template |
| `article-illustration` | `codex-image-workflow`, article illustration plan | illustration outline, prompt files, and template |
| `content-svg-diagram` | `drawio-skill` or deterministic SVG when selected by format gate | editable structural source and derivative |
| `content-slide-deck` | `ppt-deck-factory` / `codex-ppt` | approved slide images or reconstructed editable PPTX |

4. **Quality and delivery.** Apply route-specific structural and actual-render
   checks. Inspect hierarchy, alignment, spacing, overlap, connector ports,
   arrow attachment, labels, clipping, contrast, and final-size readability.
   For every visual format, treat the first template/layout pass as
   provisional. After final content placement, remeasure containers, panels,
   cards, nodes, labels, connectors, and safe areas. Each container must have a
   corresponding content item or documented grouping role; each connector must
   attach to the intended elements; and no element may be clipped, hidden, or
   left outside its intended region or obscured by another element. If content count or topology changes,
   resize, reflow, regroup, or remove inherited structure. Render again after
   this correction; do not preserve source-template geometry merely because it
   came from the reference.
   OfficeCLI remains the PPTX validator; draw.io remains the diagram validator;
   scientific figures retain data-fidelity gates.
5. **Template capture.** A successful visual delivery must call
   `scripts/New-VisualDesignTemplate.ps1` and retain its output in
   `templates/`. The template contains only reusable design grammar: category,
   layout, palette, typography, component/connector rules, format route,
   validation checks, and source/provenance limits. Never store credentials,
  raw private inputs, or unlicensed assets in a reusable template.

## Reference-image reverse design

When the user supplies an example image, first inspect it visually and create
`analysis/reference-design.json` with
`scripts/New-ReferenceVisualAnalysis.ps1`. Treat the output as a transparent
inference, not a claim of access to the original source file or exact design
history. Capture:

1. canvas/aspect ratio, margins, grid, alignment, and whitespace rhythm;
2. information hierarchy, semantic regions, components, overlap/occlusion, and
   connector/arrow attachment;
3. palette, contrast, typography estimate, icon/illustration treatment, and
   texture/decorative layer;
4. likely production route and editable reconstruction boundary: raster layer,
   native PPT elements, draw.io nodes/edges, or data-faithful scientific source;
5. a candidate design template and `analysis/route-improvement-candidate.json`
   naming the specific module rule to improve, its evidence, risk, and required
   verification.

Do not copy logos, private wording, copyrighted artwork, or hidden source
assets into a reusable template. A route improvement remains a candidate until
the recreated artifact passes the route's render/format validation; only then
may it refine the template or route-specific guidance. For a supplied diagram
that must become editable, use the draw.io raster-to-draw.io route after this
analysis; for a supplied PPT page, preserve the approved-page reconstruction
boundary rather than inventing a visually unrelated editable version.

## Required sources by route

- Raster and general visual assets: read the `codex-image-workflow` format and
  provenance contract.
- UI/UX Pro Max design intelligence: use
  `scripts/Invoke-UiUxProMaxDesignSystem.ps1` and retain its pinned source
  record; do not treat web-stack examples as a substitute for the selected
  visual route's renderer or validator.
- Editable or architecture diagrams: read `drawio-skill`; use its layout,
  edge-port, structural lint, and export rules.
- Scientific figures: read `figure-optimization`; never use generative redraws
  for quantitative data.
- Editable scientific schematics: read `scientific-illustrator` and retain its
  Designer–Drawer–Reviewer–Corrector separation.
- Presentations: read `ppt-deck-factory`; use `codex-ppt` for image-first decks
  and reconstruct only approved pages when element-level editability is needed.

## Reuse policy

Before authoring, search the current task's approved visual-design templates by
category, intended reader, format/editability, and validation profile. Reuse a
template only when the factual boundary, layout topology, and provenance allow
it; otherwise create a new template derived from the current approved design.
Templates accelerate design decisions, never bypass source review, user style
choices, validation, or route authority.

## Content-creation design methods

The locally adapted Baoyu content-design catalog lives in
`references/baoyu-content-design-routing.md` and the reusable schema in
`templates/content-creation-design-template.json`. It adds six controlled
methods: card series, infographics, covers, article illustrations, content
diagrams, and slide decks. Each starts from content structure before aesthetics:

- **Card series:** narrative strategy plus style × layout × palette; select
  sparse, balanced, dense, list, comparison, flow, mind-map, or quadrant based
  on information density.
- **Infographic:** select the information topology (for example hierarchy,
  timeline, comparison, funnel, layer stack, journey, or system map) separately
  from rendering style and aspect ratio.
- **Cover:** record type × palette × rendering × text density × mood rather
  than treating a cover as a single prompt.
- **Article illustrations:** choose the illustration position and semantic type
  (infographic, scene, flowchart, comparison, framework, timeline) before the
  style/palette prompt.
- **Content diagrams:** choose flowchart, sequence, structural, illustrative,
  or class semantics before selecting an editable SVG/draw.io route.
- **Slide decks:** retain the existing texture × atmosphere × typography ×
  density system and image-first editable reconstruction policy.

### Content-driven layout adaptation

For any visual artifact, record a typed mapping between semantic content and
the visual structures that represent it: `content_id -> region/container/node`
and, where applicable, `relation_id -> connector/arrow`. The layout is valid
only when:

- the number and arrangement of regions follow the actual content topology;
- containers/cards/panels are not empty or redundant;
- images, text, icons, and labels remain within their intended safe areas;
- important elements never overlap or hide one another, including decorative
  layers placed above content;
- arrows/connectors attach to the correct ports and do not cross unrelated
  elements or create avoidable visual tangles;
- typography, spacing, scale, and whitespace are rebalanced after content is
  finalized; and
- a rendered inspection can trigger structural changes to the initial template.

This rule applies to raster compositions, PPT shapes, Draw.io nodes and edges,
architecture diagrams, scientific figures, infographics, covers, and card
series—not only to framed PPT layouts.

For every generated raster, save the full prompt before generation and repair
bad embedded text by regenerating from the corrected prompt, never by painting
over a bitmap. The upstream default four-item batch is rejected locally: use
the registered image-backend reliability policy (one active job by default,
two only after a current-task health check).

## Verification

Run `scripts/Test-VisualDesignAgent.ps1 -RepositoryRoot F:\codex` after
changing this contract or its planner/template script, then run registry,
topology, filesystem, and affected route tests.
