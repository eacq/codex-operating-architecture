---
name: codex-image-workflow-figure-optimization
description: Owner-internal figure optimization for publication clarity, label/crop repair, data-fidelity preservation, typography, and raster/vector export.
---

# Figure Optimization

## Nature-style scientific figure workflow

This subskill has learned the `nature-figure` workflow from
`Yuan1z0825/nature-skills` commit
`91862221b39f7ca16d52ae0e1e9cb6c2bb31a96b`. Use the adapted contract for
submission-grade scientific plotting, manuscript figures, multi-panel figures,
scientific schematics, and figure QA. The upstream package is a learning source;
this repository keeps the behavior under the existing `codex-image-workflow`
owner rather than installing a parallel top-level Nature skill.

The relearned upstream router has two important execution rules that this local
Agent contract preserves:

- Treat `nature-figure` as a routed skill with a small always-loaded contract
  plus route-specific depth. Load the local scientific figure contract first,
  then load deeper references only when the figure type needs them.
- Resolve the route before work. Explicit AI manuscript schematics follow the
  image-generation/provenance gate as draft schematics; quantitative plots and
  manuscript figure assembly must resolve a Python/R/source-data/vector/raster
  route and keep that route exclusive for drawing, previews, exports, and visual
  QA.

For publication or manuscript figures, read
[references/scientific-figure-contract.md](references/scientific-figure-contract.md)
before plotting or redrawing. The required ordering is:

1. State the figure's one-sentence scientific conclusion.
2. Map the panel evidence hierarchy and reviewer risks.
3. Classify the figure archetype.
4. Select the route: data-faithful Python/R plotting, vector editing, raster
   repair, or AI-generated conceptual schematic draft.
5. Run source/export QA before delivery.

For quantitative plots, charts, heatmaps, microscopy quantification, spectra,
statistical panels, and source-data figures, do not use a generative image model
to redraw the science. For mechanism diagrams, graphical abstracts, and concept
schematics, AI generation may create a draft only; final scientific labels,
arrows, claims, and quantitative content remain reviewable downstream artifacts.
If no explicit plotting backend or source-language evidence exists and backend
choice affects the deliverable, ask once instead of guessing, then record the
chosen backend in the project notes or Agent memory when the current authority
allows it.

## Global integration

This owner-internal subskill is an execution tool under `codex-image-workflow` and the
Scientific Figure Workflow. Use it for data-faithful rendering, typography,
physical dimensions, resolution, and export formats. Continue to use
`codex-image-workflow` for generated or licensed bitmaps, prompt iteration,
image hosting, provenance, and cleanup.

Do not install Python packages silently. If `matplotlib`, `numpy`, `pandas`, or
`Pillow` are missing, route dependency setup through `codex-runtime-environments`
or the project-local runtime policy first.

Read [references/quality-checklist.md](references/quality-checklist.md) during
final verification. Use
[references/academic-figure-optimization-prompt.md](references/academic-figure-optimization-prompt.md)
when the user needs a fill-in prompt for a recurring figure optimization
request.
Use `scripts/Validate-ScientificFigureSource.ps1` for a deterministic source
preflight when plotting code is available; it checks backend exclusivity,
editable vector-text settings, export formats, unsafe colormaps, simulated-data
leakage, and missing-data/exclusion disclosure cues. Treat it as source QA, not
as proof that the rendered figure or statistical analysis is correct.

## Goal

Produce publication-ready scientific figures while preserving numerical meaning,
plotted data, axis ranges, annotations, and requested size and format
constraints.

## Core principles

1. Preserve data fidelity. Prefer original plotting code or source data; never
   use a generative image model to redraw quantitative curves, charts, spectra,
   contours, scale bars, or measurement traces.
2. Preserve requested dimensions. Accept physical size, pixel size, aspect
   ratio, and dpi; state inferred targets and avoid tight cropping when exact
   size matters.
