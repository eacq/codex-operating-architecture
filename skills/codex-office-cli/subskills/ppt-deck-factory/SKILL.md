---
name: codex-office-cli-ppt-deck-factory
description: Owner-internal PPT child Agent using codex-ppt as the primary image-based deck workflow while retaining PPT Master routes for element-editable and native PowerPoint work.
---

# PPT Deck Factory

This subskill lets the Global Experience Agent manufacture PPT decks through
the `codex-office-cli` owner. Its primary new-deck workflow is the managed
`ningzimu/codex-ppt-skill` adaptation at
`subskills/imported-codex-home/ningzimu-codex-ppt/`, using approved full-slide
images, speaker notes, deterministic slide state, and final PPTX assembly. It
retains native/editable routes learned from `hugohe3/ppt-master` commit
`10f0adc0600ff28a470d55992133b1992c56968a`; the upstream clone is a local
runtime worktree, not a new top-level owner. The full PPT Master repository
downloaded by the user is stored as a local runtime corpus under
`.runtime/work/network-learning/ppt-master/full-repo/` and is controlled through
the child-Agent profile rather than copied into the canonical skill tree.

Use this subskill when the user asks to create, regenerate, beautify, fill,
template, narrate, or enhance a PowerPoint deck, or when the Global Experience
Agent delegates a bounded deck-production child task. Use `generate-image-pptx`
by default for a visually unified new deck. Select an editable/native route only
when the user explicitly needs element-level editability, native slide shells,
or native PowerPoint behavior. Do not use it for ordinary Word/Excel automation,
exact Word pagination, or simple screenshot insertion.

## Owner and Agent boundary

- Parent owner: `codex-office-cli`.
- Concept route: `delivery-agent`.
- Child-Agent profile: `visual-design-agent` as the bounded visual delivery
  child when a deck requires sustained planning, page authoring, export, and QA.
- Tool gates remain intact: dependency installation, credentials, image
  generation, web enrichment, Git, release, and publication stay with their
  existing owners.
- Built-in image generation is a registered execution capability, not extra
  authority. The child may use it only after backend approval and must keep the
  selected backend fixed for the deck.
- The child Agent never expands authority. It returns a project path, export
  path, validation evidence, unresolved manual decisions, and residual risks.
- PPT Master's relearned route discipline is preserved locally: select exactly
  one route, read only that route's authority, and do not prepare later-phase
  artifacts before the current gate is closed.
- Upstream `BLOCKING` user gates map to local authority gates. If a route needs
  a style choice, provider key, paid/external call, dependency install, or
  irreversible source mutation, stop at that boundary and return a typed Agent
  exit instead of deciding silently.
- The v4.1.0 release material package is a runtime learning/material source,
  not the full workflow runtime. Keep it under `.runtime/work/network-learning`
  and extract only lightweight style rules into this subskill.

## Parent-child delegation protocol

The Global Experience Agent is the only controller for this child profile. For
PPT work it should:

1. Run `StartWork` or `Resume` for the parent session and retrieve relevant
   records.
2. Read the delegated child state's `structural_optimization_snapshot`; require
   status `synchronized`, retain its baseline hash in route evidence, and use
   its `domain_adaptation`, `profile_fit_summary`, and `functional_effects` to
   translate shared learning into PPT-specific routing, source processing,
   template selection, rendering, readability review, recovery, and economy.
   Do not apply a learned rule just because it appears in the baseline; if it
   does not improve the current deck task, record a bounded skip reason.
3. Use `DelegateSubagent -AgentId visual-design-agent` with an isolated write
   surface such as `.runtime/work/agent-ppt-decks/<task-id>`.
4. Pass the full demand packet, source boundary, approval state, output
   expectations, acceptance criteria, and merge verification rule. The child
   selects the route unless the user explicitly fixed it.
5. Let the child produce only PPT artifacts and evidence: route plan, design
   contract, editable project files, exported PPTX, Office validation, visual
   proof or residual-risk note.
6. Call `CompleteSubagent` with repository-relative evidence, then
   `JoinSubagent` to accept or reject the child result.
7. Keep Git, release, publication, dependency installation, credentials,
   paid/external model or image calls, and Agent structure mutation outside the
   child; route those through their existing owners if separately authorized.
   Codex built-in image generation is not treated as a third-party paid API.

The child may read the full PPT Master repository for workflow and template
behavior, but it may not turn that repository into a second global entrypoint or
write large upstream examples into Git.
For default image-based decks, the child studies the managed `codex-ppt`
workflow. It studies the local PPT Master main corpus only for editable-page
reconstruction or an explicitly selected pure-native route, then cites the
studied corpus paths in the design contract.

## Required load order

1. Read this file.
2. For `generate-image-pptx` and `reconstruct-editable-pptx`, read
   [the managed codex-ppt skill](../imported-codex-home/ningzimu-codex-ppt/SKILL.md)
   and then its upstream `SKILL.md`. Follow its referenced phase documents as
   each gate is reached.
