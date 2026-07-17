# Experience Ledger

## 已验证经验

- GitHub 文档的双语门禁在 Windows 上不得依赖控制台代码页或乱码文本匹配；应使用 Unicode 码点构造中文标记并检查实际暂存内容。该规则经完整 `v1.0` 私有同步与公开发布验证。
- 已验证的工作流变更应生成带哈希、关联 owner 与证据计数的学习记录；该记录同时进入知识和经验候选队列，经过证据门槛后才允许由架构迭代决定精炼、合并、拆分、增加或废弃，不能将工作流原文无条件提升为全局规则。
- 经验版本采用 `P.R.A.B` 四段格式：`P` 仅由公开仓库 release 决定，`R` 仅由私有仓库 release 决定，`A` 由经验系统的自动功能提交递增，`B` 由自动修复提交递增。只有明确的“同步经验系统”才创建私有 release；只有明确的“发布经验系统”才创建公开 release。
- codebase-memory-mcp 适合作为仓库级取证路由层：先索引并读取 schema/architecture/search/trace 结果，再打开被引用的源文件核验。单次图谱搜索失败不能作为缺失证明；在本架构仓库中，`search_code` 能找到 `search_graph` BM25 未命中的发布流程文本，说明图谱工具应组合使用并记录覆盖限制。

- Every verified implementation iteration should regenerate a bilingual status document and verify its changelog, README, and version-note dependencies before private commit. Private skills, knowledge, and experience become public candidates only with two independent verified evidence sources, a sanitization audit, local-only preservation of original non-secret configuration, and a separate release decision.

- Autonomous Git is safe only as a verified private-commit gate: require a completed iteration, explicit separable paths, semantic-version and bilingual GitHub metadata, full validation, and GitHub-CLI confirmation that `origin` is private. Commit and push only those paths to `origin`; never infer approval for public remotes, tags, releases, breaking-major versions, or a mixed worktree.

### 项目生命周期

- 学术任务跨越读论文、证据综合、写作、科研代码和图表时，先建立包含研究问题、来源定位、交付物和证据状态的项目内清单，再交接给专业 skill。标题、URL、搜索摘要或模型共识都不是证据本身；来源抽取、引文核验、文本改写、代码修改和制图保持独立所有权。
- 完整本地经验迭代按项目生命周期、待同步事件和错误报告、元数据会话目录、记忆索引、全局账本、关联知识索引的顺序取证；单条会话标题不是晋升证据。派生 UTF-8 JSON 必须由创建它的运行时或等效 UTF-8 解析器验证，Windows PowerShell 默认解码的解析失败不能直接判为数据损坏。
- 项目首次使用时建立项目内的需求、工作流、经验、复盘和状态文件；项目事实留在项目仓库，全局 skill 只吸收跨项目且已验证的规则。
- 项目创建能力不只是初始化目录；应把文件夹证据转换为生命周期文件、项目本地 skill、storage/index、运行时预检、错误反馈报告和已验证复盘，然后只把具备范围与失效条件的通用规则晋升到全局知识。
- Git hook 只记录待同步事件，不直接运行模型或改写业务文件；后续 Codex 任务读取事件并完成有证据的总结。
- 经验晋升要求非显然、具体、已验证、可复用且不重复。未满足条件的候选跨迭代保留，不写成强制规则。
- 流程强度应随风险增长：小改动保留必要取证和验证，但不套用大型状态机；契约、认证、数据和发布变更需要更完整的需求、回滚和复盘。
- 项目学习与联网学习共享“具体能力缺口 -> 合格证据 -> 与既有 owner 对比 -> 可逆验证 -> 经验/知识晋升”的闭环时，应作为同一学习模块的子工作流；用户认可必须有独立佐证，单次表扬、单条来源或单次会话均不得直接改写全局规则。完成学习后先审查模块关系，再精炼重复指令与失效边界。

### 操作提示边界

- Skill 内普通文件处理和全局 skill 文件同步可直接执行，不需要逐项提示。
- 安装或升级外部软件、运行时、系统组件、包管理器或系统环境依赖前，应先说明安装对象、来源、范围和影响。
- Skill 文件复制不等同于软件安装；破坏性、公开、付费、提权和不可逆外部操作仍遵守更高确认边界。

### 精确 Word/DOCX

