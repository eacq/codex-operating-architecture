---
name: codex-git-operations
description: Diagnose and perform safe Git and GitHub operations on Windows or other local workspaces, then synchronize project lifecycle knowledge. Use for enabling Git, repository-root problems, status, branches, commits, merges, rebases, tags, releases, remotes, GitHub CLI authentication, pushes, pull requests, merge conflicts, repository bootstrap, or any Git milestone that should trigger project requirements, workflow, retrospective, and experience updates.
---

# Codex Git Operations

On Windows, diagnose in this order:

1. `git --version`
2. `where.exe git`
3. `git rev-parse --show-toplevel`
4. `git status --short --branch`

Inspect remotes and authentication separately. A missing remote is not an auth failure. Preserve unrelated changes and use non-interactive commands. Never use destructive reset or checkout without explicit authorization. Before committing, review the diff and scan for secrets. Use the `codex/` branch prefix unless the user specifies another convention.

## Publication descriptions

Before every non-merge commit, update `CHANGELOG.md` and run
`scripts/Test-GitPublicationMetadata.ps1 -RepositoryRoot <root> -Staged`.
When auto-Git changes `VERSION`, generate or verify the matching changelog
section with `skills/codex-git-operations/scripts/Update-ExperienceChangelog.ps1`.
First run `scripts/Invoke-CompleteGlobalExperienceIteration.ps1 -RepositoryRoot <root> -Staged -Apply`, which must prove exact pre-iteration rollback readiness and complete isolated organization, cleanup, replacement, post-replacement validation, and lifecycle writeback. Any failed attempt must restore/verify the prior tracked and untracked worktree, repair the owning error, discard stale staged proof, and rerun completely before Git resumes. Then run `scripts/Test-ExperienceIterationGate.ps1 -RepositoryRoot <root> -Staged -Apply`; the review gate reads that proof without mutating the active repository.

## Failure recovery

On any Git-process failure, create or update the redacted `codex-error-feedback` report and resolve every Git-process report to `fixed` or `verified` before retrying. Do not reuse a failed commit, synchronization, or release plan. Recalculate the repaired worktree's complete scoped paths, regenerate changelog/documentation/version artifacts, stage that new set, and rerun full validation, global iteration, integration, metadata, privacy, and visibility checks as applicable. Release automation rejects unselected repaired paths so a stale retry cannot omit a fix.
For experience-system release sync, `Invoke-ExperienceRelease.ps1` must derive
the actual commit set through `Resolve-ExperienceReleasePathSet.ps1` after
release notes, README blocks, changelog, visual plans, and iteration status are
regenerated. The release scope may include context paths, but the commit step
receives only currently changed or untracked paths; any dirty path outside the
scope blocks the sync with the exact missing path list.
Update `README.md` or the matching `docs/` guide whenever the public workflow,
installation, configuration, or safety boundary changes. A version/tag/release
also requires `VERSION` and `docs/release-notes/v<version>.md`. See
`docs/GITHUB-PUBLISHING.md`; never put secrets or private session data in any
GitHub-facing description.

## Verified private auto-Git

Use `scripts/Invoke-VerifiedPrivateCommit.ps1` after a complete verified iteration when a new or materially changed capability, validated repair, cross-module contract, or meaningful documentation update has a scoped path set. The controller recommends `minor` for compatible functionality and `patch` for fixes or documentation; `major`, public pushes, tags, releases, and mixed worktree changes always require separate explicit direction. `Invoke-CompleteGlobalExperienceIteration.ps1 -Staged -AutoCommit -Apply` may automatically create a local commit only after that same verified iteration proves the exact staged scope; it uses `-CommitOnly`, so it never pushes, tags, or releases. The script confirms `origin` is private through GitHub CLI, stages only explicit paths, validates metadata, commits, and stores checkpoints. Read `docs/AUTO-GIT-PRIVATE.md` for the bilingual contract.

## Experience version and release commands

Use `Get-ExperienceVersion.ps1` as the sole four-part `P.R.A.B` calculator: public release controls `P`, private release controls `R`, automatic capability/architecture iterations increment `A`, and automatic fixes/documentation/refinements increment `B`. Read `docs/EXPERIENCE-VERSIONING.md`. Interpret an explicit “同步经验系统” command as `Invoke-ExperienceRelease.ps1 -Mode Private` and an explicit “发布经验系统” command as `-Mode Public`; both require scoped paths, full validation, synchronized workflow-learning and documentation, and their own `-Apply`. Private tags use `private-vP.R`; public tags use `vP.R`.

## Route and checkpoint

Every private or public release must run `skills/codex-git-operations/scripts/Update-ReleaseReadmeAndVisuals.ps1` through `Invoke-ExperienceRelease.ps1`. The release refreshes `README.md`, `README.en.md`, the versioned release note, a release visual plan, and when impact spans important workflow areas, a versioned Mermaid highlight diagram under `docs/assets/`. Keep release visuals sanitized and deterministic unless a separate privacy-safe GPT image request is materially justified.

Select the repository from the changed paths before running Git. Confirm that
`git rev-parse --show-toplevel` is the owning repository root; if it is an
accidental parent, another product checkout, or otherwise mismatched, stop and
change to the correct root before staging. Stage only paths owned by that
repository and leave unrelated working-tree changes untouched.

After a successful commit, save a local checkpoint in that repository's Git
configuration: `codex.route.repo-root`, `codex.route.branch`,
`codex.last.commit`, `codex.last.version`, and `codex.last.recorded-at`.
Before the next iteration, validate this checkpoint against the current root
and branch. Use it to continue on the same route with a new version; re-route
only when the changed-path owner changes.

After Git initialization, commit, merge, rebase, tag, or release, invoke `codex-experience-capture`. If `.codex/project/` exists, process pending Git events and synchronize project requirements, workflows, experience, retrospectives, and state. If it does not exist, invoke `codex-project-optimization` to initialize it before substantial follow-up work.

## Example

```powershell
git rev-parse --show-toplevel
git status --short --branch
.\scripts\Test-GitPublicationMetadata.ps1 -RepositoryRoot . -Staged
```
