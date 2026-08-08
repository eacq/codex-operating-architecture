# 架构说明

## 总体流程

`codex-self-evolution` 是全局经验 Agent 的总控入口。仓库中的 `agent/` 是其唯一物理架构根，按入口、接口、Agent、资源、运行时、证据、出口、呈现、维护与本地边界分区；`agent/agent-filesystem.json` 约束目录语义和投影，`agent/40-runtime/Invoke-GlobalExperienceAgent.ps1` 是唯一控制器实现。它接收有界目标和授权，并在任何会话副作用前按 `config/agent-interface-policy.json` 判定接口权限。`human`、`llm` 和 `internal-functional-unit` 只能使用注册功能元或请求其允许的门禁，不能直接修改 Agent 结构；只有具备本轮 `global-structure` 授权证据的 `global-control` 能把 Agent 任意方面的调整交给 `codex-architecture-iteration` 和 `agent_structure` 门禁。控制器随后建立持久会话与不可变回合快照，选择 owner 资源和工具门禁，记录工具结果并以类型化出口在保存点收敛；`Resume` 与 `Abort` 分别负责安全恢复和队列结算。经验只有在具备证据、适用范围和验证结果后才进入账本。模块清单不是固定不变的；总控按 `module-registry.json` 的证据决定新增、合并、拆分、停用或删除。

`config/agent-owner-connections.json` 把 23 个 active Owner 连接成可执行 Agent 网络，而不是仅在表格和图片中并列展示。每个节点都对应规范 Skill、架构平面/阶段、触发、输入、输出、验证和可选工具门禁；每条边都声明 handoff 产物与返回事件。`RouteOwner` 只生成 Owner 选择和交接证据，不执行门禁副作用；`Test-AgentOwnerConnections.ps1` 同时检查注册表、架构图映射、Skill 资源、门禁引用、全图可达性和返回路径。

## 模块

| 编号 | Skill | 职责 |
|---|---|---|
| 1 | `codex-self-evolution` | 总控入口、生命周期路由、资源经济和验证迭代门槛 |
| 2 | `codex-information-gathering` | 搜集本地、网络、项目与历史证据，并优先使用结构化图证据 |
| 3 | `codex-requirement-authoring` | 理解歧义需求并形成可验收规格 |
| 4 | `codex-task-execution` | 受控实施、测试、内容生产与交付 |
| 5 | `codex-workflow-design` | 把重复任务固化为可恢复工作流和执行计划 |
| 6 | `codex-credential-management` | 管理凭据元数据、验证和轮换；其 `provider-routing` 子 skill 处理兼容提供方路由，不保存秘密 |
| 7 | `codex-git-operations` | Git/GitHub 诊断、分支、提交、发布证据与远程操作 |
| 8 | `codex-tool-installation` | 插件、skill、软件和运行时安装验证 |
| 9 | `codex-experience-capture` | 从历史与执行结果中提炼经验，处理候选和结构优化记录 |
| 10 | `codex-project-optimization` | 初始化和维护项目本地需求、工作流、经验、复盘与生命周期状态 |
| 11 | `codex-architecture-iteration` | 调整架构模块、信息元/功能元拓扑、契约和版本 |
| 12 | `codex-learning` | 调研同类方案、核心理念、工作流和脚本，并形成可验证实践 |
| 13 | `codex-skill-packaging` | 新增、合并、精简、导入和发布 skills |
| 14 | `codex-knowledge-system` | 用 Obsidian 双向链接、MindMaster/Mermaid 导图和 Anki 复习连接经验 |
| 15 | `codex-image-workflow` | 图片检索/生成、格式选择、托管、链接替换与安全清理；其 `figure-optimization` 子 skill 负责数据保真的学术图优化 |
| 16 | `codex-file-organization` | 项目和全局迭代的文件组织、备份、回滚与清理 |
| 17 | `codex-office-cli` | OfficeCLI、Word/PPT/Excel/PDF 自动化和 MCP 文档控制能力 |
| 18 | `codex-conversation-continuity` | 跨账号与提供商检索本地会话元数据，保持历史发现连续性 |
| 19 | `codex-runtime-environments` | 管理基础与项目隔离 Python 环境、PowerShell/CMD 入口、依赖清单和高频依赖晋升证据 |
| 20 | `codex-error-feedback` | 结构化记录错误、失败、修复尝试、回归验证和全局错误反馈 inbox |
| 21 | `codex-skill-portability` | 将 skill 转换为可共享、无私有路径和无秘密的便携形式 |
| 22 | `codex-exact-word-layout` | 修复锁定模板 DOCX 的精确页流与版式，使用局部 OOXML/Word COM 编辑和渲染验收 |
| 23 | `codex-text-style` | 以风格画像、最小改写与意义保护修订中英文学术文本；不替代引文核验、研究判断或文档版式工作 |

## 模块自治

- 新增模块：出现至少两个独立使用场景，且现有模块无法清晰归属时。
- 子 skill：能力已有明确模式、脚本或测试，但触发、产物、维护知识与安全边界仍归属现有 owner 时，优先作为 owner 内部子能力而不是新增顶层模块。
- 合并模块：触发条件、工作流和维护内容高度重复时。
- 停用模块：长期无使用证据、知识已被上游工具取代或维护成本超过收益时；先标记 deprecated，经过兼容窗口且无 live reference 后删除顶层功能入口，迁移记录继续保留为历史信息元。
- 每次完整迭代更新 `module-registry.json` 的证据与决策，不以主观偏好随意增删。
- owner 与 skill 可在不改变触发、产物、维护知识、契约和安全边界时自我优化：必须有基线、预期收益、等价验证和回滚；自动范围仅限文档、owner 内部子 skill 与只读/本地可逆的工作流或脚本重构。顶层结构、实质契约、外部/凭据/安装/运行时/Git 发布、破坏性或不可逆操作仍需原有明确授权。
- 仅命名变更的 owner 与 skill 可自动重命名：实际契约、用户可识别任务语言和已验证经验必须共同支持新名称，且不改变 owner 边界；必须同步迁移记录、规范路径、一个发布周期的兼容入口、全部引用与全局接口，并通过命名迁移和接口验证。

<!-- BEGIN MANAGED BLOCK: codebase-memory-architecture-graph -->
## 架构图谱

![Codebase Memory MCP 无标签架构图谱](docs/assets/codebase-memory-mcp-graph.png)

该 PNG 在每次 release 时由 Codebase Memory MCP 的 Three.js 控制台重新索引并渲染。它只呈现结构密度，不包含路径、会话或源码文本。GIF 仅在用户明确要求生成或更新时才会写入；其他 release 保留已有 GIF。
<!-- END MANAGED BLOCK: codebase-memory-architecture-graph -->

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
