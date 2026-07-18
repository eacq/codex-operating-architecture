---
name: codex-project-optimization
description: Own project-local lifecycle initialization and reconciliation. Use on first Codex use when `.codex/project/state.json` is missing, and after a verified iteration or Git lifecycle event that must synchronize requirements, workflows, experience, retrospectives, and pending events. Route general implementation, workflow design, research, and global promotion to their dedicated owners.
---

# Codex Project Lifecycle

This owner establishes and reconciles project-local lifecycle authority. It does
not own generic project diagnosis, implementation, workflow design, or global
experience promotion:

- `codex-self-evolution` chooses the smallest owner set at project entry.
- `codex-information-gathering`, `codex-task-execution`, and
  `codex-workflow-design` own evidence, changes, and repeatable operating work.
- `codex-experience-capture` decides whether a project result can become a
  cross-project lesson.

Preserve project conventions and unrelated user work. Keep project facts in the
project, and replace initialized unknowns only with local evidence.

## Project lifecycle

Read [references/project-lifecycle.md](references/project-lifecycle.md) for first-use, Git-event, and complete-iteration requirements.

On first use, run:

```powershell
python scripts/initialize_project.py --project-root <project-root> --install-git-hook
```

Replace generated unknowns only with evidence. Preserve existing files and hooks. At lifecycle triggers, reconcile project documents before any global promotion.

Initialization also creates `.codex/project/file-organization.json`. Run `codex-file-organization/scripts/Invoke-FileOrganizationLifecycle.ps1 -Phase project-initialization -Apply` after initialization and at material follow-up work. It automatically archives and safely processes eligible `00-inbox` items before validating affected configuration/reference changes; source and runtime paths stay outside the automatic managed scope.

## Reconciliation

At a completed iteration or processed Git event, reconcile project authority
files and pending events, then hand verified reusable outcomes to
`codex-experience-capture`. Do not absorb implementation or workflow ownership
merely because their results are recorded in project lifecycle files.
