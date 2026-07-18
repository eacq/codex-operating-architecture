# Codex 经验与知识操作架构需求手册

> 状态：已验证基线
>
> 适用版本：0.7.x
>
> 权威仓库：`$ARCHITECTURE_ROOT`
>
> 面向用户：本机 Codex 使用者、维护该架构的 Codex 任务

## 1. 目标

本架构应让 Codex 在任何项目中自动进入统一的生命周期：理解项目需求，执行并验证任务，沉淀项目经验，在 Git 里程碑或完整迭代后复盘，并只把跨项目有效的结论提升到全局 skill 和知识系统。系统必须减少重复指导，同时避免把完整会话、项目私有事实和用户不需要记忆的运行规则混入全局上下文或 Anki。

## 2. 权威来源与责任边界

| 内容 | 权威位置 | 约束 |
|---|---|---|
| 全局架构、skills、脚本和策略 | `$ARCHITECTURE_ROOT` | 唯一可迭代源码，必须进入 Git |
| 全局 skill 发现接口 | `$CODEX_HOME\skills` | 目录联接到 `$ARCHITECTURE_ROOT`，不得形成独立副本 |
| 全局项目入口规则 | `$ARCHITECTURE_ROOT\config\global-AGENTS.md` | Codex Home 只保留链接或托管入口副本 |
| 项目需求、工作流和项目经验 | `<project>\.codex\project` | 留在项目内，不复制到全局知识库 |
| 全局经验 | `knowledge/experience-ledger.md` | 仅保存已验证、跨项目、非重复规则 |
| 结构化知识 | `knowledge-vault` | Obsidian Markdown 和类型化链接是权威源 |
| Codex 本地学习 | `knowledge-vault/50-Learning/codex-learning.json` | 用于未来任务和 skill 迭代，不进入用户 Anki |
| 用户学习 | `knowledge-vault/50-Learning/user-anki-import.tsv` | 仅包含用户本人值得主动回忆的知识 |

## 3. 功能需求

### FR-01 全局项目入口

- 每个新 Codex 运行必须加载 Codex Home 下的全局 `AGENTS.md`。
- 任意项目任务入口必须先路由 `$codex-self-evolution`，再选择更窄的模块。
- 简单只读任务只做状态检查，不得为了生命周期而制造无关文件变化。
- 项目内更近的 `AGENTS.md` 可以补充项目规则，但不得无意复制全局 skill 正文。

### FR-02 项目首次初始化

- 实质性项目工作开始前检查 `<project>/.codex/project/state.json`。
- 缺失时调用 `$codex-project-optimization`，生成需求、工作流、经验、复盘、事件和状态文件。
- 初始化器只能更新 `AGENTS.md` 的托管块，必须保留托管块外内容。
- 不得覆盖已有 Git hook；只有用户要求或安全确认后才安装 hook。
- Git 根异常（例如整个用户目录）时必须停止自动 hook 操作并重新识别项目根。

### FR-03 任务执行与验证

- 实施前读取项目需求、工作流和相关已验证经验。
- 变更范围、测试强度和复盘深度随风险增长。
- 验证失败时不得把结论提升为全局规则。
- 生成文件必须在连续运行中保持稳定，除非输入事实发生变化。

### FR-04 Git 与完整迭代

- Git 初始化、提交、合并、变基、标签、发布和完整验证迭代均为经验同步触发点。
- 先更新项目需求、工作流、经验和复盘，再考虑全局晋升。
- 全局晋升必须满足：非显然、具体、已验证、可跨项目复用、非重复，并记录适用范围和失效条件。
- GitHub 仓库可按发布阶段设置公开或私有；公开、发布和破坏性 Git 操作仍需明确授权。

### FR-05 模块自治

