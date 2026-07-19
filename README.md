# Codex 全局经验系统

English: [README.en.md](README.en.md)

> 面向本地 Codex 的协作型经验系统：让用户目标、已验证的本地经验与模型能力在清晰授权和验证下共同完成工作。

## 从这里开始

| 目标 | 入口 |
|---|---|
| 新项目进入规范工作流 | `$codex-self-evolution` |
| 处理异常或错误 | `$codex-error-feedback` |
| 学习并吸收外部方法 | `$codex-learning` |
| 优化用户说明 | `$github-readme-presentation` |

先复用项目事实、已验证经验和确定性工具；只有能提升结果时，才使用模型、联网检索、图片生成或外部依赖。

## 协作闭环

用户定义目标与授权；系统选择最小必要 owner；经验、知识和工具先执行可复用工作；模型补足推理与创作；验证和错误反馈决定哪些结果可以保留、提交或发布。

![协作角色与验证闭环图](docs/assets/readme-collaboration-loop-labeled.png)

## 系统如何工作

![全局架构总览：路由、工作流、知识、验证、发布与学习](docs/assets/readme-architecture-overview-labeled.png)

![Codebase Memory MCP 无标签架构图谱](docs/assets/codebase-memory-mcp-graph.png)

图谱在项目进入时由 Codebase Memory MCP 快速刷新；README 使用其上游 Three.js 图谱控制台渲染的无标签 PNG，展示架构结构密度而不公开路径、会话或源码文本。

- **路由**：按任务选择现有 owner，而不是重复创建能力。
- **沉淀**：项目经验先留在项目；只有跨项目验证的结论才进入全局系统。
- **安全**：凭据、原始会话和本机私有路径不进入 Git；外部变更仍须用户授权。
- **演进**：每次改进都需要可观察贡献与无回归验证；不能证明净收益就保留现状。

## 可靠交付

![事务化文件整理闭环：隔离、备份、整理、验证、替换与恢复](docs/assets/file-organization-architecture-labeled.png)

![隐私安全的文件整理示意图：收集、分类、保护与归档](docs/assets/file-organization-concept-labeled.png)

全局迭代通过隔离副本、备份、验证、替换和可恢复回滚来保护现有工作。图片、说明和发布材料也需经过存在性、可读性和格式验证；普通读者交付使用 PNG/JPG/WebP，不以 Mermaid/SVG 源文件作为展示目标。

## 快速开始

```powershell
git clone <repository-url> <architecture-root>
Set-Location <architecture-root>
.\scripts\install-global.ps1 -Mode Junction
.\scripts\validate.ps1
```

更多操作见 [Iteration Status](docs/ITERATION-STATUS.md)、[更新日志 / Changelog](CHANGELOG.md)、[可移植配置](docs/PORTABLE-SKILL-DISTRIBUTION.md) 和 [发布规则](docs/GITHUB-PUBLISHING.md)。

<!-- BEGIN MANAGED BLOCK: latest-release -->
## Latest Release / 最新发布

- Version: `1.2.0.0`
- Channel: `Private` / 私有
- Release note: [docs/release-notes/v1.2.0.0.md](docs/release-notes/v1.2.0.0.md)
- Highlights: Lifecycle controller, Release documentation, Knowledge and experience, Skill architecture, Automation gates
- Visual: [docs/assets/release-visual-highlights-labeled.png](docs/assets/release-visual-highlights-labeled.png)
- README optimization: audited with github-readme-presentation; provenance: [docs/release-readme-audits/v1.2.0.0.json](docs/release-readme-audits/v1.2.0.0.json)
- README 优化已通过已安装的 GitHub README 与 Profile 展示工作流复核；不引入无证据的指标或跟踪组件。
- 中文：本次发布会同步刷新 README、发布说明和必要的图示/排版材料。
<!-- END MANAGED BLOCK: latest-release -->
