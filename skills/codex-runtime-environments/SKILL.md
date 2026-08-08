---
name: codex-runtime-environments
description: Create, select, reproduce, and audit project-local Python, PowerShell, CMD, dependency, and launcher environments.
---

# Codex Runtime Environments

Keep the canonical base definition and usage ledger in `$ARCHITECTURE_ROOT\runtime-environments`; keep the physical base environment in the ignored `$ARCHITECTURE_ROOT\.runtime\envs\codex-foundation` (`base` is a Conda-reserved name). Each project owns `.codex/runtime`, including its environment, dependency declarations, lock snapshot, launchers, and evidence.

Use `$ARCHITECTURE_ROOT\scripts\Resolve-CodexRunRoot.ps1` for runtime scratch space: `.runtime\tmp` for disposable validation fixtures, `.runtime\work` for candidate clones or generated workspaces that may survive until review, and `.runtime\cache` for reusable local caches. Do not default to `%TEMP%`, `%LOCALAPPDATA%`, `$HOME\.cache`, or scattered project folders for Codex-managed runtime work unless an external tool forces that location and the exception is recorded.

Use `scripts/Release-UsedTaskProcesses.ps1` to release task-scoped leftover
processes after a bounded task: it matches a configured process name and scope
pattern, filters by minimum age and a protected-process list (Codex app, Codebase
Memory MCP, proxy, Adobe, MCP servers), and defaults to dry-run until `-Apply`.
Run `scripts/Test-ReleaseUsedTaskProcesses.ps1` for the deterministic contract
check.

Use `scripts/Invoke-ScriptResourceRelease.ps1` for script/resource control: it
releases task-scoped leftover processes (via `Release-UsedTaskProcesses.ps1`),
deletes disposable `.runtime\tmp` items older than a retention window, and
reports stale `.runtime\work` workspaces as advisory candidates only (never
deleted automatically). Defaults to dry-run until `-Apply`. The timing ledger
from `scripts/Invoke-HistoricalTimingAnalysis.ps1 -Ledger` lists every
functional unit (tool call) with duration and completion status, which drives
script-control decisions. Run `scripts/Test-ScriptResourceRelease.ps1` for the
deterministic contract check.

Use `scripts/Invoke-DataLifecycleCleanup.ps1` at task-end boundaries for the
full data lifecycle governed by `config/data-lifecycle-policy.json`: it reuses
the tmp/workspace cleanup above, prunes old pre-iteration backup snapshots and
old iteration logs to keep-latest windows, and always preserves durable
sessions, memory, timing evidence, archives, reports, proofs, gates, envelopes,
and release backups. Defaults to dry-run until `-Apply`; stale workspaces stay
advisory. `Invoke-CompleteGlobalExperienceIteration.ps1` and
`Invoke-VerifiedPrivateCommit.ps1` call it automatically when a task ends. Run
`scripts/Test-DataLifecycleCleanup.ps1` for the deterministic contract check.

Use `scripts/Manage-CodexEnvironment.ps1`:

1. Run `status` before mutation.
2. Run `init-base` only for the canonical architecture; run `init-project -ProjectRoot <root>` for projects.
3. Run `profiles` to inspect reusable dependency groups. Use `add-profile -Profile office-media-basic` to record Word/PPT/PDF/image intent; add `-Apply` only after the required installation notice.
4. Run `scaffold-file-tools` to create project-local file-processing launchers and DPAPI secret helper scripts under `.codex/runtime`.
5. Use `add -Package <name> -ProjectRoot <root> -Apply` only after the required installation notice. Without `-Apply`, record intent only.
6. Run `record-use` after a dependency-backed operation succeeds. Record failed or unverified attempts without promoting them.
7. Run `recommend` to produce candidates. Promote only dependencies verified in at least two projects and three successful uses, after checking compatibility and duplication.

For a validator or builder, probe its declared imports before treating the selected interpreter as usable. If the primary runtime lacks a required package, create structured error feedback and use an already verified interpreter only for safe read-only validation when available. Do not silently install a package, do not label the primary runtime ready, and record the missing dependency as an environment gap for later review.
Use `python -s` for runtime probes that decide readiness. A project runtime is not ready merely because normal `python` can import from the current user's site-packages. Dependency profiles must install as a coherent group into the project prefix with user-site disabled, then refresh the project lock file from the same isolated environment.

At PowerShell/Python boundaries, resolve the project interpreter explicitly and set `PYTHONUTF8=1`, `PYTHONIOENCODING=utf-8`, and `PYTHONNOUSERSITE=1` for the bounded child process, restoring the caller environment afterward. Durable data, text, and JSON/JSONL artifacts use strict UTF-8 without BOM. Windows PowerShell 5.1 `Set-Content`, `Add-Content`, and `Out-File -Encoding UTF8` write a BOM and are not valid durable data writers; use `.NET` UTF-8 APIs with `UTF8Encoding(false)` and verify bytes rather than console rendering. PowerShell source is the deliberate exception: keep `.ps1` and `.psm1` ASCII when feasible, but require a UTF-8 BOM when non-ASCII source is necessary so Windows PowerShell 5.1 parses it correctly.

File workflows should prefer the lightest profile that fits: `office-media-basic` for `python-docx`, `python-pptx`, `pypdf`, and `Pillow`; `pdf-layout-advanced` for `PyMuPDF`; `document-markdown-ai` for `markitdown` or `docling` conversion pipelines. Generated tools import packages lazily and report missing dependencies through `file-tools.ps1 probe`.

Never install project-only packages into the base environment. Prefer the existing Miniconda backend; do not install or upgrade environment managers silently. Do not commit physical environments, credentials, DPAPI ciphertext, caches, or machine-specific activation state. Read [policy.md](references/policy.md) when changing schemas or promotion rules.

## Example

```powershell
.\scripts\Manage-CodexEnvironment.ps1 status -ProjectRoot .\test-project
.\scripts\Manage-CodexEnvironment.ps1 scaffold-file-tools -ProjectRoot .\test-project
```
