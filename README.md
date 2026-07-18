# Codex Operating Architecture

English counterpart: [README.en.md](README.en.md)

> 面向本地 Codex 的可验证工作架构：优先复用已验证经验，通过明确 owner 执行变更，并把验证与用户授权保留为不可绕过的门槛。

## 从这里开始

| 你想完成的事 | 建议入口 |
|---|---|
| 初始化新的本地项目 | `scripts/init-project.ps1` 与 `$codex-self-evolution` |
| 优化工作流或学习外部仓库 | `$codex-learning`，再映射到现有 owner，避免重复技能 |
| 排查异常结果 | 先使用 `$codex-error-feedback`，再决定是否推广经验 |
| 优化仓库或 Profile README | `$github-readme-presentation`：审计、整页 README 或仅素材三种模式 |
| 提交已验证的私有架构变更 | `$codex-git-operations` 与精确范围的私有自动 Git 门禁 |

架构遵循“证据优先”：先使用项目权威文件、已验证经验和确定性工具；只有确实改善结果时，才升级到模型、外部信息、视觉、依赖、发布或凭据步骤。

## 协作闭环

先由用户明确目标与授权；`codex-self-evolution` 选择最小 owner 集合；项目经验、知识与确定性工具优先完成可复用工作；模型或外部资源只在明显提升结果时介入；最后由验证、错误反馈和发布门禁决定是否沉淀、提交或发布。

![协作闭环概念图](docs/assets/readme-collaboration-loop.png)

![协作角色与验证闭环图](docs/assets/readme-collaboration-loop-labeled.png)

图内仅保留统一风格的角色标签；具体权限、流程和双语说明保留在 Markdown 中，便于阅读器、用户和模型可靠检索。

![全局架构总览：路由、工作流、知识、验证、发布与学习](docs/assets/readme-architecture-overview-labeled.png)

每次系统迭代都会同时检查两个 README、[更新日志 / Changelog](CHANGELOG.md) 和适用说明文件是否与实际实现一致。知识、经验或工作流存在三个及以上非线性关系且图片能明显提高理解时，优先使用经过脱敏的 GPT 生图；先按交付需要选格式，Mermaid 仅用于小型可审查结构，SVG 仅用于确有可编辑矢量价值的图，普通视觉选择 PNG/JPG 等栅格格式而非无条件回退到 SVG。面向读者的内容创作先形成带来源与主张约束的简要包、提纲、草稿和复核记录；草稿完成不等于获得发布、登录、上传或付费生成授权。

全局文件整理采用“隔离复制、备份与整理、验证沙箱、建立精确迭代前快照、替换、当前目录清理、双重全局复验、生命周期写回”的事务循环。迭代前快照保存所有可能被替换的本地文件和 SHA-256，包括未提交内容，但排除 `.git`、`.codex`、凭据和运行时。任何步骤在替换前失败时当前系统保持不变；替换后失败时自动恢复被修改或删除的文件、移除迭代新增文件、逐项复核哈希并刷新真实全局接口。回退成功后记录错误并要求修复根因、从头重新迭代；回退失败则保持未完成状态并报告严重错误。自动清理仍只处理当前未跟踪的白名单临时/缓存文件及空目录，并在删除前进入外部哈希隔离区。Git 门禁只接受同时具备回退就绪、替换、复验和写回证明的结果。

![事务化文件整理闭环：隔离、备份、整理、验证、替换与恢复](docs/assets/file-organization-architecture-labeled.png)

当错误本身用于测试和排查文件整理模块或全局迭代模块时，可进入“持续诊断模式”：每次失败都记录归属与证据，执行显式的安全修复，再从头复测，直至成功。该模式默认没有人为次数上限，但不会绕过回退校验、凭据、安装、破坏性操作或外部发布边界；回退失败或修复动作失败会立即转为阻断错误。

![隐私安全的文件整理示意图](docs/assets/file-organization-concept.png)

## 迭代说明同步与公开转化

