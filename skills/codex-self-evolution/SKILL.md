---
name: codex-self-evolution
description: Use at the start of work in any project to orchestrate the modular Codex operating architecture and improve it from verified experience. Always check project lifecycle state, then scale the workflow to the task. Also use when a request spans modules, asks to use Codex history or experience, reaches a Git milestone, completes a verified iteration, or coordinates requirements, execution, workflow, credentials, Git, installation, runtime environments, learning, packaging, project optimization, or cost.
---

# Codex Self Evolution

Treat `$ARCHITECTURE_ROOT` as canonical. Global skill paths are discovery interfaces, not editable copies.

## Route the task

1. Identify the project root and check `.codex/project/state.json`; invoke `codex-project-optimization` before substantive work when it is missing. Avoid lifecycle churn for trivial or read-only tasks.
2. Read the request and project authority files, then select only the needed modules. Before routing `codex-learning`, apply its evidence threshold: a concrete gap plus a qualifying project, network-currency, or user-recognized-capability signal. Do not treat conversational praise or a single turn as promotion evidence.
3. State material assumptions and acceptance criteria; execute and verify in proportion to risk.
4. At Git milestones or completed iterations, reconcile project requirements, workflows, experience, retrospectives, pending events, state, and file organization. Route initialization and material follow-up through `codex-file-organization`. A global iteration uses the isolated full-scope transaction, including evidence-based quarantined cleanup, post-replacement validation, and lifecycle writeback; a project operation remains limited by its scoped policy and approval boundary.
5. Route reusable outcomes to `codex-experience-capture`; route verified linked knowledge to `codex-knowledge-system`. After a learning pass, require `codex-architecture-iteration` to review owner overlap and an economy pass before any new, merged, split, deprecated, or deleted module is recorded.
6. Route unexpected module behavior to `codex-error-feedback` before promoting it as experience or changing a skill.
7. Route cloning, sharing, private-to-generic extraction, or first-use local configuration to `codex-skill-portability`.
8. Invoke `codex-architecture-iteration` only for evidence-backed module or contract changes.

For a completed verified iteration, assess the private auto-Git gate before ending: use it for a new/materially changed capability, validated repair, cross-module contract, or meaningful documentation maintenance only when the changed paths are separable from unrelated worktree edits. Route it to `codex-git-operations`; public pushes, tags, releases, and major-version decisions remain explicit user choices.

Before every Git commit, push, tag, release, or remote update, complete `scripts/Invoke-CompleteGlobalExperienceIteration.ps1 -Staged -Apply`, then run `scripts/Test-ExperienceIterationGate.ps1 -Staged -Apply` after staging. Before replacement the complete iteration must create an exact tracked/untracked rollback snapshot. A post-replacement failure must restore and verify that state, record the error, repair the owning workflow, and rerun from the beginning; a rollback failure blocks all Git work. The publication gate accepts only rollback-ready, cleaned, replaced, twice-revalidated, interface-validated, lifecycle-written proof and must never mutate the active repository itself.

If a Git commit, synchronization, tag, release, or push fails, create and repair every Git-process error report first. Then discard the failed attempt's plan as stale: recompute the scoped changed paths from the repaired worktree, regenerate documentation and version/release artifacts, stage the new exact set, and rerun the complete global iteration and integration gates before a new Git attempt. Never resume a failed Git action using an earlier staged-path proof.

Before that assessment, run `scripts/Sync-IterationDocumentation.ps1 -Apply` so the generated bilingual iteration status and required explanation files reflect the verified state. When a private skill has two independent verified use cases and no private-only purpose, route it to `codex-skill-portability` for a read-only public-conversion plan; apply conversion only after the sanitized candidate audit passes and retain original non-secret preferences solely in its local converted-skill profile. Route verified private experience and knowledge through `codex-knowledge-system`'s public-candidate converter under the same evidence rule.

After any verified workflow update, run `New-WorkflowLearningRecord.ps1`; route its knowledge and experience candidates to their owners and require architecture iteration to consider revision, merge, split, addition, deprecation, or deletion. Interpret the explicit command “同步经验系统” (or an unambiguous equivalent) as the private release gate and “发布经验系统” as the public release gate; both invoke `Invoke-ExperienceRelease.ps1` only after the full synchronization and validation path.

## Quality gate

Search indexes before raw history. Durable rules require evidence, scope, verification, and invalidation conditions; keep weaker observations as project candidates. Use `module-registry.json` for module lifecycle decisions and prefer an existing owner over overlap.

## Action notification policy

Ordinary in-scope files and skill synchronization need no separate prompt. Notify before external software or system changes; preserve higher confirmation boundaries for destructive, public, paid, privileged, or irreversible actions.

## Example

```text
At project start: read .codex/project/state.json, then route to codex-project-optimization only if it is missing.
```
