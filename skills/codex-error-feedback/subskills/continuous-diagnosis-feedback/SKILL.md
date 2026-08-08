---
name: codex-error-feedback-continuous-diagnosis-feedback
description: Owner-internal subskill for reporting failures found during continuous diagnosis of file organization or complete global iteration.
---

# Continuous Diagnosis Feedback

Use this subskill only through the parent `codex-error-feedback` owner.

## Trigger

Run when continuous diagnosis is probing file organization or complete global
iteration behavior.

## Contract

Continuous diagnosis is a special execution mode, not an exemption from
reporting. Each failed probe remains evidence. Each repair must be explicit,
targeted, and safe. The owner probe must restart from its beginning after every
repair.

The controller may repeat without an arbitrary limit, but must stop when:

- Exact rollback cannot be verified.
- The repair script fails.
- The next repair crosses a normal authorization boundary.
- The failure is outside the selected owner.

## Verification

Verify the active tree was unchanged or restored from the exact pre-iteration
snapshot before further mutation. After repair, rerun the complete owner probe
from the beginning and append the result to the same error report.
