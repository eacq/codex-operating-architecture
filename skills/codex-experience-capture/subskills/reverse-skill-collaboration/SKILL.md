---
name: codex-experience-capture-reverse-skill-collaboration
description: 将 reverse-skill 的范围契约、角色交接、证据链、时间线和供应链审查适配为经验 Agent 的团队协作控制面；不启用其攻击性技能或外部工具安装。
---

# Reverse-skill 协作控制面适配

本子能力主要学习并融合 reverse-skill 的三条机制：AI 先分类再路由、按需检查并自举工具链、以及把结果写回可回放的经验库。其进化观同时参考《技术的本质》所启发的模块化、组合、选择和累积改进视角：能力不是孤立的提示词，而是可组合的工具、信息元、功能元、工作流和证据结构。源仓库保存在 `F:\codex\.runtime\software\reverse-skill`，具体版本和采纳边界见 `config/reverse-skill-integration.json`。自举仅由本地 Agent 判断需求并路由到 `codex-tool-installation`，不绕过授权、预算、供应链和回滚门。

## 触发条件

在以下情况使用本子能力：任务跨越多个回合或多个 Agent；需要 proposer/executor/evaluator、lead/specialist/reviewer 等分工；需要长期回放、证据交接、阻塞恢复；或正在吸收外部 skill、MCP、工作流方法。简单问答、单文件小修复只做最小入口检查。

## AI 自动路由

先调用 `scripts/Invoke-ReverseSkillCollaboration.ps1 -Mode Route -Task "..."` 生成建议 owner、阶段和下一动作；然后交给 Global Experience Agent 的 `RouteOwner` 和现有 owner registry 执行。该脚本是可解释的预路由器，不是第二个 Agent 控制器：最终 owner、权限、工具、凭据、结构和发布判断仍由本地 canonical gates 决定。

路由顺序固定为：目标识别 → 检索相关经验 → 建立有边界的工作项 → owner 执行 → 独立验证 → 经验捕获与晋级判断。遇到复合任务可以并行 proposer/specialist/verifier，但共享同一目标、范围、证据和保存点。

## 按需自举工具链

需要外部能力时，先调用 `-Mode ToolchainPlan -Task "..." -Capabilities ...` 检查本机可用性和上游 manifest 的版本/校验信息。只输出缺口和安装计划，不自动下载或安装；当任务收益明确且用户/owner 已授予本次安装权限时，才将缺口交给 `codex-tool-installation`，安装到 F 盘受控目录，随后验证位置、版本、帮助/导入和代表性操作，并保留回滚证据。工具缺失不应阻塞纯规划、读文档或离线分析。

高风险或目标相关工具即使上游声明 `canAutoInstall=true`，在本地仍视为 `explicit-user-or-owner-gate-required`；“按需”表示按任务需要启用，不表示无条件自动安装。

## 自动进化经验库

任务结束、失败、发现新场景、工具链修复、交接或验证结论变化时，调用 `-Mode EvolutionPlan`，把触发、动作、结果、证据、适用范围、失效条件和下一步写入现有 `workflow-learning` / Experience / Knowledge 链路。采用“模块化 → 组合 → 小范围试用 → 证据选择 → 版本固化 → 再组合”的循环：先组合已有 owner、工具、信息元和功能元，只有明确缺口才新增模块；成功经验要说明为何可迁移，失败经验要说明停止条件；经正向、负向、跨上下文迁移验证后，才允许进入 verified architecture guidance。重复经验合并，失败经验也保存为防回归规则。

## 协作契约

1. **先定义任务边界**：记录最终目标、完成判据、in-scope、out-of-scope、权限/授权状态、隐私边界、资源档位、预算和停止条件。缺少必要授权时只能读、分析、规划和等待补充材料。
2. **再分配角色**：由当前 owner/lead 负责拆分和阶段门控；specialist 只负责被交付的工作项；verifier/evaluator 负责独立核验；recorder/reporter 负责沉淀。不得创建第二个 Global Experience Agent，也不得让子 Agent 替代 owner 的工具、发布、凭据、安装或回滚门。
3. **工作项可追踪**：每项使用稳定 ID，写明 owner、输入、产出、状态、阻塞、证据、下一动作和交接条件。长任务优先使用现有 LoopX 的 todo/lease/quota/evidence/targeted-wake 投影，不重复造一套控制器。
4. **交接必须带证据**：交接包至少包含目标与范围、已完成/未完成、证据 ID 或文件路径、关键决策及理由、未知与风险、下一动作、需要的新授权。只传结论不算完成交接。
5. **结论回链**：将“观察/日志/测试结果”作为 Evidence，将解释和判断作为 Finding，将调用链、实验链、修复链或决策链作为 Path。Finding 至少引用一条 Evidence；无法复现时必须明确限制，不得把推测写成验证结果。
6. **时间线追加写**：重大状态变化、工具结果、交接、阻塞、恢复、验证和停止决策写入追加式 timeline；历史条目不改写，修订通过新条目和版本号表达。
7. **阻塞先保存再停**：遇到权限、传输、额度、依赖、上下文或证据不足，先保存 durable work、pending writes、当前证据和恢复入口，再返回 typed blocked/restart-required；不得盲目重试或启动重复 controller。

## 与现有全局系统的映射

- 任务生命周期和最终目标：`codex-self-evolution`、Global Experience Agent、LoopX control-plane。
- 经验捕获与候选沉淀：本父 skill 的 local/global experience iteration 和 knowledge-system。
- 结构变更：`codex-architecture-iteration`；适配层不能绕过 owner routing、rollback、validation 或 publication gate。
- 实际项目交付：由对应 specialist owner 执行，当前 checkout、测试和用户给出的私有内容保持权威。
- 资源策略：默认 balanced/economy；只有目标收益明确且配额/权限允许时才由 Agent 判断是否启用 full/high-cost。

## 外部 skill / MCP 供应链边界

吸收外部仓库时，先固定 URL、commit、许可证、审查文件、适配范围和回滚路径；再做最小化适配、正负触发测试和结构验证。禁止因本子能力直接执行 `curl|bash`、pip/npm/java/IDA/Burp/Kali 等安装，禁止修改用户全局 PATH、客户端全局注入或连接外部服务。高风险能力只有在用户明确要求、任务范围明确、对应 owner 和安全门通过后，才可以由工具安装 owner 另行执行。

## 最小交接模板

```text
WorkItem: WI-...
Goal / Scope: ...
Role: lead | specialist | verifier | recorder
Status: pending | active | blocked | verified | stopped
Evidence: E-... / file path / test result
Finding or decision: ...
Uncertainty and invalidation: ...
Next action and authority needed: ...
```

## 采用状态

这是基于单一外部仓库的 guarded adaptation：方法已接入 owner 内部路由，但不宣称 reverse-skill 的攻击性能力已安装或可用。只有在后续跨上下文任务中出现正向、负向和迁移验证后，才考虑把其中的协作规则提升为更广泛的 verified architecture guidance。

详细来源和映射见 [source-grounding.md](references/source-grounding.md)、[collaboration-contract.md](references/collaboration-contract.md) 与 [technology-nature-lens.md](references/technology-nature-lens.md)。
