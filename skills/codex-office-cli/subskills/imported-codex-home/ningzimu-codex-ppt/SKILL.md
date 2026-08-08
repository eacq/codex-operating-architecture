---
name: imported-ningzimu-codex-ppt
description: Codex Home import 'ningzimu-codex-ppt'; use through codex-office-cli, never as a top-level entry.
---

# Imported External Package: ningzimu/codex-ppt

**Owner:** `codex-office-cli`  
**Invocation:** parent-owner routed internal subskill; never register a separate global entry point.  
**Source:** `ningzimu/codex-ppt-skill`, MIT license, pinned in `upstream/`.

## Local contract

1. Use this mode only for visually unified, image-based decks. It does not replace the parent owner's editable-PPT, OfficeCLI validation, or delivery workflows.
2. The upstream approval gates for outline, visual style, image backend, sample slide, and full-deck generation remain mandatory.
3. Prefer the currently available built-in image-generation capability. Third-party image APIs, keys, base URLs, and model configuration require their existing credential boundary and explicit user choice.
4. Keep each deck in an isolated user-approved output directory. Do not write API configuration, styles, or runtime state into this imported package.
5. Verify every assembled `.pptx` using the parent OfficeCLI validation route. Retain the upstream project state and slide-result evidence with the deck.

## Built-in image reliability guard

When the selected backend is Codex built-in image generation, treat it as a
rate-sensitive remote service rather than a batch renderer:

1. Set `max_concurrent_slides` to `1` by default. Raise it to `2` only after a
   successful single-slide health check in the current task; never dispatch
   more than two built-in image jobs at once.
2. Record and visually check each returned slide before dispatching the next
   job. Keep completed slides; do not restart a batch because one request
   retries or fails.
3. If Codex reports `connection failed 5/5`, stop dispatching new jobs, inspect
   the worker and generated-image state, then retry only the affected slide
   once after the queue is idle. Do not switch to API/CLI fallback without the
   user's explicit backend decision.

This guard applies to orchestration only and does not change the approved
sample's backend or visual style.

## Imported material

`upstream/` contains the upstream workflow, style references, and assembly scripts. It is a pinned compatibility source, not an additional global skill or runtime controller.
