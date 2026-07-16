---
id: project-xlw1-manuscript-knowledge
type: project
status: active
source: source-xlw1-api-conversation-evidence
verified: true
learning_audience: codex
codex_learning: Route XLW1 requests through its source-authority, JME-formatting, figure-integrity, and refinement-workflow notes before changing the manuscript.
---

# XLW1 Manuscript Knowledge Map

This map links the verified, project-specific knowledge extracted from prior API-mode conversations without importing raw conversation content.

```mermaid
flowchart LR
    S[API conversation evidence] --> V[Version authority]
    S --> F[JME formatting guardrails]
    S --> G[Source figure integrity]
    V --> W[Manuscript refinement workflow]
    F --> W
    G --> W
    W --> Q[Rendered PDF QA]
```

## Links

- Evidence: [[XLW1 API Conversation Evidence]]
- Decision: [[XLW1 Version Authority]]
- Constraint: [[XLW1 JME Formatting Guardrails]]
- Constraint: [[XLW1 Source Figure Integrity]]
- Workflow: [[XLW1 Manuscript Refinement Workflow]]
- Related: [[Project Knowledge Boundary]]
