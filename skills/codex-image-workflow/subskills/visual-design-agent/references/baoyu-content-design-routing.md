# Baoyu Content Design Adaptation

Source: `JimLiu/baoyu-skills` commit `6b7a2e417500561a5ecdd0b168332f4142584617`,
studied locally under `.runtime/work/network-learning/baoyu-skills/` on
2026-07-31. This is an adapted routing catalog, not a copied upstream runtime.

| Content task | Design grammar adopted | Local route | Required record |
|---|---|---|---|
| Social-card series | narrative strategy; style × layout × palette; density-aware cards | `content-card-series` | analysis, outline, per-card prompts, validation, template |
| Infographic | information topology × rendering style × aspect ratio | `content-infographic` | topology choice, style, aspect, prompt, render QA, template |
| Article cover | type × palette × rendering × text density × mood | `content-cover` | cover brief, prompt, readability QA, template |
| Article illustration | illustration position; semantic type × style × palette | `article-illustration` | illustration outline, prompt files, insertion map, template |
| Content diagram | flowchart, sequence, structural, illustrative, or class semantics | `content-svg-diagram` | semantic type, editable source, structural/render QA, template |
| Slide deck | texture × atmosphere × typography × density | `content-slide-deck` | PPT route plan and selected visual template |

Adopted: dimensional style systems, content-first topology selection, prompt
files as reproducibility records, reference-image modes, and output/template
artifacts. Rejected: mandatory external backend configuration, default four-way
generation, Cookie-based/undocumented APIs, automatic publication, and copying
upstream personal preferences into global state.
