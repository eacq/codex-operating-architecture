# Academic Figure Prompt

Create a submission-grade scientific schematic figure about {{topic}} in a
restrained Nature / Science / Cell style.

Research context: {{context}}
Core scientific conclusion: {{message}}
Figure role: {{figure_role}}
Evidence or mechanism chain: {{evidence_chain}}
Panel plan: {{panel_plan}}
Audience: {{audience}}
Aspect ratio: {{aspect_ratio}}

Scientific contract:

- The figure must communicate one primary scientific conclusion, not decorate a
  topic.
- Choose the correct role: method overview, experimental design, cohort flow,
  mechanism schematic, analysis pipeline, model architecture, graphical
  abstract, or conceptual summary.
- Represent inputs, outputs, modules, branches, loops, sample groups, and
  causal or data-flow direction explicitly.
- Use solid arrows for primary flow, dashed arrows for optional feedback or
  inferred links, and grouped panels for independent evidence streams.

Composition requirements:

- Build the layout on a clear grid with generous margins and consistent spacing.
- Use labeled panels only when needed, such as A/B/C, with each panel serving a
  distinct part of the argument.
- Use composite scientific elements instead of generic boxes where useful:
  cells, organs, molecules, matrix tiles, sequencing reads, mini charts,
  neural-network blocks, sample tubes, or instrument icons.
- Keep labels short and exact; prefer noun phrases over sentences.
- Leave room for later journal editing, cropping, or vector tracing.

Nature / Science style requirements:

- White or very light background, thin lines, restrained colorblind-friendly
  palette, muted teal, dusty blue, soft coral, gray, or pale sand.
- Helvetica or Arial-like clean typography; all labels must be readable at
  manuscript scale.
- Precise arrows, subtle dividers, light gray axes or grids only when they carry
  meaning.
- Visual hierarchy should make the main conclusion visible within three seconds.

Integrity requirements:

- Do not invent experimental values, p-values, sample sizes, gene names,
  citations, author logos, institutional marks, or unsupported mechanisms.
- If quantitative plots are needed, show them as schematic placeholders unless
  real data are supplied.
- If the output is intended for draw.io, Illustrator, PowerPoint, SVG, or PDF
  reconstruction, keep geometry simple enough to trace cleanly.

Do not include:

- Decorative clutter, neon colors, dark backgrounds, fake journal branding,
  watermark text, illegible microtext, clip-art aesthetics, photorealistic lab
  scenes, or purely ornamental charts.
