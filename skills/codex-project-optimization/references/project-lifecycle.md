# Project Lifecycle Contract

## Files

- `.codex/project/REQUIREMENTS.md`: current goals, users, scope, constraints, acceptance criteria, and unresolved decisions.
- `.codex/project/WORKFLOWS.md`: verified build, test, release, Git, recovery, and recurring domain workflows.
- `.codex/project/EXPERIENCE.md`: project-only verified lessons and candidates.
- `.codex/project/RETROSPECTIVES.md`: append-only iteration evidence, deviations, wins, misses, and promotion candidates.
- `.codex/project/state.json`: lifecycle schema, initialization time, last observed Git head, and pending synchronization state.
- `.codex/project/pending-events.jsonl`: machine-written Git events awaiting Codex interpretation.

## First Use

Run `scripts/initialize_project.py --project-root <root> --install-git-hook`. Then inspect the project and replace generated unknowns with evidence. Do not invent requirements. Record unknowns as open questions.

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
