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

## Handoff

Report the selected mode, evidence used, preview, changed files, unchanged
files, and validation. Commits, pushes, pull requests, public showcase
submissions, profile-repository creation, and publication require separate
explicit authorization. Route Git actions to `codex-git-operations` and visual
generation/conversion to `codex-image-workflow`.
