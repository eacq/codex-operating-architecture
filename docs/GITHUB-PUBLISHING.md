# GitHub Publication Metadata

This checkout uses two remotes:

- `origin`: private working repository for continuous updates.
- `public`: public release repository.

Normal development pushes only to `origin`. Do not push to `public`, create a
public tag, or create a public GitHub Release unless the user explicitly asks
for public publication.

Every non-merge commit must update `CHANGELOG.md` before it is pushed. The
entry may state a feature, a fix, a documentation change, or a no-user-impact
maintenance outcome; it must not include secrets or private session content.

Update the following additional descriptions when their scope changes:

| Change | Required description update |
|---|---|
| Skill behavior, script usage, install/configuration | `README.md` or the matching `docs/` guide |
| Clone, portability, provider, software setup | `docs/PORTABLE-SKILL-DISTRIBUTION.md` when applicable |
| Version/tag/release | `VERSION`, `CHANGELOG.md`, `docs/release-notes/v<version>.md` |
| Security or privacy boundary | Relevant guide plus `CHANGELOG.md` |
| Multi-module workflow or architecture change | Update or add a visual in `docs/assets/` and reference it from README or the release note |

Before committing, run:

```powershell
.\scripts\Test-ExperienceIterationGate.ps1 -RepositoryRoot . -Staged -Apply
.\scripts\Test-GitPublicationMetadata.ps1 -RepositoryRoot . -Staged
```

The iteration gate includes replay-safe probes for workflow-to-knowledge/experience routing and privacy-safe visual planning before any Git update.

The check enforces a staged changelog update, requires a staged README or docs
update for public workflow changes, and requires a release note when `VERSION`
changes. It intentionally does not create a GitHub Release; release publication
still requires explicit release scope and repository visibility verification.

## Public release flow

Use this only after explicit user authorization:

```powershell
git status --short --branch
.\scripts\validate.ps1
.\scripts\validate-global-install.ps1
.\scripts\Test-PublicReleaseSafety.ps1 -RepositoryRoot . -CandidateRef HEAD
git push public main
git tag -a v<version> -m "v<version>"
git push public v<version>
gh release create v<version> --repo eacq/codex-operating-architecture --title "v<version>" --notes-file docs\release-notes\v<version>.md --latest
```

Never use `git push --mirror` against the public repository. The public
repository should receive only the reviewed release branch state and the
intended release tag.
The safety check derives remote identities locally and rejects private remote identifiers, local paths, credential-like content, and private-state paths from the candidate snapshot.
It scans the release snapshot rather than console output and never prints a matched secret-like value.

When a Git-process error occurs, complete and verify every repair before retrying. A retry must use a fresh repaired-worktree path set, regenerated documentation/version artifacts, a new staged global-iteration proof, and fresh safety checks; it must not resume a failed release from stale staged content.

## Public release repair

An explicit user request may republish an existing public `vP.R` tag only after a repaired snapshot has passed all release gates. Update `CHANGELOG.md`, `VERSION`, and a new bilingual `docs/release-notes/v<version>.md`; push reviewed `main` first, force-update only that named public tag to the reviewed commit, then edit the existing GitHub Release with the new note. Record that the tag was republished and never use this path for an unreviewed or private snapshot.

## Release notes and visuals

Every version note should explain what changed, why it matters, how it was
verified, and whether users need to do anything. When a change affects several
modules, fixes a confusing workflow, or changes setup/release behavior, include
a small visual that shows the problem and the resolved path. Prefer a sanitized GPT-generated explanatory image when it materially improves understanding; use versionable SVG or Mermaid when generation is unavailable or the structure is deterministic. Never include private remotes, local paths, credentials, sessions, or user data in image prompts.

## 中文对照

本仓库使用两个远程仓库：`origin` 是持续更新的私有工作仓库；`public` 仅用于公开发布。日常开发只能推送到 `origin`。除非用户明确要求，否则不得推送 `public`、创建公开标签或 GitHub Release。

每次非合并提交在推送前都必须更新 `CHANGELOG.md`，且不得写入密钥或私有会话内容。skill、脚本、安装、配置或安全边界变更时，还必须更新 `README.md` 或对应 `docs/` 说明；版本、标签或发布还需更新 `VERSION`、`CHANGELOG.md` 与 `docs/release-notes/v<version>.md`。提交前执行：

```powershell
.\scripts\Test-GitPublicationMetadata.ps1 -RepositoryRoot . -Staged
```

该检查不会创建 GitHub Release。公开发布仍须获得明确授权并核验仓库可见性。多模块或复杂工作流变更应提供可版本控制的 SVG 或 Mermaid 说明图；只有真实截图或生成图确有价值时才使用托管位图。
公开推送前还必须运行 `Test-PublicReleaseSafety.ps1`；它从本机 remote 推导身份，并拒绝私有远程标识、个人路径、凭据样式内容和私有状态路径。

发生 Git 流程错误后，必须先完成并验证全部修复才能重试。重试必须使用修复后工作区重新计算的路径集合、重新生成的文档/版本产物、全新的暂存全局迭代证明和安全检查；不得从陈旧的暂存内容继续失败的发布。

## 公开发布修订

只有在用户明确要求时，才可重新发布既有公开 `vP.R` 标签，且修复后的快照必须通过全部发布门禁。更新 `CHANGELOG.md`、`VERSION` 和新的双语 `docs/release-notes/v<version>.md`；先推送经过审查的 `main`，只强制更新该指定公开标签到审查后的提交，然后用新说明编辑既有 GitHub Release。必须记录标签已重新发布，且不得将该路径用于未经审查或含私有内容的快照。
