---
id: concept-information-functional-unit-principle
type: concept
status: active
source: user-guidance-information-functional-units-2026-07-21
verified: true
learning_audience: codex
codex_learning: Model the Global Experience Agent as a bidirectionally linked graph of information units and functional units. Keep each unit minimal and owner-scoped, but require the whole graph to cover authority, memory, MCP evidence, collaboration, learning, execution, validation, and evolution.
---

# Information and Functional Unit Principle

The Global Experience Agent is maintained as a bidirectionally linked graph of
information units and functional units. This principle is itself evolvable:
future verified learning from human practice, machine learning, LLM systems,
agent systems, memory systems, MCP evidence, and local project evidence may
refine the definitions, split or merge unit types, or add better link rules.

## Unit Types

An **information unit** preserves meaning. It includes knowledge notes,
experience entries, evidence summaries, process diagrams, maps, terminology,
learning records, requirements, retrospectives, and other artifacts whose main
job is to explain, justify, classify, or index behavior.

A **functional unit** performs work. It includes owner skills, owner-internal
subskills, workflows, scripts, tests, validators, generated interfaces,
implementation procedures, and other artifacts whose main job is to execute,
transform, verify, route, or maintain behavior.

Some artifacts can contain both kinds of content. In that case, classify by the
dominant maintained responsibility and link to the counterpart instead of
duplicating it. For example, a script is a functional unit; its design record,
evidence, and operating rule are information units. A knowledge note is an
information unit; the builder, test, or workflow that consumes it is a
functional unit.

Agent-harness terminology refines the same split. The harness is a functional
coordination unit. Agent resources can be information units, functional units,
or bundles of both. Tool gates, save points, session branches, and extension
surfaces are functional contracts that must link back to the information units
that justify their authority, evidence, rollback, and invalidation boundaries.

## Minimum-System Rule

Each unit should be the smallest stable artifact that has a distinct owner,
trigger, lifecycle, evidence need, or safety boundary. Split a unit only when
that distinction improves routing, validation, rollback, or learning. Merge or
replace with links when separation creates duplicate instructions, orphaned
knowledge, or coordination cost without a verified benefit.

Minimum does not mean incomplete. A mature Agent needs enough information units
and functional units to cover the whole loop: user goal, task contract,
authority, Agent memory, MCP graph evidence, source evidence, execution,
validation, error feedback, learning, architecture evolution, and completion
reporting.

## Bidirectional Link Rule

Every durable functional unit should link to the information units that govern
its trigger, authority, assumptions, evidence, validation, and invalidation
conditions. Every durable information unit should link to the functional units
that consume, update, validate, or operationalize it.

Bidirectional links are not decoration. They are the retrieval and maintenance
contract between the user, the model, and the local Agent:

- From information to function: what should act on this knowledge, and under
  what authority and verification?
- From function to information: what knowledge, evidence, or experience explains
  why this behavior exists, when it is safe, and when it expires?

## Learning Sources

Learning may come from two broad directions:

- Human practice: user corrections, repeated project experience, expert
  workflows, upstream method systems, documentation, release discipline, and
  operational failures.
- Technical systems: machine learning, LLM and agent architecture, evaluation
  methods, retrieval systems, memory systems, tool orchestration, safety
  research, and software-engineering automation.

Both directions remain candidates until they are compared against the current
owner structure, adapted into a reversible unit change, and verified. Direct
source principles and local synthesis must be labeled separately.

## Iteration Checks

When optimizing the Global Experience Agent, ask:

1. Is the proposed change an information unit, a functional unit, or a link
   between them?
2. What is the smallest owner-scoped artifact that can hold it without losing
   coverage?
3. Which existing unit should consume, validate, update, or govern it?
4. What bidirectional links prove it is findable by the user, the model, and the
   local Agent?
5. What validation and invalidation condition prevent it from becoming stale
   ceremony?

Run the architecture owner's unit topology review before broad restructuring.
It turns these questions into a project-local audit of information units,
functional units, bidirectional-link health, and top-level owner disposition.
The audit is evidence for review; it does not by itself authorize moving files,
renaming owners, installing tools, publishing, or deleting compatibility
surfaces.

Name clarity is part of the unit contract. When a naming-only change improves
the collaboration among the user, the model, and the local Agent
without changing the unit's trigger, owner, artifacts, maintained knowledge, or
safety boundary, rename it through the migration policy instead of preserving a
confusing name for stability.

## Functional Owner Links

- `codex-architecture-iteration` owns unit topology review and top-level owner
  disposition.
- `codex-knowledge-system` owns linked information units, generated indexes,
  maps, and Codex learning output.
- `codex-experience-capture` owns evidence classification, workflow-learning
  consumption, and structural optimization records.
- `codex-learning` owns project and network learning intake before a unit
  becomes durable.

## Links

- [[Global Experience System]]
- [[Pi Agent Harness Network Learning]]
- [[Experience and Knowledge Architecture]]
- [[Learning Governance]]
- [[Knowledge System Module]]
- [[Verified Experience Promotion]]
- [[Top-Level Owner Governance]]
