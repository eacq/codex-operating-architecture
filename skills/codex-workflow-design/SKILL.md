---
name: codex-workflow-design
description: Design or refine repeatable workflows with inputs, outputs, checkpoints, recovery, idempotency, ownership, and verification. Use when initializing a project's `.codex/project/WORKFLOWS.md`, after a verified iteration changes build, test, release, Git, recovery, or domain procedures, when automating recurring work, converting a successful task into a runbook, coordinating multiple skills, or eliminating fragile manual steps.
---

# Codex Workflow Design

Define trigger, inputs, prerequisites, steps, outputs, validation, rollback or recovery, and ownership. Make repeated steps scriptable and idempotent where practical. Keep secrets outside workflow files. Add checkpoints before irreversible or external actions. Include observability: what proves each stage succeeded and how a failed run resumes.

For project work, treat `.codex/project/WORKFLOWS.md` as the current project authority. Update it after verified workflow changes; keep global skills limited to cross-project procedure.

After a verified workflow update, route it through `codex-knowledge-system/scripts/New-WorkflowLearningRecord.ps1`. The record automatically identifies related owners and creates knowledge/experience candidates from evidence count; then `codex-experience-capture` decides promotion and `codex-architecture-iteration` compares triggers, artifacts, ownership, and safety boundaries before any revise, merge, split, add, deprecate, or delete decision. Never promote workflow prose alone as global experience.

Consume `workflow-error-review.json` before changing a workflow after an error. Add a guard for preventable high-impact failures, reorder only when input/evidence order caused the fault, and remove/simplify only when redundancy is independently demonstrated.

For workflows with non-linear handoffs or three or more decision relationships, request a sanitized GPT-first explanatory visual through `codex-image-workflow`; use Mermaid/SVG only when that is more deterministic or image generation is unavailable. Reassess the visual whenever the workflow changes.