- 普通文档创建、批注和常规样式调整由 `documents` 负责；当保留模板、页眉页脚、分节/分栏、引用字段、OMML、媒体关系或分页渲染容易被整文档保存破坏时，转入 `codex-exact-word-layout`，不新建重叠 Word skill。
- 锁定模板 DOCX 的变更前先记录源文件、不可变输出位置、关键 package part 与媒体哈希、节/栏拓扑和预期变更面。未改动二进制 part 用哈希验证；预期修改的 XML 用规范化语义比较，不能因一个例外属性而放宽整份 header/package 校验。
- 采用最小编辑面：优先局部 OOXML/运行片段补丁；若必须经 Word 自动化或高层库保存，保存后重新审计 headers、relationships、styles、settings、media 和渲染页面。高层库整文档 round-trip 不是无害操作。
- 验收分为两层：包损坏、受保护媒体变化、引用/字段/公式丢失、模板硬错误和图表题分离属于硬失败；可疑分节符、空段、短行和留白是渲染人工复核队列。结构检查通过不能替代 Word/PDF/PNG 页面审查。
- 定位局部版式问题时依次检查段落机制、分页控制、题注-对象与分节转换、对象环绕、活动页眉页脚；不要先用空格、全局缩进重置、批量删节或整套页眉替换掩盖症状。

### 论文修订与学术表达

- 论文修订按“整体论证与章节角色 -> 段落逻辑 -> 句级学术表达 -> Word 安全写回与渲染复核”分层进行；先改善逻辑关系，再替换同义词。表达修改不能代替研究设计、数据解释、引文核验或作者对结论强度的决定。
- 默认保护数值、单位、条件、效应方向、比较基准、术语、缩略语、公式、变量、图表引用、引用/字段/超链接/书签、结论范围、因果强度和不确定性。遇到歧义或证据缺口应标记，而非补写机制或强化结论。
- 对“去 AI 痕迹”的处理只描述可观察问题：空泛价值判断、模糊施事、抽象名词堆叠、无逻辑关系的连接词链、对称罗列、夸张新颖性和缺少证据指向的推广。用具体对象、关系、机制、条件或指标修复，不根据文风断言作者身份。
- 含引用、交叉引用、字段、OMML 或复杂 run 的 Word 段落不可整段粗暴替换。先保留受保护标记与运行结构，再局部修改非受保护文本；任何版式压缩都必须回到精确 Word 的 package/渲染 QA。

### Windows 与 Git

- 当用户说“启用 Git”时，依次检查 `git --version`、`where.exe git`、`git rev-parse --show-toplevel` 和 `git status --short --branch`。Git 已安装时，真实问题常是仓库根目录错误或缺少远程，而不是需要重装。
- Windows 网络不稳定导致 clone 重置时，可尝试 `git -c http.version=HTTP/1.1 clone --depth 1 ...`，但使用前仍应检查当前网络和远程状态。
- 不跨 shell 拼接删除或移动命令；递归文件操作前验证绝对路径位于目标工作区。

### Skill、插件与运行时

- 用户已经指定安装目标时，直接安装该目标并完成验证，不重新展开候选讨论。
- Python 工作流必须验证未来 Codex 实际使用的运行时；本机优先检查 Codex bundled Python，而不只检查项目 venv。
- 验证器缺少依赖不等于 skill 本身损坏，应先区分运行时问题与内容问题。
- Windows 上含中文的工具输出应显式使用 UTF-8；扫描 skill 时排除 `venv`、缓存和生成目录。
- 后续软件下载包统一保留在 `$SOFTWARE_ARCHIVE_ROOT\<软件名>`，支持自定义目录的软件统一安装到 `$SOFTWARE_INSTALL_ROOT\<软件名>`；安装后必须核验实际位置，不能静默接受系统盘默认路径。
- 既有软件升级优先保持原安装目录，不自动迁移用户数据；不支持自定义目录的安装器应先报告例外。
- VS Code 扩展安装应保留官方 VSIX 到 `$SOFTWARE_ARCHIVE_ROOT\VSCodeExtensions`。若既有扩展目录已在用户目录，为避免破坏当前插件与配置可继续沿用，不自动迁移；项目通过 `.vscode/extensions.json` 和安全的项目级设置声明可恢复能力。
- 本架构的全局 skill 路径使用目录联接指向 `$ARCHITECTURE_ROOT\skills`，Codex Home 仅作为 Codex 自动发现接口，不保留可独立编辑的副本。迭代、校验、Git 提交和回滚全部以 `$ARCHITECTURE_ROOT` 为准。
- 用 Codex Home 下的全局 `AGENTS.md` 在任何项目入口强制路由 `$codex-self-evolution`；优先链接到 `$ARCHITECTURE_ROOT\config\global-AGENTS.md`。Windows 未授权文件符号链接时，可使用由安装脚本刷新的托管入口副本，但不得在 Codex Home 独立迭代。总控先检查项目生命周期状态，再按任务规模决定是否初始化或只做无改动检查。
- Skill 精简应优先删除跨模块重复叙述，让总控只负责路由、专属模块保留脆弱顺序和安全边界、可选细节进入直接 reference。只有触发、流程和维护知识都高度重叠时才合并；不能仅为减少模块数量而牺牲所有权边界。