每次已验证的实现迭代都会生成 [Iteration Status](docs/ITERATION-STATUS.md)，记录版本、模块数量和说明门禁。私有 skill、知识与经验只有在具备两个独立已验证证据、完成脱敏和验证后，才能成为公开候选；公开发布仍须单独决策。详见 [Private-to-Public Skill Conversion](docs/PRIVATE-TO-PUBLIC-CONVERSION.md)。

每次完成的全局经验迭代还会生成候选决策报告：中文内容面向用户阅读与授权决策，末尾附有字段稳定的英文经验系统附录；候选原文保留来源表述，避免自动翻译改变含义。报告只汇总证据，不会自动推广候选或执行外部操作。

完整全局迭代可使用 `-Staged -AutoCommit -Apply` 在所有验证门禁通过后自动创建本地 Git 提交；它必须拒绝范围外改动，且不会自动推送、打标签、发布或后台执行。

明确的“同步经验系统”请求走私有发布门禁，不只是提交和推送：`Invoke-ExperienceRelease.ps1 -Mode Private` 会在私有 `origin` 仓库发布 GitHub Release，Git 标签为 `private-vP.R`，Release 标题为 `vP.R`。
同步入口会在生成 release note、README 最新发布块、changelog、视觉计划和 iteration status 后重新计算实际 changed/untracked 路径；提交阶段只接收真实变化路径，若工作树还有未纳入 scope 的脏文件会精确报出并停止，避免使用过期同步计划。

Every private or public experience-system release refreshes both README files, the matching release note, and a release visual plan; important multi-area changes also generate a versioned Mermaid highlight diagram under `docs/assets/`.

“全局经验系统”是 self-evolution、experience capture、error feedback、knowledge 与 architecture iteration 的协同闭环。它优先通过交接件和 owner 内部 subskill 精炼，不把一次系统性整理直接升级为新的顶层模块。

外部 skill 仓库先通过带日期和来源的 network-learning 记录学习，并优先映射到现有 owner。必要且有价值的 skill 可以安装，但安装形态必须经过本地隐私、profile、owner 与验证门禁适配，不能原样照抄上游结构。若 `codebase-memory-mcp` 可用，外部 skill 仓库也按源码仓库处理：先索引、看 schema/architecture、再读源文件核验，最后才决定 learn-only、owner reference、owner subskill、project-local skill 或 global skill。

## Repository channels

- `origin` is a local-only private working remote for normal updates.
- `public` is the reviewed public-release remote and is used only after explicit release authorization.
- Public release checks reject private remote identities, local paths, credentials, tokens, and private-state paths before any public push.

OfficeCLI installed locally is routed by `codex-office-cli` for ordinary `.docx`, `.xlsx`, and `.pptx` structured reads, edits, validation, render previews, and optional MCP use. When the MCP surface is exposed, agents load the OfficeCLI per-format guide before mutation and still treat installed `help` as schema authority. Locked-template Word pagination and journal-format repairs still route to `codex-exact-word-layout`.

## 为什么使用

