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
   reading when the MCP tools are exposed in the current Codex task.
2. Use `list_projects`, `get_architecture`, `get_graph_schema`,
   `search_graph`, `search_code`, or `trace_path` to find likely evidence.
3. Treat graph output as routing evidence, not final proof.
4. Open and verify the cited files before claiming behavior, ownership, or
   absence.
5. Use fast mode first for large or heterogeneous repositories; retry fuller
   modes only when semantic or similarity edges are needed.

## Verification

The v0.9.0 Windows amd64 release was downloaded from GitHub, checksum-verified,
installed as a static binary, and run with a local cache. `F:\codex` was indexed
as `codex-operating-architecture` in fast mode, producing 1145 nodes and 1156
edges. `get_architecture` and `search_graph` returned architecture and
experience-system nodes tied to the current Git head.

Follow-up MCP validation from inside Codex confirmed that the configured MCP
server exposes `index_repository`, `get_graph_schema`, `get_architecture`,
`search_graph`, `search_code`, `trace_path`, `query_graph`, and
`get_code_snippet`. The refreshed architecture index at commit
`e9090e4edb57bcbc1f7bfc38b17849fcde2f408a` produced 1152 nodes and 1162 edges.
`search_code` found release workflow policy text that BM25 `search_graph` did
not, while `trace_path` and `get_code_snippet` worked for indexed PowerShell
functions. Routine repository learning should therefore combine graph tools with
source-file reads instead of treating a single graph search mode as exhaustive.

After private release `private-v1.2`, startup preflight was verified by calling
`index_repository` from inside the active Codex task for `F:\codex`; fast mode
returned status `indexed` with 1165 nodes and 1173 edges. This verifies the MCP
server is exposed and callable at task time. The lifecycle controller now
requires this preflight at source-repository entry when the tool is available.

## Boundary

The tool reads local source and writes local index/config files. Do not commit
its cache databases, generated graph artifacts, local MCP paths, or machine
installation records. Restart Codex tasks after MCP config changes so the server
is loaded by the client.
