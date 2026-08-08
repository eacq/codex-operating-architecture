# 经验 Agent 中文使用说明

版本：2026-08-06  
适用范围：已完成全局安装的本地 Codex、Global Experience Agent（GEA）及其注册的专业 Agent、概念 Agent 和受控子 Agent

## 先说结论

以后只要是 Codex、Global Experience Agent 或其下的相关 Agent，涉及经验沉淀、子 Agent 学习、项目执行或长期迭代，都默认自动拥有并使用本机制，不需要每次手动开启：

1. 由一个本地 Global Experience Agent（全局经验 Agent，简称 GEA）作为根控制器。
2. 每项重要工作都有持久会话、保存点、证据、回滚边界和验证结果。
3. 专业 Agent 是根 Agent 下的注册能力，不是彼此独立的全局经验系统。
4. 子 Agent 只能在父 Agent 授权的范围、写入面和验收标准内工作。
5. LoopX 是可选的长时项目控制平面，用来管理目标、待办、配额、证据和续接；它不会取代 GEA，也不会自动获得更高权限。

这里的“默认自动拥有”是统一治理契约，不是把所有项目混成一个数据仓库或共用一个任务会话：

- 全局安装后的每个 Codex 项目入口都会自动加载同一套入口、权限、证据、回滚、验证和退出契约；`F:\codex` 是当前全局架构仓库，不是唯一适用项目。
- 每个项目、任务或授权会话可以有自己的持久状态和证据，避免项目事实、私有资料和经验记录相互污染。
- GEA 是唯一根控制器；专业 Agent、概念 Agent 和子 Agent 都从根 Agent 进入，不得另起平行的“全局经验系统”。
- 子 Agent 使用同一机制，但权限、写入面、验收标准和证据范围更小；它们不能绕过父 Agent 或 owner gate。
- 用户明确授权跳过某一轮 GEA 持久会话时，只跳过该轮会话，不跳过安全、隐私、权限、回滚和必要验证门禁。
- 普通无项目闲聊不会凭空制造项目事实或持久经验；一旦进入 Codex 项目执行或经验系统操作，就回到本统一机制。
- 如果本地 Codex 或 MCP 传输中断，必须先重启受影响主机，再从保存点 `Resume`；不会无限自动重试。

## 一次工作是怎样运行的

无论调用方是 Codex 主 Agent、GEA、专业 Agent、概念 Agent 还是子 Agent，均遵循同一条链路。区别只在于调用方的注册身份、可用工具、写入面和授权范围。

```text
用户任务
  ↓
项目入口与生命周期检查
  ↓
GEA 创建或恢复持久会话
  ↓
意图识别与权限评估
  ↓
路由到已有专业 Agent / 概念 Agent
  ↓
受限执行、记录证据、验证结果
  ↓
保存点、经验记录、必要时生成候选报告
```

### 入口检查

进入项目时，系统会检查：

- `.codex/project/state.json`
- 项目 `REQUIREMENTS.md`、`WORKFLOWS.md`、`EXPERIENCE.md`
- `config/agent-system.json`
- `agent/agent-filesystem.json`
- `config/global-experience-agent-registry.json`
- 全局 Codebase Memory 项目范围（本项目应为唯一的 `F-codex`）

对于有源代码结构工作的任务，还会刷新 `F:\codex` 的 `F-codex` 证据图。外部参考仓库可以作为临时证据，但不应残留在全局缓存中。

### 意图识别

使用 `Auto` 时，运行时先做本地意图识别，再做权限评估：

- L0：明确操作词的确定性规则。
- L1：本地关键词和话语路由。
- L2：主机侧 LLM 分类，默认关闭或受策略限制。
- L3：安全回退，通常回到 `StartWork`。

意图标签只负责选择候选操作，不能赋予权限。真正的结构修改、发布、Git、安装、凭据和外部服务操作仍需要各自的门禁。

## 常用调用方式

### 1. 普通任务：创建经验会话

```powershell
& skills/codex-experience-capture/scripts/Invoke-ExperienceAgentAccess.ps1 `
  -Access StartWork `
  -Goal '完成一个有明确验收标准的本地任务' `
  -Authority '当前用户明确授权的任务范围' `
  -Apply
```

### 2. 继续或恢复已有任务

```powershell
& skills/codex-experience-capture/scripts/Invoke-ExperienceAgentAccess.ps1 `
  -Access Resume `
  -SessionId 'global-experience-...' `
  -Apply
```

区别：

- `Continue`：已有会话处于 idle 保存点，由另一个已授权调用方继续执行。
- `Resume`：从持久化状态恢复记录、队列、工作、历史和子 Agent 状态，尤其适合重启或中断之后。
- `Abort`：在确认不再继续时结束会话，不等同于删除证据。

### 3. 查询经验记忆

```powershell
& skills/codex-experience-capture/scripts/Invoke-ExperienceAgentAccess.ps1 `
  -Access SearchMemory `
  -SessionId 'global-experience-...' `
  -Query '与当前任务相关的路由、验证或失败经验'
```

只有范围明确、非秘密、带证据的结果才应写入 Agent Memory。不要写入密码、Token、Cookie、原始私密会话或大体积私有文件。

### 4. 路由专业 Agent

```powershell
& skills/codex-experience-capture/scripts/Invoke-ExperienceAgentAccess.ps1 `
  -Access RouteOwner `
  -SessionId 'global-experience-...' `
  -Owner codex-architecture-iteration `
  -Apply
```

