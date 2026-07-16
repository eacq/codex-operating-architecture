---
name: codex-experience-capture
description: Extract, deduplicate, validate, and store reusable lessons from Codex sessions, project logs, Git milestones, tool failures, corrections, and completed iterations. Use after Git initialization, commit, merge, rebase, tag, or release; after a complete verified project iteration; after a task yields a non-obvious repeatable success or failure; when pending project lifecycle events exist; or when updating project experience, the global ledger, and related skills.
---

# Codex Experience Capture

Start with project evidence, memory indexes, and `knowledge/history-catalog.json`; inspect raw sessions only when necessary.

## Complete Local Experience Iteration

For a whole local experience pass, inspect sources in this order: project
lifecycle files, pending events and error reports, the metadata-only local
conversation catalog, memory indexes, the global ledger, then the linked
knowledge index. Refresh and parse derived catalogs with their owning runtime
before treating them as evidence. Do not promote a metadata title or one
session alone; require a verified repair, repeated observation, or an
independent project artifact.

Classify each result as a verified lesson, a project candidate, a stale derived
artifact, or no action. Update the owning skill only when the evidence changes
its reusable procedure or boundary. Keep raw sessions, credentials, and
machine-specific paths out of project and global knowledge.

Capture trigger, observation, action, verification, scope, invalidation, source, and status. Remove secrets and personal detail; merge duplicates. Update project `EXPERIENCE.md` and `RETROSPECTIVES.md` first.

If the evidence is an unexpected module result, malformed artifact, wrong route,
failed validation, or unclear root cause, invoke `codex-error-feedback` first.
Promote the resulting report only after the cause or reusable lesson is
validated.

## Git-aware capture

When a Git event triggered the capture, record evidence from the repository
that owns the changed paths: its exact repository root, branch, commit (when
created), and the scoped files verified. Never infer the repository from the
current shell directory or copy the event into another repository's lifecycle
record. If the root is uncertain or mismatched, hand routing back to
`codex-git-operations` before recording a milestone.

After a successful commit, read the target repository's local
`codex.route.*` and `codex.last.*` checkpoint when present, then capture the
new commit as the next version of that same route. Keep checkpoint metadata
local to Git; store only reviewable evidence and lessons in project files.

Promote only non-trivial, specific, verified, cross-project, non-duplicate lessons to the global ledger or owning skill. Keep weaker candidates in the project. Use `codex-knowledge-system` for durable linked concepts or user recall material, then run full validation.

When a verified private lesson may be shared publicly, require two independent evidence sources and route its sanitized public candidate through `codex-knowledge-system/scripts/Convert-PrivateKnowledgeToPublic.ps1`. Do not publish raw history, credentials, personal paths, provider endpoints, or project-private claims; retain recipient-specific configuration only in the local portability profile.

When an experience contains multiple interacting causes, actions, and outcomes, route a sanitized summary to `codex-image-workflow` for a GPT-first visual decision. Treat visuals as derived artifacts: edit when semantics remain stable, regenerate after topology changes, and remove when they no longer improve understanding.

After a verified workflow change, consume `workflow-learning.json` before raw workflow text. One evidence source creates a linked-knowledge candidate; two independent verified sources create an experience candidate. Hand both to architecture iteration for ownership/merge/split review before changing a global skill.
