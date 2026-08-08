# 协作术语表 / Collaboration Terminology

本术语表供用户、模型与本地 Global Experience Agent 共同使用。它采用一个核心原则：**用少量稳定的术语描述可验证的协作关系**，而不是为每个工具、脚本或上游项目另造入口。

## 三方使用协议

| 角色 | 使用方式 | 不承担的负担 |
| --- | --- | --- |
| 用户 | 用“目标、约束、授权、验收、偏好、问题”描述需求；可直接引用中文术语。 | 不需要记住内部 owner、子技能、脚本路径或验证细节。 |
| 模型 | 将用户语言归一化为任务契约、权限边界、交接、验证与经验状态；必要时给出中英文稳定术语。 | 不得把候选经验、上游材料或工具名当作自动授权。 |
| 本地 Global Experience Agent | 用稳定英文 term 连接 Agent 记忆、技能、知识、脚本、错误反馈、候选经验、验证记录与发布记录。 | 不因一次成功、偏好或候选记录直接改变全局行为；“本地经验系统”仅作兼容称呼。 |

## 共同术语

| 中文术语 | English term | 共同含义 |
| --- | --- | --- |
| 用户 | User | 给出目标、业务判断、授权与验收的人；不需要承担内部路由细节。 |
| 模型 | Model | 负责推理、执行、解释与交接的语言模型；必须依据证据和授权行动。 |
| 本地 Global Experience Agent | Local Global Experience Agent | 将 Agent 记忆、技能、知识、工作流、候选经验、错误反馈、验证记录、owner gates 和保存点组织成可复用协作能力的本地根 Agent；“本地经验系统 / Local Experience System”是历史兼容称呼。 |
| 三方协作 | Three-party Collaboration | 用户、模型与本地 Global Experience Agent 之间围绕目标、权限、证据、交接和学习形成的可验证协作关系。 |
| 终极协作目标 | Terminal Collaboration Goal | 让用户、本地 Global Experience Agent 与模型在质量、安全、资源效率和可持续学习之间形成可验证的团队协作。 |
| 协作术语表 | Collaboration Terminology | 三方共享的稳定词汇入口；用于减少重复解释、错误路由和候选经验误用。 |
| 任务契约 | Task Contract | 目标、范围、权限、风险、产物、验收标准和未决问题的最小明确约定。 |
| 需求简报 | Requirement Brief | 将用户目标、约束、假设、排除项、词汇、决策、权限、验收与验证写成可执行交接的文档。 |
| 协作交接 | Collaboration Handoff | 一个角色向另一个角色交付的可追溯输入、状态、证据和下一步责任。 |
| 权限闸门 | Authority Gate | 需要用户当前授权才可进行的动作边界，例如外部安装、推送、发布、顶层所有者调整。 |
| 验证证据 | Verification Evidence | 支撑“完成、修复、可推广”结论的命令输出、测试、渲染检查、哈希或可复现实验。 |
| 完成边界 | Completion Boundary | 可以诚实报告完成的最小证据条件；未达到时只能报告进展、限制或阻塞。 |
| 停止条件 | Stop Condition | 任务应停止、交回用户或转入错误反馈的明确条件，例如权限不足、三次独立修复失败或验证无法证明目标。 |
| 回滚边界 | Rollback Boundary | 出错时可恢复的文件、配置、状态或 Git 节点范围；必须在高风险变更前明确。 |
| 候选经验 | Candidate Experience | 尚未达到推广证据阈值的观察、来源学习或局部成功；它不能自动改变全局行为。 |
| 受控指导 | Guarded Guidance | 经用户允许保留、可指导试用但仍未完全验证的经验或知识；不能绕过验证、安全或授权门槛。 |
| 错误反馈 | Error Feedback | 对异常、错误结果或重复失败的结构化记录，包含用户观察、诊断、修复、回归验证及未解决状态。 |
| 信息元 | Information Unit | 保存意义、证据、知识、经验、流程图、术语、地图或学习记录的最小稳定单元；主要用于解释、索引、约束或证明功能。 |
| 功能元 | Functional Unit | 执行、转换、验证、路由或维护行为的最小稳定单元；包括技能、子技能、工作流、脚本、测试、验证器和实现过程。 |
| 双向链接 | Bidirectional Link | 信息元与功能元之间的互相索引：信息说明功能为何存在、何时可用，功能说明它消费、更新或验证哪些信息。 |
| 最小系统原则 | Minimum-System Principle | 每个单元尽量小且 owner 边界清晰，但整体图必须覆盖目标、权限、证据、执行、验证、反馈、学习和演化。 |

