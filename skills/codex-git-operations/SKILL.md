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

For GitHub network commands on this Windows machine, use
`scripts/Invoke-GitHubNetworkCommand.ps1` for `git` and `gh` calls that touch
GitHub. For proxy-budget isolation, OpenAI reachability checks, system proxy
state, TUN/game routing, and local `127.0.0.1:7892` verification, read
[subskills/scoped-network-proxy/SKILL.md](subskills/scoped-network-proxy/SKILL.md).

Use `scripts/Invoke-CodexGitWorkflow.ps1` as the single scripted Git entry:
`Inspect` produces a sanitized status, remote, checkpoint, scope, and diff
plan. Add `-CheckWhitespace` only when an explicit whitespace audit is needed;
the expensive scan remains mandatory in the existing commit and release gates.
`Stage` stages only explicit paths; `Commit` delegates to the verified
private-commit gate and pushes only with `-Push`; `PrivateRelease` and
`PublicRelease` delegate to the existing release controller. Every mutating
action requires explicit paths and `-Apply`; the wrapper never bypasses the
complete-iteration, publication-metadata, privacy, or release authorization
gates.

## Publication descriptions

Before every non-merge commit, update `CHANGELOG.md` and run
`scripts/Test-GitPublicationMetadata.ps1 -RepositoryRoot <root> -Staged`.
When auto-Git changes `VERSION`, generate or verify the matching changelog
section with `skills/codex-git-operations/scripts/Update-ExperienceChangelog.ps1`.
First run `scripts/Invoke-CompleteGlobalExperienceIteration.ps1 -RepositoryRoot <root> -Staged -Apply`, which must prove exact pre-iteration rollback readiness and complete isolated organization, cleanup, replacement, post-replacement validation, and lifecycle writeback. Any failed attempt must restore/verify the prior tracked and untracked worktree, repair the owning error, discard stale staged proof, and rerun completely before Git resumes. Then run `scripts/Test-ExperienceIterationGate.ps1 -RepositoryRoot <root> -Staged -Apply`; the review gate reads that proof without mutating the active repository.

## Failure recovery

On any Git-process failure, create or update the redacted `codex-error-feedback` report and resolve every Git-process report to `fixed` or `verified` before retrying. Do not reuse a failed commit, synchronization, or release plan. Recalculate the repaired worktree's complete scoped paths, regenerate changelog/documentation/version artifacts, stage that new set, and rerun full validation, global iteration, integration, metadata, privacy, and visibility checks as applicable. Release automation rejects unselected repaired paths so a stale retry cannot omit a fix.
For a blocked `.git/index.lock`, use `scripts/Repair-CodexGitIndexLock.ps1` through the scripted Git entry. It removes a lock only when the target is the verified repository-local lock, the lock is empty and older than the minimum age, and no `git.exe` process is active. Any active Git process, recent lock, or non-empty lock remains a blocker rather than being removed.
When a failed release has already generated `VERSION` and its release materials but has not committed, pushed, tagged, or created the release, retry `Invoke-ExperienceRelease.ps1` with `-PreserveVersion` after repairing the reported Git failure. The flag reuses only that exact uncommitted four-part version; it does not bypass scoped paths, validation, commit, push, tag, privacy, or release checks.
After a private Release is created, the controller runs
`Test-PrivateExperienceReleaseEvidence.ps1` to align HEAD, `origin/main`, local
and remote tags, private repository visibility, Release status, and lifecycle
state. This replaces manual post-release `git`/`gh` command assembly while
retaining the same scoped-network and privacy checks.
For experience-system release sync, `Invoke-ExperienceRelease.ps1` must derive
the actual commit set through `Resolve-ExperienceReleasePathSet.ps1` after
release notes, README blocks, changelog, visual plans, and iteration status are
regenerated. The release scope may include context paths, but the commit step
receives only currently changed or untracked paths; any dirty path outside the
scope blocks the sync with the exact missing path list.
Before the expensive complete replacement gate, the release controller runs
`Test-ExperienceReleaseReadiness.ps1`. It requires the current versioned release
note and a target-version changelog section containing the release entry, and it
requires `CHANGELOG.md` to differ from HEAD. This preflight prevents a metadata
failure from consuming a complete validation cycle.
Update `README.md` or the matching `docs/` guide whenever the public workflow,
installation, configuration, or safety boundary changes. A version/tag/release
also requires `VERSION` and `docs/release-notes/v<version>.md`. See
`docs/GITHUB-PUBLISHING.md`; never put secrets or private session data in any
GitHub-facing description.

