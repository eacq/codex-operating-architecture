---
id: concept-matt-pocock-skills-method-system-relearning
type: concept

promotion_status: guarded
source: https://github.com/mattpocock/skills/tree/task/plugin-skills-dir-form;commit=c01d2b634689185203de52cfdc12b39b7ac0313d
verified: false
learning_audience: codex
codex_learning: Treat external skill repositories as whole method systems, not only SKILL.md collections. Learn their philosophy, workflow graph, docs, scripts, manifests, release boundaries, and failure-mode vocabulary; adapt only owner-compatible ideas as guarded experiments with local verification, never as raw installation or automatic authority.
---

# Matt Pocock Skills Method System Relearning

This network-learning pass reviewed `mattpocock/skills` branch
`task/plugin-skills-dir-form` at commit
`c01d2b634689185203de52cfdc12b39b7ac0313d` on 2026-07-21. The review treated
the upstream repository as a method system: skills, workflow graph, docs,
plugin manifests, changesets, scripts, setup records, deprecated/in-progress
areas, and the philosophy carried by its vocabulary.

## System Shape

The repository is bucketed by promotion state and use:

- `engineering/` and `productivity/` are promoted and shipped.
- `misc/`, `personal/`, `in-progress/`, and `deprecated/` are retained but not
  shipped through the plugin.
- The Claude plugin manifest exposes only the promoted buckets. The upstream
  ADR explicitly defers a native Codex plugin because a single recursive skills
  path cannot express "only these promoted buckets" without restructuring or
  duplicating the promoted set.
- The top-level README, bucket READMEs, docs pages, and `ask-matt` router are
  required to stay synchronized. A stale router is treated as misleading, not
  merely incomplete documentation.

Local interpretation: this reinforces the existing owner-economy rule. A
capability can be present without being promoted, user-facing, model-invoked, or
globally installed. Promotion should be a manifest and documentation invariant,
not a folder accident.

## Philosophy Learned

The strongest upstream idea is that a skill exists to make a stochastic agent
follow a predictable process. The repository uses several levers:

- **Invocation load tradeoff**: user-invoked skills spend human cognitive load
  and keep model context lean; model-invoked skills spend persistent context
  load but can be reached autonomously and by other skills.
- **Router as cognitive-load relief**: when user-invoked skills multiply, a
  router skill becomes the human-facing map. It should explain flows and
  neighbours, not execute everything itself.
- **Leading words**: compact concepts such as `tight`, `red`, `seam`, `tracer
  bullet`, `frontier`, and `fog` recruit model priors and reduce repeated prose.
- **Completion criteria before splitting**: premature completion is first fixed
  by sharpening the done condition; only split a sequence when later steps keep
  pulling the model forward.
- **No-op and negative-space audits**: every line should change behaviour. What
  a skill omits also delegates decisions to model priors; omissions should be
  deliberate branches, not accidental silence.
- **Map as index, not store**: large efforts use a low-resolution map pointing
  to decision tickets. Decisions live in one place, avoiding duplicated truth.

Local interpretation: these ideas are not automatically correct for this
architecture, but they are good experimental lenses for owner self-iteration,
global terminology, requirement briefs, and global-experience economy passes.

When a future source lacks a direct philosophy section, use this same pattern:
infer its philosophy from what the repository makes easy, what it forbids, what
it tests, what it packages, what it deprecates, and what vocabulary it repeats.
Record the inference as local synthesis rather than upstream doctrine, then
decide whether it is adopted, rejected, deferred, or used only as a creative
analogy.

## User Learning Requirement Captured

The user clarified that learning must not be isolated or limited to skills.
For this architecture, an external source can contribute through:

- skills and subskills;
- workflow shape and handoff order;
- knowledge organization and terminology;
- experience capture and promotion boundaries;
- scripts, tests, manifests, setup methods, and release mechanics;
- philosophy, design language, and failure-mode vocabulary.

The purpose of learning is to move the global experience system closer to its
terminal collaboration goal. A source idea may be wrong or incomplete and still
be useful as a guarded candidate, analogy, or experiment. Learning should cross
reference prior learning records and adjacent local knowledge so that the
system gains creative and interpretive capacity, not only a larger catalog of
copied procedures.

## Workflow Patterns

The visible upstream flow is:

1. A user-invoked router (`ask-matt`) helps the human choose a path.
2. A clarification primitive (`grilling`) resolves decisions one at a time;
   facts are looked up, decisions remain human-owned.
3. `grill-with-docs` pairs clarification with active domain modeling, updating
   glossary terms and sparse ADRs as decisions crystallize.
