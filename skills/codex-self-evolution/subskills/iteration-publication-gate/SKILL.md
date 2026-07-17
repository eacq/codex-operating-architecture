---
name: codex-self-evolution-iteration-publication-gate
description: Owner-internal subskill for verified-iteration closeout, Git/publication gates, documentation synchronization, workflow-learning records, and release command routing.
---

# Iteration Publication Gate

Use this subskill only through the parent `codex-self-evolution` owner.

## Verified Iteration Closeout

Before assessing private auto-Git, run
`scripts/Sync-IterationDocumentation.ps1 -Apply` so bilingual iteration status,
README, changelog, release metadata, and required explanations match the
verified state.

After any verified workflow update, run
`skills/codex-knowledge-system/scripts/New-WorkflowLearningRecord.ps1`. Route
knowledge and experience candidates to their owners, then require
`codex-architecture-iteration` to consider revision, parent-skill refinement,
subskill packaging, merge, split, addition, deprecation, or deletion.

## Git And Publication Gate

Before every Git commit, push, tag, release, or remote update:

1. Complete `scripts/Invoke-CompleteGlobalExperienceIteration.ps1 -Staged -Apply`.
2. Stage exact scoped paths.
3. Run `scripts/Test-ExperienceIterationGate.ps1 -Staged -Apply`.
4. Confirm the proof matches current HEAD and exact staged paths.

For a completed verified iteration, assess the private auto-Git gate only for a
new or materially changed capability, validated repair, cross-module contract,
or meaningful documentation maintenance. Changed paths must be separable from
unrelated worktree edits. Route the decision to `codex-git-operations`.

Public pushes, tags, releases, and major-version decisions remain explicit user
choices.

## Failed Git Attempt

If a Git commit, synchronization, tag, release, or push fails, create and repair
every Git-process error report first. Discard the failed attempt plan as stale:
recompute scoped changed paths from the repaired worktree, regenerate
documentation and version/release artifacts, stage the new exact set, and rerun
all applicable gates. Never resume a failed Git action using earlier staged
content or an earlier iteration proof.

## Release Commands

Interpret an explicit user command meaning "sync the experience system" as the
private release gate, and an explicit user command meaning "publish the
experience system" as the public release gate. Both invoke
`Invoke-ExperienceRelease.ps1` only after full synchronization,
workflow-learning review, documentation alignment, scoped-path selection,
validation, and explicit `-Apply`.

## Public Conversion

When a private skill, knowledge item, or experience candidate has two
independent verified use cases and no private-only purpose, route it to
`codex-skill-portability` or `codex-knowledge-system` public-candidate
conversion in read-only mode first. Apply conversion only after sanitized audit
passes. Preserve non-secret local preferences only in a local converted-skill
profile.
