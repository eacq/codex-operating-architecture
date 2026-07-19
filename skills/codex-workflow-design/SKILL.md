---
name: codex-workflow-design
description: Design or refine repeatable workflows with inputs, outputs, checkpoints, recovery, idempotency, ownership, and verification. Use when initializing a project's `.codex/project/WORKFLOWS.md`, after a verified iteration changes build, test, release, Git, recovery, or domain procedures, when automating recurring work, converting a successful task into a runbook, coordinating multiple skills, or eliminating fragile manual steps.
---

# Codex Workflow Design

Define trigger, inputs, prerequisites, steps, outputs, validation, rollback or recovery, and ownership. Make repeated steps scriptable and idempotent where practical. Keep secrets outside workflow files. Add checkpoints before irreversible or external actions. Include observability: what proves each stage succeeded and how a failed run resumes.

For global-system optimization, evaluate recurring work for scriptification before
adding chat instructions: use `scripts/New-ScriptAutomationCandidate.ps1` to
record the owner, repeated trigger, stable inputs, selected language, validation,
and risk. A deterministic read-only or local-reversible task needs at least two
observed occurrences before a script trial. External, irreversible, credential,
installation, publication, or destructive work may be scripted as an assisted
controller but still requires its separate explicit authorization and `-Apply`.

Treat scripts as first-class owner assets alongside skills, knowledge, experience,
and workflows. On every complete global iteration, run
`scripts/Invoke-ScriptAssetOptimization.ps1` to rank measured script/workflow
hotspots. A script may be split, merged, refactored, or moved to PowerShell,
Python, Node, Shell, Go, Rust, or CSharp when the owner and caller contract stay
explicit, the selected runtime is already available or separately authorized,
and baseline plus equivalent behavior evidence proves a net gain. Automatically
apply only owner-scoped read-only or local-reversible optimizations; retain all
other recommendations as candidates.

For project work, treat `.codex/project/WORKFLOWS.md` as the current project authority. Update it after verified workflow changes; keep global skills limited to cross-project procedure.

After a verified workflow update, route it through `codex-knowledge-system/scripts/New-WorkflowLearningRecord.ps1`. The record automatically identifies related owners and creates knowledge/experience candidates from evidence count; then `codex-experience-capture` decides promotion and `codex-architecture-iteration` compares triggers, artifacts, ownership, and safety boundaries before any revise, merge, split, add, deprecate, or delete decision. Never promote workflow prose alone as global experience.

Consume `workflow-error-review.json` before changing a workflow after an error. Add a guard for preventable high-impact failures, reorder only when input/evidence order caused the fault, and remove/simplify only when redundancy is independently demonstrated.

For explicit reviewed planning, use
[subskills/consensus-plan-lite/SKILL.md](subskills/consensus-plan-lite/SKILL.md).
Keep the plan evidence-grounded, critique it once, then hand off to execution
only after acceptance criteria and verification are clear.

For an accepted design or execution-ready requirement that needs a dependency-
aware multi-step implementation plan, use
[subskills/writing-plan-lite/SKILL.md](subskills/writing-plan-lite/SKILL.md).
It maps verified paths, owners, task boundaries, checks, and authority gates
into an executable plan without fabricating detail or starting execution.

For workflows with non-linear handoffs or three or more decision relationships, request a sanitized GPT-first explanatory visual through `codex-image-workflow` and select the delivery format before generation. Mermaid is for small reviewable text structures and SVG for genuine editable vector structure; otherwise choose PNG/JPG or a verified WebP derivative according to delivery need. Reassess the visual whenever the workflow changes.
