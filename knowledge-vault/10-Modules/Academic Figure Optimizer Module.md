---
id: module-academic-figure-optimizer
type: module
status: active
source: user-supplied-skill-package-2026-07-17
verified: true
learning_audience: codex
codex_learning: Use academic-figure-optimizer for data-faithful scientific figure re-rendering, user-requested or inferred dimensions, publication typography, arbitrary supported raster/vector exports, and layout repair; do not use generative image redraws for quantitative plots.
---

# Academic Figure Optimizer Module

Supports [[Scientific Figure Workflow]] when a figure needs source-data or
plotting-code based rendering, exact physical or pixel dimensions, custom dpi,
journal/report/slide/poster exports, publication typography, or repair of
clipped labels, legends, annotations, and note boxes.

It does not replace [[Image Workflow Module]]. Generated schematic figures,
prompt iteration, image provenance, hosting, and cleanup stay with the image
workflow. Dependency setup stays project-local unless the runtime environment
owner verifies repeated cross-project use.
