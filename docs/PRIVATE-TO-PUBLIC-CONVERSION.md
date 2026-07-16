# Private-to-Public Skill Conversion / 私有 Skill 公开转化

## English

Use `Convert-PrivateSkillToPublic.ps1` to assess a private skill before sharing it publicly. The read-only mode reports portability findings and whether a non-secret local profile exists. Apply mode creates a sanitized public candidate, generic profile template, and a local converted-skill profile that retains only non-secret provider/software preferences.

Conversion is allowed only with two independent verified use cases, no unresolved private-only purpose, a passing sanitized-copy audit, bilingual documentation, knowledge/experience review, and full validation. Never publish secrets, tokens, cookies, account identity, browser state, raw history, private endpoints, or personal paths.

The same rule applies to experience and knowledge: use `Convert-PrivateKnowledgeToPublic.ps1` with two evidence paths. It creates only a sanitized public candidate and rejects raw-history and credential-state markers; promotion and public release remain separate decisions.

```powershell
.\skills\codex-skill-portability\scripts\Convert-PrivateSkillToPublic.ps1 `
  -SourceSkillPath <private-skill> -PublicSkillName <generic-name>
```

## 中文

使用 `Convert-PrivateSkillToPublic.ps1` 可在公开共享前评估私有 skill。只读模式会报告可移植性问题与非秘密本地配置是否存在；应用模式会创建已脱敏的公开候选、通用配置模板，以及仅保留非秘密服务商/软件偏好的本地转化配置。

转化至少需要两个独立的已验证使用场景、没有未解决的私有专属用途、脱敏副本审计通过、双语说明、知识/经验审查和全量验证。不得公开密钥、令牌、Cookie、账号身份、浏览器状态、原始历史、私有端点或个人路径。

经验与知识遵循相同规则：使用 `Convert-PrivateKnowledgeToPublic.ps1` 并提供两个证据路径。它只生成脱敏公开候选，并拒绝原始历史和凭据状态标记；晋升和公开发布仍是独立决策。