- 自动进入项目生命周期：首次使用项目时建立需求、工作流、经验、复盘和状态文件。
- 经验不再只留在聊天里：验证后的规则进入 skill、经验账本或 Obsidian 知识库。
- 物料性任务通过小型协作契约协调用户授权、本地经验和模型执行：先复用本地已验证证据，再在确实影响结果时升级资源，隔离写入并保留验证硬门；角色分配不会自动启动代理或外部服务。见[协作闭环图](docs/assets/readme-collaboration-loop.png)。
- 自我迭代和结构优化以终极协作目标为准绳：每轮先落实为能力、协作、资源、安全和演进五项可验证要求，记录基线、预期贡献和无回归检查；不能证明净改进时保留现状，不为迭代而迭代。
- 完整全局迭代采用串行、可恢复的事务控制：调用方超时后先检查生命周期证据，不能启动重叠的替换任务。
- 顶层 owner 可以优化，但每次结构性变更都需要当前迭代的明确授权、基于证据的边界决策和验证；授权不会自动延续。
- `codex-project-optimization` 现仅负责项目本地生命周期初始化和协调；路由、执行、工作流设计和经验晋升仍由各自 owner 负责。
- 资源经济现为 self-evolution 的内部能力；`codex-cost-optimization` 仅保留一版兼容路由，当前有 25 个活跃 owner。
- 已学习或已安装的 MCP、skill、软件包和项目发现新版本时，不会自动监控或变更；仅在用户发起的任务中进行只读核验，任何下载、升级、重新配置或重新学习都需先获得该次更新的明确授权。
- 代码库学习优先使用结构化证据：安装并配置 `codebase-memory-mcp` 后，Codex 可先索引项目图谱，再按图谱结果读取必要源文件；图谱搜索用于路由取证，最终结论仍需源文件核验。全局生命周期入口会在 MCP 工具可用且项目是源码仓库时主动运行 fast `index_repository` 预热；对延迟或命名空间工具，先检查任务的可调用能力注册表，不能只凭静态工具列表判定不可用。确认当前任务确无 MCP 后，才记录不可用并回退到本地文件取证。跨仓学习或配置 MCP 时记录覆盖限制，默认不提交 `.codebase-memory/graph.db.zst`，在非完全受信环境使用 allowed-root 边界。
- Codex 学习和用户 Anki 分开：Codex 自己要记的规则不强迫用户背。
- 可移植发行：Git 中只保留通用流程，provider、路径、账号、软件选择和凭据留在本地 profile。
- 图片和导图可追溯：Mermaid/MindMaster/SVG/图床图片都是派生视图，Markdown 和 manifest 保持权威。
- GitHub 发布有门禁：每次非合并提交都要更新 changelog，涉及公开使用方式时同步 README 或 docs。
- 知识、经验和工作流出现多个交互关系时，优先基于脱敏摘要使用 GPT 生图，并先经过格式选择门：只有文本化或可编辑矢量结构确有优势时才使用 Mermaid/SVG；普通栅格交付按透明度、保真度、兼容性和文件大小选择 PNG/JPG，变更后按结构决定修图、重生或删除。

## 快速开始

```powershell
git clone <repository-url> <architecture-root>
Set-Location <architecture-root>
.\scripts\install-global.ps1 -Mode Junction
.\skills\codex-skill-portability\scripts\Initialize-PortableSkillConfig.ps1
.\scripts\validate.ps1
```

打开新的 Codex 任务后，全局 `AGENTS.md` 会先路由 `$codex-self-evolution`。如果当前项目缺少 `.codex/project/state.json`，再由项目初始化流程创建本项目自己的需求、工作流、经验和复盘。

## 日常命令

```powershell
# 发行安全的空历史目录
python .\scripts\index_history.py

# 仅本机需要历史检索时使用
python .\scripts\index_history.py --include-local-history

# 全量验证
.\scripts\validate.ps1

# 全局 skill 接口验证
.\scripts\validate-global-install.ps1

# 新项目初始化
.\scripts\init-project.ps1 -ProjectRoot <project-root>
```

## 目录结构

| 路径 | 作用 |
|---|---|
| `skills/` | 23 个可安装到全局的 Codex skill 目录 |
| `module-registry.json` | 模块增减、合并、停用的证据注册表 |
| `knowledge/experience-ledger.md` | 已验证、跨项目、非重复的经验账本 |
| `knowledge-vault/` | Obsidian 知识库、工作流、导图和 Anki 卡片源 |
| `knowledge/history-catalog.json` | 发行安全空目录；本机历史需显式生成 |
| `config/` | 全局 AGENTS、软件安装和图床策略 |
| `docs/` | 需求手册、发布规则、可移植配置和版本说明 |
| `scripts/` | 安装、验证、历史索引、项目初始化和发布门禁 |

`.codex/` 是本机或具体项目的运行状态目录，默认由 `.gitignore` 排除，不进入发行包。

## 架构闭环

1. `codex-self-evolution` 读取项目状态，选择最小必要模块。
2. 需求、执行、工作流、运行环境、安装、凭据、图片、Git 等模块各自负责清晰边界。
3. 完成验证后，项目经验先进入项目 `.codex/project`；只有跨项目有效的结论才晋升到全局经验或 skill。
4. 知识系统把已验证经验组织成 Obsidian note、MindMaster 大纲、Mermaid 导图和 Codex 本地学习索引。
5. Git 发布前运行验证和元数据门禁，确保说明、版本、变更和隐私边界同步。

