# Experience Versioning / 经验系统版本规则

## English

The canonical system version has four numeric components: `P.R.A.B`.

- `P` is determined only by the latest public GitHub Release. Public releases use tags such as `v1.0`; the first public baseline is `v1.0`.
- `R` is determined only by the latest private GitHub Release in the private repository. Private release Git tags use `private-vP.R`, while the GitHub Release title remains `vP.R`; the first private baseline under public major `1` is titled `v1.0`.
- `A` is incremented by a verified automatic Git capability/architecture iteration and resets `B`.
- `B` is incremented by a verified automatic Git repair, documentation, or refinement iteration.

`Get-ExperienceVersion.ps1` is the sole calculator. “Sync experience system” means prepare and, when explicitly applied, release the private repository after documentation, workflow-learning, knowledge/experience, validation, and scoped Git gates. “Publish experience system” means the same public-release path; it never occurs from ordinary auto-Git.

Private Git tags use `private-vP.R` so that a private release can coexist locally with the public Git tag `vP.R`; the private GitHub Release title remains `vP.R`.

Both private and public releases refresh the user-facing release surface, not only tags. `Invoke-ExperienceRelease.ps1` regenerates or updates the README latest-release blocks, the versioned release note, a release visual plan, and a deterministic Mermaid highlight diagram when the release has meaningful multi-area impact.

## 中文

规范系统版本采用四段数字：`P.R.A.B`。

- `P` 仅由最新公开 GitHub Release 决定。公开 release 使用 `v1.0` 形式标签；首次公开基线为 `v1.0`。
- `R` 仅由私有仓库中的最新私有 GitHub Release 决定。私有 release 的 Git 标签使用 `private-vP.R`，GitHub Release 标题仍为 `vP.R`；公开主版本为 `1` 时，首次私有基线标题为 `v1.0`。
- `A` 由已验证的自动 Git 功能/架构迭代递增，并重置 `B`。
- `B` 由已验证的自动 Git 修复、说明或精炼迭代递增。

只有 `Get-ExperienceVersion.ps1` 可以计算版本。“同步经验系统”表示在说明、工作流学习、知识/经验、验证和精确 Git 门禁完成后准备并在明确执行时发布私有仓库。“发布经验系统”表示走同等的公开发布路径；普通 Auto-Git 永远不会触发公开发布。

私有 Git 标签使用 `private-vP.R`，从而可与本地公开 Git 标签 `vP.R` 共存；私有 GitHub Release 标题仍为 `vP.R`。
