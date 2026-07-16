# Knowledge Workflow

## Note types

- `module`: capability ownership and routing.
- `workflow`: repeatable inputs, steps, outputs, verification, and recovery.
- `concept`: one reusable claim, distinction, pattern, or failure cause.
- `source`: provenance and freshness boundary.
- `project`: project-local map that links out instead of duplicating project files.

## Quality rules

Use a stable `id`, `type`, `status`, `source`, and `verified` field. Require evidence before marking verified. Prefer links that express dependency, contrast, evidence, or application. A high link count without semantics lowers precision.

## Paper-history routing

Route literature discovery, full-text acquisition, reading, citation verification, writing, figure production, and Zotero management into separate workflow notes. Connect provider-specific lessons to the relevant workflow rather than one large paper note.

## Obsidian

Use Dataview for structured indexes, Omnisearch for retrieval, and Obsidian Git for versioned vault synchronization. Plugin files are locally installed and Git-ignored; versions live in `.obsidian/plugin-manifest.json`.

## Learning audiences

- `learning_audience: codex`: add a concise `codex_learning` rule. It is written to `50-Learning/codex-learning.json` for local retrieval and future experience/skill iteration. It is never exported to user Anki.
- `learning_audience: user`: add `anki_question`, `anki_answer`, and optionally `anki_deck`. It is exported to `50-Learning/user-anki-import.tsv`.
- `learning_audience: both`: provide both the Codex summary and user Anki fields because the two audiences independently benefit.

Do not infer user learning from the presence of an operational rule. The build fails when audience and fields disagree.

## User Anki

Add user Anki fields only when active recall improves the user's own research, technical, or decision-making ability. Run `scripts/build_knowledge.py`; import `50-Learning/user-anki-import.tsv` as tab-separated notes. The source note ID remains a provenance tag. Codex-local learning stays outside Anki.

## Mind maps

Markdown notes and typed links are the canonical knowledge model. Run `scripts/build_mindmaps.py` to produce:

- `40-Maps/Codex Knowledge Map.md`: an Obsidian-renderable Mermaid mindmap.
- `40-Maps/Codex Knowledge Map.txt`: an indented outline suitable for import, paste, or reconstruction in MindMaster.
- `40-Maps/map-manifest.json`: provenance between source notes, generated artifacts, exported images, remote URLs, and Anki eligibility.

Use MindMaster for layout, presentation, and manual exploration. Save optional editable `.emmx` artifacts beside the generated files, but treat them as derivatives. Export useful PNG views to `assets/hostable/mindmaps`; the image workflow may host them only on demand. Keep local files until upload verification, Markdown replacement, quarantine, and manifest recording all succeed.

Learning selection happens at the source note, not in the map. The generated map labels Codex-local and User-Anki nodes separately.

## Generated visuals

When a knowledge summary benefits from a bitmap rather than Mermaid:

1. Draft or update the canonical Markdown note first.
2. Use `codex-image-workflow` to create a prompt request and record provenance.
3. Save the generated image under the vault assets workspace.
4. If the user later asks for changes, capture the follow-up requirements with
   the image prompt experience helper before revising shared templates.
5. When the image is embedded broadly or local storage matters, run image
   hosting on demand; verify the remote URL, rewrite links, quarantine the
   original, and keep the manifest.

Never treat a hosted image as the source of truth. The Markdown note, prompt
provenance, migration manifest, and local recovery path are the durable record.
