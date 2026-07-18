---
id: concept-visual-format-selection
type: workflow
status: active
source: local-image-workflow-refinement-2026-07-18; baoyu-skills-review-2026-07-18
verified: true
learning_audience: codex
codex_learning: Select image format from the reader task and delivery constraints before generation or conversion. Mermaid and SVG are conditional structural/editable formats; generated and photographic visuals should normally be PNG or JPG according to transparency, fidelity, and size needs.
---

# Visual Format Selection

Visual generation is not format selection. First identify whether the reader
needs editable structure, a crisp transparent raster, an opaque image, or a
small verified web derivative.

- Mermaid is source text for small deterministic diagrams that need review or
  frequent revision.
- SVG is for genuine editable vector diagrams, not a universal visual fallback.
- PNG is the normal raster choice for transparency, labels, line art, UI, and
  lossless inspection.
- JPG is appropriate for opaque photo-like or painterly visuals when smaller
  delivery size matters and compression will not damage meaning.
- WebP is a derivative, not a replacement for the authoritative source, unless
  verified delivery compatibility makes it the selected final artifact.

Every visual records purpose, class, format rationale, dimensions, provenance,
and a rendered final-size QA result. The format gate never authorizes external
generation, conversion software, hosting, browser automation, or publication.

## Links

- [[Global Experience System]]
- [[Experience and Knowledge Architecture]]
- [[Baoyu Skills Network Learning]]
