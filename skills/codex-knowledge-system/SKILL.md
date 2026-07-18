---
name: codex-knowledge-system
description: Build and maintain a dense, linked Codex knowledge system using Obsidian-compatible Markdown, bidirectional links, generated indexes and graphs, MindMaster-compatible mind-map outlines, Mermaid fallbacks, and Anki review cards. Use when extracting knowledge from Codex history, papers, literature workflows, project retrospectives, or experience; when connecting related modules and workflows; when generating mind maps or spaced-repetition material; or when auditing missing links, stale notes, duplicate concepts, and knowledge coverage.
---

# Codex Knowledge System

When a knowledge note has multiple interacting concepts, invoke `codex-image-workflow` to plan a sanitized GPT-first explanatory visual. Keep Markdown authoritative and treat the image as a replaceable derived view.

Treat `$ARCHITECTURE_ROOT\knowledge-vault` as the canonical linked vault.

1. Keep one durable concept, decision, failure pattern, or workflow per note. Require stable typed frontmatter, source, verification state, and meaningful semantic links.
2. Keep raw history outside the vault; retain concise evidence and source pointers.
3. Separate `learning_audience`: Codex rules use `codex_learning`; user study uses Anki fields; `both` requires independent value and wording for each audience.
4. Export user cards only when active recall benefits the user, never merely because Codex should retain a rule.
5. Keep Markdown authoritative. Mermaid, MindMaster, graphs, and hosted images are reproducible derived views.
6. Invoke `codex-image-workflow` only when a visual materially improves understanding; prefer Mermaid for structure. When a generated bitmap is useful in the vault, record prompt provenance, then host and clean it through the image workflow only after remote verification and manifests succeed.
7. Run `scripts/build_knowledge.py` and `scripts/build_mindmaps.py`; resolve link, ID, audience, provenance, and duplicate errors before promotion.

For private knowledge or experience conversion, read
[subskills/private-public-conversion/SKILL.md](subskills/private-public-conversion/SKILL.md).

For verified workflow changes, read
[subskills/workflow-learning-record/SKILL.md](subskills/workflow-learning-record/SKILL.md).

Read [references/knowledge-workflow.md](references/knowledge-workflow.md) for schemas, routing, tools, learning outputs, maps, and image provenance.

## Example

```powershell
python .\scripts\build_knowledge.py
python .\scripts\build_mindmaps.py
```

Imported local compatibility modes live under `subskills/imported-codex-home/`; preserve the knowledge-system source, privacy, and promotion rules when using them.
