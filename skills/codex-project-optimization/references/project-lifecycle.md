# Project Lifecycle Contract

## Files

- `.codex/project/REQUIREMENTS.md`: current goals, users, scope, constraints, acceptance criteria, and unresolved decisions.
- `.codex/project/WORKFLOWS.md`: verified build, test, release, Git, recovery, and recurring domain workflows.
- `.codex/project/EXPERIENCE.md`: project-only verified lessons and candidates.
- `.codex/project/RETROSPECTIVES.md`: append-only iteration evidence, deviations, wins, misses, and promotion candidates.
- `.codex/project/state.json`: lifecycle schema, initialization time, last observed Git head, and pending synchronization state.
- `.codex/project/pending-events.jsonl`: machine-written Git events awaiting Codex interpretation.
- `.codex/project/file-organization.json`: metadata-first organization policy, protected-path boundary, approval requirement, and taxonomy-evolution choices.
- `.codex/project/file-organization-review.json`: aggregate-only organization lifecycle result; never a file-name inventory or move manifest.

## First Use

Run `scripts/init-project.ps1 -ProjectRoot <root> -InstallGitHook`. It initializes the lifecycle policy and immediately runs a metadata-only organization review. Then inspect the project and replace generated unknowns with evidence. Do not invent requirements. Record unknowns as open questions.

## Git Event

After commit, merge, rebase, tag, release, or repository initialization:

1. Read pending events and `git status`, `git log`, and the relevant diff.
2. Update requirements when behavior or scope changed.
3. Update workflows when commands or operating steps changed.
4. Add verified project lessons and retrospective evidence.
5. Mark processed events in `state.json`, then truncate the event file only after durable updates succeed.
6. Promote only cross-project, verified, non-duplicate lessons to the global architecture.

## Complete Iteration

Append one retrospective with date, commit range, changed files, validation, deviations, wins, misses, surprises, and promotion candidates. Reconcile all four project documents. Update the owning global skill only when the lesson generalizes beyond this repository.

For each material follow-up, run the file-organization lifecycle review. Treat a category or naming change as a workflow change, validate handoffs to backup, knowledge, experience, and visuals, and only then retain, refine, add, merge, split, deprecate, or remove a taxonomy rule. A real move or rename remains separately user-approved and requires an off-root backup.
