---
name: codex-image-workflow-figure-optimization
description: Optimize, redraw, convert, or standardize academic/scientific figures for journal submission, reports, slides, posters, or manuscripts. Use when the user asks to improve chart clarity, repair label overlap or cropping, preserve data fidelity, set publication typography, choose arbitrary physical or pixel dimensions, or export to any requested raster/vector format supported by the local toolchain. Do not use generative image redraws when numerical data fidelity matters.
---

# Figure Optimization

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

### Step 2: Select the correct editing route

Use this priority order:

1. Modify original plotting code.
2. Replot from source data.
3. Edit vector objects.
4. Digitize a raster curve only with explicit disclosure and validation.
5. Pixel enhancement only when no reconstruction is possible.

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
