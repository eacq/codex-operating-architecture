---
id: workflow-mind-map-knowledge
type: workflow
status: active
source: user-request-2026-07-14
verified: true
learning_audience: codex
codex_learning: Keep Markdown and typed links canonical; use MindMaster, Mermaid, and exported images only as reproducible derived views.
---

# Mind Map Knowledge Workflow

This workflow connects [[Knowledge System Module]], [[Image Workflow Module]], and [[Verified Experience Promotion]] without creating a second knowledge database.

## Inputs

- Verified Obsidian notes with stable IDs, types, and meaningful links.
- A topic that benefits from hierarchy, dependency, contrast, or workflow visualization.

## Flow

1. Update the canonical Markdown notes and run the knowledge validator.
2. Run `build_mindmaps.py` to generate the Mermaid map, MindMaster-compatible outline, and map manifest.
3. Open or reconstruct the outline in MindMaster when manual layout adds value. The existing 8.5.1 portable installation is sufficient unless a required format fails.
4. Save optional `.emmx` working files under `40-Maps` and export useful PNG views to `assets/hostable/mindmaps`.
5. When remote hosting saves meaningful space, invoke [[Image Hosting and Cleanup Workflow]] manually after prompt provenance or export provenance is recorded. Never schedule a scan.
6. Mark each learning node as Codex-local, user Anki, or both. Add Anki fields only when the user benefits from active recall, then rebuild both learning outputs.

## Verification and recovery

- The Mermaid map must render in Obsidian and the outline must remain readable without MindMaster.
- The manifest must identify source notes and generated artifacts.
- A PNG remains local until remote verification, link replacement, quarantine, and migration manifest success.
- If MindMaster cannot import a generated outline, use copy/paste or Mermaid and keep the canonical notes unchanged.
