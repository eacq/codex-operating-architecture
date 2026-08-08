# Academic Figure Quality Checklist

## Data fidelity

- [ ] Original source data or plotting code was used.
- [ ] Curve values and peak locations were not altered.
- [ ] Axis ranges, tick values, units, and tolerance bounds match the source.
- [ ] No generative image model was used to redraw quantitative content.

## Typography

- [ ] Chinese characters use SimSun / 宋体.
- [ ] English, Latin letters, numbers, Greek symbols, units, and parentheses use Times New Roman.
- [ ] Mathematical variables and subscripts use Times New Roman.
- [ ] Required font size is 7.5 pt (六号字), unless overridden.
- [ ] No missing-glyph boxes or unreported font substitutions appear.

## Layout

- [ ] Nothing is clipped by the canvas.
- [ ] Annotation text and arrow remain inside the figure.
- [ ] Legend does not cover a key portion of the curve.
- [ ] Note box does not obscure data.
- [ ] Margins are balanced.
- [ ] Gridlines are subtle and do not dominate the curve.
- [ ] Line widths are consistent and legible at final print size.

## Size and resolution

- [ ] Physical size, pixel size, aspect ratio, and dpi match the user's requested target, or the stated inferred target when the user did not specify one.
- [ ] Pixel dimensions were recalculated from the selected physical size and dpi, or physical size was derived from the requested pixel dimensions and dpi.
- [ ] Embedded dpi metadata is correct.
- [ ] `bbox_inches="tight"` or post-render cropping was not used when exact dimensions were required.
- [ ] Every requested output format opens correctly in the intended consumer.
- [ ] Format-specific requirements such as TIFF LZW compression, transparent background, color mode, or vector editability were checked when requested.

## Deliverables

- [ ] User-requested raster/vector formats were produced, or unsupported formats were reported with a conversion path.
- [ ] PNG for Word insertion, TIFF for journal submission, or PDF/SVG/EPS for vector editing was included when appropriate.
- [ ] Verification summary includes dimensions, dpi, fonts, and limitations.