### API 与凭据

- 私有 OpenAI-compatible provider 只在目标需要兼容 chat/embeddings 时作为替代；不能默认替代 Gemini 图像、音频转写、OpenRouter 图像或领域文献 API。
- 私有 OpenAI-compatible provider 的 401/403 表示凭据来源被拒绝，应先规范化密钥并切换获批安全来源；已鉴权的 500/502/503 表示模型或提供商路由不可用，应保留凭据并只尝试一个本地配置的模型回退。陈旧 provider 环境变量可能遮蔽有效 Codex `auth.json`，诊断输出只能包含来源名称和状态。
- Zotero Web API 应先用 `/keys/<key>` 获取 numeric user ID，再访问 `/users/{id}`；仓库仅记录变量名与验证方法，不记录 key 或用户秘密。
- 文档中的示例使用明显的占位符，禁止放入形似真实密钥的字符串。用户在聊天中暴露有效密钥时，应建议轮换。

### 项目维护与文档

- 代码改动先映射入口、数据流和验证命令；不随机删除或缩短有意义的注释。
- WinForms 可读性调整优先检查手写逻辑，除非明确要求布局变更，否则避免盲改 `*.Designer.cs`。
- 对 RotorGrindCAM 的快速构建验证使用 `dotnet msbuild RotorGrindCAM.sln /p:Configuration=Debug /p:Platform="Any CPU" /v:minimal`，但应先确认当前仓库和工具链仍匹配。

### 图片与图床

- 结构关系优先使用 Mermaid 等文本原生图，减少二进制文件和外部依赖；位图只在能显著提高理解密度时加入。
- 仅上传用户拥有、生成或明确开放许可的图片。B 站专栏封面接口不是正式通用存储契约，必须隔离适配器并保留迁移清单。
- 本地图片只有在上传成功、HTTPS CDN 可访问、所有 Markdown 引用替换成功、隔离副本和清单写入成功后才能删除。
- Cookie 使用 Windows DPAPI 加密并留在 `.sandbox-secrets`，不得进入 Git、Markdown、日志或命令历史。
- Chrome 已登录状态可用于验证和可见 UI 操作，但不能读取 Cookie、Local Storage、密码或会话存储；后台 API 所需秘密只能由用户通过本机安全提示主动写入 DPAPI，或使用正式 OAuth。
- B 站图床不使用定期扫描任务；只在需要迁移图片时按需运行。认证或上传失败时停止替换和删除，并提示用户按 Chrome DevTools Application > Cookies 的方式重新获取 `bili_jct` 与 `SESSDATA`。

### 思维导图与知识复习

- Codex 本地学习与用户 Anki 必须分流：内部运行经验进入可检索的 Codex 学习索引并参与 skill 迭代；只有用户本人需要主动回忆的知识才进入 Anki。未声明受众或字段冲突必须使构建失败。
- 经验与知识架构应至少保留一张跨模块总览图，把证据、经验、权威知识、执行闭环以及 Obsidian、MindMaster、Anki、图床的责任边界放在同一视图中；局部短笔记不为配图而配图。
- Obsidian Markdown 与类型化链接是知识权威源；MindMaster 只用于导图布局、浏览与导出，`.emmx` 不得成为唯一知识副本。
- 先生成 Mermaid 和缩进大纲作为开放格式兜底，再按需在 MindMaster 中编辑。现有软件已满足需求时不因版本较旧而升级。
- 导图 PNG 只在确实提高理解密度或节省空间时进入按需图床流程；不得创建定期扫描或在远程验证前删除本地文件。
- Anki 卡片来自源笔记中的高价值回忆问题，不对导图节点做机械式全量制卡。
- B 站文章封面接口当前可能返回 `article.biliimg.com`；远程校验白名单需覆盖 `.biliimg.com`、`.hdslb.com` 和 `.bilibili.com`，但仍必须要求 HTTPS 与成功 GET。上传成功后若域名校验失败，流程必须保留原图且不得替换 Markdown。

## 候选经验格式

```text
标题：
状态：候选 | 已验证 | 已废弃
触发情境：
观察与证据：
采取行动：
验证结果：
适用范围：
失效条件：
来源：
```