3. Enforce requested typography. Verify fonts before claiming exact SimSun,
   Times New Roman, or other publication fonts; do not distribute font files.
4. Repair clipping, overlap, legend obstruction, annotation placement, margins,
   line weights, tick density, and excessive decoration.
5. Export requested raster or vector deliverables supported by the local
   renderer/converter. Label pure raster upscaling as resampling, not recovered
   detail.

## Required workflow

### Step 1: Inspect inputs

Identify source type: plotting code, data table, editable vector, Office
document, or raster-only image. Record size or destination constraints, fonts,
formats, dpi, labels/annotations, and whether numerical identity is required.
For manuscript figures, also record the scientific figure contract: core
conclusion, archetype, panel map, evidence hierarchy, statistics needed, source
data needed, image-integrity notes, and reviewer risk.

### Step 2: Select the correct editing route

Use this priority order:

1. Modify original plotting code.
2. Replot from source data.
3. Edit vector objects.
4. Digitize a raster curve only with explicit disclosure and validation.
5. Pixel enhancement only when no reconstruction is possible.

When both Python and R are viable, honor the user's explicit backend or the
project's established backend preference. Once selected for a figure, keep that
backend exclusive for drawing, previews, exports, and visual QA; do not render a
substitute preview in another language because it is convenient.

Do not use route 4 or 5 when the user requires exact numerical preservation unless they approve the limitation.

### Step 3: Confirm fonts

Before rendering, locate installed fonts.

Typical paths:

- Windows:
  - `C:\Windows\Fonts\simsun.ttc`
  - `C:\Windows\Fonts\times.ttf`
- macOS:
  - `/System/Library/Fonts/Supplemental/Songti.ttc`
  - `/Library/Fonts/Times New Roman.ttf`
- Linux:
  - use `fc-match "SimSun"` and `fc-match "Times New Roman"`.

If either font is absent, stop and report which font is missing. Do not silently substitute.

### Step 4: Re-render

Use the bundled script when source data are available:

```bash
python scripts/render_academic_figure.py \
  --csv data.csv \
  --x-column x \
  --y-column y \
  --output-dir output \
  --width-cm 17.13 \
  --height-cm 7.59 \
  --dpi 1200 \
  --font-size-pt 7.5 \
  --simsun "C:\Windows\Fonts\simsun.ttc" \
  --times "C:\Windows\Fonts\times.ttf"
```

The dimensions, dpi, font size, and output formats above are examples, not fixed
requirements. Adapt labels, annotations, canvas size, dpi, and formats through
arguments or script edits. If the requested format is unsupported directly,
export a lossless/vector intermediate and report the conversion path.

For pixel-first output, use `--width-px` and `--height-px` instead of
`--width-cm` and `--height-cm`. When no size is supplied, the bundled script
prints the example canvas assumption; do not treat that assumption as a
workflow requirement.

### Step 5: Quality checks

Use [references/quality-checklist.md](references/quality-checklist.md). At
minimum verify dimensions/dpi, fonts, missing glyphs, clipping or data
obstruction, axes/units/symbols, preserved data geometry, crisp line art, and
openable requested formats.
For quantitative panels, verify legend/statistics alignment: what marks
represent, exact `n` definition, independent unit, center/spread convention,
test/model, multiple-comparison correction when relevant, exact p-value or star
threshold policy, and source-data traceability.

### Step 6: Deliver

Return the requested formats plus a concise verification summary listing size,
dpi, font policy, data-preservation method, conversion path, and limitations.
Use informative filenames that include size, font policy, dpi, or vector status
when useful.

## Prohibited behavior

- Do not regenerate quantitative plots with image-generation models.
- Do not alter curve shape, peak position, axis limits, or tolerance boundaries without explicit approval.
- Do not claim exact SimSun or Times New Roman usage unless the fonts were verified and used by the renderer.
- Do not use interpolation/upscaling as a substitute for code-based re-rendering when source data exist.
- Do not crop to a different physical or pixel size after rendering when the user requested exact dimensions.
