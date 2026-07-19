---
name: codex-image-workflow-solution-visualization
description: Decide and create a Chinese explanatory visual for a solved problem when it materially reduces reasoning effort.
---

# Solution Visualization

Use this subskill only through `codex-image-workflow` after the written solution
has established the facts, constraints, and conclusion.

## Trigger

Use when a user asks to solve, explain, teach, or review a problem and the
reasoning contains a relationship graph, a multi-stage procedure, a geometric
construction, a quantitative comparison, or three or more interacting entities.
Do not add a visual merely because a solution exists.

## Workflow

1. State the written conclusion first. Extract only the facts needed by the
   visual; do not invent values, edges, labels, or intermediate steps.
2. Run `scripts/New-SolutionVisualizationPlan.ps1` with a sanitized subject,
   problem type, complexity, and relation labels.
3. Follow the returned format:
   - `mermaid`: relationship or procedure with stable text labels. Include the
     Mermaid source in the answer so it remains reviewable and editable.
   - `svg`: exact geometry or a deterministic construction that needs crisp
     labels and scale-independent lines. Validate all labels and geometry.
   - `png`: chart-like quantitative comparison or a dense visual whose labels
     need lossless raster delivery. Inspect it at final display size.
   - `generated-raster`: complex conceptual explanation only. Use the
     `solution-explanation` prompt template and a sanitized summary; record
     prompt provenance and inspect every factual label.
   - `none`: retain a concise written explanation.
4. Put the visual immediately after the reasoning step it explains. Use Chinese
   labels matching the written solution, add a short caption, and make the
   visual self-contained.
5. Verify that every edge, count, direction, and conclusion agrees with the
   written solution. Remove the visual if it makes the solution less clear.

## Required Boundaries

- Never create a visual before solving the problem or use it as evidence for a
  conclusion.
- Never include raw private questions, account data, local paths, credentials,
  or unlicensed source images in a generated prompt.
- Do not recreate tests from a live assessment. A visual may explain a user
  supplied practice problem, but does not authorize external help, answer
  sharing, or bypassing assessment rules.
- Generated text inside a raster visual is not authoritative. Keep the written
  Chinese explanation authoritative and correct any image-label mismatch.

## Verification Example

For a gift-exchange graph with degree sequence `10, 9, 8, 7, 6, 4, 3, 2, 1, 0`,
the visual should show the repeated rule: the current maximum-degree person is
paired with the current zero-degree spouse, then all remaining degrees decrease
by one. The graphic must not claim a unique answer until the written elimination
has ruled out the alternatives.
