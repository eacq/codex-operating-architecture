---
name: codex-image-workflow
description: Find, generate, select, upload, link, validate, and safely retire images for Codex projects and the Obsidian knowledge vault. Use when knowledge or workflows benefit materially from diagrams, screenshots, figures, or open-license images; when configuring PicGo or Bilibili image hosting; when converting local Markdown or Obsidian image embeds to remote HTTPS URLs; when reducing local image storage; or when auditing broken, duplicate, oversized, unlicensed, inaccessible, or unnecessary images.
---

# Codex Image Workflow

For knowledge, experience, and workflow explanations, first assess whether a visual materially improves understanding. For three or more non-linear relationships, prefer a sanitized GPT-generated visual; use SVG/Mermaid when generation is unavailable, the relationship is deterministic, or the structure is simple. Run `New-UnderstandingVisualPlan.ps1` before creating a project-bound visual. Never send raw private artifacts, local paths, remote identities, credentials, sessions, or user data to GPT image generation. On change, edit only when the visual topology is still valid; regenerate after structural change and delete/unlink obsolete visuals.

Read [references/image-workflow.md](references/image-workflow.md) before uploading, rewriting, or deleting images.

1. Use a visual only when it improves understanding. Prefer Mermaid for structure; otherwise use user-owned, generated, or explicitly licensed images and record provenance.
2. For OpenAI/ChatGPT login-backed image generation, use `scripts/New-ChatGPTImageRequest.ps1` with `-Prompt`, `-PromptFile`, or `-Template`, then read [chatgpt-plus-image-generation.md](references/chatgpt-plus-image-generation.md). Treat the login as a visible or host-authorized generation channel, not an API key, credential store, or cookie source.
3. For reusable prompts, start from `prompt-templates/` and follow [prompt-template-iteration.md](references/prompt-template-iteration.md). When a later user request modifies an already generated image, run `scripts/Capture-ImagePromptExperience.ps1` to capture the follow-up requirement, observed problem, optimized prompt, negative constraints, and candidate lesson before changing templates.
4. For knowledge-vault bitmaps that will be embedded broadly, finish with the hosting workflow: verify image usefulness, upload on demand, verify HTTPS retrieval, rewrite Markdown links, quarantine originals, and retain manifests to save local space without losing recovery.
5. Treat PicGo as replaceable and Bilibili hosting as unofficial and revocable. Never promise permanence.
6. Store Bilibili session values only through `configure_bilibili_credentials.ps1`; never expose them in Git, files, logs, commands, or chat.
7. Preview with `run_bilibili_migration.ps1` before apply. Run only on demand; never schedule scans.
8. Apply transactionally: upload all, verify HTTPS CDN retrieval, quarantine originals, write the manifest, replace every reference, confirm zero local references, then delete originals.
9. On any failure, keep originals and stop. Authentication failure requires user-assisted credential refresh through the secure DPAPI prompt.

Never upload confidential, private, paywalled, or unlicensed material. Browser login may support visible actions but does not authorize cookie or storage extraction.

## Example

```powershell
.\scripts\run_bilibili_migration.ps1 -Root .\test-vault
```
