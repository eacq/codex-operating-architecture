---
name: codex-knowledge-system
description: Maintain linked Codex knowledge, workflow-learning records, indexes, graphs, review cards, and derived knowledge views.
---

# Codex Knowledge System

When a knowledge note has multiple interacting concepts, invoke `codex-image-workflow` to plan a sanitized GPT-first explanatory visual. Keep Markdown authoritative and treat the image as a replaceable derived view.

Treat `$ARCHITECTURE_ROOT\knowledge-vault` as the canonical linked vault.

1. Keep one durable concept, decision, failure pattern, or workflow per note. Require stable typed frontmatter, source, verification state, and meaningful semantic links.
   Classify durable content as an information unit, functional unit description,
   or bidirectional link when it affects global experience-system structure.
   Information units explain or index behavior; functional units execute or
   verify behavior. Link each durable note to the skills, workflows, scripts,
   tests, or validators that consume or update it.
2. Keep raw history outside the vault; retain concise evidence and source pointers.
3. Separate `learning_audience`: Codex rules use `codex_learning`; user study uses Anki fields; `both` requires independent value and wording for each audience.
4. Export user cards only when active recall benefits the user, never merely because Codex should retain a rule.
5. Keep Markdown authoritative. Mermaid, MindMaster, graphs, and hosted images are reproducible derived views.
6. Invoke `codex-image-workflow` only when a visual materially improves understanding; prefer Mermaid for structure. When a generated bitmap is useful in the vault, record prompt provenance, then host and clean it through the image workflow only after remote verification and manifests succeed.
7. Run `skills/codex-knowledge-system/scripts/build_knowledge.py` and
   `skills/codex-knowledge-system/scripts/build_mindmaps.py`; resolve link,
   ID, audience, provenance, and duplicate errors before promotion.

For large, slow, or recoverable knowledge operations, preserve the Cherry
Studio cross-check in `config/agent-capability-routing-policy.json`: separate
durable business state from execution progress, use a persisted work item or
save point, define restart/retry/abandon behavior, and record compensation when
downstream scheduling fails. This is a workflow contract under the existing
knowledge and Agent owners, not permission to add a new scheduler or background
runtime.

For private knowledge or experience conversion, read
[subskills/private-public-conversion/SKILL.md](subskills/private-public-conversion/SKILL.md).

For verified workflow changes, read
[subskills/workflow-learning-record/SKILL.md](subskills/workflow-learning-record/SKILL.md).

Read [references/knowledge-workflow.md](references/knowledge-workflow.md) for schemas, routing, tools, learning outputs, maps, and image provenance.

## Example

```powershell
python .\skills\codex-knowledge-system\scripts\build_knowledge.py
python .\skills\codex-knowledge-system\scripts\build_mindmaps.py
```

Imported local compatibility modes live under `subskills/imported-codex-home/`; preserve the knowledge-system source, privacy, and promotion rules when using them.
