---
id: workflow-solution-visualization
type: workflow
status: candidate
source: user-request-2026-07-19; solution-visualization-planner-test-2026-07-19
verified: false
learning_audience: codex
codex_learning: After written reasoning is established, choose a Chinese explanatory visual only when it materially reduces reasoning effort. Preserve Mermaid for reviewable relationship/procedure logic, SVG for deterministic geometry, PNG for chart-like quantitative views, and a sanitized generated raster only for complex conceptual explanation.
---

# Solution Visualization Workflow

The visual is a derived explanation, never evidence for the answer. The written
solution remains authoritative and every visual label, value, edge, and arrow
must be checked against it.

- Use no visual for a simple one-step calculation.
- Use Mermaid for a relationship graph or multi-stage elimination that benefits
  from a compact, editable explanation.
- Use SVG for deterministic geometry where exact labels and lines matter.
- Use PNG for chart-like quantitative comparison at a verified display size.
- Use a generated raster only for a complex conceptual explanation after
  sanitizing the prompt and recording provenance.

## Links

- [[Visual Format Selection]]
- [[Image Workflow Module]]
- [[Global Experience System]]
