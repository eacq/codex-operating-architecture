---
name: resource-economy
description: Make a quality-preserving resource decision for model context, tool calls, time, user attention, and paid or external actions. Use through codex-self-evolution for costly, recurrent, or resource-constrained work.
---

# Resource Economy

## Contract

Set the acceptance and safety floor before selecting a cheaper path. Record the
decision only when the resource choice can materially affect outcome, time,
cost, privacy, or authority.

Use this ladder in order:

1. Project authority, verified local indexes, and compact summaries.
2. Existing skills, deterministic scripts, and non-sensitive cached results
   with provenance and expiry.
3. Targeted model context, tool calls, or external evidence only where the
   prior rungs cannot decide the task.
4. Paid, public, provider-changing, installation, or other higher-authority
   actions only after their normal explicit authorization boundary.

Batch independent read-only checks. Treat user attention as scarce: ask only
at an actual decision or authority gate. Prefer one accountable execution
owner; parallelize only independent work with isolated write surfaces and a
named merge verifier. Stop research when acceptance criteria are decidable.

Never save resources by skipping required verification, security controls,
evidence, rollback readiness, or redaction. This subskill selects work; it does
not authorize external services, provider changes, monitoring, or agents.

## Speed as a constrained optimization metric

Treat speed as a first-class metric only under a fixed quality floor. The
primary measure is `time_to_decidable_next_action`; elapsed turn time, model
and tool round trips, user wait time, and quota consumption are secondary
signals. Also retain the complete task wall-clock interval from task acceptance
to the accepted save point or final verified result. The fields
`task_wall_clock_seconds` and `task_started_at` are valid only when the host or
caller supplies the real task start; without that evidence, report
`not-measured; caller-task-start-required` and never use an operation timer as
a substitute. Keep `operation_wall_clock_seconds` for the local controller or
script interval. When the host exposes a worked-time value such as Codex's
`Worked for ...` display, retain it as `host_reported_worked_time` alongside
the lifecycle interval, controller, and step timings; it is a parallel host
view, not a replacement for lifecycle wall clock. Select the
metric layer from the goal: user outcome uses complete task time, Agent
coordination uses handoff and wait time, controller work uses end-to-end time,
scripts use step time, and validation uses evidence/writeback time. Higher
layers must still retain lower-layer timings for diagnosis. Compare runs only
when their required function set and acceptance criteria are equivalent.

`economy`, `balanced`, and `full` are function-preserving execution versions,
not quality tiers. Select the fastest version that can still retain goal and
intent routing, owner handoff, evidence capture, authority/privacy gates,
rollback or recovery, typed exit, and required validation. Move upward when
the current version cannot close the next evidence gap; move downward when
the frontier is unchanged or the next decision is already decidable. Never
buy speed by removing functionality, validation, privacy, rollback, or
authority checks.

When a global-system optimization identifies a repeated deterministic operation,
prefer an owner-bound script over recurring manual tool choreography. Record the
candidate with `codex-workflow-design/scripts/New-ScriptAutomationCandidate.ps1`:
require stable inputs, a validation check, measured or observed repeat evidence,
and the least complex supported language. Script trials may automate read-only
or local-reversible steps; higher-authority actions remain explicit controllers
with their existing authorization gates.

Treat scripts as first-class assets rather than disposable implementation
details. Complete global iterations automatically analyze persisted timing
evidence through `codex-workflow-design/scripts/Invoke-ScriptAssetOptimization.ps1`.
The analysis may recommend splitting, merging, refactoring, or selecting a more
suitable supported language. It may automatically apply only function-preserving
read-only or local-reversible changes with a measured baseline, equivalent
verification, and rollback; all other changes remain candidates or require
their existing explicit authority.

## Adaptive concise communication

Use the installed `caveman` skill as a presentation-layer compression option,
not as a reasoning, evidence, or verification shortcut. Preserve the user's
language, claims, commands, paths, code, exact errors, authority boundaries,
and verification evidence.

Autonomously choose `caveman-lite` for routine progress updates, low-risk
status summaries, and repetitive global-experience-system work when token
efficiency, context pressure, or long-running iteration overhead is material.
This autonomous choice is local to the response stream; it does not rewrite
durable files, change the user's requested document style, or persist as a
session preference unless the user explicitly asks for caveman mode, brevity,
or lower token use. Use `full`, `ultra`, or wenyan variants only on explicit
user request.

Return to ordinary clear prose for safety warnings, irreversible-action
confirmation, ambiguous multi-step procedures, formal reader-facing documents,
candidate reports, release notes, error reports, user-facing instructions that
depend on order, or any situation where compression would obscure scope or
accountability. Do not rewrite durable memory, source documents, or skills
merely to reduce tokens unless the user separately authorizes that edit and a
before/after review proves no semantic loss.
