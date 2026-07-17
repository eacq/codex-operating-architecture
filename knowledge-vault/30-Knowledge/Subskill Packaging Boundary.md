---
id: concept-subskill-packaging-boundary
type: concept
status: active
source: codex-skill-packaging-iteration-2026-07-18
verified: true
learning_audience: codex
codex_learning: Use subskill-style packaging inside an existing owner when a capability needs its own contract or tests but does not justify a new top-level skill; promote it only after independent evidence shows a separate owner boundary.
---

# Subskill Packaging Boundary

Subskill-style packaging keeps the global skill list small while preserving
real capability boundaries. The parent skill remains the discovery interface;
the subskill owns an internal mode contract, scripts, examples, and tests.

Use this pattern when a capability shares the parent's trigger, artifacts,
maintained knowledge, and safety boundary but would make the parent `SKILL.md`
too large. Use a top-level skill only when the capability needs independent
discovery, validation ownership, or safety rules.

This boundary connects [[Verified Experience Promotion]],
[[Experience and Knowledge Architecture]], and [[Knowledge System Module]].
