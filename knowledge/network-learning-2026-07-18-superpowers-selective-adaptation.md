# Network Learning: obra/superpowers selective adaptation

## Trigger

The global experience system needs stronger prevention against repeated
symptom-only repairs and completion claims without fresh evidence.

## Source and comparison

- `obra/superpowers` v6.1.1, MIT: systematic debugging, verification before
  completion, brainstorming, plans, TDD, worktrees, and optional agent/plugin
  runtime behavior.
- Existing `codex-error-feedback` already owns structured incident evidence,
  repeat reopening, targeted repair, and promotion.
- Existing `codex-task-execution`, project lifecycle, and Git gates already
  own scoped execution, verification, authority, and publication boundaries.

## Decision

Install `systematic-debugging` and `verification-before-completion` into the
local Codex skill catalog as optional focused interfaces. Adapt only their
root-cause and fresh-evidence principles into the existing owners. Adapt the
brainstorming method as `codex-requirement-authoring`'s owner-internal
`brainstorming-lite` subskill: consequential questions, bounded alternatives,
validation-aware design, and explicit handoff. Do not add a top-level owner or
a plugin controller. Adapt the writing-plan method as `codex-workflow-design`'s
owner-internal `writing-plan-lite` subskill: dependency-aware, independently
verifiable tasks with evidence-backed paths and explicit authority gates.

## Rejected or deferred

- Do not install the whole plugin, session hook, automatic skill bootstrap,
  telemetry-bearing visual companion, mandatory worktrees, or automatic
  subagent orchestration.
- Do not make TDD mandatory for every non-code or small deterministic task.
- Do not require a full design-approval cycle for a clearly bounded repair.
- Do not import the visual companion, its telemetry, browser server, or a
  universal pre-implementation approval gate.
- Do not require worktrees, automatic agents, TDD, commits, or fabricated code
  and command detail merely to satisfy a planning template.

## Validation and invalidation

Validate affected skills and the existing error-feedback/task-execution tests.
Revisit this adaptation if it duplicates an owner, forces unnecessary user
approval, expands agent/runtime authority, or materially increases routine
task cost.

## Sources

- https://github.com/obra/superpowers
- https://raw.githubusercontent.com/obra/superpowers/main/skills/systematic-debugging/SKILL.md
- https://raw.githubusercontent.com/obra/superpowers/main/skills/verification-before-completion/SKILL.md
