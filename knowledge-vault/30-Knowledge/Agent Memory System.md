---
id: concept-agent-memory-system
type: concept
status: active
source: https://github.com/LesterYu0/feynman-build-workshop;commit=20c93f76c6f55f41e6fe51493697e7034d5a38a3
verified: true
learning_audience: codex
codex_learning: Implement Agent memory as a registered functional capability and skill/action space, not as an unbounded prompt dump. Use typed memory, SQLite/FTS5 retrieval, TTL/supersession, consolidation, Frozen Snapshot rendering, search-before-store behavior, upsert/supersession, and save-point trace review behind the Global Experience Agent interface and owner gates.
---

# Agent Memory System

This note records the local adaptation of `LesterYu0/feynman-build-workshop`
episode 01 and episode 07. The source was inspected at commit
`20c93f76c6f55f41e6fe51493697e7034d5a38a3` on 2026-07-22 and treated as a
method source, not as a package to install wholesale.

## Adopted Pattern

The external workshop frames Agent memory as a layered capability:

1. classify what should be ignored, cached, or stored;
2. start with SQLite/FTS5 for cheap exact retrieval;
3. add time validity with `created_at`, `valid_until`, and `superseded_by`;
4. render a stable Frozen Snapshot for prompt-prefix reuse;
5. run consolidation to deduplicate, archive stale records, and preserve high
   priority semantic/procedural memory;
6. only add vector search or graph memory when the simpler layers fail;
7. test recall, temporal validity, instruction compliance, non-regression,
   cross-session consistency, and latency.

Episode 07 adds the more important systems lesson: memory is a skill/action
space. The Agent must explicitly choose when to search, store, upsert or
supersede, consolidate, and render memory under a scaffold, instead of
passively growing one flat `MEMORY.md`.

The local policy is `config/agent-memory-skill-policy.json`. It maps episode 01
to the storage/retrieval baseline and episode 07 to the behavior scaffold:
search before store when prior records may apply, avoid unbounded append,
retrieve memory on demand, review full memory-action traces at save points, and
only promote scaffold changes when measured behavior improves.

## Local Architecture

The local implementation keeps one Global Experience Agent. It adds memory as a
registered functional unit:

- backend: `agent/40-runtime/Invoke-AgentMemoryStore.py`;
- controller: `agent/40-runtime/Invoke-GlobalExperienceAgentRuntime.ps1`;
- policy: `config/agent-memory-skill-policy.json`;
- operations: `StoreMemory`, `SearchMemory`, `ConsolidateMemory`, and
  `RenderMemorySnapshot`;
- local state: `.codex/project/agent-memory/memory.db` and
  `.codex/project/agent-memory/frozen-snapshot.md`;
- permission model: human, LLM, and internal-functional-unit interfaces may use
  the registered memory operations under current authority, but only
  `global-control` with `global-structure` authority may change memory system
  structure.

The memory store is ignored local state. It may contain useful working
context, but not credentials, tokens, cookies, raw private conversations, or
unbounded logs.

## Linkage

- [[Global Experience System]] owns the single front door and continuation
  semantics.
- [[Information and Functional Unit Principle]] classifies the backend and
  tests as functional units, while this note and linked evidence are
  information units.
- [[Learning Governance]] requires external repositories to be adapted through
  evidence, validation, and owner boundaries.

## Verification

`scripts/Test-AgentMemorySystem.ps1` proves the local storage contract with a
temporary SQLite database: store, search, consolidate, render a frozen snapshot,
and deny direct LLM structural mutation.
`scripts/Test-AgentMemoryAsSkillPolicy.ps1` proves the skill-facing scaffold:
the policy is registered, the four memory actions keep their owner routes,
interfaces can use memory without structural authority, global-control remains
the only route to structure change, and the diagnostics cover write/search
ratio, bounded growth, redundant writes, context ratio, and delayed failures.
Full repository validation includes both tests through `scripts/validate.ps1`.
