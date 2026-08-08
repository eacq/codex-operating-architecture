---
name: codex-image-workflow
description: Plan, generate, convert, host, embed, validate, and retire diagrams, screenshots, academic figures, and stored image assets.
---

# Codex Image Workflow

For a sustained or multi-artifact visual-design task, route through the
registered [visual-design-agent](subskills/visual-design-agent/SKILL.md). It is
the single child-Agent orchestration interface for images, presentations,
diagrams, architecture visuals, and scientific figures; this owner retains
format selection, provenance, image tooling, and route-specific validation.

For knowledge, experience, and workflow explanations, first assess whether a visual materially improves understanding. Then select the visual class and final file format through [subskills/visual-format-selection/SKILL.md](subskills/visual-format-selection/SKILL.md): SVG/Mermaid are conditional editable-structure choices, never a default fallback for visuals that should be raster. For three or more non-linear relationships, prefer a sanitized GPT-generated visual when it improves comprehension. Run `New-UnderstandingVisualPlan.ps1` before creating a project-bound visual. Never send raw private artifacts, local paths, remote identities, credentials, sessions, or user data to GPT image generation. On change, edit only when the visual topology is still valid; regenerate after structural change and delete/unlink obsolete visuals.

For a user request to solve or explain a problem, read [subskills/solution-visualization/SKILL.md](subskills/solution-visualization/SKILL.md). It decides whether a Chinese explanatory visual improves the reasoning, selects Mermaid, SVG, PNG, or a generated raster, and keeps the diagram semantically tied to the written solution.

Read [references/image-workflow.md](references/image-workflow.md) before uploading, rewriting, or deleting images.

For editable architecture, workflow, UML, ERD, network, C4, BPMN, SysML, or
swimlane diagrams, route to
[subskills/drawio-skill/SKILL.md](subskills/drawio-skill/SKILL.md) after the
format-selection gate. Read
[references/drawio-skill-integration.md](references/drawio-skill-integration.md)
first: it keeps the imported capability inside this Owner, resolves the local
runtime through private configuration, and preserves Agent, source, and
external-operation gates.

For maximally editable scientific figures, graphical abstracts, mechanism
diagrams, or reference-based figure reconstruction, route to
[subskills/scientific-illustrator/SKILL.md](subskills/scientific-illustrator/SKILL.md).
It applies the Designer–Drawer–Reviewer–Corrector protocol through this
Owner's already-approved PowerPoint, WPS, and draw.io routes; it does not
silently register a second MCP or live-application controller.

1. Use a visual only when it improves understanding. Record its purpose, chosen class, final format, rationale, dimensions, and any derivative before generation or conversion. Prefer user-owned, generated, or explicitly licensed images; use Mermaid or SVG only when editable structure materially improves the result.
2. For OpenAI/ChatGPT login-backed image generation, use `scripts/New-ChatGPTImageRequest.ps1` with `-Prompt`, `-PromptFile`, or `-Template`, then read [chatgpt-plus-image-generation.md](references/chatgpt-plus-image-generation.md). Treat the login as a visible or host-authorized generation channel, not an API key, credential store, or cookie source.
3. For reusable prompts, start from `prompt-templates/` and follow [prompt-template-iteration.md](references/prompt-template-iteration.md). When a later user request modifies an already generated image, run `scripts/Capture-ImagePromptExperience.ps1` to capture the follow-up requirement, observed problem, optimized prompt, negative constraints, and candidate lesson before changing templates.
4. For knowledge-vault bitmaps that will be embedded broadly, finish with the hosting workflow: verify image usefulness, upload on demand, verify HTTPS retrieval, rewrite Markdown links, quarantine originals, and retain manifests to save local space without losing recovery.
5. Treat PicGo as replaceable and Bilibili hosting as unofficial and revocable. Never promise permanence.
6. Store Bilibili session values only through `configure_bilibili_credentials.ps1`; never expose them in Git, files, logs, commands, or chat.
7. Preview with `run_bilibili_migration.ps1` before apply. Run only on demand; never schedule scans.
8. Apply transactionally: upload all, verify HTTPS CDN retrieval, quarantine originals, write the manifest, replace every reference, confirm zero local references, then delete originals.
9. On any failure, keep originals and stop. Authentication failure requires user-assisted credential refresh through the secure DPAPI prompt.

When an optional, non-authoritative concept-generation pass fails, preserve its
source plan and continue with an already-supported deterministic renderer when
that renderer can express the verified topology. Do not escalate to a
credentialed CLI or provider merely to recover an optional concept pass; keep
the resulting deterministic artifact subject to its normal render and visual
QA gates.

Never upload confidential, private, paywalled, or unlicensed material. Browser login may support visible actions but does not authorize cookie or storage extraction.

## Figure Optimization

Use `$codex-image-workflow-figure-optimization` when a scientific figure needs
data-faithful re-rendering, publication typography, exact dimensions, or export
conversion. It inherits this owner's provenance and runtime-routing boundaries;
do not use generative redraws when numerical fidelity matters.

## Example

```powershell
.\scripts\run_bilibili_migration.ps1 -Root .\test-vault
```

Imported local compatibility modes live under `subskills/imported-codex-home/`; route to one only after this owner's normal format, provenance, and safety gates select it.
