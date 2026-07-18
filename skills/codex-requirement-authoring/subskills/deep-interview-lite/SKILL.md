---
name: codex-requirement-authoring-deep-interview-lite
description: Owner-internal subskill for explicit interview-first clarification before planning or implementation. Use through codex-requirement-authoring when the user explicitly asks for a deep interview, interview mode, or ambiguity-gated requirement pass.
---

# Deep Interview Lite

Use this subskill only through the parent `codex-requirement-authoring` owner.
It is a lightweight local adaptation of external interview-first workflows, not
an imported runtime.

## Trigger

Run only when the user explicitly requests an interview-style clarification, or
when the parent owner determines that undiscoverable ambiguity would materially
change implementation, cost, credentials, publication, data mutation, or safety.

Ordinary vague wording is not enough. Prefer conservative assumptions when the
choice is reversible and low risk.

## Contract

1. Preserve the user's literal objective and constraints.
2. Separate discovered facts, inferred assumptions, and unresolved choices.
3. Ask the smallest set of questions needed to make the task execution-ready.
4. Convert answers into acceptance criteria, exclusions, risks, and validation.
5. Hand off to `codex-workflow-design` for multi-step process design or
   `codex-task-execution` for implementation.

## Output

Produce a concise requirement brief with:

- Goal.
- Known constraints.
- Open questions already answered.
- Assumptions still in force.
- Acceptance criteria.
- Validation plan.

## Safety Boundary

Do not use the interview to delay a bounded task. Stop asking when the remaining
uncertainty is low risk, discoverable from local evidence, or safely reversible.
