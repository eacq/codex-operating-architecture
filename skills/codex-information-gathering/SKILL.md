---
name: codex-information-gathering
description: Gather and rank evidence from files, repositories, memory, session history, docs, APIs, and web sources before decisions or diagnostics.
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

For tasks with many possible tools, MCP servers, skills, or references, use
`config/agent-capability-routing-policy.json`: read the cached capability
catalog first, narrow to the smallest owner surface, and search or inspect
deferred capabilities only when the current evidence requires them. Approval-
gated capabilities stay directly visible and no deferred route may bypass an
owner gate. Treat an uncached surface as eventually consistent rather than
proof of absence; refresh it explicitly or in a safe background path without
blocking task startup. Select economy, balanced, or full resource versions from
current cost and quality evidence, never by permanently disabling the high-cost
capability.

Use `rg` for text and structured parsers for structured data. Stop gathering when success criteria can be decided reliably. Never expose credentials while searching.

For repository-scale graph evidence with `codebase-memory-mcp`, read
[subskills/codebase-graph-evidence/SKILL.md](subskills/codebase-graph-evidence/SKILL.md).

Imported local compatibility modes live under `subskills/imported-codex-home/`; select them through this owner's evidence, access, and source-trust routing rather than exposing their former package names globally.
