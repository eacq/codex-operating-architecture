---
id: concept-global-experience-system
type: concept
status: active
source: codex-global-experience-system-refinement-2026-07-18
verified: true
learning_audience: codex
codex_learning: Treat the global experience system as a coordinated loop across existing owners; refine it with handoff artifacts and owner-internal subskills before adding a top-level module.
---

# Global Experience System

The global experience system is the operating loop that turns project evidence,
failures, workflow changes, and verified iterations into reusable rules without
collapsing every responsibility into one skill.

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

## Owner Loop

1. `codex-self-evolution` recognizes the project entry and routes the system
   pass.
2. `codex-experience-capture` classifies evidence, owns promotion thresholds,
   and maintains the experience ledger.
3. `codex-error-feedback` captures unexpected behavior before it can become a
   lesson.
4. `codex-knowledge-system` stores linked concepts, workflow-learning records,
   maps, and Codex learning indexes.
5. `codex-architecture-iteration` decides whether to revise, merge, split,
   package as a subskill, deprecate, or delete.

## Refinement Rule

Use handoff artifacts and owner-internal subskills before adding a new top-level
module. Add a module only when independent evidence proves a distinct trigger,
artifact lifecycle, maintained knowledge base, and safety boundary.

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

Resource selection is now owned by the self-evolution controller's internal
`resource-economy` capability. The former standalone cost owner is retained
only as a one-release compatibility route.

## Links

- [[Experience and Knowledge Architecture]]
- [[Experience Knowledge Subskill Refinement]]
- [[Experience System Error Feedback]]
- [[Local Experience Iteration Workflow]]
- [[Visual Format Selection]]
- [[Global Iteration Candidate Report]]
