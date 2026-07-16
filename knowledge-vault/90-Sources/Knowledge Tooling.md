---
id: source-knowledge-tooling
type: source
status: active
source: github-review-2026-07-14
verified: true
---

# Knowledge Tooling

- Obsidian 1.12.7: local Markdown vault and bidirectional links.
- Obsidian Git 2.38.6: MIT, 11k+ stars at review; installed without automatic commit intervals.
- Dataview release 0.5.70: MIT, 9k+ stars; published manifest reports 0.5.68.
- Omnisearch 1.29.3: GPL-3.0, 2k+ stars.
- Anki 26.05: AGPL, user-facing spaced repetition only. User cards are generated as `50-Learning/user-anki-import.tsv`; Codex operating knowledge is kept separately in `codex-learning.json` and is never exported merely because Codex should retain it.
- Quicker 1.44.10.0: already installed, proprietary; use only as an optional launcher for `quick_capture.ps1`.
- MindMaster: optional visualization and export layer configured under `$SOFTWARE_INSTALL_ROOT/<MindMaster>`. Markdown and Mermaid remain the durable source and fallback, so an upgrade is unnecessary while the current executable works.
- Visual Studio Code: configured under `$SOFTWARE_INSTALL_ROOT/<VSCode>`. Foam adds Obsidian-style wikilinks, backlinks, and graph navigation; Markdown Preview Enhanced adds automatic live preview, Mermaid rendering, and HTTPS image URL rendering. VSIX archives belong under `$SOFTWARE_ARCHIVE_ROOT/<VSCodeExtensions>`.

This toolchain supports [[Knowledge System Module]], [[Mind Map Knowledge Workflow]], [[Verified Experience Promotion]], and [[Paper Reading and Evidence Workflow]].

Future Windows software follows the local installation profile: retained packages live under `$SOFTWARE_ARCHIVE_ROOT`, while custom-location-capable applications live under `$SOFTWARE_INSTALL_ROOT`.

- PicGo: package and install locations are local profile choices under `$SOFTWARE_ARCHIVE_ROOT` and `$SOFTWARE_INSTALL_ROOT`.
- Bilibili image hosting adapter: isolated local implementation around the article-cover endpoint; no unlicensed third-party plugin code is vendored. Treat availability as revocable and keep migration manifests.
