---
name: codex-experience-capture-global-experience-system
description: Owner-internal subskill for operating the Global Experience Agent while preserving specialist owners.
---

# Global Experience Agent

Use this subskill only through the parent `codex-experience-capture` owner.
It does not create an experience-capture entrypoint. The root controller remains
`codex-self-evolution` plus `agent/40-runtime/Invoke-GlobalExperienceAgent.ps1`.

## Trigger

Run through the project-entry Global Experience Agent by default. Direct
global-experience-system work is mandatory when the user explicitly refers to
the global experience system/Agent, or asks to fuse, split, merge, refactor,
encapsulate, streamline, or refine skill knowledge and experience workflows as
one architecture-level system. The only valid turn-level startup skip is an
explicit user authorization to skip the Agent durable session; that skip does
not bypass lifecycle entry, Codebase Memory startup/indexing when applicable,
owner gates, or permission checks.

## Boundary

The global experience system is one durable root Agent. Experience capture is a
specialist capability inside that Agent, not the controller. Its registry exposes
these existing owners as specialist Agents and may compose them into concept
Agents without creating duplicate top-level skills:

- `codex-self-evolution`: project entry, lifecycle routing, and verified
  iteration gates.
- `codex-experience-capture`: evidence classification, promotion thresholds,
  and the global experience ledger.
- `codex-error-feedback`: unexpected behavior and failed handoff reports before
  promotion.
- `codex-knowledge-system`: canonical linked knowledge, workflow-learning
  records, derived maps, and Codex learning indexes.
- `codex-architecture-iteration`: owner economy, revision, merge, split,
  subskill packaging, deprecation, and deletion decisions.

The canonical identity/composition contract is
`config/global-experience-agent-registry.json`; owner correspondence remains in
`config/agent-owner-connections.json`; executable caller permissions and exits
live in `config/agent-interface-policy.json`. The `human`, `llm`, and
`internal-functional-unit` interfaces may use only their registered functional
units and gates. They cannot directly change Agent topology, owners,
permissions, runtime contracts, tool gates, or structural manifests. Only
`global-control` with current `global-structure` authorization evidence and
declared target surfaces can route any Agent-aspect change to
`codex-architecture-iteration` through the `agent_structure` gate. Interface,
caller, model, and host labels never grant authority. Do not create a new top-level skill for this system unless at least two
independent verified use cases prove a separate trigger, artifact set,
maintained knowledge base, and safety boundary.

## Operating Order

1. Enter through `codex-self-evolution`, then create, resume, or continue durable work
   with `agent/40-runtime/Invoke-GlobalExperienceAgent.ps1`. The root Agent
   evaluates interface policy, authority scope, caller/model labels, selected
   resources, child state, and typed exits before side effects.
2. Run the MCP startup preflight: refresh `F:\codex` as `F-codex` with fast
   `index_repository`, confirm the graph UI is healthy, and keep the global
   cache scoped to exactly one canonical project unless a task-specific source
   repository graph is explicitly needed. External reference repositories may
   be inspected locally or indexed as transient evidence, but must not remain
   in the global cache when `Test-CodebaseMemoryProjectScope.ps1` is expected
   to pass.
3. Retrieve relevant Agent memory through `SearchMemory` or
   `RenderMemorySnapshot` when prior records can reduce repeated steering.
   Store new reusable results through `StoreMemory` only after they are scoped,
   non-secret, and evidence-bearing; consolidate through `ConsolidateMemory`
   when records become stale or high-priority procedural/semantic memory should
   be frozen.
   For `Auto` requests, let the runtime run `ClassifyIntent` first. It uses the
   local four-layer funnel in `config/agent-intent-policy.json`: explicit
   L0 rules, deterministic L1 utterance/keyword routes, disabled-by-default L2
   host LLM classification, and L3 safe fallback to `StartWork`. The resulting
   operation still passes through interface policy and owner gates; intent
   labels never grant authority.
4. Read project lifecycle authority and the current experience ledger.
5. Check pending events, structured error reports, and incoming global-causality
   summaries before treating behavior as a lesson.
6. Classify evidence through `local-experience-iteration` or
   `workflow-learning` as appropriate.
7. Convert workflow changes into hash-based learning records through
   `codex-knowledge-system`.
8. Ask `codex-architecture-iteration` to decide revise, parent-skill
   refinement, subskill packaging, subworkflow, merge, split, add, deprecate,
   or delete.
