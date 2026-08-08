---
name: codex-task-execution-content-production
description: Create a source-aware, reviewable content package for articles, social series, newsletters, educational explainers, cover briefs, infographics, comics, or slide narratives through codex-task-execution.
---

# Content Production

Use this subskill only through `codex-task-execution` when the requested result
is content for people to read, view, or present rather than only a technical
artifact.

Use [references/content-package-template.md](references/content-package-template.md)
to create a compact, source-aware brief and review record without inventing a
new project metadata schema.

## Content Brief

Before drafting, write the smallest durable brief in the target project:

- reader, channel, language, purpose, desired action, and delivery deadline;
- source material, claim status, protected facts, quotation/citation limits,
  and unresolved evidence;
- chosen deliverables: article, post series, newsletter, outline, cover brief,
  infographic brief, comic storyboard, or slide narrative;
- voice, accessibility, format, dimensions for visuals, and explicit
  publication boundary; and
- review owner, acceptance checks, output path, and revision stop condition.

Do not invent facts, quotations, citations, data, endorsements, legal claims,
or the user's voice. Ask only when an undiscoverable choice changes meaning,
audience risk, publication, or cost; otherwise label an assumption in the
brief.

## Production Loop

1. Extract the reader problem, one-sentence value proposition, factual spine,
   and a short outline before writing prose. Keep claim-bearing material
   traceable to the supplied or verified source.
2. Draft the smallest requested deliverable. Prefer a clear title, opening,
   sectioned argument or sequence, concrete takeaway, and channel-appropriate
   close over generic filler or engagement bait.
3. Create an asset plan only when a visual improves comprehension. For covers,
   infographics, comics, screenshots, or slide images, hand off to
   `codex-image-workflow`; its format-selection gate decides Mermaid, SVG,
   PNG, JPG, or a verified WebP derivative. Save a brief and prompt provenance
   before generation. Never use SVG merely because an image was requested.
4. For a `.pptx`, `.docx`, or `.xlsx` deliverable, hand the approved narrative
   and asset plan to `codex-office-cli`; do not treat slide-image generation as
   a substitute for an editable deck unless the user explicitly asks for image
   slides.
5. Perform a content review against the brief: factual support, reader value,
   structure, voice, headings, accessibility, visual format, copyright or
   provenance, and channel fit. Separate confirmed defects from stylistic
   alternatives.
6. Deliver a compact package: brief, source pointers, final content, visual or
   deck handoff artifacts when present, and a revision record. Preserve source
   material and named derivatives; do not overwrite an authoritative original.

## Handoffs and Boundaries

- Use `codex-text-style` for academic expression-level revision, not to invent
  research claims.
- Use `codex-information-gathering` and citation-specific owners when sources
  must be found or verified.
- Use `codex-image-workflow` for generation, format selection, hosting, and
  image prompt experience; it retains privacy and external-action boundaries.
- Use `codex-office-cli` or `codex-exact-word-layout` for document and deck
  construction or exact layout.
- Use `codex-git-operations` only for repository history, never as a content
  publishing mechanism.

Drafting does not authorize web publication, social posting, browser login,
credential handling, paid generation, external uploads, copyright reuse, or
installation. Present publication-ready content for user review unless the
user separately authorizes a specific external action.

## Verification and Learning

Verify every final package against the brief at the real delivery size or
channel constraints. If generation, conversion, or review exposes unexpected
behavior, create an error report before changing reusable guidance. Capture
only repeated, source-backed, verified patterns as experience; one successful
draft is not a global style rule.
