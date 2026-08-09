---
name: codex-self-evolution
description: Use at the start of work in any project to route lifecycle, self-evolution, Global Experience Agent work, cross-owner handoffs, resource gates, and verified iteration closeout.
---

# Codex Self Evolution

Treat `$ARCHITECTURE_ROOT` as canonical. Global skill paths are discovery
interfaces, not editable copies. This parent skill is the routing surface; long
iteration, diagnosis, publication, and release gates live in owner-internal
subskills.

## Route The Task

1. Identify the project root and check `.codex/project/state.json`; invoke
   `codex-project-optimization` before substantive work when it is missing.
   On every Codex project entry, start or resume the one local Global
   Experience Agent by default unless the user explicitly authorizes skipping
   it for that turn. Use
   `agent/40-runtime/Invoke-GlobalExperienceAgent.ps1` with `Run StartWork`
   for new durable work or `Resume`/`Continue` for an accepted save point after
   loading `config/agent-system.json`, `agent/agent-filesystem.json`, and
   `config/global-experience-agent-registry.json`. A skip authorization only
   omits the Agent durable session; it never skips this lifecycle controller,
   Codebase Memory startup/indexing when applicable, safety/privacy/rollback/
   validation gates, owner routing, or permission checks.
   Ensure the canonical graph console is available
   with `scripts/Start-CodebaseMemoryGraphUi.ps1` (`F:\codex`, `F-codex`,
   `127.0.0.1:9749`) before selecting narrower skills.
   Read the canonical startup script or command parameter contract before
   supplying host, address, port, mode, or status arguments; do not infer those
   names from adjacent tools or older wrappers.
   Query the current task's callable capability registry for deferred or
   namespaced `codebase-memory-mcp` tools. When callable, run the startup
   preflight in
   [subskills/mcp-startup-preflight/SKILL.md](subskills/mcp-startup-preflight/SKILL.md)
   before broad file reading or architecture claims. For a task without
   source-structure work, retain the global UI health check but do not force
   project graph citation. Avoid lifecycle churn for trivial or read-only tasks.
2. Read the request and project authority files, then select only the needed
   modules. Open `codex-learning` only for a concrete gap plus qualifying
   evidence.
3. State material assumptions and acceptance criteria; execute and verify in
   proportion to risk.
   For self-iteration or structural optimization, first apply
   [subskills/outcome-directed-iteration/SKILL.md](subskills/outcome-directed-iteration/SKILL.md).
   It translates the terminal collaboration goal into a small, testable
   iteration contract and blocks changes whose contribution cannot be stated.
4. At Git milestones or completed iterations, reconcile project requirements,
   workflows, experience, retrospectives, pending events, state, and file
   organization. For complete global iterations, read
   [subskills/global-iteration-gate/SKILL.md](subskills/global-iteration-gate/SKILL.md).
   After a completed global iteration, generate and present the advisory
   candidate report before asking the user for any follow-up decision. It may
   summarize candidates but never promotes them or expands authority.
