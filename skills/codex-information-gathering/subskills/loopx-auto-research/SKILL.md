---
name: loopx-auto-research
description: Use for bounded multi-agent research trajectories with proposer, executor, evaluator/promoter lanes, frontier evidence, targeted wake, and visible decisions.
---

# LoopX Auto Research Adapter

Auto Research is a thin preset over the generic LoopX multi-agent kernel. The
kernel owns goal/todo/quota/frontier/status/evidence/wake mechanics; this child
owns research role interpretation and compact evidence quality.

## Roles and handoffs

- `hypothesis_proposer` creates a bounded hypothesis todo with grounding and
  novelty refs.
- `research_executor` claims one frontier item, performs one bounded local
  action, and writes an artifact alias plus evaluation result.
- `evaluator_promoter` checks dev/holdout evidence, invalid lineages,
  guardrails, and promote/retire conditions. It cannot promote without the
  parent owner gate.

The evaluator waits on executor evidence using a resumable todo; it does not
close its own review todo merely because a pane is alive. Targeted wake is a
prompt to re-read the frontier, not a result or bypass gate.

## Desktop mode

Use one headless worker turn by default and `max-rounds=1`. Visible Codex panes
and multiple lanes are opt-in only when the parent GEA records that the
additional evidence or coordination value justifies the cost. Disable
background auto-wake by default; enable it only with a low-frequency cadence,
quota ceiling, and a targeted wake reason. Keep
the evidence packet public-safe and compact; never ingest raw trajectories,
private logs, absolute paths, credentials, or full prompts.

```powershell
& F:\codex\scripts\Invoke-LoopXTrajectory.ps1 -Action start `
  -TrajectoryKind auto-research -Question "bounded research question" `
  -GoalId research-demo
& F:\codex\scripts\Invoke-LoopXTrajectory.ps1 -Action worker-turn `
  -TrajectoryKind auto-research -GoalId research-demo `
  -AgentId auto-research-operator
```

The adapter creates a local durable registry, goal state, and one initial
research-contract todo. A worker turn may return `manual_research_required`;
that is a valid resumable boundary, not a failed experiment. The parent Agent
must perform or delegate the real research action, append public-safe evidence,
then resume the same goal. The upstream one-command demo remains a separate
plumbing smoke test and is not treated as the durable project state.

Required write surface: `.runtime/work/auto-research-agent/<task-id>`. Required
evidence: `research_contract.json`, `hypothesis.json`, `evaluation.json`,
`evidence_packet.json`, `frontier_snapshot.json`, and `handoff.json`. A child
returns a typed next action: continue, wait, replan, retire, promote-pending,
or user-gate.
