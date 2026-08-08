# Prompt Template Iteration

Image prompts are reusable project knowledge. Treat a prompt template like a
small workflow contract: it should encode a repeatable requirement, not one
private prompt copied from a chat.

## Template lifecycle

1. Start from the closest template in `prompt-templates/`.
2. Render a request with `scripts/New-ChatGPTImageRequest.ps1 -Template`.
3. Generate through the logged-in OpenAI/ChatGPT route available to the host.
4. Record the accepted prompt file, output path, manual edits, and failure notes
   in the project image request folder.
5. For any accepted image that needs follow-up editing, run
   `scripts/Capture-ImagePromptExperience.ps1`. It writes a compact
   post-generation review: original prompt, observed image problems, edit
   requirements, improved prompt wording, negative constraints, and reusable
   lesson.
6. Promote only repeatable observations into `.codex/project/EXPERIENCE.md`.
7. Update the template only after the same improvement is useful beyond one
   image.

## Useful fields

- Subject or topic.
- Purpose and target audience.
- Output surface and aspect ratio.
- Required composition and entities.
- Text constraints.
- Style constraints.
- Explicit exclusions.
- Reference-image preservation rules when editing.
- Post-generation edit requirements and negative constraints.

## Two priority prompt families

### Reference image editing

Use `prompt-templates/reference-edit.md` when the user supplies an image and a
change request. The prompt must separate what to preserve from what to change.
Good edit prompts inventory subject identity, pose, crop, camera angle,
perspective, lighting, shadows, reflections, texture, background continuity,
and existing text before applying the requested edit. Keep the edit region as
small as possible unless the user asks for full style transfer or canvas
expansion.

### SCI / Nature-style academic figures

Use `prompt-templates/academic-figure.md` when the target is a manuscript
schematic, graphical abstract, mechanism diagram, pipeline, model overview, or
other publication figure. Start with the scientific conclusion and figure role,
then specify topology, panel plan, evidence chain, semantic arrows, labels,
palette, typography, and integrity constraints. Treat "Nature style" as
argument-first, restrained, readable, and reviewable; do not imitate journal
branding or fabricate data.

### Post-generation academic polish

Use `prompt-templates/post-generation-academic-polish.md` when an image has
already been generated and should be revised for paper use. Record both the edit
request and the reason: crowded labels, decorative elements, low contrast,
non-publication palette, vague arrows, unsupported claims, fake data, or
illegible text. The review should end with optimized prompt wording and a short
negative-constraint block that can be reused in future prompts.

## Automatic capture

Use this command shape after follow-up image edits:

```powershell
skills\codex-image-workflow\scripts\Capture-ImagePromptExperience.ps1 `
  -ProjectRoot <project-root> `
  -SourceImage <original-image> `
  -OutputImage <edited-image> `
  -OriginalPromptFile <prompt.md> `
  -TemplateFamily post-generation-academic-polish `
  -FollowupRequirement "<user's later edit request>" `
  -ObservedProblems "<what the image got wrong>" `
  -UpdateExperienceCandidates
```

The script records markdown and JSON under
`.codex/images/post-generation-reviews/`. It may add a candidate lesson to
`.codex/project/EXPERIENCE.md`, but shared prompt templates should change only
after a repeated, verified pattern appears.

## External patterns summarized

Public GitHub image skills converge on three durable practices:

- Save prompt files and generated assets with timestamped provenance.
- Support multiple runtime modes: host-native tool, local CLI/API, or prompt-only
  advisor fallback.
- Keep image generation separate from credential extraction; logged-in browser or
  subscription state may be used only through visible or host-authorized actions.

Sources checked on 2026-07-15:

- https://github.com/openai/codex/blob/main/codex-rs/skills/src/assets/samples/imagegen/SKILL.md
- https://github.com/openai/openai-cookbook/blob/main/examples/multimodal/image-gen-models-prompting-guide.ipynb
- https://github.com/ConardLi/garden-skills/blob/main/skills/gpt-image-2/README.md
- https://github.com/NicholasMTElliott/codex-image-gen
- https://github.com/Leon-llb/codex-image
- https://github.com/cliprise/awesome-ai-photo-editor-prompts
- https://github.com/LPK3215/sci-plot
- https://github.com/QIANJINYDX/research-drawio-skill
