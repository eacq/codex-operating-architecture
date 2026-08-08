---
id: concept-experience-error-feedback
type: concept
status: active
source: codex-error-feedback
verified: true
learning_audience: codex
codex_learning: Unexpected experience-system behavior should become a structured error report before it becomes verified experience, knowledge, or a skill change.
---

# Experience System Error Feedback

Error feedback sits between failed execution and experience promotion. It links
[[Verified Experience Promotion]], [[Experience and Knowledge Architecture]],
and [[Knowledge System Module]].

## Rule

When a user reports an error or a Codex module, skill, script, prompt workflow,
validation run, or lifecycle step produces an unexpected result, create a
structured report first. Preserve the redacted user wording and extract its
individual error statements separately from any suspected cause. The report
names the module, component, code location, symptom, expected and actual result,
observable features, suspected causes, possible outcomes, solution options, and
verification path.

## Repair loop

Create the report before changing the owner. Attempt only the smallest safe
repair, then append the attempted change, observed result, and verification to
the same report. A repair that was not verified remains a candidate; it is not a
successful experience lesson.

## Promotion boundary

- A single error report is evidence, not a verified rule.
- A repeated or fixed-and-verified report can become project experience.
- A reusable failure pattern can become a knowledge note.
- A module contract changes only after the owning module and validation path are
  clear.

## Storage

Reports live under `.codex/errors/`. They should be concise, redacted, and
machine-readable enough for future agents to query without reading raw sessions.
Write Markdown and JSON as UTF-8 without BOM so a strict parser can consume
the artifacts without environment-specific decoding workarounds.

## Cross-project feedback

When another project or workflow calls a global experience-system skill,
script, workflow, or lifecycle gate and the failure is plausibly caused in part
by that global capability, keep the full report in the source project and
mirror only a redacted routing summary to
`$ARCHITECTURE_ROOT/.codex/project/incoming-error-feedback.jsonl`.

The summary records the source project label and path hash, source workflow,
global functions involved, owning module, severity, status, causality strength,
symptom, actual result, and reusable lesson. A global iteration reads this inbox
before declaring the experience system clean. Unresolved high or critical items
with suspected or stronger global causality block the iteration until the owner
is repaired or the report is closed as fixed or verified.
