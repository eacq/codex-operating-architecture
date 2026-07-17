# Codex Operating Architecture — English

[中文说明 / Chinese README](README.md)

This repository is a verified, self-iterating operating architecture for local Codex work. A single controller routes tasks to focused skills for project lifecycle, requirements, execution, knowledge, learning, error feedback, runtime environments, Git, and release safety.

## Repository channels

- `origin`: private continuous-development repository.
- `public`: public releases only, after explicit user authorization.

## Core guarantees

- Project facts remain project-local; only verified cross-project rules are promoted.
- Experience, knowledge, and user study material are separated.
- Secrets, raw session history, browser state, and local machine paths do not enter Git.
- When `codebase-memory-mcp` is installed locally, repository orientation should start from graph indexing and structural search, then read only the source files needed to verify cited evidence. The global lifecycle entry proactively runs fast `index_repository` when MCP tools are exposed and the project is a source repository; if the current task does not expose MCP, record that gap and fall back to local file evidence. Graph search routes evidence; final claims still require source-file verification.
- A verified iteration may use the private auto-Git gate only with scoped paths, private-origin confirmation, bilingual GitHub metadata, validation, and a semantic-version decision.
- Public pushes, tags, and GitHub Releases are never automatic.
- Public candidate snapshots are checked for private remote identities, private-state paths, local paths, and secret-shaped content before any public push.
- Complex knowledge, experience, and workflow relationships use a sanitized GPT-first visual decision, with deterministic SVG/Mermaid fallback and lifecycle-aware edit, regenerate, or delete handling.
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