## 技能架构术语

| 中文术语 | English term | 规范定义 |
| --- | --- | --- |
| 技能包 | Skill Package | 有明确触发、输入、输出、边界与验证方式的可复用能力包。 |
| 顶层所有者技能 | Owner Skill | 对一类任务的触发、产物、知识和安全边界负责的唯一全局发现入口。 |
| 发现接口 | Discovery Interface | 模型可在全局目录直接发现的顶层 `SKILL.md`；应保持少而稳定。 |
| 所有者内部子技能 | Owner-internal Subskill | 由所有者路由的内部模式；可拥有脚本、示例与测试，但不单独扩大顶层接口。 |
| 兼容性导入 | Compatibility Import | 将外部或旧本地技能的可复用部分放入现有所有者内部，并重写其配置、权限和验证契约。 |
| 上游材料 | Upstream Material | 导入技能中保留的原始参考内容；它不是本地系统的自动执行授权。 |
| 规范源 | Canonical Source | `F:\codex\skills`、`F:\codex\docs`、`F:\codex\scripts` 等受版本控制、验证和回滚保护的权威内容。 |
| 全局接口 | Global Interface | `$CODEX_HOME\skills` 中指向规范源的受控发现入口，通常是 junction。 |
| 规范化 | Normalization | 统一目录、元数据、术语、配置边界、验证与交接，而不盲目复制上游运行时。 |
| 路由 | Routing | 根据任务契约选择所有者与内部模式的过程。用户可请求能力，模型负责在已授权范围内路由。 |
| 所有者经济性 | Owner Economy | 优先扩展既有所有者或内部子技能，只有触发、产物、知识或安全边界独立时才考虑新增顶层 owner。 |
| 兼容入口 | Compatibility Surface | 为迁移、重命名或旧调用保留的临时入口；新工作应路由到当前规范入口。 |

## 任务与需求术语

| 中文术语 | English term | 规范定义 |
| --- | --- | --- |
| 用户原话 | Literal User Goal | 用户明确说出的目标、限制、偏好或问题；优先级高于模型推断。 |
| 可逆假设 | Reversible Assumption | 不改变目标即可调整的本地实现判断；应在简报或回复中标明。 |
| 排除项 | Exclusion | 为防止范围蔓延而明确不做的事项。 |
| 验收标准 | Acceptance Criteria | 用户或系统可观察到的完成条件；每项都应对应验证方式。 |
| 未决问题 | Open Question | 当前无法由文件、历史或安全默认值判断，且会影响交付、验证或授权的问题。 |
| 后果性决策 | Consequential Decision | 不同选择会显著改变范围、安全、成本、验证或后续维护的决策。 |
| 项目本地词汇 | Project-local Vocabulary | 仅在具体项目或任务中使用的术语约定；当一个词反复歧义时才写入需求简报。 |
| 术语锁定 | Term Lock | 对同一概念选定一个规范中英文表达，并在本任务或文档族中一致使用。 |
| 术语漂移 | Terminology Drift | 同一词被用于不同概念，或同一概念被多个词反复替换，导致路由、验证或交接变差。 |

## 证据与经验术语

| 中文术语 | English term | 规范定义 |
| --- | --- | --- |
| 源事实 | Source Truth | 当前文件、用户授权、运行结果或权威外部来源中可直接核对的事实。 |
| 派生证据 | Derived Evidence | 由索引、报告、摘要、渲染或缓存生成的证据；必须受当前源事实约束。 |
| 图证据 | Graph Evidence | Codebase Memory 等结构化索引提供的仓库关系证据；用于定向阅读和影响分析，但不能替代源文件或运行验证。 |
| 证据梯子 | Evidence Ladder | 先用项目权威文件和已验证经验，再用确定性脚本，最后才用新的模型或外部证据的资源节约顺序。 |
| 经验提升 | Experience Promotion | 将候选经验在足够验证、范围、失效条件和安全边界下提升为可复用规则。 |
| 失效条件 | Invalidation Condition | 一条经验或规则不再适用的触发条件，例如版本变化、路径变化、权限变化或反例出现。 |
| 回归验证 | Regression Validation | 证明修复没有重新引入旧问题或破坏关联行为的检查。 |
| 完成声明 | Completion Claim | “已完成、已修复、已发布、可复用”等结论性说法；必须绑定当前任务证据。 |