3. For an editable/native route, read
   [references/ppt-master-route-contract.md](references/ppt-master-route-contract.md).
4. For academic, research, technical report, thesis, defense, group-meeting, or
   evidence-heavy decks, read
   [references/academic-report-style-contract.md](references/academic-report-style-contract.md)
   before planning the design contract.
5. Read [references/ppt-child-agent-darwin-learning.md](references/ppt-child-agent-darwin-learning.md)
   for child autonomy, main-corpus study, readability, and Darwin-style
   keep/revert learning rules.
6. Run `scripts/Resolve-PptMasterWorkspace.ps1` only when the selected route
   needs the full PPT Master runtime.
7. Run `scripts/Resolve-AgentPptTemplateCatalog.ps1` when the task may reuse a
   local deck template, especially group-meeting, academic-report, or native
   template-fill work. The catalog exposes only validated local template
   candidates; the child still owns template choice unless the user explicitly
   fixed it.
8. Run `scripts/New-AgentPptDeckFactoryPlan.ps1` to create or preview the route
   contract before generation.
9. If actual `.pptx` delivery is requested, use the selected route and validate
   the produced PowerPoint through `codex-office-cli` delivery gates.

## Routes

Select exactly one route:

| Route | Use when | Output |
|---|---|---|
| `generate-image-pptx` | Default new deck when visual unity matters and individual slide elements need not remain editable | Approved full-slide images, speaker notes, recorded job state, and assembled PPTX |
| `reconstruct-editable-pptx` | User explicitly requires element-editable text, shapes, charts, or diagrams while retaining the approved codex-ppt page design | Approved image pages, an element manifest, and an editable PPTX reconstructed to match those pages |
| `generate-pptx` | Explicitly selected exceptional pure-native authoring workflow | New project with a design contract and exported editable PPTX |
| `create-template` | User asks for a reusable brand/layout/deck workspace | Template workspace, optional review PPTX |
| `fill-native-pptx` | User provides a raw PPTX shell/template and wants new content inserted while preserving native slide shells | Filled PPTX |
| `enhance-native-pptx` | Finished PPTX must keep visible slides stable while adding notes, narration, timings, or transitions | Enhanced PPTX |

Ambiguous "optimize this PPT" requests need one discriminator only: preserve
page count/order/wording and redesign, fill native slide shells, or preserve
visible slides and add behavior.

## Execution contract

For `generate-image-pptx`, follow the managed `codex-ppt` workflow exactly:

1. Draft and obtain approval for `outline.md`.
2. Confirm one visual direction and the image backend.
3. Generate exactly one representative sample slide and wait for approval.
4. Record the approved sample method in `deck_spec.json`, prepare per-slide
   prompt jobs, and delegate one slide job per available worker.
5. With Codex built-in image generation, default to one active slide job. Raise
   to at most two only after a successful current-task health check. If Codex
   reports `connection failed 5/5`, stop new dispatches, preserve completed
   slides, and retry only the affected slide once after the queue is idle.
6. The parent records each returned image with the bundled state scripts and
   visually checks text, overlap, arrow attachment, hierarchy, and style.
7. Write `speech.md`, assemble the PPTX, validate with OfficeCLI, and require an
   actual PowerPoint/Office render when available.

For `reconstruct-editable-pptx`, first complete the `codex-ppt` image workflow through approved page images, then use this locked-design reconstruction sequence:

1. Treat the approved `origin_image/slide_XX.png` pages as the visual source of truth. Do not create a parallel native design or reinterpret the composition.
2. Study the local PPT Master main corpus only for downstream reconstruction techniques, and cite the relevant paths.
3. Create `analysis/element_manifest.json` for every slide. Classify components as native text, native shape, connector, chart/table, or `image-layer`.
4. Recreate semantic text, shapes, connectors, charts, and tables as native PowerPoint elements aligned to the approved page. Keep complex raster illustration as an independently editable `image-layer`; never misrepresent it as a native shape.
5. Export the editable PPTX, render it with an actual Office renderer, and compare it with the approved image for positions, spacing, hierarchy, connector attachment, and clipping. Record the comparison in `validation/reference-render-comparison.md`.
6. Validate with OfficeCLI, repair the native authoring source when comparison or validation fails, then rerender before delivery.

For exceptional pure-native `generate-pptx`, use this sequence:

1. Receive the full demand packet from the parent Agent. The parent may pass
   user constraints, sources, output limits, and authority boundaries, but it
   must not choose the topic, thesis, slide outline, route, style, or template
   unless the user explicitly fixed that decision.
2. Perform the main-corpus study pass from
   `references/ppt-child-agent-darwin-learning.md`: read local PPT Master main
   corpus files relevant to the request, then cite those paths in the design
   contract.
