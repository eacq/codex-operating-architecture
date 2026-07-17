---
name: codex-learning
description: Study related tools, repositories, skills, workflows, documentation, and failure reports, then convert findings into tested Codex practices. Use when the user asks Codex to learn from similar systems, compare approaches, prevent recurrence, or expand a module using external or local evidence.
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
2. Compare at least one authoritative source with the current local contract. Record date, URL/source, what is adopted, rejected, or deferred, and why.
3. Inherit principles critically: reject vendor-specific lock-in, unsafe autonomy, untestable claims, and guidance that conflicts with local privacy, confirmation, or evidence rules.
4. Decide whether to install anything. Learning does not forbid installation,
   but an external skill must pass a necessity, value, compatibility, and
   verification gate before installation. Prefer adapting the useful behavior
   into an existing owner, subskill, reference, or local profile; install only
   when that form is still the best fit for the user's workflow.
5. Convert an adopted idea into a small reversible change plus an acceptance test. A source alone is a candidate, never a verified experience.

## 4. Architecture, knowledge, and experience handoff

After either pass, ask `codex-architecture-iteration` to review the owner relationship: revise an owner first; add a module only with two independent use cases and no clear owner; merge, split, deprecate, or delete only under the registry rules. Then run an economy pass: remove duplicated controller text, keep triggers and safety boundaries, and move durable concepts to the linked knowledge vault.

Use `codex-experience-capture` to classify results as verified lesson, candidate, stale evidence, or no action. Use `codex-knowledge-system` for linked, source-bearing concepts. Every learning record must include trigger, hypothesis, sources, comparison, decision, validation, scope, and invalidation condition.
