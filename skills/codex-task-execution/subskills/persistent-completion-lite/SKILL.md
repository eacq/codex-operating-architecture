---
name: codex-task-execution-persistent-completion-lite
description: Owner-internal completion loop for clear repository tasks that require checkpoints, verification, and durable finish evidence.
---

# Persistent Completion Lite

Use this subskill only through the parent `codex-task-execution` owner. It is a
lightweight local adaptation of external persistent execution loops, not an
autonomous runtime or hook-driven state machine.

## Trigger

Run only when the user explicitly asks Codex to keep working until a clear task
is verified, or when a previously approved implementation is mid-flight and the
next safe step is unambiguous.

Ordinary words such as "continue", "keep going", or "finish it" do not trigger
this mode by themselves when scope, authority, or safety boundaries are unclear.

## Contract

1. Restate the concrete target and current stopping condition.
2. Build a short checklist with one active item at a time.
3. After each material change, run the narrowest meaningful verification.
4. If verification fails, diagnose from local evidence, apply one safe targeted
   repair, and rerun the relevant check.
5. Stop at normal authorization boundaries: destructive scope, credentials,
   external publication, paid services, privileged installs, or unclear user
   intent.
6. Finish only after required processes have stopped and acceptance criteria are
   verified.

Use explicit terminal outcomes for long or persistent execution:

- `finished`: all scoped acceptance criteria are verified.
- `blocked`: a non-user prerequisite prevents progress.
- `failed`: the workflow or verification failed and needs repair.
- `userinterlude`: the user intentionally paused or redirected the run.
- `askuserQuestion`: one blocking user decision is required before safe
  progress can continue.

Assistant prose is not the semantic owner of completion state. Prefer current
verification output, lifecycle records, and explicit question/blocker metadata
over soft endings. Do not end a terminal handoff with optional follow-up
phrases that obscure whether the task finished, failed, blocked, paused, or is
waiting on a required answer.

## Output

Report changed artifacts, verification commands and results, unresolved risks,
the explicit terminal outcome, and any blocked boundary.

## Safety Boundary

This mode increases persistence, not authority. It must not bypass sandbox,
approval, privacy, Git, release, or installation gates.
