---
name: codex-experience-capture-local-experience-iteration
description: Owner-internal subskill for complete local experience passes. It orders evidence sources, classifies results, and prevents raw-session or weak metadata promotion.
---

# Local Experience Iteration

Use this subskill only through the parent `codex-experience-capture` owner.

## Trigger

Run for a whole local experience pass, a completed verified project iteration,
or a global experience refresh that must reconcile lifecycle, errors, memory,
conversation metadata, ledger entries, and linked knowledge.

## Source Order

Inspect sources in this order:

1. Project lifecycle files.
2. Pending events and structured error reports.
3. Incoming cross-project error-feedback summaries.
4. Metadata-only local conversation catalog.
5. Memory indexes.
6. Global experience ledger.
7. Linked knowledge index.

Inspect raw sessions only when a matched metadata record is ambiguous and the
task cannot be completed safely without it. Do not persist raw session content.

## Classification

Classify every observation as one of:

- `verified_lesson`: supported by a verified repair, repeated observation, or
  independent project artifact.
- `project_candidate`: useful but local, weak, or not yet repeated.
- `stale_derived_artifact`: refresh with the owning generator before diagnosis.
- `no_action`: context without reusable procedure or boundary change.

Do not promote a metadata title, one session, or one mirrored summary alone.
Update an owning skill only when evidence changes its reusable procedure or
safety boundary.

## Outputs

Update project `EXPERIENCE.md` and `RETROSPECTIVES.md` first. Route durable
concepts to `codex-knowledge-system`; route owner changes to
`codex-architecture-iteration`. Keep raw sessions, credentials, and
machine-specific paths out of project and global knowledge.

## Verification

Refresh derived catalogs with their owning runtime, run the relevant build or
validation command, and record the evidence source plus invalidation condition.