3. Confirm source facts and factual gaps.
4. Create a project workspace under a task-local output root.
5. Write a design contract before drawing slides: audience, narrative goal,
   route, canvas, page count, visual style, source boundary, assets, charts, and
   export expectations.
6. Author visible slide designs as an editable intermediate, not a flattened
   screenshot-only deck.
7. Run the readability gate: titles default 34-44 pt, section titles 26-34 pt,
   body text 18-24 pt, and essential content must not fall below 18 pt.
8. Run the narrowest quality gate available before export.
9. Export an editable `.pptx`.
10. Run OfficeCLI validation: save, validate, view issues/text, and visual check
   when available. For a text-bearing ellipse or oval, require **CLI-render
   agreement**: `view issues` must report no overflow and an actual PPTX render
   must show the same text without clipping. If the two disagree, repair the
   authoring source before delivery; use a rounded rectangle or separate
   text/container geometry when that preserves the intended semantics.
11. When PowerPoint, LibreOffice, OfficeCLI, or another actual Office renderer
    can export slides, create the final contact sheet from that real PPTX
    render. A hand-drawn PIL/SVG/mock preview is an authoring aid only; it is
    not final readability proof because PowerPoint text wrapping, font metrics,
    margins, and auto-fit can differ.

For direct native-PPTX routes, preserve the declared mutation model. Do not
silently switch from native filling/enhancement to full visual regeneration.
For every route, repair the owning source artifact rather than patching a
derived preview or exported PPTX when the upstream source is wrong.

## Dependency and runtime rule

The learned upstream runtime can be large and dependency-heavy. Do not claim
that full PPT Master execution is available until:

- the local worktree resolves to the learned commit or a consciously accepted
  newer commit;
- required Python dependencies are importable in the selected runtime;
- the chosen route's script entrypoints exist;
- any external model/image/search/TTS credentials needed by the selected route
  are present or the route explicitly avoids them.

When dependencies are missing, produce the plan and route contract, then hand
installation to `codex-runtime-environments` or `codex-tool-installation` only
under current user authority.

## Output standard

The final deck must be reviewable. `generate-image-pptx` is image-based and
must not be described as element-editable. `reconstruct-editable-pptx` may
claim element-level editability only for components recorded as native in its
element manifest; raster artwork remains an editable image layer.
A successful delivery report
names:

- selected route and why;
- source files and factual boundary;
- design contract path;
- project workspace path;
- exported `.pptx` path;
- validation commands and result;
- route-specific evidence: `outline.md`, `deck_spec.json`, `slide_jobs.json`,
  `origin_image/`, and `speech.md` for `generate-image-pptx`; plus
  `analysis/element_manifest.json` and `validation/reference-render-comparison.md`
  for `reconstruct-editable-pptx`; editable authoring sources for pure-native routes;
- known limits, such as missing image credentials, unsupported native features,
  or unverified visual rendering.

## Style realism gate

For academic/report decks, run the `academic-report` style realism gate. The
default style family is `data-journalism`, `editorial`, or `swiss-minimal`.
Avoid defaulting to `soft-rounded`, `glassmorphism`, large decorative KPI
cards, glow, gradient blobs, and icon-card grids. Prefer editable tables,
charts, matrices, method pipelines, source lines, captions, limitations, and
semantic rules. The deck should read as a research briefing or technical review,
not a marketing-style AI deck.

## Readability and Darwin learning gate

The child Agent must optimize for projected readability. If a generated deck's
contact sheet shows small or hard-to-read body text, repair the owning
authoring source and regenerate; do not merely accept the export. Preserve these
defaults unless the user provides a denser publication-style constraint:

- title text: 34-44 pt;
- section title: 26-34 pt;
- body text: 18-24 pt;
- caption/source/footnote text: 10-14 pt only when non-essential.

Final readability evidence must use actual PPTX rendering whenever a local
Office renderer is available. If the child can only produce a surrogate preview,
the delivery report must mark visual proof as residual risk and must not claim
that text overflow, wrapping, or cropping has been fully ruled out.

For a text-bearing ellipse or oval, do not accept either OfficeCLI inspection
or the actual render alone: require both to agree on no overflow. On a
disagreement, replace the text-bearing ellipse with a rounded rectangle or
decouple its text before rerunning the paired checks.

Use the Darwin ratchet after each deck: record the failure signal, candidate
rule, fitness signal, and keep/revert decision. Current accepted rules are:
larger type by default, full demand transfer to the child, mandatory local main
corpus study for non-trivial decks, actual-render screenshot/contact-sheet
readability as a validation signal, surrogate previews as non-final evidence
only, and paired CLI-render agreement for text-bearing ellipses or ovals.

## Verification

After changing this subskill or its scripts, run:

```powershell
skills/codex-office-cli/subskills/ppt-deck-factory/scripts/Test-AgentPptDeckFactory.ps1 -RepositoryRoot F:\codex
```

For Global Experience Agent integration, also run Agent topology/filesystem
tests and the repository validation gate.
