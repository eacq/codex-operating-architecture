---
name: codex-error-feedback-global-inbox
description: Owner-internal subskill for mirroring cross-project global-causality failures into the architecture incoming-error inbox.
---

# Global Incoming Error Inbox

Use this subskill only through the parent `codex-error-feedback` owner.

## Trigger

Run when another project or workflow fails and part of the likely cause belongs
to a global experience-system capability.

## Contract

Keep the full report in the source project. Mirror only a redacted routing
summary to:

```text
$ARCHITECTURE_ROOT/.codex/project/incoming-error-feedback.jsonl
```

The summary records source workflow, involved global function names, causality
strength, severity, status, and a pointer to non-secret evidence. It must not
copy credentials, raw sessions, private payloads, or machine-specific details.

## Blocking Rule

Unresolved high or critical global-causality summaries block global iteration
until they are triaged, repaired, downgraded with evidence, or marked
non-global-causal.

## Verification

Run `scripts/Test-GlobalErrorFeedbackInbox.ps1` after changing inbox behavior.
