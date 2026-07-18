# Codex Operating Architecture — English

[中文说明 / Chinese README](README.md)

This repository is a verified, self-iterating operating architecture for local Codex work. A single controller routes tasks to focused skills for project lifecycle, requirements, execution, knowledge, learning, error feedback, runtime environments, Git, and release safety.

> Build reliable local Codex work: reuse verified experience first, make changes through explicit owners, and keep validation and user authority non-negotiable.

## Start here

| If you need to… | Start with |
|---|---|
| Set up a new local project | `scripts/init-project.ps1` and `$codex-self-evolution` |
| Improve a workflow or learn from an external repository | `$codex-learning`, then the existing owner rather than a duplicate skill |
| Diagnose an unexpected result | `$codex-error-feedback` before promoting any lesson |
| Redesign a repository or profile README | `$github-readme-presentation` for an audit, a whole README, or asset-only work |
| Commit verified private architecture work | `$codex-git-operations` and the scoped private auto-Git gate |

The architecture is intentionally evidence-first: local project authority and deterministic tools come before expensive model or external work; a visual, dependency, publication, or credential step is used only when it materially improves the outcome.

## How it works

The user supplies the outcome and authority; `codex-self-evolution` selects the smallest owner set; project experience, knowledge, and deterministic tools do the reusable work first; model or external resources enter only when they materially improve the result; verification, error feedback, and publication gates then decide what may be retained, committed, or released.

![Collaboration loop concept](docs/assets/readme-collaboration-loop.png)

For the editable, reviewable structure, see the [Codex operating architecture](docs/assets/readme-architecture.svg).

## Repository channels

- `origin`: private continuous-development repository.
- `public`: public releases only, after explicit user authorization.

## Core guarantees

- Project facts remain project-local; only verified cross-project rules are promoted.
- Experience, knowledge, and user study material are separated.
- Secrets, raw session history, browser state, and local machine paths do not enter Git.
- The global experience system is a coordinated loop across self-evolution, experience capture, error feedback, knowledge, and architecture iteration. It is refined through handoff artifacts and owner-internal subskills before adding new top-level modules.
- Material work uses a small collaboration contract across user authority, local experience, and model execution: reuse verified local evidence first, escalate resources only when they change the outcome, isolate writes, and keep verification as a hard gate. Role assignment does not auto-start agents or external services. See the [collaboration map](docs/assets/collaborative-operating-model.mmd).
- Self-evolution and structural optimization are outcome-directed: each material iteration maps the terminal collaboration goal to testable capability, collaboration, economy, safety, and evolution checks, with a baseline, expected contribution, and no-regression proof. The system retains its current structure when no net evidence-backed improvement exists.
- Complete global iterations are serialized, resumable transactions: inspect lifecycle evidence after a caller timeout instead of launching overlapping replacement work.
- Top-level owners are optimizable, but each structural change needs explicit authorization for that iteration plus an evidence-backed boundary decision and validation; it is never standing permission.
- `codex-project-optimization` now owns only project-local lifecycle initialization and reconciliation; routing, implementation, workflow design, and experience promotion remain with their dedicated owners.
- Resource economy is now an internal self-evolution capability. `codex-cost-optimization` remains only as a one-release compatibility route; 25 owners are active.
- A newly detected version of a learned or installed MCP, skill, package, or project is not changed automatically. Read-only checks occur only in a user-initiated task; downloading, upgrading, reconfiguring, or substantive re-learning requires explicit authorization for that update.
- External skill repositories are learned through dated network-learning records and mapped onto existing owners first. Installation is allowed when a skill is necessary and valuable, but the installed form must be adapted through local privacy, profile, owner, and validation gates instead of raw upstream copying. When `codebase-memory-mcp` is exposed, treat external skill repositories as source repositories too: index, inspect schema and architecture, verify source files, then choose learn-only, owner reference, owner subskill, project-local skill, or global skill.
- When `codebase-memory-mcp` is installed locally, repository orientation should start from graph indexing and structural search, then read only the source files needed to verify cited evidence. The global lifecycle entry proactively runs fast `index_repository` when MCP tools are exposed and the project is a source repository. For deferred or namespaced tools, check the task's callable capability registry rather than relying only on the static tool list; record the gap and fall back to local file evidence only after that check confirms MCP is unavailable. Graph search routes evidence; final claims still require source-file verification. Record coverage limits, keep `.codebase-memory/graph.db.zst` local by default, and use an allowed-root boundary in less-trusted configurations.
- When OfficeCLI is installed locally, ordinary `.docx`, `.xlsx`, and `.pptx` automation routes through `codex-office-cli` for structured JSON reads, edits, validation, render previews, and optional MCP use. When MCP is exposed, agents load the OfficeCLI per-format guide before mutation and still treat installed `help` as schema authority. Locked-template Word pagination and journal-format repairs still route to `codex-exact-word-layout`.
- A verified iteration may use the private auto-Git gate only with scoped paths, private-origin confirmation, bilingual GitHub metadata, validation, and a semantic-version decision.
- Public pushes, tags, and GitHub Releases are never automatic.
- Public candidate snapshots are checked for private remote identities, private-state paths, local paths, and secret-shaped content before any public push.
- Complex knowledge, experience, and workflow relationships use a sanitized GPT-first visual decision with an explicit format gate: Mermaid/SVG only where text or editable vector structure helps; PNG/JPG for ordinary raster delivery according to transparency, fidelity, compatibility, and size needs.
- Reader-facing content uses a source-aware content package: brief, evidence and claim constraints, outline, draft, optional visual/deck handoff, and review record. Drafting remains separate from publication, browser login, uploads, and paid generation.
- Every completed global experience iteration writes an advisory candidate report that consolidates candidate evidence, suggested decisions, and authorization boundaries for user review. The Markdown report is Chinese-primary and appends a stable English model-reading section; source wording remains preserved for auditability. It never auto-promotes candidates or performs external actions.
- A complete global iteration can use `-Staged -AutoCommit -Apply` to create a local Git commit only after explicit scope, full verification, metadata checks, and an out-of-scope-change rejection. It never auto-pushes, tags, releases, or runs in the background.
- File organization uses a transactional isolate, backup/organize, sandbox-validation, exact pre-iteration snapshot, replacement, active cleanup, double global revalidation, and lifecycle-writeback loop. The rollback snapshot preserves every replaceable local file and SHA-256, including uncommitted content, while excluding `.git`, `.codex`, credentials, and runtimes. A pre-replacement failure leaves the active system untouched. A post-replacement failure restores modified/deleted files, removes iteration-added files, verifies every hash, and refreshes real global interfaces. A verified rollback records the error and requires owner repair followed by a complete rerun; rollback failure remains incomplete and raises a critical error. Cleanup remains limited to currently untracked allowlisted temporary/cache artifacts and empty directories, with off-root hash-verified quarantine before deletion. The Git gate accepts only proof that includes rollback readiness, replacement, revalidation, and lifecycle writeback. See [File Organization Architecture](docs/assets/file-organization-architecture.mmd) and [image provenance](docs/assets/file-organization-concept.provenance.md).
- When failures are intentionally used to test and debug file organization or the complete global iteration, continuous diagnosis records each owned attempt, runs an explicit safe repair, and restarts the whole probe until it passes. Unlimited attempts do not bypass rollback verification or normal credential, installation, destructive-action, and publication boundaries; rollback or repair-action failure becomes a blocker.

