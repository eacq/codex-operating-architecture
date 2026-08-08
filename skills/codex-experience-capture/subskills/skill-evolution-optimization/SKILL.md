---
name: codex-experience-capture-skill-evolution-optimization
description: Optimize experience-system skills with Darwin-style review loops and SkillOpt-style strict-improvement gates.
---

# Skill Evolution Optimization

Use this subskill only through `codex-experience-capture` and the Global
Experience Agent entry path. It adapts the method, not the package shape, from
`alchaincyf/darwin-skill` commit
`7c7b7909b630dc3b5cbb91bd4bcb1b10bfb1f894` and `microsoft/SkillOpt` commit
`61735e3922efc2b90c6d6cab561e62e98452ca90`. It also adapts Brian Arthur's
technology-evolution model from the user-provided local EPUB stored for Agent
reuse under `F:/codex/book/技术的本质：技术是什么，它是如何进化的（经典版） (［美］布莱恩•阿瑟曹东溟　王健译) (z-library.sk, 1lib.sk, z-lib.sk).epub`.

## Trigger

Run when the user asks the experience Agent to improve, optimize, train,
evolve, judge, score, consolidate, or ratchet a skill or skill-like experience
record. Also run when external learning should become an operational skill and
the current evidence already passed methodology distillation. When the user
asks the experience Agent to learn from all local books, use the private book
shelf learning script below before proposing a skill candidate.

Do not run for a normal task execution, one-off document edit, unrelated code
refactor, raw upstream package installation, or a broad owner-architecture
change. Structural owner, topology, permission, interface, credential,
installation, release, and publication changes still route through their
existing gates.

## Core Model

Treat each `SKILL.md` as a small external state module for a frozen Agent. The
Agent can propose a candidate, test it, compare it against the current version,
and keep only a strictly better version. It cannot silently rewrite its own
structure, bypass owner gates, or treat an unverified candidate as promoted
knowledge.

The local loop is:

1. `harvest`: collect grounded evidence from successful/failed tasks, source
   repos, candidate reports, error feedback, and memory snapshots.
   For local books, run
   `scripts/Invoke-ExperienceBookShelfLearning.ps1 -RepositoryRoot F:\codex`.
   It scans the ignored `book/` shelf, parses readable EPUB/text sources,
   records PDF parser degradation explicitly, and writes only derived metadata
   and learning lenses under `.runtime/evidence/`.
2. `mine`: extract specific deltas: trigger, non-trigger, workflow step,
   failure guard, resource pointer, verification, or pruning.
3. `compose`: map the candidate through the technology-evolution lens below so
   it uses existing Agent components, names the phenomenon or effect it
   captures, and avoids creating a standalone module when a combination of
   current functional units is enough.
4. `propose`: stage exactly one candidate patch for exactly one `SKILL.md`,
   plus optional references or deterministic tests.
5. `score-current`: score the current skill against the local rubric and task
   evidence.
6. `score-candidate`: score the staged candidate with the same rubric and
   evidence.
7. `gate`: accept only if the candidate score is strictly higher, the safety
   checks pass, and no required human/owner checkpoint is unresolved.
8. `validate`: run the narrowest deterministic test for that skill plus any
   repository validation required by the touched owner.
9. `adopt-or-revert`: keep the candidate only after validation. Otherwise
   reject it, preserve the evidence, and use a recoverable Git revert or
   explicit patch reversal; never use broad destructive reset.
10. `consolidate`: record the accepted lesson, supersede stale records, update
   linked knowledge, and stop when marginal gain is low.

## Technology-Evolution Lens

Use this lens for Agent optimization after a source has been parsed and
grounded. It adapts Arthur's model that technology evolves through reusable
components, recursive assemblies, captured phenomena, domains, needs, and the
cycle where solutions create new problems.

- `component inventory`: identify the existing owners, subskills, scripts,
  policies, memory stores, and Agent runtime operations that can be recombined
  before inventing a new capability.
- `phenomenon capture`: name the real operational effect the Agent is trying to
  exploit, such as stable retrieval, strict improvement, scoped rollback,
  cross-caller continuation, or trigger precision.
- `recursive assembly`: define whether the candidate is a primitive, subskill,
  concept Agent, specialist Agent, child-Agent template, validator, knowledge
  note, or generated manifest. A higher-level assembly must cite its lower
  components and their owner gates.
- `domain grammar`: state the local domain that makes the component usable:
  Codex host, Windows filesystem, global-control interface, F-codex graph,
  skill frontmatter, Agent memory, Git/release gate, or document parse input.
- `need and niche`: tie the change to a concrete recurring need and its
  operating environment. Do not optimize for abstract elegance without a task
  pressure or failure pattern.
