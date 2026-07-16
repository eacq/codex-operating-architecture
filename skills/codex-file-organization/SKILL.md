---
name: codex-file-organization
description: Plan, preview, and safely apply privacy-aware file and folder organization for a project or user-selected directory. Use when users ask to sort files, design a folder hierarchy, rename files, reduce clutter, create a file inventory, or generate an architecture diagram for stored material.
---

# File Organization

1. Inventory before changing anything. Read only names, extensions, sizes, and timestamps by default; never inspect file bodies, credentials, browser data, `.git`, `.codex`, or hidden private-state folders unless the user explicitly scopes them.
2. Classify by purpose first, then lifecycle: `00-inbox`, `10-active`, `20-reference`, `30-output`, `40-archive`, and `90-private-local`. Keep source, generated output, documentation, assets, and runtime state separate.
3. Use lowercase kebab-case folder names and descriptive files. Prefer `YYYY-MM-DD-topic` for dated records and preserve extensions. Never overwrite; add a collision suffix and produce a preview manifest.
4. Every global iteration, project initialization, and material follow-up invokes `scripts/Invoke-FileOrganizationLifecycle.ps1 -Apply`. For eligible managed files it creates an off-root archive before changing anything, analyzes text-based references and configuration, rewrites only verified references, moves safely, and runs configured validation commands. A backup is skipped only when the plan has no move or rename.
5. For three or more non-linear categories, call `codex-image-workflow`'s visual planner. Use a sanitized GPT-generated explanatory image first when it materially improves understanding; use Mermaid/SVG only as deterministic fallback. Do not put names, paths, credentials, personal identifiers, or file contents in image prompts.
6. Treat organization rules like workflows: review evidence for a category or naming rule, then choose retain, refine, add, merge, split, deprecate, or remove. Record the decision and its validation in the project lifecycle; do not create overlapping buckets merely because one folder is untidy.
7. Default automatic scope is `00-inbox` only. This prevents accidental relocation of source trees, `.git`, `.codex`, credentials, and unknown entry points. Expand `managed_roots` only after a project-specific impact review; retain non-movable code and runtime paths at their supported locations.
8. When structure or image semantics change, refresh the README, manifest, and diagram together. Edit a still-valid image, regenerate after topology changes, and delete obsolete images.

Read `references/organization-contract.md` for the naming, privacy, and apply contract.
