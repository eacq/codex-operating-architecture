---
name: github-readme-presentation
description: Owner-internal GitHub profile and repository README presentation workflow. Use for a read-only audit, a whole README redesign, or a bounded asset set that must be grounded in real project evidence and previewed before publication.
---

# GitHub README Presentation

Owner: `codex-task-execution`. This is the installed local adaptation of
`oil-oil/beautify-github-readme` (MIT, commit
`e337ceac3d78cc37315296ee2c3d2a18407d052e`) and the curated reference
collection `rzashakeri/beautify-github-profile` (CC0-1.0, commit
`34f41124c4b32fa9b4ae9504966a1d0f46080aaf`). Read
[profile-resource-catalog.md](references/profile-resource-catalog.md) when
selecting profile components.

## Select one explicit mode

- **Audit**: inspect clarity, hierarchy, proof, maintenance cost, and asset
  risk; do not edit files.
- **README**: improve the repository homepage's reading order, evidence,
  Markdown, and visual system.
- **Asset-only**: create only the named hero, section headers, workflow,
  badges, diagram, or other asset. Do not edit or embed into a README unless
  the user separately authorizes it.

If the request does not make the mode clear, ask one compact question before
editing. A repository URL or a request to beautify does not grant mutation,
commit, push, PR, or publication authority.

## Build from evidence

1. Read the target README, project metadata, examples, screenshots, and real
   outputs. Identify audience, one-sentence value, primary proof, and first
   successful action. Never invent adoption, benchmarks, compatibility, or
   features.
2. Define a project-native visual direction: palette, typography, shape,
   recurring motif, and composition. Make the first screen explain the project
   rather than serving as generic decoration.
3. In README mode, prefer: hero/value, proof, what it is, mechanism,
   first-use path, then constraints/license/contribution details. Keep body
   copy, commands, links, and accessibility information as Markdown.
4. In asset-only mode, write assets below the target project's approved asset
   directory and show rendered previews before suggesting an embed snippet.

## Complex README design system

For a **whole README**, or whenever a README has at least six headings, changes
three or more top-level sections, or introduces/revises more than one visual,
this subskill is mandatory rather than optional. Before editing, locate the
repository's design-system manifest (default:
`docs/readme-design-system.json`). If absent, create it as part of the README
work. It must record the approved palette, type/layout direction, component
rules, reading order, visual assets, each asset's provenance, and the condition
that requires regeneration or replacement.

Treat that manifest as the source of visual continuity: reuse approved assets
and tokens first, then make the smallest coherent extension. Do not introduce a
new palette, card style, badge family, illustration treatment, external widget,
or image format without updating the manifest and explaining why the existing
system no longer fits. Store project-bound images in the approved asset
directory, retain a provenance record alongside every generated image, and
preview the complete README at GitHub content width and narrow width. Complex
README work is complete only when the design manifest, Markdown layout, asset
references, and project checks agree.

## User-facing explanation routing

Do not limit this workflow to files named README. For every main user-facing
explanation—setup, operating guide, release explanation, changelog, concept
overview, collaboration contract, safety boundary, or decision guide—assess
whether presentation work would improve the collaboration between the user,
local experience system, and model. Use **README** mode when the document is a
large or complex reader journey; otherwise use **Audit** mode and retain the
existing structure when no evidence-backed improvement is warranted. Exclude
only machine manifests, generated plans, raw asset provenance, and similarly
non-reader-facing records. Record the chosen mode, evidence, design-system
relationship, and validation in the project audit artifact.

## Visual and safety gates

- Apply `codex-image-workflow`'s format-selection gate. SVG is appropriate for
  editable deterministic titles, diagrams, badges, and section systems; use
  PNG/JPG/WebP for screenshots, generated artwork, photos, or complex raster
  composition. Do not use SVG as a reflexive default and never rasterize the
  whole README.
- Use only GitHub-safe markup: no scripts, `foreignObject`, remote fonts, or
  essential SVG animation. Make GIF an opt-in derivative only when meaningful
  motion is explicitly requested; retain its source asset.
- Treat external counters, statistics cards, badges, profile widgets, embeds,
  and tracking services as optional dependencies. Verify availability,
  privacy, and reader value before using one; do not add personal identifiers,
  tokens, or analytics merely to decorate a profile.
- Preview at GitHub content width and narrow width. Check contrast, clipped
  text, image alt text, missing assets, links, and file size. In README mode,
  also run the target project's Markdown/readme checks when available.
- Deliver only raster assets (PNG/JPG/WebP) to reader-facing Markdown. Mermaid
  and SVG may remain as internal maintainer sources, but never as Markdown
  display or link targets in a user-facing explanation.
- Decide whether an image contains text from the reader task, not from a
  blanket aesthetic preference. Use text-free artwork for a conceptual hero or
  atmosphere. Add a concise title, labels, legend, or numbered callouts when
  they make a workflow, comparison, architecture, or decision legible without
  forcing readers to cross-reference the body. Keep commands, dense prose,
  accessibility detail, and bilingual explanations in Markdown captions.
- When an image contains text, the design-system manifest must define its
  typography, language policy, contrast, spacing, and exact-text review. Reuse
  the approved palette and component geometry; preview at delivery size and
  verify that every label is readable, accurate, and not clipped. Regenerate a
  visual that has garbled, inconsistent, or unsupported text rather than
  silently shipping it.

## Handoff

Report the selected mode, evidence used, preview, changed files, unchanged
files, and validation. Commits, pushes, pull requests, public showcase
submissions, profile-repository creation, and publication require separate
explicit authorization. Route Git actions to `codex-git-operations` and visual
generation/conversion to `codex-image-workflow`.
