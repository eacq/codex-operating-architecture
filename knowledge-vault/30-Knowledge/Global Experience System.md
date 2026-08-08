---
id: concept-global-experience-system
type: concept
status: active
source: codex-global-experience-agent-refinement-2026-07-22
verified: true
learning_audience: codex
codex_learning: Treat the global experience system as the executable Global Experience Agent. Experience capture, knowledge, memory, error feedback, MCP graph evidence, Git, release, and owner routing are registered Agent capabilities or gates under one root harness, not parallel entrypoints.
---

# Global Experience System

The global experience system is now the executable **Global Experience Agent**.
It turns project evidence, failures, workflow changes, verified iterations, and
Agent memory and Agent intent recognition into reusable action while preserving one root harness, registered
specialist Agents, concept Agent profiles, tool gates, typed exits, and durable
save points.

Experience capture is no longer the conceptual center of the system. It is a
specialist capability inside the root Agent. The root Agent owns intake,
authority, resource selection, caller/model-neutral continuation, child-Agent
boundaries, MCP graph startup evidence, save-point recovery, and closeout. Its
Agent memory layer is described in [[Agent Memory System]], and its Auto-route
classifier is described in [[Agent Intent Recognition System]]. Memory is a
registered functional capability of the one Global Experience Agent, not a
parallel global-system entrypoint.

Codex tasks that need a short, repeatable access path should use the
owner-internal adapter
`skills/codex-experience-capture/subskills/experience-agent-access/SKILL.md`.
That adapter wraps common StartWork, Continue, Resume, SearchMemory,
StoreMemory, RouteOwner, CandidateReport, DescribeInterfaces, and
EvaluateAccess calls while forwarding to the same root controller. It does not
create a second Agent entrypoint or weaken interface, owner, or tool gates.

The reusable child-Agent design unit is [[Minimal Agent Architecture Template]].
It extracts the minimum contract required to delegate other tasks: child
identity, registered profile, inherited authority, bounded goal, selected
resources, isolated write surface, acceptance criteria, merge verifier,
privacy boundary, and error-feedback route. The planner designs by default and
delegates only when explicitly asked to persist child state through the root
Agent runtime.

## Terminal Outcome and Testable Requirements

The terminal outcome is a trustworthy collaboration system in which the user
sets goals and authority, local experience supplies verified reusable context,
and the model executes bounded work. It must improve useful-task completion
without trading away quality, safety, privacy, or user control.

Before a material self-iteration, translate that outcome into five explicit
checks: (1) capability -- a concrete task can be completed or verified more
reliably; (2) collaboration -- roles, handoffs, and the final accountable
verifier are clearer; (3) economy -- user attention, model/context/tool work,
or coordination cost is reduced without lowering the floor; (4) safety --
authority, privacy, rollback, and external-action boundaries remain intact;
and (5) evolution -- evidence, invalidation, and a route to feedback or
rollback are retained. State the affected check, baseline evidence, expected
observable result, and no-regression test before changing structure.

If no candidate can demonstrate a net contribution on these checks, preserve
the current architecture and record only an evidence review. Module count,
rewriting, or activity is never an optimization result by itself.

## Agent-Centered Owner Loop

1. `codex-self-evolution` recognizes project entry and invokes the root Global
   Experience Agent contract.
2. The root Agent evaluates interface policy, authority scope, MCP graph
   availability, relevant memories, lifecycle state, and required resources.
3. Registered operations route work to specialist or concept Agents without
   creating parallel global-system entrypoints.
4. `codex-experience-capture` classifies evidence, owns promotion thresholds,
   and maintains the experience ledger as one specialist Agent capability.
5. `codex-error-feedback` captures unexpected behavior before it can become a
   lesson.
6. `codex-knowledge-system` stores linked concepts, workflow-learning records,
   maps, and Codex learning indexes.
7. `codex-architecture-iteration` decides whether to revise, merge, split,
   package as a subskill, deprecate, or delete.
8. Git, release, installation, credential, external, destructive, publication,
   global-iteration, and Agent-structure changes remain gated tools returning
   evidence to the root save point.

## Global Experience Agent

The experience system is one executable durable Agent rather than only a
catalog of skills or an Agent-shaped lens. This local architecture learned from
[[Pi Agent Harness Network Learning]] and constrained by the existing authority
model.

