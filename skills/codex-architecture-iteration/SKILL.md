---
name: codex-architecture-iteration
description: Evolve the Codex operating architecture repository by adding, merging, splitting, deprecating, or revising modules and their contracts. Use when evidence shows this architecture has duplication, missing coverage, unclear routing, stale rules, or needs a versioned self-improvement release.
---

# Codex Architecture Iteration

Read `$ARCHITECTURE_ROOT\ARCHITECTURE.md`, the experience ledger, affected skills, and relevant evidence. Prefer revising an owner module over creating overlap. Update routing and human-facing documentation together. Use semantic versioning: patch for compatible guidance fixes, minor for compatible capabilities, major for incompatible contracts. Validate every skill, review the Git diff, and ensure no history payloads or secrets entered the repository.

Use `$ARCHITECTURE_ROOT\module-registry.json` as the module lifecycle authority. Require at least two independent use cases before adding a module. Merge substantial overlap, deprecate before deletion, and preserve evidence for every decision. For project/network learning results, compare trigger, workflow, maintained knowledge, artifacts, and safety boundary against the current owner before choosing revise, parent-skill refinement, subskill-style packaging, subworkflow, add, merge, split, deprecate, or delete. Prefer refining the mother skill plus owner-internal subskills when it reduces top-level surface area without hiding a new safety boundary. Finish with an economy pass: remove duplicate controller language, retain routing and safeguards, and update the knowledge graph when relationships change.

For every material iteration, require an outcome-directed case before selecting
the structural action: identify the user/local-experience/model collaboration
failure, the expected observable improvement, the affected handoff, resource
and safety constraints, baseline evidence, and no-regression checks. An owner
or contract change that only rearranges text or module count is not sufficient.
When evidence cannot show a net contribution to capability, learning,
coordination, or safe resource use, retain the current structure and record the
candidate rather than manufacturing a change.

Before the economy pass, test that affected skills, linked knowledge, experience records, and workflows still interoperate. Use failed or weak handoffs as evidence to strengthen contracts before any simplification.

## Top-Level Owner Authorization Gate

Adding, merging, splitting, deprecating, deleting, or materially revising a
top-level owner requires explicit user authorization for the current iteration.
Record the authority, candidates considered, trigger/artifact/knowledge/safety
comparison, chosen action, migration or rollback boundary, and verification in
the project retrospective and module registry. Prior authorization does not
carry forward to later owner changes. In the absence of authorization, retain
the owner and confine improvements to evidence, documentation, or
owner-internal subskills.
