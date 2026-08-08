---
name: codex-experience-capture-workflow-learning
description: Owner-internal subskill for consuming workflow-learning records and routing them into experience, knowledge, and architecture review.
---

# Workflow Learning

Use this subskill only through the parent `codex-experience-capture` owner.

## Trigger

Run after a verified workflow change or after
`codex-knowledge-system/scripts/New-WorkflowLearningRecord.ps1` writes
`.codex/project/workflow-learning.json`.

## Rules

1. Consume `workflow-learning.json` before raw workflow text.
2. Treat one evidence source as a linked-knowledge candidate.
3. Treat two independent verified sources as an experience candidate.
4. Hand candidates to `codex-architecture-iteration` before changing a global
   skill so ownership, merge, split, subskill packaging, or deletion can be
   reviewed.
5. Keep workflow hashes and source pointers; do not store raw private workflow
   payloads in global knowledge.

## Outputs

Write project experience candidates first, then update linked knowledge or
owner skills only after validation. Record source, scope, verification, and
invalidation conditions.