4. `to-spec` synthesizes current knowledge without re-interviewing.
5. `to-tickets` turns a spec or conversation into tracer-bullet vertical
   slices with blocking edges and frontier semantics.
6. `implement` builds from the agreed work, using `tdd` at pre-agreed seams and
   closing with `code-review`.
7. Hard bugs route through a tight red-capable feedback loop before hypotheses.
8. Huge foggy efforts route through `wayfinder`: decision tickets, research,
   prototypes, human-in-the-loop checkpoints, and a destination-scoped map.

Local interpretation: this overlaps with existing owners rather than requiring
new ones. It maps mainly to:

- `codex-requirement-authoring`: conversation-to-spec, project vocabulary,
  consequential decisions, and explicit human-owned decision boundaries.
- `codex-workflow-design`: dependency/frontier planning and wide-refactor
  sequencing.
- `codex-task-execution`: implementation, verification, handoff, and completion
  claims.
- `codex-error-feedback`: tight red-capable reproduction loops.
- `codex-architecture-iteration`: deep-module vocabulary, owner economy, and
  router/documentation freshness.
- `codex-knowledge-system`: source-bearing learning records and maps that index
  rather than duplicate truth.

## Script And Manifest Lessons

Useful script and packaging ideas:

- `scripts/list-skills.sh` is a tiny inventory front door: list every
  `SKILL.md` deterministically.
- `scripts/link-skills.sh` links skill folders into harness roots, detects a
  dangerous destination symlink back into the repo, and treats the script as a
  maintainer-only tool rather than a supported installer.
- The plugin manifest exposes promoted buckets, while `.changeset` records
  human-readable release intent. Release metadata is part of the method system.
- The Git guardrails skill demonstrates pre-tool command blocking for dangerous
  Git commands, but its direct hook installation and `jq` shell assumptions do
  not transfer directly to this Windows Codex Desktop architecture.

Local interpretation: script methods should be adapted as deterministic
validators, dry-run inventory tools, and manifest consistency checks. Do not
copy shell hooks or install plugin manifests without local authority and
platform-specific verification.

## Candidate Experiments For This Architecture

- **Invocation-load audit**: classify owner or subskill surfaces by user
  cognitive load versus model context load before adding more globally
  discoverable descriptions.
- **Router freshness gate**: when user-facing skill relationships change, test
  that the routing surface and docs still mention the changed skill and no stale
  route remains.
- **Promotion-bucket manifest**: distinguish promoted, experimental, personal,
  deprecated, and compatibility surfaces explicitly; validate that only promoted
  surfaces enter global install or public presentation.
- **Docs-as-router nodes**: for main user-facing workflows, keep a short
  human-facing page that explains what the workflow does, when to reach for it,
  and where it fits. Do not duplicate the operational `SKILL.md`.
- **Leading-word/no-op audit**: during owner self-iteration, scan long guidance
  for repeated prose that could become a stable term, and for instructions that
  do not change behaviour.
- **Negative-space review**: ask what decisions the guidance leaves to the
  model's priors; either make the branch explicit or document that it is
  intentionally open.
- **Frontier planning**: for very large global iterations, represent unresolved
  work as a map of decisions and blockers, not as a flat checklist.
- **Prototype-as-primary-source**: keep throwaway experiments outside the main
  line, but record the question answered and the decision extracted.
- **Learning workspace structure**: for user learning or system learning,
  separate mission, resources, learning records, lessons, reference documents,
  and reusable assets.

## Rejected Or Deferred

- Do not install the upstream repository or a plugin form now. No current task
  requires its runtime, and direct installation would add foreign invocation,
  hook, and update surfaces.
- Do not adopt direct `implement` auto-commit semantics. This architecture keeps
  commits behind complete iteration, metadata, privacy, staged-scope, and
  private-origin gates.
- Do not treat issue trackers as required global infrastructure. The local
  lifecycle files, Git gates, Codebase Memory graph, and candidate reports are
  the current canonical coordination surfaces.
- Do not copy Claude Code hook installation. The idea is useful, but local
  enforcement belongs in existing Git and publication gates.
- Do not promote "grilling every time" as an automatic rule. The local system
  already disabled automatic brainstorming; clarification remains bounded by
  real ambiguity or explicit user request.

## Cross-links

- [[Matt Pocock Skills Network Learning]]
- [[Project Vocabulary and Decision Brief]]
- [[Oh My Codex and OMX Lite Network Learning]]
- [[Learning Governance]]
- [[Global Experience System]]
- [[Subskill Packaging Boundary]]
- [[Codebase Graph Evidence Workflow]]
- [[Experience System Error Feedback]]
