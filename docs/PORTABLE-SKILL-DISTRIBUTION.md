# Portable Skill Distribution

This repository separates shared skill behavior from recipient-specific choices.
The tracked repository is safe to clone; each recipient configures providers,
software locations, and optional tools locally on first use.

## Quick start after cloning

```powershell
git clone <repository-url> <architecture-root>
Set-Location <architecture-root>
.\scripts\install-global.ps1 -Mode Junction
.\skills\codex-skill-portability\scripts\Initialize-PortableSkillConfig.ps1
.\scripts\validate.ps1
```

Restart or open a new Codex task after global installation so skill discovery
refreshes. The initializer asks for a provider/auth preference and optional
software folders. Select `skip` or leave optional values blank when they are not
needed; it installs nothing and never asks for a secret.

## Public versus private boundary

| Shared in Git | Local-only configuration |
|---|---|
| Workflow, protocol shape, validation, templates | Provider label and endpoint |
| API-key versus ChatGPT-login choice | Environment-variable name and model choice |
| Software-install procedure | Archive/install roots and selected tools |
| Placeholder examples | Keys, tokens, cookies, accounts, browser state |

The local profile is `~/.codex/private-skill-config/portable-skill.json`. Do not
add it to Git. Store secrets in a supported secure store or environment variable.

## Making an existing skill portable

```powershell
.\skills\codex-skill-portability\scripts\Test-SkillPortability.ps1 -SkillPath .\skills\test-skill
```

For each finding, replace the personal value with a generic configuration key,
move the actual choice to the local profile, and document what remains optional.
Keep provider protocol and authentication modes in the shared skill, but keep a
specific service, endpoint, quota plan, and account choice local.

`your-api-source` is retained as a compatibility entry but now uses this generic
OpenAI-compatible provider contract. Its previous provider-specific endpoint and
model choices must be supplied by the recipient's local profile.

## Installation boundary

Skill files, templates, and profiles do not count as software installation.
When a recipient selects a tool that requires external installation, the normal
tool-installation workflow must first explain the item, source, target location,
and impact, then request confirmation.

## 中文对照

本仓库将共享 skill 行为与接收者的私有选择分离。克隆后，接收者仅在本地配置服务商、软件位置和可选工具；初始化器不会安装软件，也不会索要或保存密钥。

Git 中只保存工作流、协议、验证、模板与占位示例；服务商端点、环境变量名、模型、安装目录、令牌、Cookie、账号与浏览器状态只能保留在本地。私有配置文件位于 `~/.codex/private-skill-config/portable-skill.json`，不得提交。

让既有 skill 可移植时，使用可移植性检查器发现个人化值，并改为通用配置键；协议和认证模式可以进入共享 skill，但具体服务、端点、配额方案和账号选择必须留在本地。外部软件安装仍遵守说明对象、来源、路径和影响后再确认的边界。
