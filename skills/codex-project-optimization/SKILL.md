---
name: codex-project-optimization
description: Initialize and improve any project using its requirements, source code, tests, logs, telemetry, documentation, Git history, and prior Codex sessions. Use on first Codex use in a project, when `.codex/project/state.json` is missing, when asked to optimize or document a project, after Git initialization or major Git events, and after a complete verified iteration that must synchronize requirements, workflows, project experience, retrospectives, and global skill candidates.
---

# Codex Project Optimization

Before editing, map entry points, data flow, ownership, tests, logs, and relevant history. Rank changes by impact, evidence, risk, and effort; preserve project conventions and unrelated user work. Compare verified results with a baseline and keep project facts in the project.

## Project lifecycle

Read [references/project-lifecycle.md](references/project-lifecycle.md) for first-use, Git-event, and complete-iteration requirements.

On first use, run:

```powershell
python scripts/initialize_project.py --project-root <project-root> --install-git-hook
```

Replace generated unknowns only with evidence. Preserve existing files and hooks. At lifecycle triggers, reconcile project documents before any global promotion.
