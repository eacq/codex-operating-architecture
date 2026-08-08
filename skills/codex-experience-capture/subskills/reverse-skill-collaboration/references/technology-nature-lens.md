# 《技术的本质》方法论镜头

本文件是对用户提供的《技术的本质》的概念性借鉴，不是逐字摘录，也不替代原书。它只把适合本地 Agent 架构的思想转成可验证的设计约束。

## 对经验 Agent 的转译

| 方法论镜头 | 本地架构转译 | 可验证证据 |
|---|---|---|
| 技术由可复用模块组合而成 | 信息元、功能元、skill、工具、角色、工作流和证据模板各自保持清晰边界，再通过 owner 组合 | 路由记录能列出输入模块、组合关系和输出 |
| 新能力常来自已有模块的新组合 | 先检索既有经验、owner 和工具链；新建 skill 前先记录缺口与不可复用原因 | candidate 中有 reuse-search 和 gap 记录 |
| 实践反馈会选择更有效的组合 | 任务结果、失败、验证、交接和资源消耗进入 evidence/evolution 记录 | 正向、负向和跨上下文迁移测试 |
| 复杂系统通过层次化结构扩展 | Global Experience Agent 负责目标与边界，concept/child Agent 负责专门工作，owner 负责 gated side effect | 单一 root session、明确 owner route、子 Agent 生命周期证据 |
| 组合会受环境与资源约束 | 由 Agent 在 economy/balanced/full 之间选择；工具链按需启用，预算和权限是组合条件 | LoopX quota/should-run、工具 readiness 和回滚记录 |
| 路径依赖和历史经验会影响下一步 | 保留 revision、timeline、失效条件和 rollback；不把一次成功自动泛化成普遍规则 | revision-stamped candidate、invalidation 和验证结果 |

## 设计结论

自动进化不是无边界地增加 skill 数量，而是让系统在每次任务后判断：哪些模块被重复使用，哪些组合有效，哪些失败应阻止重试，哪些新模块值得进入候选。只有证据支持且能跨上下文迁移的组合，才进入更稳定的全局结构；其余保留在项目或 guarded candidate 层。
