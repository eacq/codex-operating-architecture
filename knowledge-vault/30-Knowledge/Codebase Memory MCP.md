---
id: concept-codebase-memory-mcp
type: concept
status: active
source: codebase-memory-mcp-v0.9.0-install-2026-07-18
verified: true
learning_audience: codex
codex_learning: Use codebase-memory-mcp as a local structural codebase index before broad repository reading; verify graph results against source files before making behavior claims.
---

# Codebase Memory MCP

`codebase-memory-mcp` is a local MCP and CLI code-intelligence backend for
repository orientation. It builds a persistent graph of files, sections,
functions, classes, routes, imports, calls, and related structural entities, then
serves graph search and architecture queries to MCP clients.

It connects [[Codebase Graph Evidence Workflow]],
[[Experience and Knowledge Architecture]], [[Integrated Experience Feedback Loop]],
and [[Verified Experience Promotion]] through evidence-first repository learning.

## Installed role

- Owner skill: [[Knowledge System Module]] records the concept;
  `codex-information-gathering` owns task-time use.
- Local installation: external binary retained outside Git, with the Codex MCP
  config pointing to the installed executable.
- Cache boundary: graph databases and tool config stay in local `.codex`
  storage and are not portable knowledge.

## Operating rule

1. At project entry, index or refresh the current repository before broad file
   reading when the MCP tools are exposed in the current Codex task. For the
   Global Experience Agent repository, the only supported project name is
   `F-codex` rooted at `F:\codex`.
2. Use the currently exposed callable surface: `index_repository`,
   `get_architecture`, `get_graph_schema`, `search_code`, and `trace_path`.
   Use CLI `list_projects` only for local scope validation and cache cleanup.
3. Treat graph output as routing evidence, not final proof.
4. Open and verify the cited files before claiming behavior, ownership, or
   absence.
5. Use fast mode first for large or heterogeneous repositories; retry fuller
   modes only when semantic or similarity edges are needed.

## Agent self-use policy

The Global Experience Agent now treats Codebase Memory as a registered
structural-evidence resource, not as a parallel memory system or independent
owner. The executable policy lives in
`config/agent-codebase-memory-policy.json` and is exposed by
`agent/40-runtime/Get-AgentHarnessState.ps1` as `agent_codebase_memory`.

The Agent self-use lifecycle is:

1. discover the callable MCP surface before deciding graph evidence is
   unavailable;
2. refresh the single canonical `F-codex` project for `F:\codex`;
3. inspect schema and architecture to choose owners and target files;
4. use graph search or trace operations only as routing evidence;
5. open source files and run tests before behavior, ownership, absence, or
   mutation claims;
6. record freshness, coverage limits, verified source evidence, and residual
   risk in the save point or final evidence.

Human, LLM, and internal functional-unit interfaces may consume this graph
evidence under current task authority, but they cannot mutate Agent structure
through it. Only `global-control` may route structure-affecting changes through
`codex-architecture-iteration` and the `agent_structure` gate. Codebase Memory
itself never bypasses owner gates, never creates aliases for `F:\codex`, and
never turns a graph miss into absence proof without source verification.

## Verification

Earlier validation used historical project aliases such as
`codex-operating-architecture` and older callable tools such as `search_graph`,
`query_graph`, and `get_code_snippet`. Those records are retained only as
history. Current Agent-era operation uses the single canonical project name
`F-codex` for `F:\codex` and the currently exposed tool surface:
`index_repository`, `get_graph_schema`, `get_architecture`, `search_code`, and
`trace_path`.

Current startup preflight is verified by calling `index_repository` for
`F:\codex` with project name `F-codex`, confirming status `indexed`, confirming
the graph UI reports `F-codex` healthy, and running
`scripts/Test-CodebaseMemoryProjectScope.ps1`. The required invariant is
exactly one cached global project: `F-codex` rooted at `F:/codex`. Node and edge
counts are run evidence, not stable documentation constants.

On 2026-07-18, `DeusData/codebase-memory-mcp` was re-reviewed from upstream
source at commit `e678b2b6acb02bc1ab84a854f2df0e1d092f2cc0`. A fast MCP index of
the upstream repository as `deusdata-codebase-memory-mcp` produced 14485 nodes
and 67778 edges, with graph schema labels dominated by functions, files,
modules, variables, fields, sections, routes, classes, folders, interfaces, and
methods. Source and test searches confirmed implementation paths for
`CBM_ALLOWED_ROOT`, `.codebase-memory/graph.db.zst`, `auto_index`, and
`CBM_DIAGNOSTICS`.

This changes the local operating emphasis from "use a graph if present" to
"the Global Experience Agent warms `F-codex`, inspects callable graph evidence
when relevant, records coverage limits, then verifies against source." Security
and portability guidance should mention allowed-root configuration in
less-trusted contexts, keep graph databases local by default, and treat
diagnostics as user-controlled support artifacts rather than durable knowledge.

## Boundary

The tool reads local source and writes local index/config files. Do not commit
its cache databases, local MCP paths, or machine installation records. For the
Global Experience Agent repository, clear C-drive, WindowsApps, external
reference, network-learning, and duplicate alias indexes from the active
Codebase Memory cache before full validation; preserve only `F-codex` unless
the user explicitly asks for a separate project-scoped graph. Restart Codex
tasks after MCP config changes so the server is loaded by the client. If a
project explicitly wants to share `.codebase-memory/graph.db.zst`, require a
separate privacy review and reproducibility reason; otherwise treat it as a
local derived artifact.
