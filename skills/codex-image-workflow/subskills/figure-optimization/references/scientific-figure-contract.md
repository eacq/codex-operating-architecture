# Scientific Figure Contract

Adapted from `Yuan1z0825/nature-skills` `nature-figure` at commit
`91862221b39f7ca16d52ae0e1e9cb6c2bb31a96b`.

Use this reference before plotting, redrawing, auditing, or generating a
submission-grade scientific figure. The goal is not to imitate a journal's
surface style; the figure must defend a scientific claim with traceable
evidence.

## Admission

Use this contract for:

- manuscript figures, paper figures, SCI/Nature-style figures, and conference
  paper plots;
- multi-panel quantitative figures, heatmaps, distributions, forest plots,
  image plates plus quantification, and mechanism/workflow schematics;
- figure logic review, legend/statistics audit, export preparation, and
  reviewer-risk checks.

Do not use it for:

- EDA-only exploratory plots without a publication target;
- interactive dashboards or web-first visualizations;
- pure photo retouching;
- Figma/Illustrator-first infographics with no scientific figure intent.

## Required contract before drawing

Record this in working notes or in the response when useful:

```text
Core conclusion:
Figure archetype:
Target venue/output:
Route: Python plotting / R plotting / vector edit / raster repair / AI schematic draft
Backend:
Final size:
Panel map:
  a:
  b:
  c:
Evidence hierarchy:
  hero evidence:
  validation evidence:
  controls/robustness:
Statistics needed:
Source data needed:
Image-integrity notes:
Reviewer risk:
```

Rules:

- The core conclusion must be a sentence with a verb.
- Every panel must carry a unique evidence role; merge or remove panels that do
  not change the argument.
- Give the clearest or largest visual position to the hero evidence.
- Keep controls, sensitivity checks, and robustness panels visually quieter.
- If data are provided but the claim is unclear, infer a provisional claim and
  ask for confirmation before final styling.

## Archetypes

| Archetype | Use when | Design implication |
|---|---|---|
| `quantitative grid` | Main claim is numerical comparison | Shared axes, aligned scales, compact legends, visible uncertainty |
| `schematic-led composite` | Workflow, mechanism, device, or experimental design must be understood first | Schematic leads; validation panels support it |
| `image plate + quant` | Microscopy, histology, spatial overlays, segmentation, gels, or blots lead the evidence | Image integrity, scale bars, and quantification are mandatory |
| `asymmetric mixed-modality figure` | Figure combines schematics, raster images, heatmaps, and quantitative panels | One hero panel spans rows/columns; evidence hierarchy controls size |

## Route and backend policy

Prefer routes in this order:

1. Modify original plotting code.
2. Replot from source data.
3. Edit vector objects.
4. Digitize raster data only with explicit limitation and validation.
5. Pixel enhancement only when no reconstruction is possible.

For Python/R plotting:

- honor an explicit user backend choice;
- otherwise reuse the project's established backend preference when present;
- if neither exists and backend affects the deliverable, ask once instead of
  guessing;
- after selection, keep the backend exclusive for drawing, previews, exports,
  and visual QA.
- load backend-specific plotting guidance only after the backend is selected;
  do not mix Python and R examples in one deliverable just to make previewing
  easier.
- if a backend preference is learned for the same project or caller-authorized
  Agent memory, store it as a scoped preference, not as a global scientific
  default for all future users.

AI-generated images are allowed only for conceptual schematics, graphical
abstracts, and mechanism draft visuals. They are not evidence. Do not use them
to redraw quantitative plots, microscopy results, spectra, heatmaps, statistical
panels, or any data panel.

For explicit AI-schematic requests, the required output is a draft plus
provenance and review boundary. The final scientific content still needs
human/model-visible label, arrow, claim, and source review before it can stand
beside data panels.

## Panel and visual logic

Default panel order:

1. Define the system, sample, method, cohort, device, or workflow.
2. Show the main effect or primary comparison.
3. Show mechanism, localization, or explanatory structure.
4. Quantify representative images or qualitative observations.
5. Add robustness, controls, subgroup analysis, or sensitivity analysis.

Design rules:

- Use one neutral family, one signal family, and one accent family.
- Keep method/condition colors consistent across panels.
- Prefer direct labels when the category position is stable.
- Use a shared legend area when repeated legends waste space.
- Avoid rainbow colormaps unless the scale has a defensible domain-specific
  reason and remains interpretable.
- Background stays white for plots and diagrams; dark backgrounds are reserved
  for microscopy or volume-rendered image plates.

## Statistics and legend alignment

For each quantitative panel, verify:

- what points, bars, boxes, lines, or shaded regions represent;
- exact `n` definition and independent unit;
- biological vs technical replicate status;
- center statistic and spread/interval definition;
- statistical test or model;
- paired/repeated-measures status when relevant;
- multiple-comparison correction when relevant;
- exact p-values or star threshold policy;
- source data behind the panel.

Avoid legends that only state star thresholds. If star labels are used, the
legend must identify the test, correction, comparison set, and independent unit
or explicitly mark missing facts as author input needed.

## Export and QA

Before delivery:

- run `scripts/Validate-ScientificFigureSource.ps1` when plotting source exists;
- verify rendered outputs at the final intended size;
- confirm editable SVG/PDF text when vector editability is requested;
- confirm dimensions, dpi, font policy, labels, scale bars, color accessibility,
  and absence of clipping/overlap;
- keep source data, script, exported figure, and QA notes together when the user
  requests a delivery bundle.

The source validator is a preflight. It does not prove numerical correctness,
statistical validity, or rendered appearance.
