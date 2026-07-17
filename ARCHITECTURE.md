# 架构说明

## 总体流程

`codex-self-evolution` 是总控入口。它根据任务选择一个或多个模块，要求执行前取证、执行后验证，并把可复用结论送入经验候选区。经验只有在具备证据、适用范围和验证结果后才进入账本。模块清单不是固定不变的；总控按 `module-registry.json` 的证据决定新增、合并、拆分、停用或删除。

## 模块

| 编号 | Skill | 职责 |
|---|---|---|
| 1 | `codex-information-gathering` | 搜集本地、网络、项目与历史证据 |
| 2 | `codex-requirement-authoring` | 理解歧义需求并形成可验收规格 |
| 3 | `codex-task-execution` | 受控实施、测试与交付 |
| 4 | `codex-workflow-design` | 把重复任务固化为可恢复工作流 |
| 5 | `codex-credential-management` | 管理凭据元数据、验证和轮换，不保存秘密 |
| 6 | `codex-git-operations` | Git/GitHub 诊断、分支、提交与远程操作 |
| 7 | `codex-tool-installation` | 插件、skill、软件和运行时安装验证 |
| 8 | `codex-experience-capture` | 从历史与执行结果中提炼经验 |
| 9 | `codex-project-optimization` | 使用项目日志、数据和历史优化项目 |
| 10 | `codex-architecture-iteration` | 调整本架构的模块、契约和版本 |
| 11 | `codex-learning` | 调研同类方案并形成可验证实践 |
| 12 | `codex-skill-packaging` | 新增、合并、精简和发布 skills |
| 13 | `codex-cost-optimization` | 在不降低验收质量的前提下降低费用 |
| 14 | `codex-knowledge-system` | 用 Obsidian 双向链接、MindMaster/Mermaid 导图和 Anki 复习连接经验 |
| 15 | `codex-image-workflow` | 图片检索/生成、B 站托管、链接替换与安全清理 |
| 16 | `your-api-source` | 私有 OpenAI-compatible provider、凭据来源、模型路由与低频连接诊断兼容入口 |
| 17 | `codex-conversation-continuity` | 跨账号与提供商检索本地会话元数据，保持历史发现连续性 |
| 18 | `codex-runtime-environments` | 管理基础与项目隔离 Python 环境、PowerShell/CMD 入口、依赖清单和高频依赖晋升证据 |
| 19 | `codex-exact-word-layout` | 修复锁定模板 DOCX 的精确页流与版式，使用局部 OOXML/Word COM 编辑和渲染验收 |
| 20 | `codex-text-style` | 以风格画像、最小改写与意义保护修订中英文学术文本；不替代引文核验、研究判断或文档版式工作 |

## 模块自治

- 新增模块：出现至少两个独立使用场景，且现有模块无法清晰归属时。
- 子 skill：能力已有明确模式、脚本或测试，但触发、产物、维护知识与安全边界仍归属现有 owner 时，优先作为 owner 内部子能力而不是新增顶层模块。
- 合并模块：触发条件、工作流和维护内容高度重复时。
- 停用模块：长期无使用证据、知识已被上游工具取代或维护成本超过收益时；先标记 deprecated，再删除。
- 每次完整迭代更新 `module-registry.json` 的证据与决策，不以主观偏好随意增删。

## 迭代闭环

1. 从需求、工作区、现有 skill、记忆索引和必要的原始历史中取证。
2. 写明假设、成功标准、风险与选用模块。
3. 执行最小充分变更并进行与风险相称的验证。
4. 记录成功、失败、原因、修复、适用范围和证据。
5. 去重后更新经验账本或对应 skill；行为变化时升级版本。
6. 运行全量校验并检查 Git diff，禁止把秘密或原始历史提交到仓库。

## 项目生命周期触发

- **首次使用**：发现项目缺少 `.codex/project/state.json` 时，调用 `codex-project-optimization`，执行项目初始化，读取源码、文档和 Git 历史后填写需求与工作流。
- **Git 里程碑**：初始化仓库、提交、合并、变基、打标签或完成发布后，调用 `codex-git-operations` 与 `codex-experience-capture`；处理 `.codex/project/pending-events.jsonl`，同步项目经验和全局候选经验。
- **完整迭代**：功能、修复或阶段性交付完成并验证后，更新需求、工作流、经验和复盘；跨项目有效的已验证结论再进入全局 skill。

项目文件是项目事实的权威来源；全局 skills 只保存跨项目规则。项目初始化器通过托管标记更新 `AGENTS.md`，保留标记外的用户内容。已有 Git hook 不会被覆盖。

## 经验质量门槛

经验条目必须包含：触发情境、观察结果、行动、验证、适用范围、失效条件和来源。未经验证的内容只能标为“候选”，不得写成强制规则。时间敏感状态必须在使用前重新验证。

## 操作提示规则

- Skill 工作所需的普通文件读取、搜索、创建、修改、移动、整理、生成、验证和全局 skill 文件同步，可在用户授权的任务范围内直接执行，不逐项提示。
- 安装或升级外部软件、系统组件、运行时、驱动、包管理器或会改变系统环境的依赖前，必须先提示用户安装对象、来源、范围和主要影响。
- 仅复制或更新 skill、模板、脚本、引用文档和配置文件，不视为软件安装；但执行其中声明的外部依赖安装时仍需提示。
- 删除用户数据、覆盖已有 hook、公开仓库、发布、付费操作、权限扩大及其他不可逆外部变更，继续遵守更高等级的确认和安全边界。

## 软件路径策略

- 所有后续软件下载包、离线安装器和安装校验材料统一保存在 `$SOFTWARE_ARCHIVE_ROOT\<规范软件名>\`。
- 所有支持自定义安装目录的软件统一安装到 `$SOFTWARE_INSTALL_ROOT\<规范软件名>\`。
- 安装前同时创建并显示两个目标路径；安装后验证实际可执行文件或注册的 `InstallLocation` 位于目标目录。
- 安装器不支持自定义路径、Microsoft Store/UWP 强制系统路径或驱动/系统组件必须进入系统目录时，先报告例外，不得静默安装到其他位置。
- 不自动迁移既有安装；升级前识别其当前目录，优先保持原有 `$SOFTWARE_INSTALL_ROOT` 子目录，避免破坏配置和用户数据。
