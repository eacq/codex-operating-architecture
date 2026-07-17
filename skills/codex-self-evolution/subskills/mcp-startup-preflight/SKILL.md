---
name: codex-self-evolution-mcp-startup-preflight
description: Owner-internal startup preflight for automatically warming available MCP evidence backends, especially codebase-memory-mcp, at project entry.
---

# MCP Startup Preflight

Use this subskill only through the parent `codex-self-evolution` controller at
project entry.

## Purpose

Ensure available MCP evidence backends are actively called early enough to be
useful. Codex MCP server configuration exposes tools to a task, but durable
startup behavior still needs a lifecycle instruction that tells the agent to
invoke the relevant MCP tool before broad repository reading.

## Procedure

1. Confirm the project root. If it is not a source repository, skip MCP graph
   warmup and continue normal lifecycle routing.
2. If `codebase-memory-mcp` tools are exposed in the current task, call
   `index_repository` with:

   ```text
   repo_path=<project-root>
   mode=fast
   name=<stable-project-name>
   ```

3. Treat the result as startup evidence: record project name, status, node and
   edge counts, and visible exclusions when they affect confidence.
4. Do not block ordinary work only because the MCP tool is not exposed in the
   current task. Record the missing tool and fall back to `rg`, Git state, and
   local files.
5. Do not commit MCP cache databases, `.codebase-memory` artifacts, local
   binary paths, or machine-specific MCP config.
6. For architecture, ownership, impact, or absence claims, hand off to
   `codex-information-gathering` and its codebase graph evidence subskill:
   startup indexing routes evidence but does not replace source-file
   verification.

## Verification

For the architecture repository, a valid startup preflight is:

```text
index_repository(repo_path="F:\\codex", mode=fast, name="codex-operating-architecture")
```

The current verified result indexed `codex-operating-architecture` with 1165
nodes and 1173 edges after private release `private-v1.2`.
