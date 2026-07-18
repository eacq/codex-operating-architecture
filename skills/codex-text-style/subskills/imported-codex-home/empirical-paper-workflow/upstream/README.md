# empirical-paper-workflow

> AI 辅助微观数据实证论文的**写作、修订与审校**工作流 Skill（含「防失真铁律」）。
> A Claude Code / Agent Skill for writing, revising, and proofreading **empirical social-science papers** built on microdata — with hard rules against data fabrication and citation drift.

[![Skill](https://img.shields.io/badge/type-agent--skill-blue)](#) [![Lang](https://img.shields.io/badge/lang-中文-red)](#) [![License](https://img.shields.io/badge/license-MIT-green)](#)

---

## 这是什么 / What it is

这是一个 [Agent Skill](https://docs.claude.com/en/docs/claude-code/skills)，把「用 AI 写实证论文」这件容易出事的事，固化成一套**可追溯、可复算、防失真**的流程。它特别针对使用中国微观调查数据（CFPS / CHFS / CGSS 等）的社会科学定量论文。

核心问题：AI 写实证论文最大的风险不是写不出来，而是**编数字、编文献、改着改着把真数据改假**。本 Skill 用「铁律 + 三线审校」把这些失真点逐一堵死。

This skill turns "writing an empirical paper with AI" into a **traceable, re-computable, fabrication-resistant** pipeline. It targets quantitative social-science papers using microdata, where the real danger is not writer's block but *hallucinated numbers, fake references, and silent data drift during revision*.

## 何时触发 / When it triggers

Claude 会在以下情况自动加载该 Skill：

- 写、改、审一篇实证 / 定量学术论文（尤其是用 CFPS/CHFS/CGSS 等微观数据的中文社科论文）
- 用户说「写论文 / 改论文 / 审稿 / 审阅论文 / 查数据失真 / 核对参考文献」
- 修订阶段补稳健性检验、加文献

## 三种模式 / Three modes

Skill 不强制走完整流程，而是按请求进入对应模式：

| 模式 | 触发 | 做什么 |
|------|------|--------|
| **写作模式** | 从零或某阶段开始写 | 按「十阶段流程」推进 |
| **修订模式** | 回应审稿意见 / 补稳健性 / 加文献 | 重点执行「铁律」，新增内容一律过脚本与题录核验 |
| **审校模式** | 要求审阅 / 检查失真 | 执行「三线审校」（数据 → 引证 → 排版）|

## 核心：防失真铁律 / The integrity rules

无论哪种模式都不可违反：

1. **正文每一个数字必须有脚本出处** —— 禁止凭推算或记忆补数。
2. **新增文献一律过题录核验** —— 本地 RIS 库 → Crossref API → WebSearch。
3. **引用前确认文献立场** —— 题录真伪 AI 可核，「文献是否真说了这句话」需人读原文。
4. **交叉引用即时验证** —— 写下「见表 X」立刻回看目标处是否真有该内容。
5. **修订留痕** —— 每轮改前备份，README 记录每个数字的来源步骤。
6. **数据引证** —— 外部统计数字必须有出处，并注意口径。

「三线审校」会按 **数据复算 → 引证核验 → 排版合规** 三条线系统过一遍，重点是**不在表格里的数字**（口述稳健性结果、子样本特征、筛选链样本量）——失真集中区。

## 安装 / Install

**作为个人 Skill（Claude Code）:**

```bash
# 克隆到 Claude 的 skills 目录
git clone https://github.com/Amarantosy1/empirical-paper-workflow.git \
  ~/.claude/skills/empirical-paper-workflow
```

**或者按项目使用：** 把本仓库放到项目的 `.claude/skills/` 下即可。

Claude Code 会读取 `SKILL.md` 的 frontmatter（`name` + `description`），并在匹配到上面「何时触发」的场景时自动调用。

## 仓库结构 / Layout

```
.
├── SKILL.md      # Skill 本体（frontmatter + 工作流定义）
└── README.md     # 本文件
```

## 适用对象 / Who it's for

写定量实证论文的研究生、研究者，以及任何想用 AI 辅助但**不想被 AI 编的数字坑**的人。

## License

MIT
