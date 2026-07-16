# Image Workflow

## Visual selection

Use a visual when it reduces reasoning or navigation effort. Prefer, in order: Mermaid or native diagrams with no binary asset; generated user-owned visuals; open-license images with recorded attribution; user-provided images. Avoid decorative images and low-information screenshots.

## ChatGPT Plus web generation

Use `scripts/New-ChatGPTImageRequest.ps1` when the user's local OpenAI/ChatGPT login should drive image generation through a visible web session, a host-native image tool, or an already authenticated Codex CLI handoff. The script records prompt, purpose, destination, handoff instructions, and credential boundary under the target project's `.codex/images/chatgpt-plus/` folder, then can optionally open ChatGPT, copy the prompt, or attempt the CLI handoff. It does not access cookies, tokens, passwords, browser profile files, or account internals. Read [chatgpt-plus-image-generation.md](chatgpt-plus-image-generation.md) and [prompt-template-iteration.md](prompt-template-iteration.md) before changing this workflow.

For knowledge-vault summaries, keep the note authoritative. Generated images
are derived views: record the prompt, save the selected output, capture later
edit requirements, and only then host and clean up local embeds when it saves
meaningful space.

## Bilibili hosting

The adapter uses `https://api.bilibili.com/x/article/creative/article/upcover`, authenticated by the user's Bilibili session Cookie and `bili_jct` CSRF value. This is not an official general-purpose storage contract. Keep provider logic isolated and retain migration manifests.

Chrome login verification does not authorize or technically permit Cookie extraction by Codex. Use Chrome for visible session-bound actions only. Configure API access through the local DPAPI secure prompt. If a value was pasted into chat, treat it as exposed and require a refreshed value.

## Transaction

1. Discover local `![[image.png]]` and `![alt](image.png)` references.
2. Upload all unique images before editing any document.
3. Require an HTTPS URL on a Bilibili CDN host and a successful remote GET.
4. Copy originals to `$IMAGE_QUARANTINE_ROOT\<timestamp>`.
5. Rewrite every reference and write a manifest with SHA-256, source path, documents, URL, and quarantine path.
6. Verify no document still references the local file.
7. Delete originals only after all prior stages succeed.

## Obsidian

Run the migration against `$ARCHITECTURE_ROOT\knowledge-vault`. Remote Markdown image links remain portable. Mermaid blocks should remain local text and are never uploaded.

Obsidian attachments default to `assets/hostable`. Run the migration explicitly when images are ready. Do not use a scheduled or periodic scan. If Bilibili rejects authentication or upload, stop without rewriting or deleting files and prompt the user to refresh credentials using Chrome DevTools Application > Cookies.
