---
name: codex-skill-portability
description: Make Codex skills easy for other people to clone, install, and configure by separating reusable workflow from machine-, provider-, account-, path-, and software-specific private configuration. Use when sharing a skill repository, extracting a private skill into a generic one, preparing a GitHub installation guide, auditing hard-coded paths or providers, or guiding first-use configuration.
---

# Codex Skill Portability

Treat tracked skill content as reusable and local profiles as private. Never
copy API keys, cookies, tokens, account data, private endpoints, or personal
paths into a shared skill or Git history.

## Workflow

1. Audit the candidate before editing:

   ```powershell
   .\scripts\Test-SkillPortability.ps1 -SkillPath <skill-directory>
   ```

   Move reported paths, provider names/endpoints, credential variable choices,
   account assumptions, and install locations into a profile; retain only the
   provider protocol, auth modes, workflow, and validation in the skill.
2. On a recipient's first use, create or open their local profile. Ask which
   API/auth mode and software they need, then run:

   ```powershell
   .\scripts\Initialize-PortableSkillConfig.ps1
   ```

   It writes `~/.codex/private-skill-config/portable-skill.json`; it never asks
   for or stores a secret. Use `codex-credential-management` for secrets and
   `codex-tool-installation` only after notifying before an external install.
3. Keep the generic contract in the skill and the private choices in the local
   profile. For OpenAI-compatible providers, support both API-key and ChatGPT
   login modes; do not label a private provider as a universal default.
4. Add a short clone/install/configure/verify section to repository docs. A
   recipient must be able to choose "skip" for optional provider or software
   setup and still understand what capability is unavailable.
5. Validate the skill, profile template, audit output, and a clean first-use
   run. Promote only repeatable portability lessons to experience.

## Compatibility installation

When importing or learning from an external skill, do not preserve its upstream
shape by default. Decide the compatible local form first:

- `learn-only`: record the pattern as knowledge or candidate experience.
- `owner-reference`: add a concise rule or reference under an existing owner.
- `owner-subskill`: package a distinct mode under the existing owner when it
  shares artifacts and safety boundaries.
- `project-local skill`: keep project-specific workflow in that project.
- `global skill`: use only when no current owner fits and the registry evidence
  threshold is met.

Every installed form must remove or isolate private paths, provider assumptions,
account choices, credentials, install locations, and upstream tool-specific
commands that do not apply locally. The result does not need to be the upstream
"best" shape; it must be the best fit for this architecture and the user's
actual workflow.

For external packages, prefer a manifest-backed compatibility install contract:
preview with dry-run, back up replaced Codex-home files, verify with a check
mode, enforce small global guidance and skill-size budgets, and stop when
orphaned markers from another runtime are found instead of trying to repair a
mixed hooks/config state blindly. If the upstream package installs into a
different skill root, translate that root to this architecture's canonical
`$ARCHITECTURE_ROOT\skills` plus `$CODEX_HOME\skills` discovery interface.

## Private-to-public conversion

Use `scripts/Convert-PrivateSkillToPublic.ps1` only when the candidate has two independent verified use cases and no unresolved private-only purpose. Its default mode creates a read-only conversion plan. With `-Apply`, it creates a sanitized public candidate, re-audits it, writes a generic public profile template, and copies the original non-secret provider/software preferences only to `~/.codex/private-skill-config/converted-skills/`. Never copy secrets, cookies, account identity, browser state, raw history, or private evidence. The global controller must route the result through documentation synchronization, knowledge/experience review, validation, and the private auto-Git gate before a later explicit public release.

Read [references/config-contract.md](references/config-contract.md) before
changing the profile schema or migration boundary.

## Example

```powershell
.\scripts\Test-SkillPortability.ps1 -SkillPath .\skills\test-skill
.\scripts\Initialize-PortableSkillConfig.ps1
```
