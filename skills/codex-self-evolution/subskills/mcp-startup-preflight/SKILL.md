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

1. Before checking the task root, run
   `F:\codex\scripts\Start-CodebaseMemoryGraphUi.ps1 -RepositoryRoot F:\codex -ProjectName F-codex -Port 9750`.
   It is idempotent: reuse an existing local listener rather than starting a
   second UI process, and use the UI service's own `POST /api/index` endpoint
   until `GET /api/project-health?name=F-codex` is healthy. This applies to
   every Codex task, including non-source repositories, so the graph console
   remains available at `http://127.0.0.1:9750/` with `F-codex` visible.
2. Determine whether `codebase-memory-mcp` is callable in the current task.
   When the tool surface is deferred or namespaced, inspect the task's callable
   capability registry before concluding it is unavailable; do not rely only on
   the initially displayed static tool list. If callable, first call:

   ```text
   index_repository(repo_path="F:\\codex", mode=fast, name="F-codex")
   ```

   This is the automatic structural index of the global experience system and
   applies even when the current task is not in `F:\codex`. Record the result
   as global-experience startup evidence.
3. Confirm the project root. If it is not a source repository, keep the fresh
   `F-codex` index available and continue normal lifecycle routing.
4. When the current project is a source repository other than `F:\codex`, call
   `index_repository` with the exact callable-contract key `repo_path` (not
   `repository_path`) and:

   ```text
   repo_path=<project-root>
   mode=fast
   name=<stable-project-name>
   ```

   For the canonical global experience-system repository, use the single stable
   project name `F-codex`. Do not create additional aliases such as `codex` or
   `codex-operating-architecture` for the same `F:\codex` root.

5. Treat the result as startup evidence: record project name, status, node and
   edge counts, and visible exclusions when they affect confidence.
6. Do not block ordinary work only after the callable-capability check confirms
   the MCP tool is unavailable in the current task. Record the missing tool and
   fall back to `rg`, Git state, and local files.
7. Do not commit MCP cache databases, `.codebase-memory` artifacts, local
   binary paths, or machine-specific MCP config.
8. For architecture, ownership, impact, or absence claims, hand off to
   `codex-information-gathering` and its codebase graph evidence subskill:
   startup indexing routes evidence but does not replace source-file
   verification.

## Evidence Authority

Treat a fresh `codebase-memory-mcp` graph as the high-priority **structural
evidence source** for repository orientation, dependency/caller discovery,
ownership mapping, and impact scoping. Use it before broad unstructured file
reading when its indexed coverage contains the relevant surface.

It is derived evidence, not a replacement authority: current user direction
sets intent and permission; project requirements/workflows and current source
files set the applicable contract and implementation truth; current commands,
tests, and rendered/runtime checks establish behavior. Record node/edge counts
and visible exclusions with any material graph-based conclusion. An omitted,
stale, truncated, or excluded graph surface cannot establish absence; narrow or
refresh the graph and verify the cited source file instead.

## Verification

For the architecture repository, a valid startup preflight is:

```text
index_repository(repo_path="F:\\codex", mode=fast, name="F-codex")
```

The current verified result indexed `F-codex` with 9731 nodes and 20151 edges
after clearing stale C-drive and duplicate project indexes.