- `structural deepening`: when a broad skill repeatedly grows, split only the
  repeated mechanism into an owner-internal subskill, reference, script, or
  policy; preserve the parent as a routing surface.
- `problem cascade`: record any new coordination, validation, privacy,
  performance, trigger, or rollback problem created by the candidate and route
  it to the owning gate before adoption.
- `adjacent possible`: prefer the smallest next recombination that current
  evidence can validate. Larger architecture changes remain staged candidates
  unless `global-control` and the architecture owner authorize them.

## Book-Shelf Learning Lens

When `F:/codex/book` contains multiple local books, treat it as a private
multi-model learning corpus. The Agent learns from derived summaries, keyword
signals, title-level lenses, and verified parse statistics rather than copying
book text.

- `multi-model triangulation`: use books as different thinking models, not as a
  single authority. A skill change should state which model lens it uses and
  which neighboring lens could falsify or constrain it.
- `fast-slow split`: separate quick routing heuristics from slower validation,
  bias checks, and evidence gates.
- `role-separated review`: evaluate candidates through distinct roles for
  facts, risks, benefits, alternatives, process, and final synthesis.
- `complexity feedback`: inspect second-order effects, feedback loops,
  coordination cost, and emergent failure modes before adopting a capability.
- `analogy boundary`: analogies and abstractions may generate candidates, but
  adoption requires a local Agent-domain boundary and a deterministic test.
- `top-down delivery`: communicate the answer first, then evidence, caveats,
  and next boundary; preserve detailed evidence in artifacts.
- `parser degradation`: unreadable or metadata-only books remain candidates for
  runtime/tool improvement and cannot be treated as fully learned.

## Rubric

Score each dimension from 0 to 5 and record evidence for every non-zero score:

- `frontmatter`: valid minimal YAML, stable hyphen-case name, concise
  description, no hidden trigger broadening.
- `trigger_precision`: clear positive triggers, negative lures, and neighboring
  skill boundaries.
- `workflow_specificity`: ordered actions, inputs, outputs, stop conditions,
  and handoff artifacts.
- `failure_guards`: known failure modes, rollback boundary, stale conditions,
  and error-feedback route.
- `checkpoint_quality`: human/owner checkpoint only where authority or judgment
  actually changes the outcome.
- `resource_integration`: uses existing references, scripts, templates,
  manifests, Agent resources, and owner routes instead of duplicating content.
- `agent_alignment`: respects Global Experience Agent entry, save points,
  caller/model neutrality, interface policy, and child-Agent boundaries.
- `combinatorial_fit`: reuses and recombines existing Agent components,
  exposes recursive dependencies, names the captured phenomenon, and avoids
  unnecessary top-level module growth.
- `measured_effect`: cites a real validation, regression, fixture, or task
  result; dry-run-only evidence reduces confidence.
- `risk_blacklist`: rejects credential leaks, raw private sessions, platform
  lock-in, unmanaged installs, destructive operations, and gate bypasses.

## Gate Policy

Use `scripts/Invoke-SkillEvolutionOptimizationGate.ps1` for deterministic
candidate review when the change is more than a small wording edit.

- `candidate_score` must be greater than `current_score`.
- `candidate_score` must also be greater than or equal to `best_score` when a
  best-known score exists.
- Any failed safety check rejects the candidate regardless of score.
- A required human checkpoint pauses adoption until explicit current authority
  is recorded.
- A high dry-run ratio marks the result as candidate-only unless a real
  validation also passes.
- Only one primary `SKILL.md` is changed per optimization epoch. Supporting
  tests, references, and knowledge notes are allowed when they prove or explain
  that one skill change.

## SkillOpt-Sleep Adaptation

For background or delayed learning, do not mutate live skills directly. Stage a
proposal with source evidence, replay examples, candidate score, risk notes,
and validation commands. The Global Experience Agent may later resume the
session, re-run the gate against current files, and adopt only if the strict
improvement still holds.

## Darwin Adaptation

Use an independent review lens when available, but do not require a runtime or
subagent that is unavailable in the current host. If true parallel judging is
not available, separate the review pass from the proposal pass and make the
rubric evidence explicit. Preserve the Darwin keep/revert ratchet: accepted
changes must be reviewable; rejected changes must leave an auditable reason.

## Verification

Run:

```powershell
skills/codex-experience-capture/scripts/Test-SkillEvolutionOptimization.ps1 -RepositoryRoot F:\codex
skills/codex-experience-capture/scripts/Test-ExperienceBookShelfLearning.ps1 -RepositoryRoot F:\codex
```

For complete global iterations, also run Agent filesystem sync/tests and the
standard repository validation path required by the Global Experience Agent.
