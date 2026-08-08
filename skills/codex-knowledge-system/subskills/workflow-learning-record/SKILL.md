---
name: codex-knowledge-system-workflow-learning-record
description: Owner-internal subskill for recording verified workflow changes as hash-based knowledge and experience candidates.
---

# Workflow Learning Record

Use this subskill only through the parent `codex-knowledge-system` owner.

## Trigger

Run after a verified workflow change, before promoting workflow text into
experience or skill instructions.

## Contract

`scripts/New-WorkflowLearningRecord.ps1` records:

- Workflow hash.
- Related module owners.
- Evidence count.
- Knowledge candidate state.
- Experience candidate state.
- Required architecture action.

The record must not retain raw workflow payloads.

## Handoffs

Route evidence-backed workflow knowledge to linked notes. Route workflow
experience to `codex-experience-capture`. Then require
`codex-architecture-iteration` to consider revise, subskill packaging,
subworkflow, add, merge, split, deprecate, or delete.

## Verification

Run the workflow-learning script, then run the knowledge builders and full
validation when durable behavior changes.
