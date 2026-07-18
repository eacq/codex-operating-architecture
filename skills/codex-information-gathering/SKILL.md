---
name: codex-information-gathering
description: Gather and rank evidence from local files, repositories, Codex memory, session history, documentation, APIs, and the web before making decisions. Use for ambiguous tasks, repository orientation, historical reconstruction, diagnostics, research, or any request that says to use prior Codex history or project evidence.
---

# Codex Information Gathering

1. Define the decision the evidence must support.
2. Search cheap structured sources first: workspace files, `MEMORY.md`, indexes, Git state, and existing skills.
3. For codebase orientation in a repository that has `codebase-memory-mcp`
   available, prefer graph evidence before broad file reads: index or refresh
   the project, query architecture/schema/search results, then open only the
   cited files needed for exact verification. Use fast mode first on large or
   heterogeneous repositories; escalate to fuller indexing only when semantic
   edges are needed and the cost is justified.
4. Verify drift-prone facts live when inexpensive.
5. Read only the relevant raw history or large files.
6. Separate observed facts, inferences, assumptions, and unknowns.
7. Record source paths, commands, dates, and confidence.

Use `rg` for text and structured parsers for structured data. Stop gathering when success criteria can be decided reliably. Never expose credentials while searching.

For repository-scale graph evidence with `codebase-memory-mcp`, read
[subskills/codebase-graph-evidence/SKILL.md](subskills/codebase-graph-evidence/SKILL.md).

Imported local compatibility modes live under `subskills/imported-codex-home/`; select them through this owner's evidence, access, and source-trust routing rather than exposing their former package names globally.
