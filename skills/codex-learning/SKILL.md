---
name: codex-learning
description: Study tools, repositories, skills, workflows, docs, and failures, then convert verified findings into Codex practice changes.
---

# Codex Learning

This skill owns two subworkflows, not two new top-level skills: **project learning** and **network learning**. Both produce a dated learning record, a reversible change proposal, and a verification result; neither may promote raw conversation content, credentials, or a one-off preference.

## 1. Decide whether learning is warranted

The controller may open a learning pass only when it has a concrete capability gap plus one of these signals:

- **Project learning:** a named project has an experience/knowledge system, a reusable local skill, or at least two relevant completed artifacts; use it when its approach can resolve the current gap.
- **Network learning:** a maintained external source is likely to have changed the relevant practice, or local evidence shows a repeated gap with no adequate internal owner.
- **User-recognized capability:** the conversation contains an explicit acceptance signal (for example, the user asks to reuse, generalize, promote, or calls a workflow useful) *and* a second evidence source exists: a verified result, repeated use, project artifact, or independent source. Mere praise, a single successful turn, or an inferred preference is not consent to promote.

If no condition holds, record no learning action and continue the task. Learning must never delay a bounded user task unless the missing knowledge blocks a safe result.

## 2. Project learning

1. Read the target project’s requirements, workflows, experience, retrospectives, module/skill registry, and generated indexes before raw history.
2. Map each candidate practice to its trigger, inputs, outputs, owner, evidence, safety boundary, and validation.
3. Compare it with the global registry. Reuse an existing owner whenever the trigger, workflow, and maintained knowledge substantially overlap.
4. Extract only general rules. Keep project paths, claims, templates, private data, and unverified observations in the project.
5. Test a proposed adaptation in a reversible fixture or representative task, then send verified rules to experience capture and durable concepts to the knowledge system.

## 3. Network learning

1. State the gap, currency risk, evaluation rubric, and source class before browsing. Prefer primary documentation, standards, original research, and maintained upstream repositories.
2. Treat a source as a method system when appropriate, not only as a package of
   skills. Skills, workflows, knowledge records, experience patterns, scripts,
   manifests, release rules, setup docs, tests, terminology, and philosophy are
   all valid learning objects when they can improve the global experience
   system's terminal collaboration goal.
   Classify learned objects as information units, functional units, or
   bidirectional links between them. Human practice and ML/LLM/agent-system
   technical knowledge are both valid source directions, but neither bypasses
   owner fit, reversible adaptation, validation, or invalidation.
3. Extract the source's core philosophy before selecting tactics. If the source
   states its principles directly, cite the statement and compare it with local
   contracts. If it does not, infer the philosophy from README structure,
   workflow order, scripts, manifests, tests, failure modes, and safety
   boundaries; label the result as a local synthesis, not an upstream quote.
   A learning record is incomplete until it records this philosophy, its
   evidence basis, and where the philosophy is adopted, rejected, or kept as a
   guarded analogy.
4. Compare at least one authoritative source with the current local contract. Record date, URL/source, what is adopted, rejected, or deferred, and why.
5. Cross-link related knowledge, experience, and previous learning records
   instead of evaluating each source in isolation. Creative expansion is allowed
   as a guarded experiment when the source idea, local analogy, owner boundary,
   validation path, and invalidation condition are explicit.
6. Inherit principles critically: reject vendor-specific lock-in, unsafe autonomy, untestable claims, and guidance that conflicts with local privacy, confirmation, or evidence rules.
7. Decide whether to install anything. Learning does not forbid installation,
   but an external skill must pass a necessity, value, compatibility, and
   verification gate before installation. Prefer adapting the useful behavior
   into an existing owner, subskill, reference, or local profile; install only
   when that form is still the best fit for the user's workflow.
8. Clone or extract reviewed upstream repositories only under the configured
   Codex work root, resolved by `scripts/Resolve-CodexRunRoot.ps1 -Kind work`.
   Do not leave network-learning worktrees in OS Temp, Downloads, or user-home
   caches. If an external tool forces another location, record and clean or
   retain it as an exception.
9. Convert an adopted idea into a small reversible change plus an acceptance test. A source alone is a candidate, never a verified experience.

## 3A. Full historical relearning

When the user explicitly asks to relearn prior work broadly, or the Global
Experience Agent is running a `full` historical pass, use the owner-internal
`subskills/historical-learning-reconciliation/SKILL.md` workflow. “All prior
learning” means the current local source snapshots and their provenance, the
complete owner/subskill/upstream Skill surface, Agent and runtime manifests,
project requirements/workflows/experience, knowledge-vault records, installed
tool contracts, and the tests that prove their current adaptation. Do not
mistake an old summary, filename, or memory entry for a reread.

The pass is staged as inventory -> source/method reread -> local adaptation
comparison -> functional tests -> information/functional-unit reconciliation ->
knowledge and Agent-memory writeback. It may use local snapshots without a new
network download; current upstream claims still require a fresh source check.
Use `full` for coverage, while preserving the same evidence and quality gates
for `economy` and `balanced` execution versions. The pass must report stale,
guarded, missing, and verified surfaces separately and must not promote or
install anything merely because it was encountered historically.

## Update and re-learning authorization

Treat a newly discovered version, release, commit, or capability change in a
previously learned external MCP, skill, package, or project as a candidate, not
standing authorization. A user may ask for a read-only version check in a
specific task, but do not create periodic monitoring. Before downloading,
installing, upgrading, reconfiguring, or starting a substantive re-learning
pass that could change local skills, knowledge, workflows, or configuration,
report the detected change, proposed scope, and rollback boundary and obtain
explicit user authorization. Prior authorization for an earlier version does
not authorize a later update.

## 4. Architecture, knowledge, and experience handoff

After either pass, ask `codex-architecture-iteration` to review the owner relationship: revise an owner first; add a module only with two independent use cases and no clear owner; merge, split, deprecate, or delete only under the registry rules. Then run an economy pass: remove duplicated controller text, keep triggers and safety boundaries, and move durable concepts to the linked knowledge vault.

Use `codex-experience-capture` to classify results as verified lesson, candidate, stale evidence, or no action. Use `codex-knowledge-system` for linked, source-bearing concepts. Every learning record must include trigger, hypothesis, sources, comparison, decision, validation, scope, and invalidation condition.
