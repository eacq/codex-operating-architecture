# Global Experience Agent Paper-Style Architecture Provenance

## English

- Asset: `global-experience-agent-architecture-paper-style.png`.
- Purpose: provide a lighter academic-paper presentation of the verified Global Experience Agent architecture while preserving the exact filesystem, interface, permission, exit, registry, owner, lifecycle, and handoff facts.
- Reference style: the user-provided `codex-knowledge-system-paper-style.png` supplied the warm-white canvas, thin outlined cards, restrained accent colors, generous whitespace, simple diagram language, and publication-oriented hierarchy. It was used as style guidance only; the new layout is generated from the current Agent sources.
- Content sources: `agent/agent-filesystem.json`, `config/global-experience-agent-registry.json`, `config/agent-interface-policy.json`, `config/agent-owner-connections.json`, and `config/agent-architecture-diagram.json`.
- Final format: opaque lossless PNG at 3840 x 2400. The editable source is `scripts/New-AgentArchitectureDiagram.ps1 -Style Paper` plus the machine-readable mapping and registries.
- Agent registry: one root Agent, five concept Agents, 23 specialist Agents, four dynamic child states, and 50 durable handoffs.
- Permission interfaces: human, LLM, and internal-functional-unit interfaces remain limited to registered functions and their allowed gates; only explicit global-control can route changes to all Agent aspects through the architecture owner. Nine typed exits make success, handoff, gated work, authorization blocks, structure requests, review checkpoints, and failures machine-readable.
- Deterministic fallback: the built-in reference-guided image-generation pass failed with a network error. The approved image workflow retained the sanitized prompt plan and used the mapping-driven renderer so every module label and connection remained verifiable; no credentialed CLI fallback was used.
- Validation: original-resolution inspection, `Test-AgentArchitectureDiagram.ps1`, exact Agent/owner counts, image dimensions, visual color sampling, and default-renderer regression.
- Privacy boundary: no local paths, credentials, account identifiers, raw sessions, prompts, tool payloads, or private user content appear in the image.
- Regenerate when: the physical Agent filesystem, root/concept/specialist Agent registry, interface/permission/exit policy, child lifecycle, runtime stages, module responsibilities, owner handoffs, continuation contract, or visual theme changes materially.

## 中文

- 资源：`global-experience-agent-architecture-paper-style.png`。
- 用途：以更接近论文插图的白底视觉呈现已经验证的全局经验 Agent 架构，同时保持注册表、Owner、生命周期与交接关系完全一致。
- 风格参考：用户提供的 `codex-knowledge-system-paper-style.png` 仅用于白底、细描边卡片、克制配色、留白和论文式层级参考；新图布局由当前 Agent 配置重新生成，并非复制原图。
- 内容来源：`agent/agent-filesystem.json`、`config/global-experience-agent-registry.json`、`config/agent-interface-policy.json`、`config/agent-owner-connections.json` 与 `config/agent-architecture-diagram.json`。
- 最终格式：3840 x 2400 无损不透明 PNG；可编辑权威源为 `scripts/New-AgentArchitectureDiagram.ps1 -Style Paper` 及机器可读映射和注册表。
- Agent 对应：1 个根 Agent、5 个概念 Agent、23 个专业 Agent、4 个动态子 Agent 状态和 48 条持久交接。
- 确定性回退：内置参考图生成通道出现网络错误，因此保留脱敏提示方案并使用映射驱动渲染器，避免模块名称和连接失真；未切换到需要凭据的 CLI。
- 验证：原分辨率检查、架构图测试、Agent/Owner 精确计数、图像尺寸、颜色采样和默认渲染器回归。
- 隐私边界：图中不包含本机路径、凭据、账户标识、原始会话、提示词、工具载荷或用户私有内容。
- 重生成条件：根/概念/专业 Agent 注册表、子 Agent 生命周期、运行阶段、模块职责、Owner 交接、续作契约或视觉主题发生实质变化。

