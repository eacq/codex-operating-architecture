---
name: loopx-issue-fix
description: Use for a durable public issue-to-PR trajectory with revision-pinned repository evidence, bounded fix routes, reviewer preferences, and PR lifecycle monitoring.
---

# LoopX Issue-Fix Adapter

Use this under `codex-git-operations` for the Issue-Fix child profile. LoopX
keeps control-plane state between turns; GitHub remains authoritative for
issues, checkout, commits, checks, reviews, and merge state.

## Route

`repository context -> workflow plan -> candidate preflight -> feasibility`
then exactly one route: `fix_pr`, `comment_only`, or `triage_only`. For `fix_pr`,
use the current checkout and tests, create the smallest branch change, validate
it, prepare a reviewer packet, and monitor the PR through explicit lifecycle
observations. Keep reviewer-facing preferences separate from patch knowledge.

Authority order is current checkout, repository-scoped memory, then external
advice. External advice can suggest; it cannot override a current checkout or
test result. Use revision stamps and compact evidence handles so a successor
can tell which knowledge is stale.

For an issue with a long review or monitor horizon, the parent may enable the
higher-cost monitor path after recording expected review value, poll cadence,
quota ceiling, and stop condition. Unchanged polls remain no-spend
observations.

## Child contract

Required write surface: `.runtime/work/issue-fix-agent/<task-id>`. Required
evidence: `route_plan.json`, `repository_context.json`, `feasibility.json`,
`validation.json`, `review_packet.json`, and `handoff.json`. The child may plan,
inspect, patch an explicitly approved local branch, and prepare a PR packet. It
may not merge, publish, request external review, use credentials, or alter
global Agent structure; the parent owns those gates.

Use the installed CLI through the Windows adapter, for example:

```powershell
& F:\codex\scripts\Invoke-LoopX.ps1 issue-fix workflow-plan --format json --repo owner/repo --issue-ref issue_42 --goal-id issue-fix-demo
& F:\codex\scripts\Invoke-LoopX.ps1 issue-fix feasibility --help
& F:\codex\scripts\Invoke-LoopX.ps1 issue-fix pr-lifecycle --help
```

Do not poll an unchanged PR repeatedly, retain raw review bodies, or spend
quota on a no-op. A merged observation is an idempotent evidence event; the
next action is either a successor issue, a monitor continuation, a user gate,
or a typed no-follow-up.
