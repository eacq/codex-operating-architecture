<!-- managed-source: $ARCHITECTURE_ROOT\config\global-AGENTS.md -->
# Global Codex Project Lifecycle

- At the start of work in any project, invoke `$codex-self-evolution` as the lifecycle controller before selecting narrower skills.
- Check `<project-root>/.codex/project/state.json`. If it is missing, invoke `$codex-project-optimization` and initialize requirements, workflows, experience, retrospectives, and lifecycle state before substantial project changes.
- Read project requirements, workflows, and relevant verified experience before planning or implementation. Project facts remain in that project.
- When the user reports an error, failure, missing behavior, or wrong result, invoke `$codex-error-feedback`: retain the redacted user wording, create a project error report, attempt only a safe targeted repair, verify it, and promote only verified lessons.
- After a Git initialization, commit, merge, rebase, tag, release, or complete verified iteration, invoke `$codex-experience-capture`, reconcile project lifecycle files, and process pending Git events.
- Promote only verified, non-duplicate, cross-project lessons into the canonical architecture at `$ARCHITECTURE_ROOT`; keep candidates and project-specific knowledge in the project.
- Global architecture skills under `$CODEX_HOME\skills` are discovery interfaces to `$ARCHITECTURE_ROOT\skills`. Edit, validate, version, and roll back them only through the canonical repository.
- Scale the lifecycle work to the task. A read-only or trivial request may only need the entry check; do not create unrelated project churn.
