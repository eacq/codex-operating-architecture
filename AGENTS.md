<!-- BEGIN MANAGED BLOCK: codex-project-lifecycle -->
## Codex Project Lifecycle

- At every project entry, invoke `$codex-self-evolution` to route the task and check lifecycle state.
- On first use, when `.codex/project/state.json` is absent, invoke `$codex-project-optimization` and initialize the project lifecycle before substantial work.
- Before planning or implementation, read `.codex/project/REQUIREMENTS.md`, `WORKFLOWS.md`, and relevant `EXPERIENCE.md` entries.
- After Git initialization, commit, merge, rebase, tag, release, or a complete verified iteration, invoke `$codex-git-operations` and `$codex-experience-capture`.
- Process `.codex/project/pending-events.jsonl`, then synchronize requirements, workflows, project experience, retrospectives, and lifecycle state.
- Keep project-specific knowledge in this repository. Promote only verified cross-project rules to the global Codex skills.
- Preserve user content outside this managed block and never store credentials or raw private session content.
<!-- END MANAGED BLOCK: codex-project-lifecycle -->
