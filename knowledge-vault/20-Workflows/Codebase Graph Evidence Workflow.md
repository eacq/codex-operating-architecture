---
id: workflow-codebase-graph-evidence
type: workflow
status: active
source: codebase-memory-mcp-validation-2026-07-18
verified: true
learning_audience: codex
codex_learning: For repository-scale learning, use codebase-memory-mcp to route evidence first, then verify every claim against cited source files before editing or reporting.
---

# Codebase Graph Evidence Workflow

This workflow connects [[Codebase Memory MCP]], [[Experience and Knowledge Architecture]],
[[Verified Experience Promotion]], and [[Project Knowledge Boundary]].

## Flow

1. At project entry, confirm the repository root and current Git head.
2. If `codebase-memory-mcp` tools are exposed, run `index_repository` in fast
   mode with a stable project name before broad file reading. For the canonical
   global experience-system repository, use only `F-codex` for `F:\codex`; do
   not create C-drive, WindowsApps, network-learning, or duplicate alias indexes
   in the global cache. If the MCP tool is unavailable in the current task,
   record the gap and fall back to local file evidence.
3. Read `get_graph_schema` and `get_architecture` to understand coverage,
   indexed labels, edge types, hotspots, and exclusions.
4. Use `search_graph` for symbols, sections, labels, and known qualified-name
   patterns.
5. Use `search_code` for policy text, documentation wording, and cases where
   graph search returns no results.
6. Use `trace_path` and `get_code_snippet` for caller/callee evidence after an
   exact symbol is found.
7. Read the cited files directly before making a behavior claim, changing code,
   or saying something is absent.
8. Record coverage limits when the graph excludes directories, returns
   truncated results, or a search mode misses known evidence.

## Verification Rule

Graph evidence reduces search cost; it does not replace source verification.
Final answers and durable experience must cite observed graph outputs plus the
source files that confirm them.

## Local Validation

The architecture repository is indexed as `F-codex`. MCP tools verified
indexing, schema, architecture overview, text search, graph search, caller
tracing, and snippet retrieval. `search_code` found release workflow policy text
that BM25 `search_graph` missed, so the workflow uses both tools before
source-file verification.

Startup preflight was verified after clearing stale project aliases: invoking
`index_repository` in fast mode for `F:\codex` as `F-codex` returned status
`indexed` with 9731 nodes and 20151 edges, and `list_projects` showed no other
global experience-system project indexes.
