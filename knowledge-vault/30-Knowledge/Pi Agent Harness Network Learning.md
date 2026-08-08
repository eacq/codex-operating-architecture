---
id: concept-pi-agent-harness-network-learning
type: concept
status: active
promotion_status: guarded
source: https://github.com/earendil-works/pi;commit=dd6bea41efa8caa7a10fe5a6401676dc5699f83f
verified: true
learning_audience: codex
codex_learning: Treat earendil-works/pi as an agent-harness method source. Adopt its small-core resource model, evented lifecycle, session tree, save-point semantics, project-trust split, and extension-surface discipline as guarded architecture lenses; do not install Pi or inherit its no-sandbox runtime stance without local authority and validation.
---

# Pi Agent Harness Network Learning

This network-learning pass reviewed `earendil-works/pi` at commit
`c8c3cd499f4d35c0f9cfebfec5f4e3822411a49f` on 2026-07-21. The review treated
Pi as an agent harness method system, not as an install target.

The 2026-07-22 re-learning pass refreshed `origin/main` to
`dd6bea41efa8caa7a10fe5a6401676dc5699f83f`. The newer Pi source reinforces the
agent-system reading: `AgentHarness` owns session persistence, runtime config,
resource resolution, operation locking, pending writes, save points,
compaction/branch-summary retry events, and deterministic hook/listener
settlement. The local adaptation therefore moved from a documentation-only
lens to an executable state model. `agent/40-runtime/Get-AgentHarnessState.ps1` now
emits the current local harness, resources, tool gates, session tree,
durability model, retry/recovery boundaries, save points, extension surfaces,
and subagent policy as JSON. `scripts/Test-AgentHarnessContract.ps1` verifies
that projection.

The next optimization made the adaptation structural: `config/agent-system.json`
is the local Pi-style harness topology manifest, and
`scripts/Test-AgentSystemTopology.ps1` validates that the repository exposes a
real harness/resource/tool/session/extension/recovery topology rather than only
descriptive guidance.

The first executable optimization added
`agent/40-runtime/Invoke-GlobalExperienceAgent.ps1`, but its initial behavior was still
a topology verifier: it emitted six lifecycle events and wrote one save-point
record without owning a durable turn. The 2026-07-22 agentification pass closed
that gap. The front door now delegates `Run`, `Resume`, and `Abort` to
`agent/40-runtime/Invoke-GlobalExperienceAgentRuntime.ps1`, which persists a local
session tree, immutable turn snapshot, queues, pending writes, operation and
tool-call lifecycle, tool result, recovery decision, and save point. The
runtime invokes only registered local controllers and does not install Pi.

The 2026-07-22 Pi consistency pass then expanded the local contract from
"agent-shaped" to explicit general agent functionality. The manifest and tests
now require runtime configuration separate from turn snapshots, turn-safe queue
operations, pending session write durability, tool-registry read/update
semantics, model-registry/provider boundaries, typed hook observers and
result-producing reducers, safe observability events, durable recovery entries,
JSONL tree v3 session-entry coverage, abort barriers, and compaction/branching
retry events. This keeps the adaptation aligned with Pi's current
`origin/main` design while preserving the local rule that Pi is a method source,
not a default runtime dependency.

## Source Shape

Pi is organized as a small agent ecosystem:

- `packages/ai`: multi-provider model API and provider normalization.
- `packages/agent`: stateful agent runtime with tool execution, event
  streaming, context transforms, and harness lifecycle work.
- `packages/coding-agent`: CLI, sessions, project trust, resources, extensions,
  skills, prompt templates, packages, SDK, RPC, and JSON modes.
- `packages/tui`: terminal UI components.
- `packages/orchestrator`: process/RPC orchestration surface.

The source keeps many features outside the core. Plan mode, permission gates,
sub-agents, custom compaction, MCP support, sandbox routing, UI widgets, and
provider integrations are extension/package surfaces rather than core
requirements.

## Philosophy Learned

