---
name: codex-task-execution
description: Execute a scoped technical or operational task from requirements through implementation, verification, and handoff. Use when Codex must make changes, run commands, build artifacts, diagnose-and-fix an issue, or complete a multi-step request rather than only advise.
---

# Codex Task Execution

1. Inspect the target and preserve unrelated user changes.
2. Convert the request into a short internal checklist.
3. Make the smallest coherent change that meets acceptance criteria.
4. Use existing project patterns and tools.
5. Verify behavior, not only syntax or installation.
6. Report changed artifacts, validation, and remaining limitations.

Before claiming a task is fixed, complete, passing, or ready to publish, run
the narrowest command that proves the specific claim in the current task and
read its exit result. A previous validation, an expected result, or a delegated
report is not proof. This evidence gate complements existing project and Git
gates; it never authorizes a commit, push, release, or broader action.

For a compound task, use the smallest logical owner set. Each owner needs a
bounded scope, named output, shared acceptance criteria, and an isolated write
surface. Default to a single owner; parallel work is limited to independent
read-only work or non-overlapping writes and requires a named merge verifier.

For articles, social series, newsletter copy, educational explainers, cover
briefs, infographics, comics, or slide narratives, route through
[subskills/content-production/SKILL.md](subskills/content-production/SKILL.md).
It turns a source-backed brief into a reviewable content package and hands
visual, Office, citation, and publication work to their existing owners.

For a GitHub profile README or repository homepage that needs a read-only
audit, a whole-README redesign, or a bounded visual-asset set, route through
[subskills/github-readme-presentation/SKILL.md](subskills/github-readme-presentation/SKILL.md).
It adapts the installed `beautify-github-readme` workflow and the
`beautify-github-profile` reference collection without treating decoration,
third-party statistics, or publication as defaults.

For explicit durable finish loops, use
[subskills/persistent-completion-lite/SKILL.md](subskills/persistent-completion-lite/SKILL.md).
This mode increases persistence through checkpoints and verification, but does
not expand authority or auto-trigger from generic continuation wording.

Do not claim completion while required processes are running. Do not perform destructive or materially broader actions without authorization.

Ordinary in-scope file handling does not require a separate prompt. Notify the user before installing or upgrading external software, runtimes, system components, package managers, or system-changing dependencies. Keep higher-risk confirmation boundaries for destructive, public, paid, privilege-expanding, or irreversible actions.

Imported local compatibility modes live under `subskills/imported-codex-home/`; they remain owner-routed and inherit this execution and authorization boundary.
