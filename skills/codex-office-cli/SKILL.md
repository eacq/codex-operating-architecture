---
name: codex-office-cli
description: Use the locally installed OfficeCLI binary and optional MCP server to create, inspect, render, validate, and modify Office documents (.docx, .xlsx, .pptx) with structured JSON output. Use for Word, Excel, or PowerPoint automation, document issue checks, template merge, batch edits, screenshots/HTML previews, and agentic Office workflows when exact locked-template Word pagination is not the primary owner.
---

# Codex OfficeCLI

Use OfficeCLI as the preferred deterministic tool for ordinary Office document
creation, inspection, modification, validation, and render-feedback loops across
`.docx`, `.xlsx`, and `.pptx`.

## Tool Boundary

- Prefer OfficeCLI for cross-format Office automation, structured JSON reads,
  template merge, batch operations, document validation, `view issues`, HTML,
  SVG, screenshot, and live `watch` previews.
- Use `codex-exact-word-layout` instead when the task is locked-template Word
  pagination, section/header fidelity, rendered page-flow repair, or journal
  format preservation.
- Use project-local runtime helpers only when a Python library is already the
  lighter or more verified owner for the requested operation.
- Do not run OfficeCLI's upstream auto-installer from a global task unless the
  user explicitly wants it to mutate PATH and agent skill directories. The
  architecture install keeps the binary under the local software install root
  and records checksum evidence.

## Invocation

Resolve the executable with `scripts/Get-OfficeCliPath.ps1`. The local
architecture install uses:

```powershell
.\skills\codex-office-cli\scripts\Get-OfficeCliPath.ps1
```

For shell calls, set `OFFICECLI_SKIP_UPDATE=1` unless the task explicitly asks
to update OfficeCLI. Add `--json` whenever the command supports it.

Use the progressive model:

1. L1 read and inspect: `view`, `get`, `query`, `validate`, `view issues`.
2. L2 DOM edits: `set`, `add`, `remove`, `move`, `swap`, `merge`, `batch`.
3. L3 raw fallback: `raw`, `raw-set`, `add-part` only when L2 cannot express
   the needed OOXML change.

Before guessing properties, run `officecli help <format> <element>` or
`officecli help <format> <verb> <element>`.

## MCP Integration

OfficeCLI's MCP server is started with:

```powershell
officecli mcp
```

The MCP tool passes one raw command string through to the CLI. Use commands such
as `help docx paragraph`, `view report.docx text --json`, or
`validate deck.pptx --json`; do not assume a structured multi-parameter schema.

Codex exposes newly configured MCP servers only after a new task or restart. If
the OfficeCLI MCP tool is not exposed in the current task, use the local CLI
path directly and record that the MCP surface was unavailable.

## Verification

After installation or upgrade, run:

```powershell
.\skills\codex-office-cli\scripts\Test-OfficeCli.ps1
```

Representative verification must cover version/help plus at least one JSON
operation for each of `.docx`, `.pptx`, and `.xlsx`. Close resident documents
before handing files to non-OfficeCLI tools.
