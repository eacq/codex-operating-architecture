---
id: concept-locked-template-docx-package-invariants
type: concept
status: active
source: codex-exact-word-layout;verified locked-template Word repairs
verified: true
learning_audience: codex
codex_learning: For a locked-template DOCX, snapshot critical package parts and media, patch the smallest known surface, compare intentional XML changes semantically, and accept only after both hard structural checks and rendered-page review pass.
---

# Locked Template DOCX Package Invariants

Locked-template Word work is a package-preservation problem as well as a text
editing problem. A document can open successfully while a high-level save has
changed headers, relationships, styles, section behavior, or rendered flow.

## Rule

Before mutation, record the authoritative source and critical package boundary.
After mutation, prove that untouched binary parts remain identical and that any
expected XML change is confined to the documented semantic edit surface.

## Acceptance Boundary

- Structural hard failures and visible render defects both reject the output.
- XML equality alone cannot approve layout; rendering alone cannot approve a
  corrupted package or lost citation/field/equation content.
- A documented exception must name the exact allowed semantic difference and
  reject all other variation in that package part.

## Links

- Module: [[Exact Word Layout Module]]
- Workflow: [[Exact Word Layout Workflow]]
- Promotion boundary: [[Verified Experience Promotion]]
- Candidate diagnostic: [[Header Frame Body Wrap Diagnostic]]
