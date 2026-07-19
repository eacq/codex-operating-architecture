# README Raster Visuals Provenance

All reader-facing PNG assets below were generated with the Codex built-in image tool on 2026-07-18. They share the approved warm-canvas, navy, teal, and amber design system; contain no private input, branding, metrics, tracking, or watermark. Text-free conceptual visuals and labeled explanatory visuals are intentionally both supported.

| Asset | Purpose | Regenerate when |
|---|---|---|
| `readme-architecture-overview-labeled.png` | Labeled local experience-system architecture | The owner graph, lifecycle topology, or labels `ROUTE`, `WORKFLOWS`, `KNOWLEDGE`, `VERIFY`, `RELEASE`, `LEARN` change materially. |
| `file-organization-architecture-labeled.png` | Labeled safe transactional organization and rollback loop | Organization, validation, replacement, rollback topology, or labels `ISOLATE`, `BACKUP`, `ORGANIZE`, `VALIDATE`, `REPLACE`, `RECOVER` change materially. |
| `release-v1.6.0.0-highlights.png` | v1.6 release improvement highlight | The release explanation is corrected or superseded. |
| `readme-collaboration-loop-labeled.png` | Labeled collaboration-role loop | The USER, LOCAL EXPERIENCE, MODEL, or VERIFY & LEARN role contract changes, or a label fails the exact-text/readability review. |
| `file-organization-concept-labeled.png` | Labeled privacy-safe file-organization concept | The labels `COLLECT`, `CLASSIFY`, `PROTECT`, or `ARCHIVE` change, or a label fails the exact-text/readability review. |
| `release-visual-highlights-labeled.png` | Labeled release visual | The labels `CLARITY`, `RASTER DELIVERY`, `VERIFY`, or `LEARN` change, or a label fails the exact-text/readability review. |
| `codebase-memory-mcp-graph.png` | Unlabeled Codebase Memory MCP structural graph | Every release after the `F-codex` fast graph refresh, or when `DeusData/codebase-memory-mcp` changes its graph-console rendering contract. The optional GIF is retained unchanged unless the user explicitly asks to generate or update it. |

`readme-collaboration-loop-labeled.png` uses the exact reviewed English labels `USER`, `LOCAL EXPERIENCE`, `MODEL`, and `VERIFY & LEARN`; it is the shared palette/typography example for in-image text. Bilingual detail, commands, and accessible explanations remain in Markdown.

`readme-architecture-overview-labeled.png` and `file-organization-architecture-labeled.png` are the mandatory labeled explanations for the two non-linear workflows; their exact labels were visually checked before embedding.

`file-organization-concept-labeled.png` and `release-visual-highlights-labeled.png` complete the reader-facing visual set. Each image was checked for its exact labels before embedding; the former text-free assets are retained only as maintainers' historical sources and are not reader-facing Markdown targets.

Mermaid and SVG may remain as maintainer-editable sources. User-facing Markdown must embed the approved raster visual instead.

`codebase-memory-mcp-graph.png` is exported directly from the deployed `DeusData/codebase-memory-mcp` Three.js WebGL canvas: live `layout3d` coordinates; UI OrbitControls full-graph framing; `[0, 0, 800]` perspective camera with `fov: 50`; `#06090f` background; default edge/node density compensation; instanced MeshBasic node meshes; AdditiveBlending; and Bloom threshold `0.3`, radius `0.6`, intensity `1.45`. Labels are disabled. The exporter reads canvas pixels through `toDataURL()` and never calls a browser screenshot API. It contains no repository paths, source text, session material, or credentials. Release rendering writes PNG only; the legacy GIF is generated or overwritten only by an explicit user request through `-GenerateGif`.
