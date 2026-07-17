---
name: codex-information-gathering-codebase-graph-evidence
description: Use codebase-memory-mcp as a local graph evidence layer for repository orientation, impact analysis, ownership mapping, and source-targeted verification before broad file reading.
---

# Codebase Graph Evidence

Use this subskill when a task needs repository orientation, architectural
mapping, impact analysis, dependency/caller discovery, or codebase learning and
`codebase-memory-mcp` is available.

## Evidence Order

1. At project entry, when the MCP tools are exposed and the current project is
   a source repository, refresh the graph for the current repository with
   `index_repository` before broad file reading.
   Prefer `mode: fast` for first-pass orientation, large repos, mixed Markdown
   and scripts, or when semantic similarity is not required.
2. Read `get_graph_schema` and `get_architecture` before making architecture
   claims. Treat node and edge counts as coverage evidence.
3. Use `search_graph` for known symbol, section, file, route, or label patterns.
   Check `total` and `has_more`; paginate or narrow before claiming absence.
4. Use `search_code` when graph text search misses documentation or Markdown
   wording. It is often better than `search_graph` for policy text and release
   instructions.
5. Use `trace_path` for callers/callees and `get_code_snippet` only after
   `search_graph` identifies the exact qualified name.
6. Open the cited source files with normal file reads before final conclusions,
   edits, or negative claims.

## Boundaries

- Graph output routes attention; it is not final proof.
- Fast mode may omit semantic/similarity edges and can underrepresent scripts or
  generated files excluded by the tool. Record visible exclusions when they
  affect confidence.
- A failed or empty graph search is not absence proof until search mode,
  pagination, file scope, and source-file verification are checked.
- Prefer local cache paths and never commit MCP databases, local installation
  paths, generated `.codebase-memory` artifacts, or machine-specific MCP config.
- Restart or create a new Codex task after MCP configuration changes when the
  tool is not exposed in the current session.

## Verified Local Findings

On the architecture repository, MCP validation showed:

- `index_repository` fast mode works and records current Git head.
- `get_graph_schema` and `get_architecture` summarize Markdown/skill structure
  and provider-switch PowerShell hotspots.
- `search_code` finds workflow policy text that BM25 `search_graph` can miss.
- `trace_path` and `get_code_snippet` work for indexed PowerShell functions.
- A broad Cypher labels aggregation did not return useful label names in this
  environment, so prefer schema/search tools for routine orientation.

## Example

```text
index_repository(repo_path=<repo>, mode=fast, name=<stable-project-name>)
get_graph_schema(project=<name>)
get_architecture(project=<name>, aspects=["overview","packages","hotspots","clusters"])
search_code(project=<name>, pattern=<policy-or-symbol>)
search_graph(project=<name>, name_pattern=<regex>, limit=<n>)
```