Its entry and exit boundary is executable. `config/agent-interface-policy.json`
defines four interfaces: `human`, `llm`, `internal-functional-unit`, and
`global-control`. Human and LLM callers may retrieve and continue work through
registered functional units; internal units may change only owner-bounded
functional surfaces inherited from the parent task contract. None of these
three interfaces may directly change Agent topology, owners, permissions,
runtime contracts, tool gates, or structural manifests. Interface, caller,
model, and host labels never grant authority.

Only `global-control` can authorize adjustment of any Agent aspect. It requires
current `global-structure` authority, a non-secret authorization reference,
declared target surfaces, an idle/save-point boundary, rollback, and
verification. The runtime itself produces an evidence-only structure-change
route; `codex-architecture-iteration` performs the bounded implementation
through the `agent_structure` gate. Every accepted or denied call returns a
typed exit with its audience, authority decision, and next authority boundary.
Unauthorized structural requests are denied before durable session mutation.

`codex-self-evolution` owns the root harness: it creates the task contract, reads the
current authority and evidence, selects resources, coordinates phases, and
names the completion boundary. Owner skills, owner-internal subskills, scripts,
tests, validators, knowledge notes, terminology, lifecycle state, and release
proofs are agent resources. They are not all loaded at once; they are selected
through routing, progressive disclosure, graph evidence, and validation.

Tool-like actions remain gated. Git, release, installation, credential,
external, destructive, top-owner, and publication actions need deterministic
preflight plus the existing authority gate. Imported extensions, packages,
hooks, MCP servers, and sub-agent patterns are extension surfaces: they may
contribute ideas or bounded tools, but they do not become trusted runtime
authority merely by existing.

The session model is tree-shaped in spirit. Conversation continuity, project
lifecycle state, candidate records, error feedback, rollback snapshots,
publication envelopes, and release evidence preserve branch, compaction,
handoff, and save-point information without committing raw private sessions.
Save points define when validated state may affect the next iteration; they
must not mutate an in-flight proof.

The Agent exposes both a read-only projection and an executable runtime.
`agent/40-runtime/Get-AgentHarnessState.ps1` reports the current harness owner,
information units, functional units, tool gates, session evidence, save points,
extension surfaces, and subagent policy. `agent/40-runtime/Invoke-GlobalExperienceAgent.ps1`
is the single front door; `config/global-experience-agent-registry.json`
registers one root Agent, 23 owner-backed specialist Agents, concept Agent
profiles, and the dynamic child lifecycle. Its runtime implementation persists bounded turns
under the ignored `.codex/project/agent-sessions/` tree.

The `DescribeFilesystem` and `ResolveAgentPath` operations let human and LLM
interfaces enumerate and resolve the physical topology as read-only evidence.
They do not change the `global-control` requirement for structural mutation.

The projection is also the local agent-system contract. A task moves through
an evented loop: `user_goal_received`, `experience_context_loaded`,
`agent_resources_selected`, `tool_gate_requested`, `tool_result_recorded`, and
`save_point_committed`. This mirrors Pi's harness discipline without importing
its runtime: events name the current phase, accountable owner, and expected
evidence rather than starting hidden background work.

The Agent loop is now also constrained by [[Agent Loop System]], adapted from
`LesterYu0/feynman-build-workshop` episode 06. C01-C05 provide the data plane
for memory, intent, document parsing, retrieval, and rerank calibration; C06 is
the control plane. It requires a bounded Plan-Act-Observe-Reflect-Settle loop,
explicit error observations, context-budget retention, multi-condition
termination, safe trace metadata, and owner-gated tool execution.

Resource selection follows an experience-first ladder: current user authority,
project lifecycle files, verified project experience, knowledge and learning
indexes, callable codebase graph evidence, owner skills and deterministic
scripts, then targeted fresh external evidence. The system loads the smallest
resource set that can decide the next bounded action, but it never saves
context by skipping safety, privacy, authority, rollback, or validation gates.

Tool calls have their own lifecycle: requested, preflighted, authorized,
executed, observed, verified, then captured or reported. A task is settled only
when the output exists, the narrowest proving check passed, state changes are
scoped and reviewable, residual risks are named, and reusable lessons are
captured or consciously left as candidates.

The local phase model is intentionally small: idle, turn, compaction,
branch-summary, and retry. Structural changes require an idle or verified
save-point boundary. Runtime-like changes can update future routing snapshots,
but they must not rewrite the evidence used by an active proof.