![Privacy-safe file organization concept](docs/assets/file-organization-concept.png)

## Quick start

```powershell
git clone <repository-url> <architecture-root>
Set-Location <architecture-root>
.\scripts\install-global.ps1 -Mode Junction
.\skills\codex-skill-portability\scripts\Initialize-PortableSkillConfig.ps1
.\scripts\validate.ps1
```

## Daily validation and private Git

```powershell
.\scripts\validate.ps1
.\scripts\validate-global-install.ps1
.\skills\codex-git-operations\scripts\Invoke-VerifiedPrivateCommit.ps1 -Paths <iteration-paths>
```

An explicit "sync experience system" request uses the private release gate,
not only a commit and push: `Invoke-ExperienceRelease.ps1 -Mode Private`
publishes a GitHub Release in the private `origin` repository with a
`private-vP.R` tag and a `vP.R` release title.
After the release note, README latest-release blocks, changelog, visual plan,
and iteration status are regenerated, the sync gate recomputes the current
changed/untracked path set. The commit step receives only real changed paths,
and any dirty path outside the release scope blocks the sync with an exact path
list.

Every private or public experience-system release refreshes both README files,
the matching release note, and a release visual plan; important multi-area
changes also generate a versioned Mermaid highlight diagram under `docs/assets/`.

Read [Verified Private Auto-Git](docs/AUTO-GIT-PRIVATE.md), [GitHub Publication Metadata](docs/GITHUB-PUBLISHING.md), and [Dual Repository Release Flow](docs/DUAL-REPOSITORY-RELEASE.md). These GitHub-facing guides contain Chinese counterparts in the same files.

When `VERSION` changes, the metadata gate requires a matching section in
`CHANGELOG.md` for that exact version, not only that the file was included in
the staged paths.

## Iteration synchronization and public conversion

Every verified implementation iteration generates [Iteration Status](docs/ITERATION-STATUS.md), which records version, module count, and the required documentation gate. Private skills, knowledge, and experience can become public candidates only after two independent verified evidence sources, sanitization, validation, and a separate release decision. See [Private-to-Public Skill Conversion](docs/PRIVATE-TO-PUBLIC-CONVERSION.md).

Every iteration also reviews both README files, the [Changelog / 更新日志](CHANGELOG.md), and applicable guides for consistency with the implemented behavior. When a knowledge, experience, or workflow relationship has three or more non-linear connections, use a sanitized GPT-first explanatory image when it materially improves understanding; use SVG or Mermaid only when generation is unavailable or the structure is simple and deterministic.

## Release notes

Read the user-facing [Changelog / 更新日志](CHANGELOG.md) for every release and operational update.

<!-- BEGIN MANAGED BLOCK: latest-release -->
## Latest Release / 最新发布

- Version: `1.6.0.0`
- Channel: `Private` / 私有
- Release note: [docs/release-notes/v1.6.0.0.md](docs/release-notes/v1.6.0.0.md)
- Highlights: Release documentation, Automation gates, Skill architecture
- Visual: [docs/assets/release-v1.6.0.0-highlights.mmd](docs/assets/release-v1.6.0.0-highlights.mmd)
- README optimization: audited with github-readme-presentation; provenance: [docs/release-readme-audits/v1.6.0.0.json](docs/release-readme-audits/v1.6.0.0.json)
- README 优化已通过已安装的 GitHub README 与 Profile 展示工作流复核；不引入无证据的指标或跟踪组件。
- 中文：本次发布会同步刷新 README、发布说明和必要的图示/排版材料。
<!-- END MANAGED BLOCK: latest-release -->





