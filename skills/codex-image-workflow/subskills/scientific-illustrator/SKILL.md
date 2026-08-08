---
name: scientific-illustrator
description: Create or reconstruct editable scientific figures through a governed Designer, Drawer, Reviewer, and Corrector loop using approved PowerPoint, WPS, or draw.io backends.
license: MIT
homepage: https://github.com/icebird1998/scientific-illustrator
---

# Scientific Illustrator

Use this owner-internal subskill when a scientific figure, graphical abstract,
mechanism diagram, workflow, or multi-panel schematic needs maximum
editability and a structured quality loop. It is an imported methodology under
`codex-image-workflow`, not an independent Global Experience Agent or MCP
entrypoint.

## Route

1. Select the backend through the existing image, Office, or draw.io route.
   Reuse `drawio-skill` for editable draw.io files and `codex-office-cli` for
   editable presentations; do not auto-register the upstream plugin's MCP
   server or mutate Codex configuration.
2. Read the matching upstream role contract on demand from
   `upstream/plugins/scientific-illustrator/skills/`: Designer for a new
   illustration, Recreator for reference-based work, Drawer for the selected
   backend, Reviewer for read-only evidence, and Corrector for object-level
   repair instructions.
3. Keep text, shapes, connectors, tables, and charts editable where the
   selected backend supports them. Raster material must be semantically atomic
   and must not conceal reconstructable content.
4. Require both structural and actual-render evidence after each material
   region and for the final figure. The Reviewer cannot approve its own
   correction plan; return material findings through a fresh review pass.

## Boundaries

- Do not use live application, browser, certificate, credential, network, Git,
  publication, or Agent-structure operations unless their existing Owner gate
  and explicit task authority permit them.
- For a task without a configured live backend, produce a backend-neutral
  design/review specification or use the existing file-based draw.io/PPTX
  routes. Never claim live canvas control from imported instructions alone.
- Store task outputs only in the approved target project or runtime work
  surface; the `upstream/` folder is reference material and must remain
  unchanged.

The imported source is pinned at `57116d16c76486c34493027dce3720a59548d657`.