The harness contract now includes the general agent functions made explicit by
the current Pi design. Runtime configuration is distinct from a turn snapshot:
getters report the latest future-routing configuration, while setters during a
turn only affect the next snapshot. Queue operations (`steer`, `followUp`,
`nextTurn`, `abort`, and runtime config setters) are accepted only at safe
points, while structural operations (`prompt`, `skill`, `promptFromTemplate`,
`compact`, and `navigateTree`) require idle/save-point boundaries. Pending
session writes are durable accepted state and flush at save points, settlement,
or failure cleanup.

Tool and model registries are now explicit resource contracts. Tool-gate
updates validate owner, active names, idempotency, retry-safety, and provenance
before affecting future routing. Providers own model metadata, auth, model
listing, explicit refresh, and stream behavior; auth failures remain visible
and redacted rather than silently falling through to another source.

Hooks and observability are separated. Hooks are typed control-plane events:
observers are read-only, result-producing handlers reduce through
event-specific semantics, cleanup and source metadata are tracked, and hook
context uses facades rather than raw internals. Observability is passive:
stable trace/span events carry only safe metadata by default, and content,
headers, shell output, tool arguments, tool results, and secrets are unsafe
unless a future explicit redaction workflow authorizes capture.

Durability follows the session-tree analogy. Metadata headers, tree entries,
leaf entries, compaction checkpoints, branch summaries, custom extension
entries, and tool-result evidence map locally to conversation catalogs,
lifecycle state, error reports, candidate records, iteration proofs, and
release evidence. Recovery resumes from durable save points. Interrupted
provider streams or non-idempotent tool calls are reported as interrupted
unless the owning workflow proves retry safety.

Recovery also records durable queue, pending-write, operation, turn, provider
request, and tool-call entries as the target contract. Host-specific runtime
dependencies such as models, tools, resources, hooks, auth providers, and
extension handlers must be recreated by the host before durable state is
reduced. Abort preserves `nextTurn` and accepted pending writes, clears only
the appropriate in-turn queues, and waits for safe settlement.

The structural contract lives in `config/agent-system.json`. The physical Agent
topology lives in `agent/agent-filesystem.json` and is projected into numbered
root, interface, Agent, resource, runtime, evidence, exit, presentation,
maintenance, and local-boundary zones. The identity and
composition contract lives in `config/global-experience-agent-registry.json`. The manifest is
the local equivalent of Pi's harness topology: it names the harness, resources,
phase model, event loop, tool gates, session storage model, extension surfaces,
recovery policy, caller/model-neutral continuation, executable subagent
conditions, and completion criteria. The manifest and registry are
validated by `scripts/Test-AgentSystemTopology.ps1` and consumed by
`agent/40-runtime/Get-AgentHarnessState.ps1`, so the agent structure is a repository
interface rather than only prose.

The owner network lives in `config/agent-owner-connections.json`. It adapts
every active owner into a specialist Agent and remains the
executable correspondence layer between the 23 active registry modules, their
architecture plane and stage, canonical skill resource, trigger/input/output
contract, verification rule, optional tool gate, and named handoffs. The
`RouteOwner` runtime operation resolves any one active owner through this
network and returns an evidence-only handoff plus an accepted save point; it
does not execute the owner's gated mutation. The connection validator requires
every owner to have incoming and outgoing routes and proves that all owners are
reachable from and can return evidence to `codex-self-evolution`.

The executable controller is `agent/40-runtime/Invoke-GlobalExperienceAgent.ps1`. Its
`Inspect` and `Verify` modes preserve the structural compatibility surface.
`Run StartWork` retrieves durable records and creates a task; `Continue` lets a
different authorized caller/model host execute the next registered operation at
an idle save point. `Resume` reconstructs work, records, next actions,
caller/model history, and child state from `state.json` plus `events.jsonl`, and
conservatively marks unfinished non-idempotent work interrupted. `Abort`
preserves accepted writes while settling queues. Registered operations route
specialists; delegate, complete, join, or cancel child Agents; verify the Agent;
generate candidate reports; and invoke transactional complete iteration.
Specialist owners still own every mutation and verification.

