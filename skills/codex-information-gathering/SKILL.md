---
name: codex-information-gathering
description: Gather and rank evidence from local files, repositories, Codex memory, session history, documentation, APIs, and the web before making decisions. Use for ambiguous tasks, repository orientation, historical reconstruction, diagnostics, research, or any request that says to use prior Codex history or project evidence.
---

# Codex Information Gathering

1. Define the decision the evidence must support.
2. Search cheap structured sources first: workspace files, `MEMORY.md`, indexes, Git state, and existing skills.
3. Verify drift-prone facts live when inexpensive.
4. Read only the relevant raw history or large files.
5. Separate observed facts, inferences, assumptions, and unknowns.
6. Record source paths, commands, dates, and confidence.

Use `rg` for text and structured parsers for structured data. Stop gathering when success criteria can be decided reliably. Never expose credentials while searching.

