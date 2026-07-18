# Codex Home Skill Consolidation

## 中文说明

本次迭代把原来直接散落在 `$CODEX_HOME/skills` 的用户技能，归并到
`$ARCHITECTURE_ROOT/skills` 下的既有规范所有者中。它不是把外部或本地技能原样复制成
新的全局入口，而是按经验系统的边界进行兼容性安装：保留有复用价值的工作流、脚本、
模板和非敏感素材；把它们封装为 `imported-codex-home` 子技能；再由少量稳定的所有者技
能负责发现、路由和验证。

这种结构的目标是减少平铺技能数量，同时保留可审计的来源材料和回滚边界。模型仍从规
范所有者入口开始，例如文本、图像、Office、凭据、错误反馈、知识和任务执行；只有在具
体任务需要时，所有者才会调用内部导入包。

## 迁移边界

- 规范源：`F:\codex\skills`。
- 全局发现接口：由 `scripts/install-global.ps1 -Mode Junction` 管理的
  `$CODEX_HOME/skills` junction。
- 迁移内容：`SKILL.md`、脚本、模板、公开示例、通用配置片段和必要素材。
- 不迁移内容：`.git`、`venv`、`.venv`、`node_modules`、缓存、实际 `.env`、令牌、
  Cookie、证书、认证 JSON、私有端点和账号状态。
- 回滚边界：实际迁移会把原技能目录移动到
  `$CODEX_HOME/skill-migration-backups/global-experience-<timestamp>/`；本地非秘密配
  置清单写入 `$CODEX_HOME/private-skill-config/`，不写入版本库。

## 执行流程

```powershell
# 先检查映射与文件数，不修改内容
.\scripts\Migrate-CodexHomeSkills.ps1

# 已获授权时执行可回滚迁移
.\scripts\Migrate-CodexHomeSkills.ps1 -Apply

# 重建唯一全局发现接口并验证
.\scripts\install-global.ps1 -Mode Junction
.\scripts\validate.ps1
.\scripts\validate-global-install.ps1
```

## 设计依据

本次整合借鉴 `mattpocock/skills` 中小而可组合的技能思想，以及对用户调用编排和模型调
用复用纪律的区分。经验系统把这个区分收敛为三层：用户面向任务目标，模型面向所有者
路由，所有者面向内部子技能。这样既避免把大量历史包暴露为平铺入口，也保留了可审计
的原始材料、来源说明和迁移回滚路径。

## English Counterpart

This iteration consolidates user skills that previously lived directly under
`$CODEX_HOME/skills` into existing canonical owners under
`$ARCHITECTURE_ROOT/skills`. It is a compatibility consolidation, not a raw copy
or a new top-level skill expansion. Reusable workflows, scripts, templates,
public examples, and non-sensitive assets are retained as `imported-codex-home`
subskills, while canonical owners remain the only global discovery interfaces.

The result keeps the top-level experience system smaller and easier to route.
Agents start from owners such as text style, image workflow, Office automation,
credential management, error feedback, knowledge, and task execution. Imported
packages are selected only when the owning workflow needs them for a concrete
task.
