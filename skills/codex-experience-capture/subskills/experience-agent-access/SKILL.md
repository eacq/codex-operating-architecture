---
name: codex-experience-capture-experience-agent-access
description: Owner-internal access adapter for starting, continuing, resuming, querying, and routing the Global Experience Agent from Codex tasks.
---

# Experience Agent Access

Use this subskill only through `codex-experience-capture` when a Codex task
needs a convenient, repeatable way to call the Global Experience Agent.

## Contract

This is an access adapter, not a new Agent, owner, or controller. It forwards to
`agent/40-runtime/Invoke-GlobalExperienceAgent.ps1` and preserves:

- the single root Agent identity in `config/global-experience-agent-registry.json`;
- interface permissions in `config/agent-interface-policy.json`;
- owner handoffs in `config/agent-owner-connections.json`;
- all Git, release, credential, installation, publication, and structural gates.

Use `scripts/Invoke-ExperienceAgentAccess.ps1` for common calls. It keeps array
parameters named in the current PowerShell process so `WriteSurface`,
`AcceptanceCriteria`, `ResultEvidence`, and queued actions cannot become
positional arguments.

## Common operations

Start durable work:

```powershell
& skills/codex-experience-capture/scripts/Invoke-ExperienceAgentAccess.ps1 `
  -Access StartWork `
  -Goal 'bounded task goal' `
  -Authority 'current authority evidence' `
  -Apply
```

Continue or resume an existing session:

```powershell
& skills/codex-experience-capture/scripts/Invoke-ExperienceAgentAccess.ps1 `
  -Access Resume `
  -SessionId 'global-experience-...' `
  -Apply
```

Search or store Agent memory only when records are scoped and non-secret:

```powershell
& skills/codex-experience-capture/scripts/Invoke-ExperienceAgentAccess.ps1 `
  -Access SearchMemory `
  -SessionId 'global-experience-...' `
  -Query 'routing or lesson query'
```

Resolve a specialist owner without executing its gated side effect:

```powershell
& skills/codex-experience-capture/scripts/Invoke-ExperienceAgentAccess.ps1 `
  -Access RouteOwner `
  -SessionId 'global-experience-...' `
  -Owner codex-architecture-iteration `
  -Apply
```

Design a bounded child Agent from the minimal template:

```powershell
& skills/codex-experience-capture/scripts/New-MinimalAgentPlan.ps1 `
  -Goal 'bounded child task goal' `
  -AcceptanceCriteria 'checkable child result' `
  -Verification 'parent merge verifier checks evidence'
```

Add `-Delegate -Apply -SessionId <parent-session>` only when the parent session
is already idle and the current authority permits registering child state. The
planner still does not execute the child task.

## Safety boundary

- Use `-GlobalStructure` only when the current user explicitly authorized
  structural Agent or skill changes for this iteration.
- Use `-Interface global-control` only for explicitly authorized controller
  work. Human and LLM callers may use functional operations but cannot directly
  mutate Agent structure.
- Do not store credentials, raw private sessions, tokens, cookies, or secret
  command output in Agent memory.
- Treat denied access, malformed arguments, unexpected owner routes, and failed
  verification as `codex-error-feedback` inputs before changing this adapter.

## Verification

Run:

```powershell
& skills/codex-experience-capture/scripts/Test-ExperienceAgentAccess.ps1
& scripts/Test-AgentSkillInvocationPolicy.ps1
& scripts/Test-GlobalExperienceAgent.ps1
& scripts/validate-global-install.ps1
```
