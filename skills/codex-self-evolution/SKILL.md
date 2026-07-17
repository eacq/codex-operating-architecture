---
name: codex-self-evolution
description: Use at the start of work in any project to orchestrate the modular Codex operating architecture and improve it from verified experience. Always check project lifecycle state, then scale the workflow to the task. Also use when a request spans modules, asks to use Codex history or experience, reaches a Git milestone, completes a verified iteration, or coordinates requirements, execution, workflow, credentials, Git, installation, runtime environments, learning, packaging, project optimization, or cost.
---

# Codex Self Evolution

Treat `$ARCHITECTURE_ROOT` as canonical. Global skill paths are discovery
interfaces, not editable copies. This parent skill is the routing surface; long
iteration, diagnosis, publication, and release gates live in owner-internal
subskills.

## Route The Task

1. Identify the project root and check `.codex/project/state.json`; invoke
   `codex-project-optimization` before substantive work when it is missing.
   Avoid lifecycle churn for trivial or read-only tasks.
2. Read the request and project authority files, then select only the needed
   modules. Open `codex-learning` only for a concrete gap plus qualifying
   evidence.
3. State material assumptions and acceptance criteria; execute and verify in
   proportion to risk.
4. At Git milestones or completed iterations, reconcile project requirements,
   workflows, experience, retrospectives, pending events, state, and file
   organization. For complete global iterations, read
   [subskills/global-iteration-gate/SKILL.md](subskills/global-iteration-gate/SKILL.md).
5. Route reusable outcomes to `codex-experience-capture`; route linked concepts
   to `codex-knowledge-system`. After learning or workflow changes, require
   `codex-architecture-iteration` to review owner overlap and economy.
6. Route unexpected module behavior to `codex-error-feedback` before promoting
   it as experience or changing a skill. Cross-project failures with suspected
   global causality mirror only a redacted summary into the architecture inbox.
7. Route cloning, sharing, private-to-generic extraction, or first-use local
   configuration to `codex-skill-portability`.
8. Invoke `codex-architecture-iteration` only for evidence-backed module,
   parent-skill, subskill, or contract changes.

For verified iteration closeout, Git/publication gates, failed Git attempts,
continuous diagnosis, workflow-learning records, documentation synchronization,
public/private conversion, and release command routing, read
[subskills/iteration-publication-gate/SKILL.md](subskills/iteration-publication-gate/SKILL.md).

## Quality Gate

Search indexes before raw history. Durable rules require evidence, scope,
verification, and invalidation conditions; keep weaker observations as project
candidates. Use `module-registry.json` for lifecycle decisions and prefer an
existing owner over overlap.

## Action Notification Policy

Ordinary in-scope file edits, skill synchronization, generation, and validation
need no separate prompt. Notify before external software or system changes;
preserve higher confirmation boundaries for destructive, public, paid,
privileged, credential, or irreversible actions.

## Example

```text
At project start: read .codex/project/state.json, then route to codex-project-optimization only if it is missing.
```
