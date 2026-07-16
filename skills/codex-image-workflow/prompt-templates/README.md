# Image Prompt Templates

These templates are project-owned prompt knowledge. Use them through
`scripts/New-ChatGPTImageRequest.ps1 -Template <name> -Set key=value`.

Template rules:

- Keep prompts concrete: subject, visual form, composition, style constraints,
  aspect ratio, text requirements, and exclusions.
- Prefer workflow-specific templates over generic style recipes.
- After a generated image is accepted or rejected, record the reusable lesson in
  `.codex/project/EXPERIENCE.md` before changing a template.
- Do not add private source material, credentials, account identifiers, or raw
  ChatGPT exports to templates.

Priority templates:

- `reference-edit`: image-plus-requirement editing. It first inventories what
  must be preserved, then limits the edit to the requested region.
- `academic-figure`: SCI / Nature / Science / Cell style schematic figure. It
  starts from scientific conclusion, figure role, topology, and panel plan.
- `post-generation-academic-polish`: revise an already generated image for
  paper use, while recording observed problems, required edits, optimized
  prompt wording, and negative constraints.
  Use `scripts/Capture-ImagePromptExperience.ps1` after the edit so the
  follow-up requirement becomes a review record and candidate experience.

Other templates:

- `knowledge-diagram`: visual explanation for a Codex or project workflow.
- `frontend-hero`: product or project hero image for web work.
- `ui-mockup`: interface screenshot or product UI concept.
