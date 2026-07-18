---
id: concept-top-level-owner-governance
type: architecture-governance
status: active
source: authorized-top-level-owner-economy-review-2026-07-18
verified: true
learning_audience: codex
codex_learning: A top-level owner can evolve only with explicit current-iteration user authority, an evidence-backed boundary comparison, a rollback or migration condition, and validation; otherwise retain the owner and improve it internally.
---

# Top-Level Owner Governance

Top-level owners are an optimization surface, not a frozen list. Their changes
carry a wider routing and safety impact than owner-internal subskills, so each
add, merge, split, material revision, deprecation, or deletion needs explicit
user authorization for the current iteration.

The decision record compares trigger, workflow, maintained artifact lifecycle,
knowledge base, safety boundary, and independent use evidence. It records the
chosen action, migration or rollback condition, and verification. Prior
authorization never becomes standing permission for a later owner change.

When the evidence does not establish a distinct or overlapping owner boundary,
retain the current owner and optimize its routing, references, or internal
subskills instead.

The 2026-07-18 review applied this rule to `codex-project-optimization`: it
retains its top-level status because project-local lifecycle files and the
initializer are a distinct artifact lifecycle, while its generic work claims
were narrowed and handed back to specialized owners.

The same review deprecated `codex-cost-optimization`: its resource rules lacked
an independent artifact lifecycle and were absorbed by the controller's
`resource-economy` subskill. A compatibility entry remains for one release;
the active-owner count excludes it until a later authorized no-reference review.

## Links

- [[Global Experience System]]
- [[Experience and Knowledge Architecture]]
- [[Mother Skill Refinement]]
