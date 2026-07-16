---
id: workflow-image-hosting
type: workflow
status: active
source: codex-image-workflow
verified: true
---

# Image Hosting and Cleanup Workflow

1. Let [[Image Workflow Module]] determine whether the visual is necessary and eligible.
2. For generated images, record prompt provenance and any post-generation edit requirements before upload.
3. Discover local Markdown and Obsidian image references.
4. Upload all unique images and verify HTTPS Bilibili CDN retrieval.
5. Write quarantine copies and a SHA-256 migration manifest.
6. Replace references and verify no local reference remains.
7. Delete originals only after every previous stage succeeds.

This workflow connects [[Knowledge System Module]], [[Experience and Knowledge Architecture]], and [[Scientific Figure Workflow]]. Bilibili hosting is a revocable adapter, so manifests must preserve future migration options. Committed image migrations are also summarized in the generated mind-map manifest so visual provenance remains discoverable from the knowledge graph.
