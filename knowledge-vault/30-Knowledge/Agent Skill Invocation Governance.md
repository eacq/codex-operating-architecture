---
title: Agent Skill Invocation Governance
type: information-unit
status: active
learning_audience: codex
codex_learning: "Treat mattpocock/skills as a method source for predictable skill invocation: separate human-only orchestration from model-reachable discipline, keep model-visible descriptions trigger-focused, use checkable completion criteria, and bind implementation work to red-capable loops, tracer-bullet slices, and two-axis review."
source: mattpocock/skills
source_commit: ed37663cc5fbef691ddfecd080dff42f7e7e350d
owner: codex-self-evolution
verification:
  - scripts/Test-AgentSkillInvocationPolicy.ps1
  - scripts/Test-AgentHarnessContract.ps1
  - scripts/validate.ps1
---

# Agent Skill Invocation Governance

`mattpocock/skills` is useful to the Global Experience Agent as a method
source, not as an installed upstream bundle. The local system already has
owner-routed skills, caller interfaces, tool gates, rollback, and release
validation, so the adopted unit is a policy:
`config/agent-skill-invocation-policy.json`.

## Adopted principle

Skills should make the Agent's process predictable. The local translation is:

- Human-only orchestration stays human-triggered or global-control routed.
- Model-reachable discipline stays small, trigger-focused, and owner-scoped.
- Top-level model-visible owner descriptions stay within the current
  recommended ceiling in `config/agent-skill-invocation-policy.json` unless a
  separately recorded safety boundary justifies the extra text.
- Parent skills behave like specialist Agent entry surfaces: they keep trigger,
  authority, handoff, and exit criteria visible, while branch-only procedure
  moves into owner-internal subskills or linked references.
- Owner-internal subskills are functional units. Split them only for distinct
  triggers, write surfaces, proof loops, reusable procedures, tool gates, or
  artifact lifecycles; merge them back when they restate the parent or cannot
  be independently verified.
- Codex Home imported compatibility wrappers use a shorter generated
  description: they route through the parent owner and never advertise
  themselves as top-level entries. Their `upstream/SKILL.md` files remain
  preserved reference material, not model-visible authority.
- Concept Agents compose existing parent skills and subskills; they never
  create parallel top-level skill authority or bypass owner gates.
- Every state-changing step needs a checkable completion criterion.
- Branch-only reference moves behind a clear context pointer.
- Implementation work prefers red-capable checks, pre-agreed seams, one
  vertical slice at a time, and review against both standards and spec.

## Local mapping

- User-invoked upstream flows map to `human` or `global-control` interfaces.
  They can route work but do not become autonomous model triggers.
- Model-invoked upstream discipline maps to owner-internal functional units
  that an LLM or internal unit may select when the task contract fits.
- Router behavior maps to `codex-self-evolution` and requirement/workflow
  owners. The router orients and selects; gated side effects still return to
  their owner gates.
- Tracer-bullet ticketing maps to `codex-workflow-design`: each slice must be
  independently verifiable and declare blocking edges. Wide refactors use
  expand-contract batches instead of pretending every change can be vertical.
- TDD and diagnosing-bugs map to `codex-task-execution` and
  `codex-error-feedback`: a red-capable seam or loop is the proof surface.
- Two-axis review maps to `codex-architecture-iteration`: standards and spec
  are reported separately so one cannot mask the other.

## Rejected or deferred

The upstream skill files, plugin flow, external issue-tracker setup, and
unconditional parallel review agents are not installed by default. They would
create overlapping discovery surfaces and external state changes. Future
installation requires the normal tool, credential, publication, and owner gates.

## Links

- [[Global Experience System]]
- [[Information and Functional Unit Principle]]
- [[Agent Loop System]]
- [[Learning Governance]]

## Functional units

- `config/agent-skill-invocation-policy.json`
- `scripts/Test-AgentSkillInvocationPolicy.ps1`
- `skills/codex-self-evolution/SKILL.md`
- `skills/codex-learning/SKILL.md`
- `skills/codex-architecture-iteration/SKILL.md`