## 配置与资源术语

| 中文术语 | English term | 规范定义 |
| --- | --- | --- |
| 便携配置 | Portable Profile | 可共享的配置键、选择和占位说明；不含账户、路径、令牌、Cookie 或密钥。 |
| 私有配置 | Private Profile | 本机可用的非秘密偏好记录；位于 Codex Home 私有配置区域，不进入 Git。 |
| 凭据 | Credential | 密钥、令牌、Cookie、证书、认证状态及等价敏感信息；只能通过安全凭据机制处理。 |
| 运行时 | Runtime | Python 环境、Node 依赖、浏览器状态、系统软件及其缓存；不是技能内容，按需单独安装。 |
| 资源经济 | Resource Economy | 在质量和安全不下降的前提下，减少不必要的模型上下文、人力步骤、下载、重复执行与接口数量。 |
| 脚本资产 | Script Asset | 拥有稳定输入、输出、验证和所有者边界的可执行自动化；应像技能和知识一样维护。 |
| 快速验证 | Fast Verification | 面向开发过程的低成本语法、接口或局部行为检查；不能替代发布或完整迭代证明。 |
| 完整验证 | Full Validation | 面向完成、发布或全局变更的完整检查；包括接口、回滚、状态、隐私和无回归证据。 |

## Agent 架构术语

| 中文术语 | English term | 规范定义 |
| --- | --- | --- |
| Agent 线束 | Agent Harness | 协调模型、资源、工具、状态、事件、权限和验证的运行/治理层。本地 Global Experience Agent 中主要对应 `codex-self-evolution` 和 `agent/40-runtime/Invoke-GlobalExperienceAgent.ps1`，不是新的外部运行时授权。 |
| Agent 资源 | Agent Resource | 可被 harness 选择、加载、组合或验证的信息元与功能元，包括 owner skill、subskill、脚本、测试、知识、术语、生命周期状态、模型/工具配置和发布证据。 |
| 专家 Agent | Specialist Agent | 由一个 active owner 适配而成的可调用 Agent。其 ID、Skill、触发、输入、输出、验证、工具闸门和往返 handoff 由 owner network 约束，不产生第二套 owner。 |
| 概念 Agent | Concept Agent | 将多个现有 owner 组合为一个可委派的逻辑角色，例如经验记忆、交付、平台或自我进化 Agent；它通过 Agent registry 解析资源和责任，不成为重复的顶层 Skill。 |
| Agent 工具闸门 | Agent Tool Gate | 对高风险或可变更动作的预检与授权边界，例如 Git、发布、安装、凭据、外部服务、破坏性操作和顶层 owner 调整。 |
| 会话分支 | Session Branch | 围绕一个任务或对话状态形成的可恢复路径；本地可由 conversation continuity、项目状态、候选记录、错误反馈、回滚快照和发布证据表达。 |
| 保存点 | Save Point | 经验证后允许影响下一轮执行或发布的状态边界，例如 rollback snapshot、publication envelope、complete iteration proof 和 release evidence。 |
| 扩展表面 | Extension Surface | 能改变 harness 行为或暴露新工具的包、hook、MCP、脚本、项目本地资源或子 agent 模式；必须经过来源、信任、范围、回滚和验证检查。 |
| 项目信任 | Project Trust | 是否加载项目本地可执行/行为资源的输入边界。它不是沙箱；不替代凭据、文件系统、网络、发布或破坏性操作的授权闸门。 |
| 子 Agent | Subagent | 根 Agent 在当前授权下创建的持久子分支；必须记录父会话、注册 Agent profile、目标、授权哈希、隔离写入面、验收、证据化完成、合并验证或取消状态。委派不扩大权限，也不绕过 owner 工具闸门。 |
| 调用者上下文 | Caller Context | 当前调用者、模型提供方、模型和兼容 host 的非秘密标签。会话身份由持久 Session ID 决定，因此不同授权用户或模型可在保存点继续；标签本身不授予权限。 |
| Agent 事件循环 | Agent Loop | 从用户目标、经验上下文、资源选择、工具闸门、结果观察到保存点提交的有序执行循环；它描述阶段和证据，不授权隐藏后台工作。 |
| Agent 阶段 | Agent Phase | Harness 当前可接受的操作状态，例如 idle、turn、compaction、branch_summary 和 retry；结构性突变只能发生在 idle 或验证过的保存点边界。 |
| 持久会话条目 | Durable Session Entry | 可用于恢复、分支、压缩、审计或发布证明的最小状态记录；本地对应生命周期状态、错误报告、候选记录、迭代证明和发布证据。 |
| 工具调用生命周期 | Tool Call Lifecycle | requested、preflighted、authorized、executed、observed、verified、captured_or_reported 的工具行为状态链；非幂等副作用不得凭模型意愿重试。 |

