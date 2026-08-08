# Post-Generation Academic Polish Prompt

Revise the supplied generated image so it is suitable for a scientific paper or
thesis figure.

Original purpose: {{purpose}}
Observed problems: {{problems}}
Required edits: {{edits}}
Target venue or style: {{venue_style}}
Output use: {{output_use}}
Aspect ratio: {{aspect_ratio}}

Preserve:

- Preserve the core information architecture, folder/module names, semantic
  arrows, and overall reading order unless listed in `Required edits`.
- Preserve correct labels and remove only text that is wrong, crowded,
  decorative, or not useful for manuscript interpretation.

Academic polish requirements:

- Make the figure cleaner, flatter, and more publication-ready.
- Use a white or very light background, thin vector-like lines, restrained
  colorblind-friendly palette, and generous margins.
- Reduce decorative icon weight; keep only simple semantic icons that aid
  interpretation.
- Improve label hierarchy and spacing so all text is legible at manuscript
  scale.
- Use consistent alignment, panel spacing, arrow direction, and line weights.
- Make every arrow express a real relation: evidence flow, knowledge curation,
  derived view, learning output, or asset workflow.
- Remove visual noise, redundant captions, heavy shadows, thick borders, and
  nonessential gradients.

Negative constraints:

- Do not add fake data, fake citations, fake journal logos, author/institution
  branding, watermarks, decorative charts, or unsupported mechanisms.
- Do not invent new modules, rename existing correct modules, or change the
  meaning of arrows.
- Do not use dark backgrounds, neon colors, tiny microtext, crowded callouts,
  clip-art aesthetics, or presentation-slide decoration.

Reusable lesson to record after editing:

- What was wrong in the generated image.
- Which edit instruction fixed it.
- Which negative constraint should be added to future prompts.
- Whether the improvement is specific to this image or reusable for the
  template.