- `codex-self-evolution` 是唯一总控；功能模块按 `module-registry.json` 注册。
- 新模块至少需要两个独立使用场景，且现有模块无法清晰归属。
- 高度重叠模块应合并；停用模块至少保留一个发布周期再删除。
- 模块增减必须有证据，不得仅因主观偏好调整。
- 自我迭代或结构优化必须先将终极协作目标转化为可验证要求：能力结果、角色与交接、资源节约、安全边界、反馈/回滚演进；记录基线、预期贡献和无回归检查。无法证明净改进时保留现状，仅记录候选或证据审查。
- 用户可授权将候选经验推广为“受限经验”：必须保留原始候选措辞、来源、范围和失效条件，可用于路由与最小范围试验，但在独立验证前不得视为强制规则，也不得绕过验证、安全、安装、凭据、发布或回滚边界。

### FR-06 全局 skill 安装与迭代

- `scripts/install-global.ps1` 默认用目录联接注册全部架构 skills。
- Codex Home 全局入口和 架构源码必须一一对应，重复安装应幂等。
- 全局指导文件优先使用符号链接；权限不足时允许带托管标记的入口副本，并在每次安装时从 `$ARCHITECTURE_ROOT` 刷新。

### FR-06A 可移植 skill 分发

- 可共享 skill 必须把通用流程与个人服务商、端点、路径、软件选择、账号和密钥配置分离。
- 克隆者首次使用时必须能选择 API-key、ChatGPT 登录或跳过，并可选择软件；初始化不得写入密钥、Cookie、令牌或账号数据，也不得自动安装软件。
- 仓库必须提供本地私有配置模板、审计入口和克隆后的安装/验证说明。
- 非空用户全局指导文件不得被静默覆盖。
- `scripts/validate-global-install.ps1` 必须检查遮蔽文件、指导内容和全部联接。

### FR-07 经验与知识系统

- 原始会话不进入知识库；只保存脱敏证据摘要和来源指针。
- 每篇知识笔记必须具有稳定 ID、类型、状态、来源和验证状态。
- 链接必须表达依赖、应用、证据或对比，不以链接数量代替质量。
- Markdown 是唯一权威知识源；MindMaster、Mermaid、PNG 和图谱均为派生视图。
- 导图生成器必须产生开放格式大纲、Mermaid 和关联清单。

### FR-08 学习受众分流

- `learning_audience: codex` 必须提供 `codex_learning`，只进入 Codex 本地学习索引。
- `learning_audience: user` 必须提供 `anki_question` 与 `anki_answer`，只进入用户 Anki TSV。
- `learning_audience: both` 必须分别提供 Codex 总结和用户回忆问题。
- 受众缺失、字段不完整或字段冲突时构建必须失败。
- 不得因为 Codex 需要保留某条运行规则，就要求用户在 Anki 中记忆它。

### FR-09 图片与图床

- 图像工作流先记录读者任务、视觉类别、最终格式、尺寸、透明/可编辑需求、来源和最终尺寸预览；格式由交付需要决定。
- Mermaid 只用于小型、可审查的确定性结构；SVG 只用于确有可编辑矢量结构价值的图；两者都不是普通视觉的默认兜底。
- 透明背景、清晰标签、界面或无损栅格优先 PNG；不透明的照片感、封面或绘画视觉在体积更重要且压缩不伤害信息时优先 JPG；WebP 仅在兼容性已验证时作为保留源文件的派生交付格式。
- 面向读者的内容创作必须先形成来源感知的简要包、主张约束和提纲，再交付草稿、必要的视觉或 Office 交接件及复核记录；草稿不构成发布、登录、上传、付费生成或版权复用授权。
- 每次完成的全局经验迭代必须生成候选汇总报告，列出项目经验、经验台账、候选知识、workflow-learning 和候选错误反馈的来源、证据、建议决策及授权边界，供用户决定保留、测试、晋升、废弃或另行授权；Markdown 必须以便于用户决策的中文为主，并在末尾附上字段稳定的英文经验系统附录；候选原文保持来源文本，以避免自动翻译改变含义。报告本身不得自动执行上述动作。
- 完整全局经验迭代可使用 `-Staged -AutoCommit -Apply` 自动创建本地 Git 提交，但仅当暂存范围明确、全量验证与迭代证明通过、元数据完备且不存在范围外改动时才允许；自动提交不得推送、打标签、发布或后台运行。
- 只允许用户拥有、系统生成或明确开放许可的图片。
- B 站图床只能按需触发，禁止定期扫描任务。
- 迁移顺序必须为：发现、上传、HTTPS CDN 校验、隔离备份、清单、引用替换、零残留检查、本地删除。
- 任一步失败必须停止删除并保留原图；凭据只能通过 DPAPI 文件保存，不得进入 Git、文档或日志。
- 必须兼容已验证的 `.biliimg.com`、`.hdslb.com` 和 `.bilibili.com` CDN。