9. When the evidence points to improving a skill rather than changing owner
   topology, route to `skill-evolution-optimization`: stage one primary
   `SKILL.md` candidate, score current/candidate/best state, run the strict
   improvement gate, and adopt only after safety checks, required human/owner
   checkpoints, and owner validation pass. Keep rejected candidates as
   auditable evidence; do not turn them into promoted rules.
10. Apply the smallest owner-scoped change, then update the ledger, linked
   knowledge, registry evidence, and documentation surfaces that describe the
   changed behavior.
   If a verified learning changes reusable Agent structure, register it in
   `config/agent-structural-optimization-policy.json` and run
   `agent/80-maintenance/Sync-ChildAgentStructuralOptimizations.ps1 -Apply`
   before any child delegation. This synchronizes the minimal template,
   registered named child profiles, manifest, and filesystem projections. At
   delegation, the runtime injects a content-hashed snapshot into every child
   state; stale named profiles fail closed instead of silently using an older
   contract. Domain knowledge and private/user-specific facts are never copied
   through this structural channel.
   Use `agent/40-runtime/Invoke-GlobalExperienceAgent.ps1 -Mode Run -Operation StartWork
   -Apply` to create durable work and retrieve relevant records. Use `Continue`
   with the same session ID from another authorized caller or compatible model
   host; use `Resume` to reconstruct the save point, records, next actions,
   caller/model history, and child state. Every operation creates a durable
   snapshot, persists its result, and settles at a save point.
   Resolve specialist-Agent handoffs through `-Operation RouteOwner -Owner
   <active-owner>`. The route is read/evidence-only: it proves the canonical
   owner resource, architecture plane/stage, typed inputs/outputs, verification,
   optional gate, and incoming/outgoing connections, but it cannot execute the
   owner's gated mutation. Concept Agents resolve to existing owner sets through
   the Agent registry. Child Agents are executable through delegate, complete,
   join, and cancel operations only when the parent records bounded authority,
   isolated write surfaces, acceptance criteria, repository-relative evidence,
   and merge verification. No child expands authority or bypasses a tool gate.
   When a task needs a new child Agent contract, design it from
   `config/minimal-agent-template.json` with
   `skills/codex-experience-capture/scripts/New-MinimalAgentPlan.ps1`. The
   planner selects a registered concept or specialist profile, produces the
   bounded child contract, and may call `DelegateSubagent` only with
   `-Delegate -Apply` from an idle parent session. It never executes the child
   task by itself.
   For array-valued parameters, call the Agent controller directly in the
   current PowerShell process or use a host adapter that preserves named JSON
   fields. Never expand an array into unlabelled arguments after
   `powershell.exe -File`; positional binding is disabled intentionally so such
   calls fail before creating a wrong owner route or state root.
   Evaluate `config/agent-interface-policy.json` before durable session writes.
   `DescribeInterfaces` exposes the policy; `EvaluateAccess` returns a
   read-only decision for a proposed operation; `RequestStructureChange`
   returns only an evidence-bearing architecture-owner route. Every runtime
   result must emit a typed exit with audience, authority decision, and next
   authority boundary. A denied structure request must return
   `authorization-required` without creating or changing its durable session.
11. After a completed global iteration, generate the advisory candidate report.
   Present its Chinese-primary user view with source, evidence, suggested
   decision, and authority boundary, then append the stable English model view
   so the user and Global Experience Agent can consume the same evidence without
   changing source wording. The user can decide whether to retain, test,
   promote, retire, or separately authorize an external change.
   In a Codex chat, render the report directly in the assistant response.
   Local-file links open source in the right sidebar and do not execute a CMD,
   so do not promise command launching from a chat click. The local report
   script and optional `codex-report` handler remain manual compatibility
   routes for File Explorer or a terminal, not the primary user delivery path.
