# 协作术语表 / Collaboration Terminology

本术语表供用户、模型与本地经验系统共同使用。它采用一个核心原则：**用少量稳定的术语描述可验证的协作关系**，而不是为每个工具、脚本或上游项目另造入口。

## 共同术语

| 中文术语 | English term | 共同含义 |
| --- | --- | --- |
| 用户 | User | 给出目标、业务判断、授权与验收的人；不需要承担内部路由细节。 |
| 模型 | Model | 负责推理、执行、解释与交接的语言模型；必须依据证据和授权行动。 |
| 本地经验系统 | Local Experience System | 将技能、知识、工作流、候选经验、错误反馈与验证记录组织成可复用协作能力的本地系统。 |
| 终极目标 | Terminal Collaboration Goal | 让用户、经验系统与模型在质量、安全、资源效率和可持续学习之间形成可验证的团队协作。 |
| 任务契约 | Task Contract | 目标、范围、权限、风险、产物、验收标准和未决问题的最小明确约定。 |
| 协作交接 | Collaboration Handoff | 一个角色向另一个角色交付的可追溯输入、状态、证据和下一步责任。 |
| 权限闸门 | Authority Gate | 需要用户当前授权才可进行的动作边界，例如外部安装、推送、发布、顶层所有者调整。 |
| 验证证据 | Verification Evidence | 支撑“完成、修复、可推广”结论的命令输出、测试、渲染检查、哈希或可复现实验。 |
| 候选经验 | Candidate Experience | 尚未达到推广证据阈值的观察、来源学习或局部成功；它不能自动改变全局行为。 |
| 错误反馈 | Error Feedback | 对异常、错误结果或重复失败的结构化记录，包含用户观察、诊断、修复、回归验证及未解决状态。 |

## 技能架构术语

| 中文术语 | English term | 规范定义 |
| --- | --- | --- |
| 技能包 | Skill Package | 有明确触发、输入、输出、边界与验证方式的可复用能力包。 |
| 顶层所有者技能 | Owner Skill | 对一类任务的触发、产物、知识和安全边界负责的唯一全局发现入口。 |
| 发现接口 | Discovery Interface | 模型可在全局目录直接发现的顶层 `SKILL.md`；应保持少而稳定。 |
| 子技能 | Owner-internal Subskill | 由所有者路由的内部模式；可拥有脚本、示例与测试，但不单独扩大顶层接口。 |
| 兼容性导入 | Compatibility Import | 将外部或旧本地技能的可复用部分放入现有所有者内部，并重写其配置、权限和验证契约。 |
| 上游材料 | Upstream Material | 导入技能中保留的原始参考内容；它不是本地系统的自动执行授权。 |
| 规范化 | Normalization | 统一目录、元数据、术语、配置边界、验证与交接，而不盲目复制上游运行时。 |
| 路由 | Routing | 根据任务契约选择所有者与内部模式的过程。用户可请求能力，模型负责在已授权范围内路由。 |

## 配置与资源术语

| 中文术语 | English term | 规范定义 |
| --- | --- | --- |
| 规范源 | Canonical Source | `F:\codex\skills` 中受版本控制、验证和回滚保护的权威技能内容。 |
| 全局接口 | Global Interface | `$CODEX_HOME\skills` 中指向规范源的受控发现入口（通常为 junction）。 |
| 便携配置 | Portable Profile | 可共享的配置键、选择和占位说明；不含账户、路径、令牌、Cookie 或密钥。 |
| 私有配置 | Private Profile | 本机可用的非秘密偏好记录；位于 Codex Home 私有配置区域，不进入 Git。 |
| 凭据 | Credential | 密钥、令牌、Cookie、证书、认证状态及等价敏感信息；只能通过安全凭据机制处理。 |
| 运行时 | Runtime | Python 环境、Node 依赖、浏览器状态、系统软件及其缓存；不是技能内容，按需单独安装。 |
| 资源经济 | Resource Economy | 在质量和安全不下降的前提下，减少不必要的模型上下文、人力步骤、下载、重复执行与接口数量。 |

## 使用约定

1. 用户用“目标、产物、约束、授权”描述需求；不必指定内部子技能。
2. 模型先选择顶层所有者，再选择子技能或参考材料；不得把导入包名称当成新的默认入口。
3. 经验系统以任务契约、交接和验证证据连接模块；候选经验和错误反馈在验证前不改变默认行为。
4. “同步”指经过验证的私有 Git 同步；“发布”还要求版本、说明和发布闸门。两者都不等于未经授权的外部行动。

## English Appendix (Stable Model Terms)

Use **Owner Skill** for the single public discovery surface; use
**Owner-internal Subskill** for a routed capability that shares the owner's
artifact and safety boundary. A **Compatibility Import** preserves reusable
upstream material while translating it to the local authority, privacy,
configuration, and validation contract. **Canonical Source** is versioned
architecture content; a **Global Interface** is its managed Codex Home
discovery link. A **Candidate Experience** is advisory until supported by
verification evidence and an appropriate promotion decision.