5. Treat an explicit request about the "global experience system" as a
   coordinated `codex-experience-capture` system pass, not as permission to add
   a new top-level owner. Route reusable outcomes to
   `codex-experience-capture`; route linked concepts to
   `codex-knowledge-system`. After learning or workflow changes, require
   `codex-architecture-iteration` to review owner overlap and economy.
   Global experience-system work continues through the same one local Global
    Experience Agent contract. Load `config/agent-system.json`,
    `config/global-experience-agent-registry.json`, and
    `config/agent-interface-policy.json`; use
   `agent/40-runtime/Invoke-GlobalExperienceAgent.ps1` as the harness controller when
   the work changes global experience, learning, owner/skill structure,
   information/function units, agent architecture, global iteration, auto-Git,
   or release synchronization, and treat owner-backed specialist Agents and
   concept Agents as registered capabilities under the root rather than
   independent global-system entrypoints. `Run StartWork` establishes a durable
   task; `ClassifyIntent` exposes the local four-layer intent funnel used by
   `Auto` before operation permission evaluation and emits the auditable
   `capability_plan` from `config/agent-autonomous-capability-decision-policy.json`.
   The Agent selects the smallest sufficient learned capability set from task
   evidence, while selection labels never grant authority; `Continue` permits another authorized caller/model host to act from an
    idle save point; `Resume` reconstructs records, work, queues, and child state.
    Evaluate the declared interface before side effects. Human, LLM, and
    internal-functional-unit calls may use registered functional units but may
    not directly mutate Agent structure. Only global-control with current
    global-structure evidence and declared target surfaces may route any
    Agent-aspect change through `codex-architecture-iteration` and the
    `agent_structure` gate. Interface labels never elevate authority, and every
    runtime response must expose a typed exit and next authority boundary.
   Child delegation/completion/join/cancel is executable only with a registered
   profile, bounded authority, isolated write surface, acceptance criteria,
   evidence, and merge verification. The exit must align tool results or error feedback, the narrowest
   proving check, save-point acceptance, lifecycle/candidate state, candidate
   report when applicable, and any Git/release/install/credential/publication
   or top-owner gate before completion is reported.
   The global experience system uses the local executable Agent model:
   `codex-self-evolution` is the harness; owners are specialist Agents; composed
   profiles are concept Agents; lifecycle artifacts are Agent resources; high-risk operations are
   tool gates, durable state is session/branch evidence, and validation or
   publication envelopes are save points. This is an executable local agent
   harness: `Run` starts durable work, `Continue` executes later registered
   operations, and `Resume`/`Abort` own recovery and queue settlement. It does
   not create public access, require Pi, load arbitrary extensions, or let
   delegation expand authority.
   Invoke Agent array parameters such as `AcceptanceCriteria`, `WriteSurface`,
   or `ResultEvidence` directly in the current PowerShell process. Do not expand
   a PowerShell array as unlabelled arguments across `powershell.exe -File`;
   both Agent entry scripts disable positional binding so malformed calls fail
   before an array element can become `Owner`, `StateRoot`, or another unrelated
   parameter.
   All active owners are connected through
   `config/agent-owner-connections.json`. Use `RouteOwner -Owner <active-owner>`
   when the harness must resolve a specialist: it selects the canonical skill,
   architecture plane/stage, triggers, inputs, outputs, verification, optional
   gate, and incoming/outgoing handoffs, then records an evidence-only save
   point. Routing never executes the gated side effect; the owning controller
   still performs the separately authorized operation.
   For a material task spanning user direction, local evidence, and model work,
   use [subskills/collaborative-operating-model/SKILL.md](subskills/collaborative-operating-model/SKILL.md).
   It assigns the smallest logical owner set and handoffs; it does not itself
   authorize or auto-spawn extra agents, models, or external services.
   For a long-running project goal, repeated bounded turns, explicit todo
   ownership, quota/heartbeat decisions, or evidence-backed handoffs, load
   [subskills/loopx-control-plane/SKILL.md](subskills/loopx-control-plane/SKILL.md).
   LoopX is a project-control-plane adapter under this owner: it may govern
   project goals and turn continuation, but it never replaces the one Global
   Experience Agent, expands authority, or bypasses an existing owner/tool
   gate.
   For resource-sensitive long-running work, also load
   [subskills/long-running-trajectory/SKILL.md](subskills/long-running-trajectory/SKILL.md)
   and apply `config/loopx-resource-policy.json`: choose economy, balanced, or
   full from current evidence and budget. Preserve high-cost capabilities as
   opt-in options; do not reduce this to an always-on or always-off rule.
6. Route unexpected module behavior to `codex-error-feedback` before promoting
   it as experience or changing a skill. Cross-project failures with suspected
   global causality mirror only a redacted summary into the architecture inbox.
7. Route cloning, sharing, private-to-generic extraction, or first-use local
   configuration to `codex-skill-portability`.
8. Invoke `codex-architecture-iteration` only for evidence-backed module,
   parent-skill, subskill, or contract changes.
   A top-level owner add, merge, split, deprecation, deletion, or material
   contract revision additionally requires explicit user authorization for that
   iteration. Without it, limit work to evidence gathering and owner-internal
   candidates; authorization for one review is not standing permission for a
   later structural change.
9. For expensive, recurring, context-heavy, or resource-constrained work, use
   [subskills/resource-economy/SKILL.md](subskills/resource-economy/SKILL.md).
   It owns quality-preserving resource routing; the former top-level cost owner
   has been retired from discovery and remains only as migration history.

The terminal direction for self-evolution is not module growth: improve the
user, local-experience, and model collaboration system so it completes useful
work with a fixed quality and safety floor while reducing avoidable user effort,
model/context/tool work, and coordination loss. Every material iteration must
make its expected contribution and its evidence observable; retain the current
contract when no evidence-backed improvement remains.

For verified iteration closeout, Git/publication gates, failed Git attempts,
continuous diagnosis, workflow-learning records, documentation synchronization,
public/private conversion, and release command routing, read
[subskills/iteration-publication-gate/SKILL.md](subskills/iteration-publication-gate/SKILL.md).

## Quality Gate

Search indexes before raw history. Durable rules require evidence, scope,
verification, and invalidation conditions; keep weaker observations as project
candidates. Use `module-registry.json` for lifecycle decisions and prefer an
existing owner over overlap.

## Action Notification Policy

Ordinary in-scope file edits, skill synchronization, generation, and validation
need no separate prompt. Notify before external software or system changes;
preserve higher confirmation boundaries for destructive, public, paid,
privileged, credential, or irreversible actions.

## Example

```text
At project start: read .codex/project/state.json, then route to codex-project-optimization only if it is missing.
```
