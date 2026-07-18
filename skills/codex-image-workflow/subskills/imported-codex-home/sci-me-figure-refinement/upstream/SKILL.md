---
name: sci-me-figure-refinement
description: Refine, rebuild, or audit figures for Chinese mechanical-engineering and SCI-style manuscripts from dissertation originals, simulation screenshots, experiment photos, plots, tables, and local reference papers. Use when the user asks for academic figure generation, SCI-style figure polishing, border repair, single-column figure layout, caption consistency, visual comparison, or publication-quality mechanical-engineering diagrams.
---

# SCI Mechanical Figure Refinement

## Source Priority

Start from the user's original dissertation figures, simulation outputs, experimental photos, and data whenever available. Use reference papers for layout and style calibration, not as a substitute for the user's results.

## Figure Decision Tree

1. **Geometry or algorithm workflow**: redraw as vector-like clean schematic with minimal text.
2. **Simulation result**: crop, denoise, standardize labels, and keep the simulation as evidence, not as CAM-operation description.
3. **Experimental photo**: correct perspective/lightness, annotate only necessary parts, preserve real evidence.
4. **Result curve**: rebuild from data when possible; otherwise improve contrast, axes, units, and markers.
5. **Table-like result**: use a Word table if exact values matter; use a plot if trend matters.

## Publication Rules

- Prefer single-column width if labels remain readable.
- Preserve closed borders when the original visual or journal style relies on them.
- Use consistent line weight, font, marker size, and caption style across the paper.
- Avoid decorative gradients, heavy backgrounds, and unnecessary 3D effects.
- Keep Chinese labels concise; use symbols and units consistently with the text and equations.
- Place the figure near the first paragraph that interprets it.

## QA Checks

- No border is missing or open.
- No label overlaps a curve, axis, image edge, or neighboring subfigure.
- Captions identify the object and condition, not just "simulation result".
- Subfigure labels `(a)`, `(b)` are consistent and visible.
- Raster images are sharp at target Word size.
- Figures do not dominate the argument; each figure must support a method, result, or validation claim.

Use `references/figure_polish_checklist.md` for a detailed pass.