## Git 与发布术语

| 中文术语 | English term | 规范定义 |
| --- | --- | --- |
| Git 里程碑 | Git Milestone | 初始化、提交、合并、变基、标签、推送或 Release 等会改变版本历史或外部可见状态的事件。 |
| 暂存范围 | Staged Scope | 当前准备提交的精确路径集合；不能混入无关工作区变更。 |
| 私有发布 | Private Release | 面向私有远程或私有 GitHub Release 的发布流程；仍需验证、版本、说明、可见性与权限证据。 |
| 公开发布 | Public Release | 会让内容对外公开的发布流程；需要更强的隐私、版权、说明和显式授权门槛。 |
| 发布元数据 | Publication Metadata | 版本号、CHANGELOG、release note、README、标签、远程、可见性和发布证明。 |
| 本地检查点 | Local Checkpoint | 记录当前仓库、分支、提交或路由状态的本机恢复锚点。 |

## 术语维护规则

1. 优先复用本表术语；只有当现有术语无法表达新的协作边界、验证边界或用户可见概念时才新增。
2. 新术语应同时给出中文、稳定英文、三方共同含义、使用范围和失效条件。
3. 项目、论文、产品或领域专有术语不直接进入本表；先放入项目本地词汇、领域术语表或需求简报。
4. 候选经验中的术语可用于受控试用，但在验证和提升前不得成为强制路由规则。
5. 改名或废弃术语时保留兼容说明，更新引用文档，并用搜索或脚本验证旧术语不会误导路由。
6. 用户问“这是什么意思”时，优先用本表解释；用户使用近义词时，模型可映射到稳定 term 并说明映射。

## 使用约定

1. 用户用“目标、产物、约束、授权”描述需求；不必指定内部子技能。
2. 模型先选择顶层所有者，再选择子技能或参考材料；不得把导入包名称当成新的默认入口。
3. Global Experience Agent 以任务契约、交接、Agent Memory 和验证证据连接模块；候选经验和错误反馈在验证前不改变默认行为。
4. “同步”指经过验证的私有 Git 同步；“发布”还要求版本、说明和发布闸门。两者都不等于未经授权的外部行动。
5. 当需求中出现反复歧义的领域词，模型应把它写入项目本地词汇，而不是污染全局协作术语表。

## English Appendix (Stable Model Terms)

Use **Collaboration Terminology** for the shared vocabulary used by the user,
the model, and the local Global Experience Agent. Use **Owner Skill** for the single
public discovery surface; use **Owner-internal Subskill** for a routed
capability that shares the owner's artifact and safety boundary. A
**Compatibility Import** preserves reusable upstream material while translating
it to the local authority, privacy, configuration, and validation contract.
**Canonical Source** is versioned architecture content; a **Global Interface**
is its managed Codex Home discovery link. A **Candidate Experience** is
advisory until supported by verification evidence and an appropriate promotion
decision. A **Project-local Vocabulary** belongs in the task or project brief
when repeated ambiguity affects delivery; it does not create a global term by
itself.
