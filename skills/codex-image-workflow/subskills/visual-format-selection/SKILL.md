---
name: visual-format-selection
description: Select a visual class and final image format before generating, rendering, converting, hosting, or embedding an image.
---

# Visual Format Selection

Use this subskill only through `codex-image-workflow` whenever a task creates,
edits, renders, converts, hosts, or embeds a visual.

## Decision Gate

Before choosing a tool, record the smallest useful plan:

- the reader task and whether a visual materially improves it;
- visual class: text diagram, editable vector diagram, generated illustration,
  photo-like cover, screenshot, UI mockup, scientific figure, or raster export;
- final delivery format, dimensions, transparency requirement, and whether an
  editable source or web derivative is needed;
- provenance, ownership/licence, storage destination, and validation view.

Do not select SVG, Mermaid, PNG, JPG, or WebP by habit. Do not convert a
user-provided or authoritative original destructively; retain the source and
name any derivative.

## Format Rules

| Need | Preferred result | Boundary |
| --- | --- | --- |
| Small deterministic structure, source review or frequent text edits | Mermaid source | Keep it as text; render only when a bitmap delivery is actually required. |
| Editable line/shape diagram for vector-aware consumers | SVG plus a preview when useful | SVG is justified by editability and structural precision, not by being a generic fallback. |
| Transparent background, crisp labels, UI, line art, or lossless raster QA | PNG | Inspect at final display size for text and edge quality. |
| Opaque photo-like, painterly, or cover visual where smaller size matters | JPG | Do not use for transparency or when compression artifacts harm labels/data. |
| Verified web delivery requires a smaller derivative | WebP derivative | Preserve source PNG/JPG/SVG and check target compatibility first. |

Generated illustration, infographic, comic, slide image, screenshot, and
photo-like output are raster by default. Choose PNG when detail/transparency
matters; choose JPG when opaque visual delivery and size favor it. Do not emit
SVG as a substitute for a requested raster result.

## Workflow and Verification

1. Obtain confirmation when the format choice changes cost, editability,
   generated output, public delivery, or the user's original asset. A current
   request that explicitly names a format is the decision.
2. Write prompts and creation metadata before image generation; keep the
   selected source and any derivative linked in the artifact record.
3. Validate dimensions, alpha/background behavior, file size where relevant,
   and a rendered preview at the intended embedding size. For diagrams, also
   check label legibility and semantic direction.
4. Store or host only the selected final asset plus required authoritative
   source; do not create needless duplicate formats.

## Safety

Format selection does not authorize image generation, external conversion,
software/runtime downloads, browser automation, upload, publication, or
destructive overwrite. Keep the existing image-generation, hosting, privacy,
and confirmation boundaries.
