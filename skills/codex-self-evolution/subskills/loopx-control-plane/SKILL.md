---
name: codex-self-evolution-loopx-control-plane
description: Use for long-running goals, bounded turns, todo ownership, quota or heartbeat decisions, evidence handoffs, and LoopX state; never replace the Global Experience Agent or owner/tool gates.
---

# LoopX Control-Plane Adapter

LoopX is integrated as a project-level control plane under
`codex-self-evolution`. The one Global Experience Agent remains the global
lifecycle and architecture controller. LoopX supplies a durable project goal
surface for multi-turn work: objective, scope, user gate, ordered todos,
claims/leases, evidence, quota, turn lineage, and handoff readback.

## Windows entrypoint

Use the canonical Windows adapter instead of the upstream Bash installer:

```powershell
& F:\codex\scripts\Invoke-LoopX.ps1 --format json doctor --deep
& F:\codex\scripts\Invoke-LoopX.ps1 --format json status
```

The adapter selects the reviewed release from
`.runtime/software/loopx/current.json` and prefers the Codex bundled Python
3.11+ runtime. It does not modify the user PATH. The release source, commit,
runtime, and rollback metadata are recorded by `Install-LoopX.ps1`.

## Read-first project loop

For a long-running project goal:

1. Run `doctor`, then inspect `status`, `diagnose`, and the project boundary.
2. If the project is not connected, preview `start-goal --guided` and make the
   project-state write only within the explicit task scope.
3. Check `quota should-run` before selecting another agent turn.
4. Claim one concrete todo/lease; do not infer ownership from chat order or
   registry order.
5. Execute one bounded slice within the declared write scope.
6. Validate the changed artifact and write evidence back to the todo/state.
7. Refresh the projected state, then complete/update the todo.
8. Spend quota only after validated writeback; a wait, preview, failed
   preflight, or transport recovery does not spend.
9. Preserve typed turn lineage and handoff receipts when a host/runtime bridge
   is used. A failed or timed-out turn remains recoverable evidence, not a
   successful delivery.

The control surface is intentionally compatible with the existing Agent
contract: `Run`/`Continue`/`Resume` and accepted save points remain authoritative
for the Global Experience Agent; LoopX project state is an additional readback
and scheduling surface, not a second durable global session.

## Owner routing

- Project goal, todo, quota, heartbeat, and handoff projection: this subskill.
- Global Agent lifecycle, structure, child state, and save points:
  `codex-self-evolution` and `agent/40-runtime/Invoke-GlobalExperienceAgent.ps1`.
- Unexpected behavior or projection drift: `codex-error-feedback`.
- Git/PR publication or merge: `codex-git-operations`.
- Durable document/material registration: `codex-knowledge-system`.
- Runtime installation and version changes: `codex-tool-installation`.

Never let a LoopX command authorize credentials, publication, destructive
work, production writes, Agent structure changes, or owner-gated external
actions. Keep `.loopx/`, `.codex/goals/`, and LoopX runtime state local and
ignored; do not commit raw logs, private sources, or credentials.

## Adopted and deferred surfaces

Adopted from the reviewed upstream release: goal/state projection, typed todo
ownership and leases, quota/heartbeat decisions, transaction/turn lineage,
evidence-backed writeback, diagnostic/doctor read models, and recovery-aware
handoffs. Optional Lark/OpenViking providers, public dashboard/projections,
Unix shell profile mutation, macOS LaunchAgents, and autonomous production
control remain deferred until a separate owner, provider, and verification
need exists.

Source grounding and the exact upstream commit are recorded in
`knowledge-vault/30-Knowledge/LoopX Control Plane.md` and
`config/loopx-integration.json`. Run
`scripts/Test-LoopXIntegration.ps1` after installation or release changes.