Direct upstream philosophy: Pi keeps the core minimal and expects users or
packages to extend it through extensions, skills, prompt templates, themes, and
packages. It explicitly avoids built-in MCP, sub-agents, permission popups,
plan mode, todo lists, and background bash; those are extension, file, tmux, or
container concerns.

Local synthesis: Pi is useful to this architecture because it separates an
agent into a harness plus resources:

- The harness owns lifecycle, event order, session persistence, current
  snapshot, queued writes, and safe mutation phases.
- The harness separates latest runtime configuration from the turn snapshot
  used by an in-flight provider request; config changes affect future
  snapshots at save points, not the active request.
- Resources are loaded through explicit surfaces: skills, prompt templates,
  extensions, context files, packages, and models.
- Tools are not just capabilities; they have preflight, result, ordering, and
  termination semantics.
- Session history is not a flat transcript. It is a tree with compaction,
  branch summaries, custom entries, labels, and model/thinking changes.
- Durable session storage matters. Newer compaction entries can carry retained
  tail context as a self-contained checkpoint, leaf entries persist the active
  branch, and unfinished streams or tool calls must be resumed only from safe
  durable boundaries.
- Retry is scoped. Pi exposes retry events for transient compaction and branch
  summary failures; it does not imply retrying non-idempotent tool calls or
  external side effects.
- Project trust is an input-loading boundary, not a sandbox.
- Real isolation belongs to OS, container, VM, micro-VM, or policy sandbox
  boundaries.

## Adopted Guarded Rules

Use Pi as an analogy for the Global Experience Agent:

1. Treat `codex-self-evolution` plus `agent/40-runtime/Invoke-GlobalExperienceAgent.ps1` as the **agent harness** for the Global Experience Agent. It routes tasks, creates snapshots of authority/evidence,
   controls lifecycle phases, and delegates to owner resources.
2. Treat owner skills, subskills, scripts, tests, knowledge notes, terminology,
   and lifecycle files as **agent resources**. They should be loadable,
   validated, provenance-bearing, and owner-scoped.
3. Treat Git, release, installation, credential, external, destructive, and
   top-owner changes as **agent tool gates**. The model may request them, but a
   deterministic preflight and authority boundary decides whether they run.
4. Treat conversation continuity, project lifecycle state, candidate records,
   error feedback, and release proofs as a local **session tree** rather than a
   flat memory dump. Branches and compaction summaries should preserve
   decisions, read files, modified files, and handoff context without storing
   raw private sessions in Git.
5. Treat validation, publication envelopes, rollback snapshots, and lifecycle
   writeback as **save points**. State changes after a save point may affect
   the next turn or iteration, but they must not mutate an in-flight proof.
6. Treat imported packages, hooks, MCP servers, and executable extensions as
   **extension surfaces**. They need trust, provenance, scope, rollback, and
   validation before they can influence global behavior.
7. Keep sub-agent work explicit. Logical roles can improve handoff design, but
   spawning agents or parallel workers still needs isolated write surfaces,
   shared acceptance criteria, and a merge verifier.
8. Expose the local agent shape as a deterministic state projection before
   claiming the system has become agent-like. The projection is read-only and
   must not load raw private sessions, credentials, Pi extensions, or project
   runtimes.
9. Make the local agent loop evented and phase-aware. At minimum, distinguish
   intake, orientation, resource selection, gated action, observation, and
   settlement; keep structural mutation behind idle/save-point boundaries.
10. Treat local lifecycle files, error reports, candidate records, iteration
    proofs, and release evidence as durable session entries. Resume from
    verified save points; mark interrupted streams or unsafe tool calls as
    interrupted unless an owner proves idempotent retry safety.
11. Keep runtime configuration separate from the active turn snapshot. Getters
    report the latest future-routing config; setters during a turn affect only
    the next save-point snapshot.
12. Treat queues and pending writes as durable agent state. `steer`,
    `followUp`, `nextTurn`, `abort`, and runtime config setters are turn-safe
    only at documented points; accepted pending writes flush at save point,
    settlement, or failure cleanup.
