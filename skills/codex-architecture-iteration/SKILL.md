---
name: codex-architecture-iteration
description: Evolve Codex architecture modules and contracts through evidence-backed add, merge, split, deprecate, revise, or release decisions.
---

# Codex Architecture Iteration

Read `$ARCHITECTURE_ROOT\ARCHITECTURE.md`, the experience ledger, affected skills, and relevant evidence. Prefer revising an owner module over creating overlap. Update routing and human-facing documentation together. Use semantic versioning: patch for compatible guidance fixes, minor for compatible capabilities, major for incompatible contracts. Validate every skill, review the Git diff, and ensure no history payloads or secrets entered the repository.

Treat `config/global-experience-agent-registry.json` as the Agent identity and
composition authority, `config/agent-owner-connections.json` as the specialist
handoff authority, and `module-registry.json` as the owner lifecycle authority.
Concept Agents may compose owners but never duplicate them. Material changes to
root operations, caller/model continuation, child lifecycle, or tool-gate
routing require synchronized runtime, registry, topology tests, diagram mapping,
and global-interface validation.

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

## Information And Functional Unit Topology

Before material restructuring of information units, functional units, or
top-level owners, run
`skills/codex-architecture-iteration/scripts/Invoke-UnitTopologyReview.ps1 -ProjectRoot <project> -Apply`. It
classifies knowledge notes and lifecycle records as information units, skills,
subskills, scripts, tests, and validators as functional units, then records
bidirectional-link health and top-owner disposition. A link gap is review input,
not automatic permission to move files or change owners.

Use the review to prefer link repair, owner-internal refinement, or script/test
coverage before top-level owner changes. Add, merge, split, deprecate, delete,
or materially revise a top-level owner only when the review plus current
evidence proves a distinct or overlapping trigger, artifact lifecycle,
maintained knowledge base, and safety boundary under the explicit authorization
gate.

Evaluate naming separately from owner-boundary changes. If a naming-only owner
or skill migration would improve user, model, and local experience-system
collaboration while preserving the actual contract, trigger, artifacts,
maintained knowledge, owning parent, and safety boundary, treat the rename as a
valid optimization rather than a cosmetic change. Route it through
`config/skill-name-migrations.json`, keep the one-release compatibility entry,
update references and global interfaces, and pass migration plus global
interface validation before treating the new name as active.

For a deeper structural pass, run
`skills/codex-architecture-iteration/scripts/Invoke-DeepArchitectureAudit.ps1 -ProjectRoot <project> -Apply`.
It correlates the module registry, owner handoff network, concept Agents,
named child profiles, runtime manifest, and current information/functional-unit
topology. Its lexical overlap candidates are review prompts only: owner
changes still require trigger, artifact, maintained-knowledge, safety-boundary,
rollback, and two-independent-use-case evidence. The audit itself is
evidence-only and does not mutate structure.

## Owner And Skill Self-Iteration

On every complete global iteration, run `scripts/Invoke-OwnerSelfIterationReview.ps1`.
Owners and skills may self-optimize documentation, internal subskill packaging,
and read-only or local-reversible workflow/script refactors when their contract,
trigger, artifacts, maintained knowledge, and safety boundary remain unchanged.
Each candidate needs baseline evidence, an expected benefit, equivalent
validation, and a rollback boundary. The review is evidence, not mutation
authority except for a naming-only owner or skill migration that satisfies the
automatic rename policy in `config/owner-self-iteration-policy.json` and
`config/skill-name-migrations.json`. Automatic rename requires tri-source
naming evidence, a canonical path, migration record, one-release compatibility
route, synchronized references, and passing migration/global-interface
validation. External actions, credentials, runtime or installation changes, Git
publication, destructive work, material contract changes, and top-level owner
add/merge/split/deprecation/deletion retain their existing explicit gates.

## Top-Level Owner Authorization Gate

Adding, merging, splitting, deprecating, deleting, or materially revising a
top-level owner requires explicit user authorization for the current iteration.
An evidence-backed naming-only owner rename may instead use the stored
`skill-name-migrations.json` authority when the owner contract and safety
boundary are unchanged; it does not authorize any of the preceding structural
actions.
Record the authority, candidates considered, trigger/artifact/knowledge/safety
comparison, chosen action, migration or rollback boundary, and verification in
the project retrospective and module registry. Prior authorization does not
carry forward to later owner changes. In the absence of authorization, retain
the owner and confine improvements to evidence, documentation, or
owner-internal subskills.
