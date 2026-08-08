---
name: historical-learning-reconciliation
description: Relearn all previously adopted project, skill, method, runtime, and knowledge assets through a bounded full evidence pass.
---

# Historical Learning Reconciliation

Use only through `codex-learning` and the Global Experience Agent. This is a
repeatable full-pass workflow, not a second learning owner or a background
monitor.

## Trigger

Use when the user asks to relearn all earlier projects, Skills, methods,
books, tools, or experience records, or when a full self-evolution task must
reconcile the historical learning surface before structural optimization.

## Required order

1. Load the current project lifecycle, Global Experience Agent registry,
   module registry, Agent filesystem, knowledge indexes, and pending errors.
2. Inventory every current owner Skill, internal subskill, imported wrapper,
   upstream source file, local source snapshot, runtime installation, project
   record, and knowledge note that claims to be learned.
3. Reread source entry points and local adaptations. For a large source,
   inspect its README/manifest, tests, lifecycle, security boundary, and the
   exact files cited by the existing learning record; do not rely on a summary
   alone.
4. Compare each asset with the current owner by trigger, inputs, outputs,
   maintained information, executable functions, privacy boundary, rollback,
   and invalidation condition.
5. Run representative owner, runtime, and graph tests. A source may be
   verified as read while its local adaptation remains guarded or stale.
6. Write a machine-readable reconciliation record and a linked knowledge note;
   store only sanitized, source-bearing conclusions. Store a GEA memory item
   only after the evidence and residual risks are explicit.
7. Ask architecture iteration to review topology and economy. Prefer owner
   refinement or an internal subskill; a new top-level owner requires two
   independent verified use cases and a separate boundary.

## Classification

Each asset ends as one of `verified`, `guarded`, `candidate`, `stale`,
`missing`, or `not-adopted`. `verified` means the current local adaptation and
its proving check are both present. A source commit or old note alone is not
verification. Preserve user-private project content as pointers and bounded
claims only; never copy raw PPT, conversations, credentials, or private files.

## Speed and rollback

`full` controls coverage, not permission to skip gates. Measure time to the
next decidable action and keep the same quality floor. `economy` may use
existing indexed evidence for stable surfaces; `balanced` rereads changed or
uncertain surfaces; `full` rereads all historical categories. All generated
records remain under `F:\codex`; source downloads, if separately authorized,
must be pinned and reversible.

## Verification

Run `scripts/Invoke-HistoricalLearningReconciliation.ps1 -Mode full` for a
read-only preview, then add `-Apply` only when the output path is under the
project root. Run
`scripts/Test-HistoricalLearningReconciliation.ps1` and the narrow owner tests
for every changed surface. Finish with the global candidate report and an
accepted or rejected Agent save point.