路由只确认“谁负责、输入输出是什么、需要什么验证和门禁”，不会因为路由成功就直接执行受限副作用。

### 5. 设计受限子 Agent

```powershell
& skills/codex-experience-capture/scripts/New-MinimalAgentPlan.ps1 `
  -Goal '一个边界清晰的子任务' `
  -AcceptanceCriteria '可检查的完成条件' `
  -Verification '父 Agent 如何验证结果'
```

子 Agent 必须具备：注册 profile、明确写入面、有限权限、验收标准、项目相对证据和父 Agent 合并验证。它不会自动继承用户私密事实，也不会扩大父 Agent 权限。

## LoopX 什么时候会启用

LoopX 不是每轮对话都启动，也不是持续占用本地资源的后台服务。它是 GEA 下面的长时轨迹适配器，适合：

- 多轮、跨较长时间的项目目标。
- Issue-Fix：滚动仓库上下文、修复知识和审查偏好分离。
- Auto ML Experiment：假设、证据、无效 lineage、重复实验和 promote/stop 门。
- Auto Research：提案、执行、评估、待办、配额、证据和定向唤醒。

资源由运行时按任务、预算和当前证据选择：

| 档位 | 适用情况 | 默认行为 |
|---|---|---|
| `economy` | 短任务、低预算、已有明确答案 | 只保留必要持久状态和轻量验证 |
| `balanced` | 一般多轮任务 | 持久目标、证据和适度续接 |
| `full` | 长时实验、复杂 Issue-Fix、需要多分支证据 | 启用更完整的轨迹、配额、唤醒和重复验证 |

高消耗能力保留为可选项。系统应根据任务价值和资源状态决定是否启用，而不是永远开启或永远关闭。

LoopX 仍受以下边界约束：

- 不替代唯一的 GEA 根会话。
- 不绕过父 Agent、专业 Agent、Git、发布、安装、凭据或结构修改门禁。
- 外部真实研究、计算资源、发布和联网操作默认仍需要父 Agent 授权。
- 本地续接不等于自动提交、推送或发布。

## 经验如何沉淀

一次结果不会因为“看起来成功”就自动成为全局经验。通常按以下等级处理：

1. **项目记录**：先写入项目的 `EXPERIENCE.md`、`RETROSPECTIVES.md` 或工作流记录。
2. **候选经验**：需要保留触发、观察、行动、验证、范围、失效条件和来源。
3. **可复用经验**：通常需要至少两个独立的已验证证据来源，并通过 owner 复核。
4. **结构变化**：如果要改全局技能、Agent 拓扑、权限或运行时契约，必须经过架构 Agent 和对应结构门禁。
5. **候选报告**：完整迭代后生成建议报告，供用户决定保留、试用、推广、退休或另行授权。

经验系统不会把一次失败直接当成规则；异常行为应先进入 `codex-error-feedback`，定位原因并验证后再考虑沉淀。

## 隐私与私有资料

私有资料应留在本机、项目私有目录或明确的本地隔离区。尤其是：

- `ppt/` 等私有资料不进入 Git 提交、推送或公开发布边界。
- Agent Memory 只保存脱敏后的结论、来源指针、风险和下一步，不保存原始私密内容。
- 不把私人联系方式、凭据、Token、Cookie、原始会话或大文件复制到公共经验、技能或候选报告。
- 本地 Git 排除规则和缓存隔离不等同于删除；需要清理时优先移动到可恢复的本地备份区。

## 发生中断时怎么做

如果看到 `transport closed`、连接中断、TLS 错误或请求超时：

1. 停止自动重试，不要并发启动第二个控制器。
2. 重启 Codex 或受影响的 MCP 主机。
3. 使用原会话 ID 执行 `Resume`。
4. 确认会话回到 idle 保存点后，再执行 `Continue` 或原定操作。
5. 检查持久化状态、待写入队列、错误报告和最后一个证明文件。

如果只是普通任务失败，不要直接标记为“经验已修复”。应记录错误报告，完成最小修复和最窄验证，再决定是否更新项目经验。

## 完整收口的判定

以下事项都满足时，才能称为一次完整收口：

- 目标结果已经实现，而不是只完成了准备或暂存。
- 相关专项测试通过。
- 高严重度错误报告和 Git 过程错误已修复或有证据核验关闭。
- 回滚边界明确，必要时已验证恢复能力。
- 生命周期、经验、工作流和候选状态已写回。
- 没有未处理的传输恢复、权限、隐私、发布或外部操作阻塞。
- 生成并检查了当前候选报告（适用于完整全局迭代）。

## 本地入口与验证

核心入口：

- `agent/40-runtime/Invoke-GlobalExperienceAgent.ps1`
- `skills/codex-experience-capture/scripts/Invoke-ExperienceAgentAccess.ps1`
- `config/global-experience-agent-registry.json`
- `config/agent-interface-policy.json`
- `config/loopx-resource-policy.json`

建议验证：

```powershell
& skills/codex-experience-capture/scripts/Test-ExperienceAgentAccess.ps1
& scripts/Test-AgentSkillInvocationPolicy.ps1
& scripts/Test-GlobalExperienceAgent.ps1
& scripts/validate-global-install.ps1
```

本说明描述的是当前本地项目的实际边界：它保证受管项目中的默认入口和治理方式一致，但不把普通无项目聊天、外部平台或未安装生命周期配置的项目伪装成同等的持久经验 Agent 环境。
