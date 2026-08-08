---
id: concept-cherry-studio-capability-routing
title: Cherry Studio Capability Routing and Durable Workflow Learning
type: information-unit
status: verified-source-adaptation
learning_audience: codex
codex_learning: "从 Cherry Studio 源码学习缓存优先的能力目录、按需延迟暴露、搜索-检查-调用路由、审批能力直达、Agent 会话驱动器解耦，以及知识操作的持久作业化；只在现有 owner 和独立闸门内融合。"
source: https://github.com/CherryHQ/cherry-studio/tree/55130eef9beb48c454f3a0bdcfffe21c3ac2fb7e
owner: codex-self-evolution
related:
  - "[[Global Experience System]]"
  - "[[Information and Functional Unit Principle]]"
  - "[[Agent Intent Recognition System]]"
  - "[[Agent Memory System]]"
  - "[[Agent Loop System]]"
verification:
  - config/agent-capability-routing-policy.json
  - scripts/Test-AgentCapabilityRoutingPolicy.ps1
  - skills/codex-experience-capture/scripts/Test-MethodologySkillDistillation.ps1
---

# Cherry Studio Capability Routing and Durable Workflow Learning

学习日期：2026-08-06。审阅对象是 Cherry Studio 官方仓库浅克隆的提交
`55130eef9beb48c454f3a0bdcfffe21c3ac2fb7e`，不安装其 Electron 运行时、Node
依赖、MCP 服务或桌面应用。

## 源方法与证据

Cherry Studio 当前源码把 AI 能力组织成多个相互连接的层：provider/adapter
解析、AI 工具注册表、MCP 工具目录、Agent session runtime、知识库工作流、
JobManager/Scheduler 以及一组可按需加载的 skill/reference。关键证据包括：

- `docs/references/ai/tool-registry.md`：工具具有 namespace、owner-like
  scope、defer 模式和 apply 条件；延迟工具通过 search/inspect/invoke
  暴露；审批工具保持 inline；外部 MCP 目录读取走缓存，活跃刷新不阻塞启动。
- `docs/references/ai/tool-approval.md`：Main 进程持有审批状态，renderer 只
  呈现和提交决定，数据库锚点校验避免覆盖并发写入。
- `docs/references/ai/agent-session-runtime.md`：会话宿主与具体 Agent driver
  解耦；转向消息、恢复 token、工具策略更新和中断/延后边界都有显式状态。
- `docs/references/knowledge/knowledge-service.md` 与
  `docs/references/knowledge/workflow-architecture.md`：知识操作由持久作业
  承载，业务状态与执行进度分开，重建/删除有竞争保护、补偿和恢复策略。
- `docs/references/job-and-scheduler/overview.md`：DB 是作业真相源，内存队列
  是派生视图；队列并发、事务 claim、启动恢复和重试具有明确顺序。
- `resources/skills/cherry-tool-guide/SKILL.md`：顶层 skill 只做路由，详细
  前置条件和错误恢复放到按需 reference；工具缺失与依赖缺失必须分开报告。

## 与本地全局经验 Agent 的对照

| Cherry 方法 | 本地对应 | 决定 |
| --- | --- | --- |
| 多 provider 通过 adapter family 解析 | `codex-credential-management` provider routing | 采用“身份、协议、adapter、运行时解析分离”的校验视角；不复制 provider 表或凭据 |
| registry + namespace + defer | `codex-self-evolution` + `codex-information-gathering` | 采用缓存优先的能力目录和按需暴露策略 |
| search/inspect/invoke 元操作 | GEA 的 `ClassifyIntent`、`RouteOwner`、注册 functional unit | 采用为延迟能力生成可审计的检索/检查/调用路径；不把它变成第二入口 |
| force-prompt / needsApproval 工具 inline | `config/agent-interface-policy.json` 与 owner gates | 采用审批能力永不隐藏，延迟路由不得绕闸门 |
| MCP catalog cache-only read | `F-codex` 图谱与 deferred capability registry | 采用启动不阻塞、后台/显式刷新；保留“缓存为空”和“未刷新”区别 |
| Agent host/driver 分离、resume token、steer | GEA session state、Continue/Resume、host/model labels | 作为现有 durability 合同的外部交叉证据，不新增 runtime |
| DB 作业、并发、恢复、补偿 | Agent loop、save point、pending writes、error feedback | 采用“业务状态不等于进度状态”的记录原则，保留现有脚本实现 |
| Cherry skills/marketplace 和 auto-install | `codex-skill-portability`、`codex-tool-installation` | 只采用“轻路由 + 深 reference”；安装仍须独立授权和兼容性验证 |

## 已融合的功能元

`config/agent-capability-routing-policy.json` 是现有 owner 下的功能契约，
由 `scripts/Test-AgentCapabilityRoutingPolicy.ps1` 验证。它定义：

1. `inline / deferred / cold` 三种暴露池；
2. `classify -> cache catalog -> narrow owner -> search/inspect -> gate ->
   execute -> record/refresh` 的有序路由；
3. economy、balanced、full 三种资源版本；full 可启用高成本目录刷新，
   economy 默认只读缓存，但功能质量边界不降低；
4. 审批、凭据、安装、发布、破坏性、Git/release 和任意代码执行保持独立
   闸门；
5. 缓存目录读取不等待外部 MCP；未知缓存只安排一次非阻塞刷新，已知空目录
   不能被误当成“未查询”。

## 未采用、暂缓与原因

- 不安装 Cherry Studio：目标是学习和融合，不需要桌面应用或依赖；安装会
  增加本地资源、供应链和运行时边界。
- 不复制 Electron/renderer/IPC：这些是产品实现细节，不改善全局 Agent 的
  终端协作目标。
- 不启用任意 `tool_exec`：源码文档明确其全 Node 权限会形成提权面；本地
  继续保持默认禁用。
- 不自动安装 MCP/skill、连接 IM 或创建调度任务：这些属于外部或持久副作用，
  必须由现有 owner gate 单独授权。
- 不把 Cherry 的 MCP wire name、provider catalog、企业后端和商业版本当作
  本地事实；它们保留为来源语境，不进入全局经验规则。

## 触发与验证

当任务出现大量候选工具、上下文压力、外部 MCP 启动变慢、工具审批被隐藏、
或 full/balanced/economy 版本选择时，先读取
`config/agent-capability-routing-policy.json`，再由 `codex-self-evolution`
进入 `codex-information-gathering` 或对应 owner。若任务是普通小规模工作、
审批能力、凭据/安装/发布或需要明确副作用的调用，不应使用 deferred 路由
替代其 owner gate。

当前验证证明策略结构、owner 归属、资源版本、审批保留和测试登记有效；它
尚未证明具体任务上的延迟收益。后续只有在至少两次有基线的真实本地任务中
测得上下文、启动或协调开销下降且没有漏闸门，才可把策略提升为更强的运行时
自动化。若 deferred surface 导致能力遗漏、刷新阻塞或路由开销超过节省，
回滚到现有 inline/owner 路由并保留本记录作为失效证据。
