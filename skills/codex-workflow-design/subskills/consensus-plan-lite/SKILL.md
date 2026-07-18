---
name: codex-workflow-design-consensus-plan-lite
description: Owner-internal subskill for explicit lightweight consensus planning before durable implementation. Use through codex-workflow-design when the user explicitly asks for a consensus plan, reviewed plan, ralplan-like planning, or high-risk implementation plan.
---

# Consensus Plan Lite

Use this subskill only through the parent `codex-workflow-design` owner. It is a
local, lightweight planning mode adapted from external planner/reviewer
workflows; it does not require external agents, hooks, or runtime state.

## Trigger

Run when the user explicitly asks for a reviewed or consensus plan, or when a
durable change has high uncertainty across architecture, data, credentials,
publication, rollback, or user-visible behavior.

Do not run for small reversible edits unless the user asks for planning first.

## Contract

1. Build the plan from repository evidence and current lifecycle files.
2. Identify the owner module for each step before proposing changes.
3. Add a critique pass in the same artifact: list likely failure modes,
   overreach, missing validation, and rollback gaps.
4. Revise the plan once after critique.
5. Hand off only when the plan has clear acceptance criteria and verification.

## Output

Produce:

- Scope and non-goals.
- Owner map.
- Step plan.
- Critique findings.
- Revised execution path.
- Verification and rollback.

## Safety Boundary

Planning is not implementation. If code or file changes are needed, hand off to
`codex-task-execution` after the plan is accepted or after the parent owner
determines execution is already authorized by the user's current request.
