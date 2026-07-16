# Changelog / 更新日志

## 1.0.2.0 - 2026-07-16

### English

- Add evidence-based cleanup to isolated global iteration: only originally untracked allowlisted temporary/cache artifacts and truly empty non-protected directories are eligible.
- Copy every file candidate to an off-root quarantine and verify SHA-256 before deletion; recompute and quarantine active candidates after replacement and again after validation instead of propagating stale sandbox hashes.
- After replacement, validate the active repository twice, refresh and validate the real global skill interfaces, then write aggregate cleanup/replacement evidence and lifecycle state.
- Extend the pre-Git proof gate, tests, bilingual documentation, deterministic architecture diagram, knowledge, experience, and workflow contracts for the new completion boundary.

### 中文对照

- 为隔离全局迭代加入基于证据的清理：只有原始未跟踪且位于明确临时/缓存白名单中的文件，以及真正为空的非受保护目录才可进入清理。
- 每个候选文件删除前都复制到根目录外隔离区并校验 SHA-256；替换后及验证后都会重新计算并隔离当前候选，不传播沙箱中的陈旧哈希。
- 替换后连续验证当前仓库两次，刷新并验证真实全局 Skill 接口，最后写回清理/替换聚合证据和生命周期状态。
- 扩展 Git 前证明门禁、测试、中英说明、确定性架构图、知识、经验与工作流契约，使其覆盖新的完成边界。

## 1.0.1.3 - 2026-07-16

### English

- Make global self-iteration transactional: isolated copy, recoverable off-root backup, full eligible-file organization, verified reference repair, canonical Git-layout restoration, full validation, and replace only after success.
- Repair the discovered scaling and recovery failures, including large archive timeout, quadratic reference scans, path normalization, line-ending drift, stale-reference checks, moved restore tools, and incomplete untracked restoration.
- Make validation select the first PyYAML-capable runtime from explicit configuration, the repository foundation environment, or portable system Python; remove the machine-specific runtime fallback from isolated iteration.
- Make the complete pre-Git iteration own the isolated replacement workflow; the later integration gate now verifies the replacement proof without reorganizing the active repository.
- Synchronize the bilingual README, file-organization contract, workflow knowledge and experience, architecture diagram, changelog, and release notes with the verified behavior.

### 中文对照

- 将全局自身迭代改为事务式流程：隔离复制、根目录外可恢复备份、全量合格文件整理、已验证引用修复、Git 规范布局恢复、完整验证，并且仅在成功后替换。
- 修复本次暴露的扩展性与恢复错误，包括大归档超时、二次复杂度引用扫描、路径规范化、换行漂移、陈旧引用检查、恢复工具被移动以及未跟踪文件恢复不完整。
- 验证入口会从显式配置、仓库基础运行时和可移植系统 Python 中选择首个支持 PyYAML 的运行时；隔离迭代不再包含机器专属运行时回退路径。
- 由 Git 前完整迭代统一负责隔离替换；后续集成门禁只验证替换证明，不再整理当前仓库。
- 同步更新中英 README、文件整理契约、工作流知识与经验、架构图、更新日志和发行说明，使其与验证后的实际行为一致。

## 1.0.1.2 - 2026-07-16

### English

- Add a preview-first, privacy-aware global file-organization skill with lifecycle folders, a Mermaid architecture diagram, and GPT-first visual guidance.
- Couple file organization to global iterations, project initialization, ongoing work, backup readiness, workflow learning, knowledge, experience, visual provenance, and the pre-Git integration gate. Taxonomy changes now follow evidence-backed retain/refine/add/merge/split/deprecate/remove decisions.
- Upgrade file organization from a preview-only review to an automatic safe managed-root executor: archive before every planned change, analyze and repair supported references, move only after backup success, and validate configured project commands.
- Allow every non-protected folder to enter managed scope and restore Git-tracked paths/configuration from the local-only move manifest before staging; credentials remain secure-store references only.
- Reset the verified Codex Operating Architecture release line at v1.0.
- Provide lifecycle routing, linked knowledge and experience capture, GPT-first privacy-safe visual planning, README iteration alignment, and safe public-release checks.

### 中文对照

- 加入先预览、注重隐私的全局文件整理 skill，提供生命周期文件夹、Mermaid 架构图和 GPT 生图优先指引。
- 将文件整理接入全局迭代、项目初始化、后续工作、备份就绪、工作流学习、知识、经验、图片溯源及 Git 前集成闸门；分类法现按证据执行保留、精炼、增加、合并、拆分、弃用或移除。
- 将文件整理从仅预览审查升级为自动安全受管理根目录执行器：每项计划变更前归档、分析并修复受支持引用，仅在备份成功后移动，并运行配置的项目验证命令。
- 允许所有非受保护目录加入受管理范围；Git 前自动从本地迁移清单恢复受跟踪路径与配置引用，凭据仅保留安全存储引用。
- 将经过验证的 Codex Operating Architecture 发布线重置为 v1.0。
- 提供生命周期路由、关联知识与经验捕获、GPT 优先的隐私安全可视化规划、README 迭代一致性检查和安全的公开发布检查。
