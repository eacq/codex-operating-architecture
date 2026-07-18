---
name: codex-task-execution-persistent-completion-lite
description: Owner-internal subskill for explicit persistent completion of a clear repository task through checkpoints and verification. Use through codex-task-execution when the user explicitly asks for persistent completion, keep working until verified, ralph-like execution, or a durable finish loop.
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

## Output

Report changed artifacts, verification commands and results, unresolved risks,
and any blocked boundary.

## Safety Boundary

This mode increases persistence, not authority. It must not bypass sandbox,
approval, privacy, Git, release, or installation gates.