12. When an active explicit all-candidate authorization exists, the complete
   serialized complete-iteration controller (`scripts/Invoke-CompleteGlobalExperienceIteration.ps1 -Apply`)
   consumes it through
   `skills/codex-experience-capture/scripts/Process-AuthorizedCandidateRecords.ps1`
   before its
   isolated replacement transaction:
   archive source evidence, reclassify durable items as guarded guidance, clear
   derived pending records, regenerate the report, and mark the authorization
   consumed. This local processing authorization never covers installation,
   updates, reconfiguration, credentials, publishing, or destructive action.
   If the user explicitly says the candidates should be used to optimize the
   global structure, write the authorization with
   `processing_mode: structural-optimization`. In that mode, workflow-learning
   candidates are not merely cleared: the processor writes a structural
   optimization record that preserves source evidence, related owners, required
   handoff, rollback boundary, and validation expectations. The architecture
    owner then decides revise, subskill packaging, subworkflow, merge, split,
    add, deprecate, or delete under the current authorization and verification
    proof.
   If the user explicitly requests formal promotion, set
   `processing_mode: formal-promotion` and include an exact verified evidence
   record for every candidate in the current report. The processor must reject
   count, source, wording, status, or evidence-path drift; after acceptance it
   archives every original, writes a formal-promotion proof, and reclassifies
   durable records as verified promotion. The same external-action gates remain
   in force.

## Economy Rules

- Prefer a handoff artifact over duplicating instructions across owners.
- Model the Global Experience Agent as linked information units and functional
  units. Information units preserve meaning, evidence, concepts, maps,
  terminology, experience, memory summaries, MCP evidence, and learning
  summaries. Functional units perform work through skills, subskills,
  workflows, scripts, validators, tests, runtime operations, and implementation
  procedures. Keep each unit minimal and owner-scoped, but require durable
  bidirectional links: functional units cite their governing information units,
  and information units cite the functions that consume, update, validate, or
  operationalize them.
- Treat repeated deterministic manual operations as an economy candidate. Route
  them through `codex-workflow-design/scripts/New-ScriptAutomationCandidate.ps1`
  before adding more prompt text: preserve owner routing, stable inputs,
  validation, language choice, and authorization boundaries. Future global
  optimization reviews must consider this scriptification path.
- Treat scripts as first-class knowledge/workflow assets alongside skills,
  knowledge, and experience. Every complete iteration automatically writes a
  measured script-asset optimization review. It may split, merge, refactor, or
  select a different suitable language only when caller contracts, equivalent
  behavior, owner boundaries, rollback, and validation remain explicit; it
  automatically applies only measured read-only or local-reversible gains.
- For long or repetitive global-experience-system work, ask
  `codex-self-evolution` -> `resource-economy` to decide whether routine
  progress and closeout can use autonomous `caveman-lite` presentation
  compression. Compress chat delivery only; never compress source evidence,
  candidate reports, release notes, error reports, formal instructions, or
  ordered safety-critical steps.
- Do not auto-open `brainstorming-lite` from the global experience system.
  If a proposed workflow, skill, experience, learning, or architecture change
  has an unresolved choice, first resolve it from local evidence or use
  conversation-to-spec. Route to `brainstorming-lite` only when the user
  explicitly asks for brainstorming/design exploration, or when
  `codex-requirement-authoring` is already the active owner and a
  non-discoverable consequential choice blocks an execution-ready brief.
- External skill learning may lead to installation, but only after the system
  classifies necessity, reusable value, owner fit, privacy impact, and
  validation. Compatible adaptation is preferred over raw upstream copying.
- When an external methodology or upstream skill should be absorbed into the
  experience system, route through
  `subskills/methodology-skill-distillation/SKILL.md`: ground the source,
  extract candidate units, apply experience triple verification, shape accepted
  units with RIA++, link them to existing owners and Agent resources, and
  pressure-test triggers before promotion.
- When a grounded method should improve an existing skill, route through
  `subskills/skill-evolution-optimization/SKILL.md`: use Darwin-style
  evaluate-improve-validate-review-keep/revert loops and SkillOpt-style
  current/candidate/best scoring gates. A candidate must strictly improve and
  pass safety, validation, and checkpoint requirements before adoption.
- Prefer an owner-internal subskill when the mode has distinct steps but shares
  the parent trigger, artifacts, maintained knowledge, and safety boundary.
- Merge only when trigger, workflow, maintained knowledge, and validation
  substantially overlap.
- Split only when a workflow has an independently verified safety boundary or
  artifact lifecycle.
- Remove or shorten parent-skill text only after the detailed contract exists
  in an internal subskill or reference.

## Verification

Run the narrowest builders or validators that cover the change. For durable
workflow or knowledge changes, run the workflow-learning record generator,
knowledge builders, and full validation in proportion to risk. Record source,
scope, verification, and invalidation conditions before calling the refinement
verified.
