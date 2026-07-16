---
name: codex-architecture-iteration
description: Evolve the Codex operating architecture repository by adding, merging, splitting, deprecating, or revising modules and their contracts. Use when evidence shows this architecture has duplication, missing coverage, unclear routing, stale rules, or needs a versioned self-improvement release.
---

# Codex Architecture Iteration

Read `$ARCHITECTURE_ROOT\ARCHITECTURE.md`, the experience ledger, affected skills, and relevant evidence. Prefer revising an owner module over creating overlap. Update routing and human-facing documentation together. Use semantic versioning: patch for compatible guidance fixes, minor for compatible capabilities, major for incompatible contracts. Validate every skill, review the Git diff, and ensure no history payloads or secrets entered the repository.

Use `$ARCHITECTURE_ROOT\module-registry.json` as the module lifecycle authority. Require at least two independent use cases before adding a module. Merge substantial overlap, deprecate before deletion, and preserve evidence for every decision. For project/network learning results, compare trigger, workflow, maintained knowledge, artifacts, and safety boundary against the current owner before choosing revise, subworkflow, add, merge, split, deprecate, or delete. Finish with an economy pass: remove duplicate controller language, retain routing and safeguards, and update the knowledge graph when relationships change.

Before the economy pass, test that affected skills, linked knowledge, experience records, and workflows still interoperate. Use failed or weak handoffs as evidence to strengthen contracts before any simplification.
