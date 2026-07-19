---
name: codex-runtime-environments
description: Create, select, reproduce, and audit project-local Python environments plus PowerShell and CMD entry scripts. Use when initializing a project runtime, installing or recording Python dependencies, diagnosing interpreter drift, generating shell launchers, tracking dependency usage, or deciding whether verified multi-project dependencies should become base-environment candidates.
---

# Codex Runtime Environments

Keep the canonical base definition and usage ledger in `$ARCHITECTURE_ROOT\runtime-environments`; keep the physical base environment in the ignored `$ARCHITECTURE_ROOT\.runtime\envs\codex-foundation` (`base` is a Conda-reserved name). Each project owns `.codex/runtime`, including its environment, dependency declarations, lock snapshot, launchers, and evidence.

Use `$ARCHITECTURE_ROOT\scripts\Resolve-CodexRunRoot.ps1` for runtime scratch space: `.runtime\tmp` for disposable validation fixtures, `.runtime\work` for candidate clones or generated workspaces that may survive until review, and `.runtime\cache` for reusable local caches. Do not default to `%TEMP%`, `%LOCALAPPDATA%`, `$HOME\.cache`, or scattered project folders for Codex-managed runtime work unless an external tool forces that location and the exception is recorded.

Use `scripts/Manage-CodexEnvironment.ps1`:

1. Run `status` before mutation.
2. Run `init-base` only for the canonical architecture; run `init-project -ProjectRoot <root>` for projects.
3. Run `profiles` to inspect reusable dependency groups. Use `add-profile -Profile office-media-basic` to record Word/PPT/PDF/image intent; add `-Apply` only after the required installation notice.
4. Run `scaffold-file-tools` to create project-local file-processing launchers and DPAPI secret helper scripts under `.codex/runtime`.
5. Use `add -Package <name> -ProjectRoot <root> -Apply` only after the required installation notice. Without `-Apply`, record intent only.
6. Run `record-use` after a dependency-backed operation succeeds. Record failed or unverified attempts without promoting them.
7. Run `recommend` to produce candidates. Promote only dependencies verified in at least two projects and three successful uses, after checking compatibility and duplication.

For a validator or builder, probe its declared imports before treating the selected interpreter as usable. If the primary runtime lacks a required package, create structured error feedback and use an already verified interpreter only for safe read-only validation when available. Do not silently install a package, do not label the primary runtime ready, and record the missing dependency as an environment gap for later review.

File workflows should prefer the lightest profile that fits: `office-media-basic` for `python-docx`, `python-pptx`, `pypdf`, and `Pillow`; `pdf-layout-advanced` for `PyMuPDF`; `document-markdown-ai` for `markitdown` or `docling` conversion pipelines. Generated tools import packages lazily and report missing dependencies through `file-tools.ps1 probe`.

Never install project-only packages into the base environment. Prefer the existing Miniconda backend; do not install or upgrade environment managers silently. Do not commit physical environments, credentials, DPAPI ciphertext, caches, or machine-specific activation state. Read [policy.md](references/policy.md) when changing schemas or promotion rules.

## Example

```powershell
.\scripts\Manage-CodexEnvironment.ps1 status -ProjectRoot .\test-project
.\scripts\Manage-CodexEnvironment.ps1 scaffold-file-tools -ProjectRoot .\test-project
```
