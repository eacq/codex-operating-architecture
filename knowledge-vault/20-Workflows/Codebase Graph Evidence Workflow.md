---
id: workflow-codebase-graph-evidence
type: workflow
status: active
source: codebase-memory-mcp-validation-2026-07-18
verified: true
learning_audience: codex
codex_learning: For repository-scale learning, let the Global Experience Agent warm the canonical F-codex graph, use currently callable codebase-memory-mcp tools for routing evidence, then verify every claim against cited source files before editing or reporting.
---

# Codebase Graph Evidence Workflow

This workflow connects [[Codebase Memory MCP]], [[Experience and Knowledge Architecture]],
[[Verified Experience Promotion]], and [[Project Knowledge Boundary]].

## Flow

1. At project entry, confirm the repository root and current Git head.
2. If `codebase-memory-mcp` tools are exposed, run `index_repository` in fast
   mode with a stable project name before broad file reading. For the canonical
   Global Experience Agent repository, use only `F-codex` for `F:\codex`; do
   not leave C-drive, WindowsApps, external reference, network-learning, or
   duplicate alias indexes in the global cache. If the MCP tool is unavailable
   in the current task, record the gap and fall back to local file evidence.
3. Read `get_graph_schema` and `get_architecture` to understand coverage,
   indexed labels, edge types, hotspots, and exclusions.
4. Use `search_code` for policy text, documentation wording, symbols, and
   graph-enriched file/function search.
5. Use `trace_path` for caller/callee, data-flow, or cross-service evidence
   after an exact function name is known.
7. Read the cited files directly before making a behavior claim, changing code,
   or saying something is absent.
8. Record coverage limits when the graph excludes directories, returns
   truncated results, or a search mode misses known evidence.

## Agent self-use contract

The Agent-facing contract is stored in
`config/agent-codebase-memory-policy.json` and appears in the harness state as
`agent_codebase_memory`. Agent callers use it as a resource-selection policy:

- `codex-self-evolution` owns entry refresh and save-point alignment.
- `codex-information-gathering` owns graph evidence interpretation.
- `codex-architecture-iteration` owns any structure-affecting change routed
  from that evidence.
- `scripts/Test-AgentCodebaseMemoryPolicy.ps1` proves that the policy, harness
  state, canonical project name, allowed operations, and source-verification
  boundary stay aligned.

This keeps Codebase Memory usable by any authorized model host that can call the
Agent, while preserving the same authority boundary: graph evidence can select
work, but only source files, tests, and owner gates can prove or mutate work.

## Verification Rule

Graph evidence reduces search cost; it does not replace source verification.
Final answers and durable experience must cite observed graph outputs plus the
source files that confirm them.

## Local Validation

The architecture repository is indexed as `F-codex`. Current MCP tools verify
indexing, schema, architecture overview, graph-enriched text/code search, and
caller tracing. Older references to `search_graph`, `query_graph`, or
`get_code_snippet` are historical unless the current callable registry exposes
them again.

Startup preflight is current when invoking `index_repository` in fast mode for
`F:\codex` as `F-codex` returns status `indexed`, the graph UI reports
`F-codex` healthy, and `scripts/Test-CodebaseMemoryProjectScope.ps1` proves the
global cache contains exactly one project: `F-codex` rooted at `F:/codex`.