### FR-10 工具与软件安装

- 软件包和离线安装器保存在 `$SOFTWARE_ARCHIVE_ROOT\<软件名>`。
- 支持自定义位置的软件安装在 `$SOFTWARE_INSTALL_ROOT\<软件名>`。
- 安装或升级外部软件前必须提示对象、来源、范围和影响。
- 普通 skill、模板、脚本和配置处理不需要逐项提示。
- 现有软件满足需求时不得仅因版本较旧而更新。
- 不自动迁移既有安装和用户数据；安装后必须验证真实执行位置并记录结果。

### FR-11 编辑与阅读工具

- Obsidian 支持双向链接、检索和知识图谱。
- MindMaster 只作为可视化和导出层，不得成为唯一知识副本。
- VS Code Foam 读取知识目录的 wikilink、反向链接和图谱。
- Markdown Preview Enhanced 自动渲染 Mermaid 与 HTTPS 图片，同时禁用脚本执行和 HTML5 嵌入。
- 本机 VS Code 已具备 Markdown Preview Enhanced 时，所有打开的 Markdown 文件应自动显示源文件右侧的渲染预览，并启用多预览、实时更新和滚动同步；该规则只修改本机编辑器偏好，不安装扩展也不写入项目文件。

### FR-12 安全与隐私

- 禁止提交密码、令牌、Cookie、`auth.json`、DPAPI 密文文件和原始私密会话。
- 用户曾在聊天中粘贴的凭据视为暴露，必须轮换后才能使用。
- Chrome 登录态只能用于可见操作或人工取值指导，不得自动提取 Cookie、密码或会话存储。
- 删除、公开、付费、提权、权限扩大和不可逆外部变更仍需更高等级确认。

### FR-13 私有 OpenAI-compatible provider 诊断

- Provider 检查必须支持本地 profile 中配置的 OpenAI chat-completions 形状。
- 检查脚本不得依赖第三方 Python 包，不得打印密钥、认证头或模型回复正文。
- 401/403 只能触发安全凭据来源切换；已鉴权的 5xx 应优先尝试一个文档内模型回退，不得盲目轮换密钥。
- Codex `auth.json` 仅在本地 profile 或 active provider 明确选择对应 provider 时作为候选凭据来源。
- 模型可用性和配额成本必须分别核验，不把一次成功写成永久保证。

### FR-14 运行环境与脚本

- 在 `$ARCHITECTURE_ROOT` 保存最小基础环境定义和忽略提交的物理环境，各项目在 `.codex/runtime` 保存隔离环境、直接依赖、锁定快照及 PowerShell/CMD 入口。
- 项目环境必须从基础环境创建，项目专用依赖不得直接安装到基础环境。
- 依赖使用必须记录项目、用途、结果和验证；至少三个成功事件跨两个项目才成为基础候选，候选仍需兼容性复核。
- 环境本体、缓存、凭据和机器激活状态不得进入 Git；外部软件或依赖安装仍遵守安装提示规则。

## 4. 非功能需求

### NFR-01 可恢复性

- 所有全局架构变更必须可通过 Git 提交和标签回滚。
- 图片删除必须有隔离副本和迁移清单。
- 项目托管块、Git hook 和用户文件均采用非破坏性更新。

### NFR-02 幂等性

- 全局安装、知识生成、导图生成和项目初始化重复运行不得产生无事实变化的差异。
- 生成输出应通过连续两轮哈希或 Git diff 稳定性检查。

