---
title: Reverse Skill Collaboration Control Plane
status: guarded-adaptation
source: https://github.com/zhaoxuya520/reverse-skill
reviewed_commit: d8bf34540cbc1aa34052e1b142576fc36a1f1437
owner: codex-experience-capture
---

# Reverse Skill 协作控制面

reverse-skill 的可迁移价值主要在协作纪律，而不是把整套网络安全技能库注入全局 Agent。已接入的组合是：任务范围与授权状态、lead/specialist/verifier/recorder 角色、工作项与追加式时间线、Evidence→Finding→Path 证据链、阻塞恢复、外部 skill/MCP 供应链审查。

进化结构参考用户提供的《技术的本质》：把信息元、功能元、skill、工具、角色、工作流和证据看成可重组的模块；每次任务先复用和重组，再用结果、失败、验证和资源消耗进行选择，最后只把可迁移、可回滚、证据充分的组合固化。这样“自动进化”表现为受约束的组合选择，而不是无边界堆积或未经验证的自我修改。

本记录是 guarded adaptation。它用于改善 Codex、全局经验 Agent 和相关子 Agent 的交接与回放；不授予网络目标操作权限，不自动安装 Kali/Burp/IDA/JDK/Node/Python 等依赖，不修改全局客户端指令，不替代现有 owner、回滚、验证、凭据和发布门。

适配入口：`skills/codex-experience-capture/subskills/reverse-skill-collaboration/SKILL.md`。