## 可移植配置

仓库中的文档和脚本使用逻辑根，不写个人盘符：

- `$ARCHITECTURE_ROOT`
- `$CODEX_HOME`
- `$SOFTWARE_ARCHIVE_ROOT`
- `$SOFTWARE_INSTALL_ROOT`
- `$IMAGE_QUARANTINE_ROOT`

克隆者的私有选择写入 `~/.codex/private-skill-config/portable-skill.json`。模板使用 `test-provider`、`TEST_API_KEY`、`test-model`、`test-tool` 这类占位名；不要把真实密钥、Cookie、账号、浏览器状态或 `auth.json` 放进 Git。

更多说明见 [Portable Skill Distribution](docs/PORTABLE-SKILL-DISTRIBUTION.md) 和 [Portable Path Configuration](docs/PATH-CONFIGURATION.md)。

## 知识、学习与图片

用 Obsidian 打开 `$ARCHITECTURE_ROOT\knowledge-vault`。Markdown 是权威源，MindMaster、Mermaid、SVG 和图床图片是派生视图。

```powershell
python .\skills\codex-knowledge-system\scripts\build_knowledge.py
python .\skills\codex-knowledge-system\scripts\build_mindmaps.py
```

学习受众必须显式区分：

- `learning_audience: codex` 进入 `50-Learning/codex-learning.json`，供 Codex 后续任务迭代经验。
- `learning_audience: user` 进入 `50-Learning/user-anki-import.tsv`，供用户导入 Anki。
- `both` 需要分别写 Codex 规则和用户回忆卡片。

图片只在能明显降低理解成本时加入。结构图优先使用 Mermaid 或仓库内 SVG；需要图床迁移时，必须按需触发、先预览、远程验证成功后再替换和清理本地图片。禁止定期扫描。

## 版本更新说明

每次版本更新至少包含：

- [更新日志 / Changelog](CHANGELOG.md) 中的用户可读变更说明。
- 如改变安装、配置、工作流、安全边界或发行体验，同步 README 或对应 docs。
- 如改变版本号，同步 `VERSION`、`docs/release-notes/v<version>.md`，并确保 `CHANGELOG.md` 存在该精确版本的条目。
- 如变更复杂或影响多个模块，增加或更新一张图来解释问题、解决路径和新架构位置；先使用脱敏 GPT 生图。若不生成图片，则按格式门选择可版本化的 Mermaid、确有编辑价值的 SVG，或 PNG/JPG 等栅格交付，并同步图片溯源与 README。

发布规则见 [GitHub Publication Metadata](docs/GITHUB-PUBLISHING.md)。

## 软件安装边界

普通 skill、模板、脚本和配置处理不需要逐项提示。外部软件、系统组件、运行时或会改变系统环境的依赖安装前，必须先说明对象、来源、范围、目标路径和影响。

软件包默认进入 `$SOFTWARE_ARCHIVE_ROOT`，支持自定义路径的软件进入 `$SOFTWARE_INSTALL_ROOT`。现有软件满足需求时不因版本较旧自动升级。

<!-- BEGIN MANAGED BLOCK: latest-release -->
## Latest Release / 最新发布

- Version: `1.8.0.0`
- Channel: `Private` / 私有
- Release note: [docs/release-notes/v1.8.0.0.md](docs/release-notes/v1.8.0.0.md)
- Highlights: Release documentation, Automation gates, Skill architecture
- Visual: [docs/assets/readme-collaboration-loop.png](docs/assets/readme-collaboration-loop.png)
- README optimization: audited with github-readme-presentation; provenance: [docs/release-readme-audits/v1.8.0.0.json](docs/release-readme-audits/v1.8.0.0.json)
- README 优化已通过已安装的 GitHub README 与 Profile 展示工作流复核；不引入无证据的指标或跟踪组件。
- 中文：本次发布会同步刷新 README、发布说明和必要的图示/排版材料。
<!-- END MANAGED BLOCK: latest-release -->