### NFR-03 可验证性

- `scripts/validate.ps1` 必须校验全部 skills、历史索引、秘密扫描、模块注册、知识图、导图和图片回归测试。
- `scripts/validate-global-install.ps1` 必须独立校验全局入口。
- Python 工作流必须使用未来 Codex 实际会使用的 bundled Python 验证。

### NFR-03A GitHub 描述同步

- 每次非合并 Git 提交前必须更新 `CHANGELOG.md` 并运行发布元数据检查。
- 影响公开使用、安装、配置或安全边界时，必须同步 `README.md` 或对应 `docs/`；版本变更还必须同步版本说明和发布说明。
- GitHub 描述不得包含密钥、Cookie、令牌、账号信息或原始私有会话内容。

### NFR-04 成本与上下文

- 历史处理优先元数据和索引，再按需读取相关原始记录。
- 不把完整历史、所有知识笔记或所有 skill 正文一次性加载进上下文。
- 小任务不套用大型流程，但不得绕过风险相关验证。

## 5. 明确排除

- 不建立定时图床扫描或定时 Cookie 检查。
- 不保证非官方 B 站文章封面接口永久可用。
- 不把项目私有需求和经验集中复制到全局知识库。
- 不把每个知识节点都转换成 Anki 卡片或图片。
- 不自动升级 MindMaster、Obsidian、Anki、VS Code 或其他现有软件。
- 不自动公开 GitHub 仓库或执行付费操作。

## 6. 验收矩阵

| 编号 | 验收方法 | 通过条件 |
|---|---|---|
| AC-01 | 运行 `scripts/validate-global-install.ps1` | 全局指导有效，23 个 architecture-root skill 接口全部正确，无遮蔽 |
| AC-02 | 在新项目运行 `scripts/init-project.ps1` | 创建 5 类生命周期文件和托管块，不覆盖用户内容或 hook |
| AC-03 | 连续运行两次 `scripts/validate.ps1` | 两次均通过，生成结果稳定 |
| AC-04 | 构造受众冲突的知识笔记 | `build_knowledge.py` 明确拒绝 |
| AC-05 | 检查学习输出 | Codex JSON 与用户 Anki TSV 分离，旧模糊 TSV 不存在 |
| AC-06 | 执行一张测试图迁移 | 远程 HTTPS 可访问、Markdown 已替换、清单已提交、本地源已安全删除 |
| AC-07 | 检查配置策略 | `periodic_scan=false`，软件包与安装位置符合 本地软件根策略 |
| AC-08 | 检查 Git | 版本、提交、标签与远程主分支一致，无秘密进入提交 |
| AC-09 | 运行 `your-api-source/scripts/check_your_api_source.py` | `TEST_API_KEY` 失效时安全切换到获批凭据来源，输出只含模型、来源名称和状态 |
| AC-10 | 初始化基础环境与临时项目环境 | Python、PowerShell 和 CMD 入口均使用隔离解释器，物理环境保持 Git 忽略 |

## 7. 运行入口

```powershell
# 全量架构验证
.\scripts\validate.ps1

# 全局接口验证与刷新
.\scripts\install-global.ps1 -Mode Junction
.\scripts\validate-global-install.ps1

# 新项目初始化
.\scripts\init-project.ps1 -ProjectRoot <项目路径>

# Python 与脚本运行环境
.\skills\codex-runtime-environments\scripts\Manage-CodexEnvironment.ps1 init-project -ProjectRoot <项目路径>

# 知识与学习分流
python .\skills\codex-knowledge-system\scripts\build_knowledge.py
python .\skills\codex-knowledge-system\scripts\build_mindmaps.py
```

## 8. 变更规则

- 补充说明或修复不改变契约时增加补丁版本。
- 新增兼容能力或新的可选工作流时增加次版本。
- 学习字段、模块契约、安装接口等不兼容变化增加主版本。
- 每次完整迭代必须更新项目复盘；只有跨项目证据充分时才同步经验账本或对应 skill。