## Verified private auto-Git

Use `scripts/Invoke-VerifiedPrivateCommit.ps1` after a complete verified iteration when a new or materially changed capability, validated repair, cross-module contract, or meaningful documentation update has a scoped path set. The controller recommends `minor` for compatible functionality and `patch` for fixes or documentation; `major`, public pushes, tags, releases, and mixed worktree changes always require separate explicit direction. `Invoke-CompleteGlobalExperienceIteration.ps1 -Staged -AutoCommit -Apply` may automatically create a local commit only after that same verified iteration proves the exact staged scope; it uses `-CommitOnly`, so it never pushes, tags, or releases. The script confirms `origin` is private through GitHub CLI, stages only explicit paths, validates metadata, commits, and stores checkpoints. When a current complete replacement proof already matches the same `HEAD` and staged path hash, the controller may reuse it and write `.codex/project/publication-envelope.json`; otherwise it reruns the full complete iteration. Read `docs/AUTO-GIT-PRIVATE.md` for the bilingual contract.

## Experience version and release commands

Use `Get-ExperienceVersion.ps1` as the sole four-part `P.R.A.B` calculator: public release controls `P`, private release controls `R`, automatic capability/architecture iterations increment `A`, and automatic fixes/documentation/refinements increment `B`. Read `docs/EXPERIENCE-VERSIONING.md`. Interpret an explicit “同步经验系统” command as `Invoke-ExperienceRelease.ps1 -Mode Private` and an explicit “发布经验系统” command as `-Mode Public`; both require scoped paths, full validation, synchronized workflow-learning and documentation, and their own `-Apply`. Private tags use `private-vP.R`; public tags use `vP.R`.

## Route and checkpoint

Every private or public release must run `skills/codex-git-operations/scripts/Update-ReleaseReadmeAndVisuals.ps1` through `Invoke-ExperienceRelease.ps1`, then pass `Test-ReleaseReadmeOptimization.ps1`. This is the mandatory release-time application of `github-readme-presentation`, grounded in both installed sources: `oil-oil/beautify-github-readme` for repository hierarchy/evidence/first-use review and `rzashakeri/beautify-github-profile` for reader-value and component-dependency review. It refreshes `README.md`, `README.en.md`, the versioned release note, a durable optimization audit, a release visual plan, and when impact spans important workflow areas, a versioned Mermaid highlight diagram under `docs/assets/`. Keep verified project-native Markdown and claims; never add decorative counters, trackers, widgets, or unverified metrics. Keep release visuals sanitized and deterministic unless a separate privacy-safe GPT image request is materially justified.

For the global experience system, this presentation workflow is mandatory for every main user-facing explanation, not only the README: overall introduction, setup/operating guide, concept overview, collaboration contract, safety boundary, decision guide, `CHANGELOG.md`, and release note all enter the evaluation when changed. `Invoke-VerifiedPrivateCommit.ps1` automatically runs `New-GlobalReadmePresentationAudit.ps1`, adds the versioned audit to the exact commit scope, and `Test-GitPublicationMetadata.ps1` rejects a commit without it. Machine manifests, generated plans, and raw asset provenance are excluded. Complex README scope selects README mode and must conform to `docs/readme-design-system.json`; other explanation scope receives an evidence-and-reader-value audit, then retains its existing structure unless an improvement is justified.

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
