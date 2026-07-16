# File organization lifecycle learning / 文件整理生命周期学习

## English

### Evidence and comparison

- Repository maintenance guidance supports keeping ownership and documentation explicit; code ownership is not a substitute for a safe organization policy.
- Repository best practices favor clear top-level structure and reviewable changes; this supports preview manifests and protected paths rather than broad automatic moves.
- AI-assisted file sorting is useful for classification ideas, but its inferred labels are not enough authority to relocate private material.

### Adopted contract

- Use metadata-only planning by default, aggregate-only lifecycle records, protected-path exclusion, and an explicit off-root backup before any approved apply.
- Treat category changes like workflow changes: retain, refine, add, merge, split, deprecate, or remove only with evidence and cross-module handoff tests.
- Run the review during global iteration, project initialization, and material follow-up work; connect successful decisions to workflow learning, knowledge, experience, documentation, and visual provenance.
- For a self-hosting architecture, never reorganize the active tree in place. Use an isolated copy, recoverable backup, full-scope organization, reference repair, canonical-layout restoration, full validation, and replace-on-success transaction. Failed attempts remain repairable evidence and never become the active system.

### Sources

- GitHub Docs: [About CODEOWNERS](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/about-code-owners)
- W3C: [GitHub best practices](https://www.w3.org/guide/github/best-practices.html)
- GitHub: [hyperfield/ai-file-sorter](https://github.com/hyperfield/ai-file-sorter)

## 中文对照

### 证据与比较

- 仓库维护指引强调明确所有权和说明文件；代码所有权不能替代安全的文件整理策略。
- 仓库最佳实践提倡清晰的顶层结构与可审查变更，因此应采用预览清单和受保护路径，而不是大范围自动移动。
- AI 辅助整理可用于分类思路，但推断出的标签不足以授权迁移私有资料。

### 已采纳契约

- 默认仅元数据计划、生命周期记录仅保留聚合信息、排除受保护路径；任何获批执行前必须在选定根目录外完成显式备份。
- 分类法变化按工作流变化处理：只有在证据和跨模块交接测试支持时，才保留、精炼、增加、合并、拆分、弃用或移除。
- 在全局迭代、项目初始化及实质性后续工作中运行审查；将经验证的决定接入工作流学习、知识、经验、说明文件和图片溯源。
- 自托管架构不得原地整理当前目录；应使用“隔离复制、可恢复备份、全量整理、引用修复、规范布局恢复、完整验证、成功后替换”的事务。失败尝试只作为可修复证据保留，不得成为当前系统。
