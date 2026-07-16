# Verified Private Auto-Git / 已验证的私有自动 Git

## English

`codex-git-operations` owns private auto-Git. It is a controlled commit-and-push gate, not a scheduler or a public-release mechanism.

After a completed, verified iteration, the controller may prepare a candidate for a new or materially changed skill or workflow, a validated repair, a cross-module contract change, or meaningful documentation maintenance. Compatible functionality is classified as `minor`; fixes and documentation as `patch`; breaking changes always require explicit user direction.

Before `-Apply`, provide exact iteration paths and update `CHANGELOG.md`, the applicable README or guide, and the matching release note if `VERSION` changes. The script confirms that `origin` is private through GitHub CLI, stages only supplied paths, validates publication metadata, commits, pushes only to `origin`, and writes a local Git checkpoint. It rejects mixed worktrees, missing metadata, unconfirmed privacy, public pushes, tags, and GitHub Releases.

Every verified implementation iteration runs `scripts/Sync-IterationDocumentation.ps1 -Apply`, which regenerates `docs/ITERATION-STATUS.md`. Versioning follows `docs/EXPERIENCE-VERSIONING.md`: compatible automatic capability or architecture work increments the third component; verified fixes, documentation, and refinements increment the fourth component.

If a Git-process action fails, record and repair every Git-process error before any retry. Recalculate the repaired path set, regenerate documentation and version artifacts, stage the new exact set, and rerun full validation plus the global-iteration, integration, and metadata gates. Never reuse the failed attempt's staged-path proof.

```powershell
# Inspect a candidate without changing Git state.
.\skills\codex-git-operations\scripts\Invoke-VerifiedPrivateCommit.ps1 -Paths <iteration-paths>

# Commit and push a verified, explicitly scoped candidate.
.\skills\codex-git-operations\scripts\Invoke-VerifiedPrivateCommit.ps1 -Paths <iteration-paths> -Apply -Message 'feat: <summary>'
```

## 中文对照

`codex-git-operations` 负责私有自动 Git。它是受控的提交与推送门禁，不是后台定时任务，也不用于公开发布。

在一次完整且已验证的迭代完成后，总控模块可为新增或实质更新的 skill、工作流、已验证修复、跨模块契约变更或有意义的文档维护准备候选项。兼容功能归类为 `minor`；修复与文档归类为 `patch`；破坏性变更始终需要用户明确决定。

执行 `-Apply` 前，必须提供精确的迭代路径，并更新 `CHANGELOG.md`、适用的 README 或说明文件；若 `VERSION` 变化，还必须更新对应发布说明。脚本通过 GitHub CLI 确认 `origin` 为私有仓库，只暂存所提供路径，校验发布元数据，提交并只推送到 `origin`，再写入本地 Git 检查点。它拒绝混入工作区改动、缺失元数据、无法确认私有性、公开推送、标签和 GitHub Release。

每次已验证的实现迭代均运行 `scripts/Sync-IterationDocumentation.ps1 -Apply`，以重新生成 `docs/ITERATION-STATUS.md`。版本遵循 `docs/EXPERIENCE-VERSIONING.md`：兼容的自动功能或架构工作递增第三位；已验证的修复、文档和精炼递增第四位。

若 Git 流程操作失败，重试前必须记录并修复全部 Git 流程错误。重新计算修复后路径集合，重新生成文档和版本产物，暂存新的精确集合，并重新运行全量验证、全局迭代、联动和元数据门禁。不得复用失败尝试的暂存路径证明。
