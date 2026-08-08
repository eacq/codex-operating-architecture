# Codex Prompt Template: Academic Figure Optimization

Copy the following prompt into Codex and replace the bracketed variables.

---

Use the `$codex-image-workflow-figure-optimization` subskill.

## Task

Optimize or redraw the attached scientific figure for academic publication.

## Input

- Input figure/data/code: `[PATH_TO_INPUT]`
- Source type: `[plotting code / CSV / Excel / vector graphic / raster image / Word document]`
- Output directory: `[OUTPUT_DIR]`

## Mandatory specifications

- Final size: `[width × height in cm / inches / pixels / aspect ratio / infer from destination]`.
- Figure text size: `[7.5 pt / journal requirement / readable at final scale]`.
- Chinese characters: `[SimSun / 宋体 / journal-required font / preserve original if not editable]`.
- English text, Latin letters, numbers, Greek symbols, mathematical symbols, units, subscripts, and parentheses: `[Times New Roman / journal-required font / preserve original if not editable]`.
- Raster resolution: `[300 / 600 / 1200 / custom]` dpi, or `[pixel-first output]`.
- Required outputs: `[any requested raster/vector formats, such as PNG, TIFF, JPEG, PDF, SVG, EPS, BMP, WebP]`.
- Format-specific rules: `[TIFF LZW / transparent PNG / CMYK / RGB / vector editability / journal portal requirement]`.
- Preserve the original data, curve shape, axis ranges, units, legend meaning, tolerance bounds, and annotations.

## Figure content to retain

- X-axis label: Chinese part `[砂轮轴向坐标]`; Latin/math part `[$Z_w$ (mm)]`.
- Y-axis label: Chinese part `[径向偏差]`; Latin/math part `[$\Delta r_w$ (μm)]`.
- Tolerance band: `[−5 to +5 μm]`.
- Legend entries:
  1. `[±5 μm 精密磨削允差带]`
  2. `[峰值偏差点]`
- Annotation: `[峰值偏差点]`.
- Note box: `[备注：阴影为 ±5 μm 精密允差；曲线为解析法相对离散法径向偏差]`.

## Editing rules

1. Prefer modifying the original plotting code or replotting from source data.
2. Do not use an image-generation model to recreate quantitative chart content.
3. If only a raster image is available:
   - first state whether exact font replacement and exact data preservation are possible;
   - do not claim exact SimSun/Times New Roman use after mere pixel enhancement;
   - reconstruct/digitize only when necessary and clearly report possible extraction error.
4. Repair all clipping, overlap, and obstruction problems.
5. Keep annotations inside the canvas.
6. Keep the legend and note box away from important data.
7. Use restrained academic styling: white background, black data curve, subtle gray dotted grid, light translucent tolerance band, consistent thin borders.
8. Do not change the requested physical or pixel canvas size through automatic tight cropping.
9. Verify the installed SimSun and Times New Roman font files before rendering. Stop and report missing fonts rather than silently substituting.
10. Do not distribute or copy font files into the output.

## Required validation

Before completion, verify and report:

- exact pixel dimensions;
- embedded dpi;
- physical width and height, pixel size, or aspect ratio as applicable;
- detected font names and paths;
- absence of missing glyph warnings;
- no clipped or overlapping labels;
- numerical/data preservation method;
- output filenames, formats, and any conversion path.

For physical-size targets, compute expected raster dimensions as `width_cm / 2.54 × dpi` by `height_cm / 2.54 × dpi`. For pixel-first targets, report the pixel size directly and state any inferred physical size.

## Deliverables

Save the outputs in `[OUTPUT_DIR]` using descriptive names such as:

- `figure_17.13cmx7.59cm_7.5pt_SimSun_TNR_1200dpi.png`
- `figure_17.13cmx7.59cm_7.5pt_SimSun_TNR_1200dpi.tif`
- `figure_vector_SimSun_TNR.pdf`
- `figure_vector_SimSun_TNR.svg`
- `figure_16x9_300dpi.png`
- `figure_2400x1600px.pdf`

Also create a short `verification_report.md` summarizing the checks and any limitations.
