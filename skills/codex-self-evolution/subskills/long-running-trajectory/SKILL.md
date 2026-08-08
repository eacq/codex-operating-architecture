---
name: long-running-trajectory
description: Use for project goals that span repeated bounded turns, multiple Agent lanes, evidence-backed decisions, quotas, handoffs, or elapsed-time continuity.
---

# Long-Running Trajectory

This is the shared control contract for LoopX-backed work. It is a project
control-plane adapter, not a second Global Experience Agent and not an
unattended production controller.

## Required shape

Every trajectory has one durable goal, an explicit scope, a small runnable todo
frontier, a quota decision, a typed turn identity, compact evidence, a next
action, and a stop or promotion gate. A turn may end in `continue`, `handoff`,
`blocked`, `user_gate`, `stop`, or `promote`; never infer progress from elapsed
time alone. The 200+ hour claim means wall-clock lifetime across bounded turns,
not continuous compute.

The parent Global Experience Agent owns session continuity, owner routing,
delegation, child join, memory capture, structural changes, Git/release gates,
and final publication. A child Agent owns only its registered write surface and
returns a compact result with verification and evidence.

## Desktop resource policy

- One worker lane by default; parallel lanes require an explicit frontier and
  separate write scopes.
- High-cost LoopX capabilities remain installed and available. The parent GEA
  decides whether to enable them per trajectory after checking expected value,
  evidence need, budget, authority, and a stop/recovery condition. The decision
  is recorded in the turn packet; it is not inferred from task wording alone.
- No background wake loop by default. Wake on a user turn, a material event,
  or a deliberately scheduled low-frequency heartbeat. Auto-wake is enabled
  only when the GEA records why manual wake would lose material progress.
- Use `quota should-run` before any worker turn and spend a slot only after
  validated evidence writeback.
- Prefer `--headless --no-auto-wake` for local rehearsals. When the GEA enables
  high-cost mode, visible panes, extra worker rounds, or parallel lanes are
  allowed only inside the declared budget and stop condition.
- Keep raw logs, prompts, absolute paths, credentials, and private provider
  payloads outside public-safe state. Store aliases, hashes, summaries, and
  revision-pinned references only.

## Monitor and heartbeat lifecycle

- Represent a durable watch as one `continuous_monitor` todo with a stable
  target, cadence, next-due time, expiry, and material-transition condition.
  The host automation or scheduler is an execution surface, not evidence that
  the monitored target is progressing.
- Collapse unchanged heartbeats into one no-progress receipt. They do not
  count as delivery, quota spend, new experience evidence, or proof that the
  target completed or stalled.
- Treat an explicit user pause or stop request as the next control-plane action.
  Resolve the exact host automation, persist its paused state through the host
  automation control surface when exposed, preserve its definition unless the
  user requested deletion, and verify the persisted state before more target
  diagnostics.
- A provider, model, quota, or transport failure in the monitor turn describes
  monitor health only. It must not reopen target work, prove target failure, or
  consume a successful observation. On the next available control turn, settle
  any pending pause or stop request before resuming diagnostics.
- `Get-AgentHostRecoverySignal.ps1` returning `not-stalled` is liveness evidence
  only. It does not prove completion and does not authorize mutation of the
  observed task.

## Windows entrypoint

From `F:\codex`, use:

```powershell
& .\scripts\Invoke-LoopXTrajectory.ps1 -Action doctor
& .\scripts\Invoke-LoopXTrajectory.ps1 -Action start -TrajectoryKind issue-fix -GoalText "..." -GoalId issue-fix-demo
& .\scripts\Invoke-LoopXTrajectory.ps1 -Action inspect -TrajectoryKind issue-fix -GoalId issue-fix-demo
```

The bridge keeps LoopX registry/runtime state project-local under
`.runtime\loopx-trajectory` unless the caller supplies another bounded path.
Use `-Action checkpoint -CommandArgs ...` to call an upstream LoopX packet or
ledger command without creating a parallel state machine.

To request an expensive but still bounded mode, the parent may add
`-EnableHighCost`; to permit background wake it must separately add
`-AllowAutoWake`. These switches change resource scheduling only and never
grant external write, publication, credential, merge, or production authority.

## Turn protocol

1. Read the durable goal, latest thin evidence ledger, and current checkout or
   artifact revision.
2. Ask LoopX for `quota should-run`; if it says wait, persist the next due
   condition and stop this turn.
3. Claim exactly one todo/lease for the bounded action. A child may not claim a
   todo belonging to another lane.
4. Perform the smallest authorized action and run the narrowest proving check.
5. Write compact evidence and decision classification back before quota spend.
6. Refresh state, set the next action or typed terminal gate, and hand off with
   verification, risks, and an explicit recovery condition.

## Failure and recovery

Transport/TLS/request timeout is `restart-required`: persist the save point,
stop retry, and ask for Codex/host restart; after restart use GEA `Resume` then
`Continue`. A failed validation is not a quota success. Repeated unchanged
frontier observations should become a monitor/no-progress receipt, not a hot
loop.