Future global experience-system work uses that controller as the default
entry/exit contract. Requests about experience capture, learning or promotion,
owner or skill structure, information/function units, agent architecture,
global iteration, auto-Git, and release synchronization first enter through
`codex-self-evolution`, then transfer into the global experience agent. The
specialist owners still own their artifacts, but they are invoked as registered
Agent capabilities inside the root harness rather than as independent
global-system entrypoints. Git, releases, installation, credentials,
self-evolution, experience promotion, and publication remain gated Agent tools;
concept Agents never become duplicate owners.

The exit is equally explicit. A global experience-system task is not complete
until tool results or error feedback have been recorded, the narrowest proving
check has passed, the save point is accepted or rejected, lifecycle and
candidate state are updated, the current candidate report is generated after a
complete global iteration, and any Git, release, install, credential,
publication, or top-owner action has returned through its owning gate. Human
review uses approve/edit/reject/respond decisions and repeatable eval surfaces
such as topology tests, harness tests, global-agent run tests, validation,
global-install validation, candidate reports, and complete iteration proofs.

## Refinement Rule

Use handoff artifacts and owner-internal subskills before adding a new top-level
module. Add a module only when independent evidence proves a distinct trigger,
artifact lifecycle, maintained knowledge base, and safety boundary.

## Information and Functional Units

The system is maintained as a graph of [[Information and Functional Unit Principle|information units and functional units]].
Information units preserve meaning: knowledge notes, experience entries,
evidence summaries, process diagrams, maps, terminology, learning records, and
requirements. Functional units perform work: skills, subskills, workflows,
scripts, tests, validators, generated interfaces, and implementation
procedures.

Each unit should be the smallest owner-scoped artifact that preserves a real
trigger, lifecycle, evidence need, or safety boundary. The combined graph must
still cover the full collaboration loop: goal, authority, evidence, execution,
validation, feedback, learning, architecture evolution, and completion. Durable
functional units link back to governing information units; durable information
units link forward to the functions that consume, update, validate, or
operationalize them.

Before broad restructuring, use the architecture owner's unit topology review
to measure link health and top-owner disposition. Prefer repairing links or
owner-internal packaging when the current owner boundary is still correct.

## Collaborative operating model

The system treats the user, local experience, and model work as complementary
logical roles. `codex-self-evolution` selects the smallest accountable owner
set and records a task contract: objective, quality floor, authority, resource
budget, handoffs, verification, fallback, and stop condition. This is a routing
model, not permission to launch autonomous agents or external services.

Three lanes share one evidence boundary: operate (execution and verification),
learn (evidence and candidate classification), and evolve (verified experience
and architecture iteration). The resource ladder is experience-first: project
authority and verified indexes, reusable skills and deterministic scripts, then
targeted fresh model or external evidence only when needed to decide the task.
User attention, model calls, context, time, and paid actions are all budgeted,
but required security and verification are never traded away.

Parallel work is exceptional: it requires independent work, isolated write
surfaces, shared acceptance criteria, and a merge verifier. A future update,
installation, reconfiguration, or substantive re-learning still needs fresh
explicit authorization. Failed handoffs route to error feedback before any
lesson is promoted.

For complete global iterations, resource governance also means serialized
runtime ownership: one resumable controller may outlast an interactive caller.
Inspect lifecycle state and the iteration proof before retrying; do not overlap
replacement writers, and restore the exact snapshot if replacement may have
started.

Top-level owners remain evolvable under [[Top-Level Owner Governance]]: current
user authorization, an evidence-backed boundary comparison, rollback or
migration conditions, and validation are required for each structural change.

Candidate authorization has two meanings. Default guarded processing preserves
source wording, promotes only non-mandatory guidance, and clears derived
pending records. Structural optimization authorization is stronger: it must
turn workflow-learning candidates into architecture-iteration input with source
evidence, related owners, required handoff, rollback boundary, and validation.
Archiving alone is not completion when the user asks the system to use the
candidate to optimize the global structure.

Resource selection is now owned by the self-evolution controller's internal
`resource-economy` capability. The former standalone cost owner is retained
only as a historical migration record after its compatibility route was retired.

## Links

- [[Experience and Knowledge Architecture]]
- [[Experience Knowledge Subskill Refinement]]
- [[Experience System Error Feedback]]
- [[Local Experience Iteration Workflow]]
- [[Visual Format Selection]]
- [[Global Iteration Candidate Report]]