13. Model and tool registries are first-class resources. Providers own
    metadata, auth, model listing, stream behavior, and refresh boundaries;
    tools require active-name validation, owner provenance, idempotency, and
    retry-safety metadata.
14. Hooks and observability are separate. Hooks can transform or block through
    event-specific reducers; observability is passive, stable, and safe by
    default.
15. Do not call a system an executable agent merely because its manifest names
    agent concepts. A bounded `Run` must persist a session and immutable turn
    snapshot, select resources and a gate, execute or reject one registered
    operation, record the tool result, flush accepted writes, and commit a save
    point. `Resume` and `Abort` must be behaviorally tested against that state.
16. Use `LesterYu0/feynman-build-workshop` episode 06 as a complementary
    control-plane lens: the minimal agent loop is Plan/Act/Observe/Reflect
    plus settlement, and production use requires max-iteration limits, explicit
    error observations, context-budget control, multi-condition termination,
    tracing, and harness configuration. This reinforces the local Pi-inspired
    harness without installing an external framework or hosted loop.

## Rejected Or Deferred

- Do not install Pi as part of this learning pass. The current gap is
  architecture modeling, not a missing local runtime.
- Do not adopt Pi's lack of in-process permissions as a local rule. This
  architecture already has stronger authority and publication gates; preserve
  them.
- Do not replace Codex skills with Pi packages. Use package/extension thinking
  to improve resource boundaries while retaining the canonical `F:\codex`
  owner model.
- Do not make sub-agents default. Pi's subagent example is useful, but this
  system keeps one accountable execution owner unless parallel work is
  independently justified and isolated.

## Local Integration Points

- `codex-self-evolution`: agent harness entry, lifecycle phase and authority
  routing.
- `codex-learning`: network-learning intake, source philosophy extraction, and
  guarded adoption.
- `codex-architecture-iteration`: owner/resource topology, agent-resource
  boundary review, and no-regression validation.
- `codex-conversation-continuity`: session tree analogy for branch, compaction,
  and resumability work.
- `codex-git-operations`: tool-gate and save-point enforcement for Git,
  publication, release, and rollback.
- `codex-skill-packaging`: package/resource boundary and compatibility import
  review.
- `agent/40-runtime/Get-AgentHarnessState.ps1`: read-only agent state projection for
  the current Global Experience Agent.
- `scripts/Test-AgentHarnessContract.ps1`: regression check that the state
  projection preserves harness, resource, event-loop, tool-gate, phase,
  durability, retry/recovery, save-point, extension, and subagent boundaries.
- `config/agent-system.json`: Pi-style agent-system topology manifest for the
  Global Experience Agent.
- `scripts/Test-AgentSystemTopology.ps1`: manifest-level topology contract
  test wired into repository validation.
- `agent/40-runtime/Invoke-GlobalExperienceAgent.ps1`: executable local controller for
  the Global Experience Agent loop.
- `agent/40-runtime/Invoke-GlobalExperienceAgentRuntime.ps1`: durable Run/Resume/Abort
  implementation with registered-operation dispatch and conservative recovery.
- `scripts/Test-GlobalExperienceAgent.ps1`: controller-level run and save-point
  test wired into repository validation.
- `scripts/Test-AgentSystemTopology.ps1`: Pi consistency guard for runtime
  config, turn snapshot, queues, pending writes, tool/model registries, hooks,
  observability, durable recovery, session-entry schema, abort semantics, and
  compaction/branching.
- `config/agent-loop-policy.json`: episode 06 control-plane policy for bounded
  loop phases, control points, termination, tracing, and owner-gated execution.
- `scripts/Test-AgentLoopPolicy.ps1`: regression test that the C06 Agent Loop
  policy remains connected to the runtime, manifest, state projection, and
  authority boundary.

## Links

- [[Global Experience System]]
- [[Information and Functional Unit Principle]]
- [[Learning Governance]]
- [[Matt Pocock Skills Method System Relearning]]
- [[Oh My Codex and OMX Lite Network Learning]]
- [[Top-Level Owner Governance]]
