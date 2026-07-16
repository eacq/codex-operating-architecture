---
name: codex-file-organization
description: Plan, preview, and safely apply privacy-aware file and folder organization for a project or user-selected directory. Use when users ask to sort files, design a folder hierarchy, rename files, reduce clutter, create a file inventory, or generate an architecture diagram for stored material.
---

# File Organization

1. Inventory before changing anything. Read only names, extensions, sizes, and timestamps by default; never inspect file bodies, credentials, browser data, `.git`, `.codex`, or hidden private-state folders unless the user explicitly scopes them.
2. Classify by purpose first, then lifecycle: `00-inbox`, `10-active`, `20-reference`, `30-output`, `40-archive`, and `90-private-local`. Keep source, generated output, documentation, assets, and runtime state separate.
3. Use lowercase kebab-case folder names and descriptive files. Prefer `YYYY-MM-DD-topic` for dated records and preserve extensions. Never overwrite; add a collision suffix and produce a preview manifest.
4. A global architecture iteration must invoke `scripts/Invoke-IsolatedGlobalExperienceIteration.ps1 -Apply -Replace`: copy the current system to an isolated workspace, create an off-root recoverable backup, organize all eligible files, repair verified references, restore the canonical Git layout, quarantine and delete proven unnecessary artifacts, validate the sandbox, and replace only after success. Then validate the active repository twice, refresh and validate its real global interfaces, and write aggregate cleanup/replacement evidence plus lifecycle state back under `.codex/project`.
5. For three or more non-linear categories, call `codex-image-workflow`'s visual planner. Use a sanitized GPT-generated explanatory image first when it materially improves understanding; use Mermaid/SVG only as deterministic fallback. Do not put names, paths, credentials, personal identifiers, or file contents in image prompts.
6. Treat organization rules like workflows: review evidence for a category or naming rule, then choose retain, refine, add, merge, split, deprecate, or remove. Record the decision and its validation in the project lifecycle; do not create overlapping buckets merely because one folder is untidy.
7. The global default is `managed_roots: ["."]`: every non-backup, non-protected file beneath the project root is eligible for organization during an iteration. `.git`, `.codex`, credential files, and external backup roots remain excluded. `Restore-GitTrackedWorkspaceLayout.ps1` reverses both tracked and eligible untracked moves in the isolated copy and restores affected references, so validation and Git always see the canonical layout.
8. When structure or image semantics change, refresh the README, manifest, and diagram together. Edit a still-valid image, regenerate after topology changes, and delete obsolete images.
9. Deletion requires evidence. `Remove-UnnecessaryOrganizationArtifacts.ps1` may delete only currently untracked disposable temporary/cache files and empty non-protected directories. Re-run candidate discovery on the active tree after replacement and again after validation, because validation may regenerate caches; never propagate deletion from a stale manifest. Quarantine every file outside the project with its relative path and SHA-256 before each deletion. Never recursively delete an unknown folder or a tracked, runtime, dependency, credential, backup, `.git`, or `.codex` path.

Read `references/organization-contract.md` for the naming, privacy, and apply contract.
