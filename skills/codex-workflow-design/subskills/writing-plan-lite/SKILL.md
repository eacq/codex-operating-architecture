---
name: codex-workflow-design-writing-plan-lite
description: Owner-internal implementation-planning mode for accepted designs or execution-ready requirements. Use through codex-workflow-design to create dependency-aware, validation-complete plans without invented detail, automatic execution, or authority expansion.
---

# Writing Plan Lite

Use this subskill only through `codex-workflow-design`. It selectively adapts
the detailed, task-oriented planning discipline learned from
`obra/superpowers`; it is not an imported plugin, mandatory TDD workflow,
worktree policy, agent dispatcher, or auto-commit mechanism.

## Trigger

Use when an accepted design or normalized requirement has multiple dependent
steps, meaningful handoffs, non-trivial rollback, or a user-requested plan.
For a high-uncertainty or consequential design decision, first use
`consensus-plan-lite` or return to `brainstorming-lite`. Do not write a formal
plan for a small, reversible edit unless the user asks for one.

## Inputs and Evidence

Start from the accepted design or normalized brief, current repository state,
project lifecycle files, and relevant owner contracts. Mark each fact as
observed or assumed. Use exact file paths, symbols, commands, and expected
results only after confirming them locally. If they are not discoverable, plan
the evidence-gathering task first rather than inventing implementation detail.

## Plan Flow

1. State the user-visible goal, non-goals, acceptance criteria, authority
   boundary, and completion verifier. Check whether independent subsystems need
   separate plans with independently useful deliverables.
2. Map the smallest coherent file or artifact set: existing responsibilities,
   proposed changes, owner for each handoff, dependencies, and rollback or
   fallback. Do not add unrelated cleanup.
3. Split work at independently reviewable, verifiable deliverables. Fold setup,
   configuration, documentation, and validation into the deliverable they
   serve; do not use arbitrary time estimates as a correctness proxy.
4. For every task, record: purpose; exact create/modify/read surfaces when
   verified; consumed and produced interfaces or artifacts; preconditions;
   action; expected observable result; validation command or inspection;
   failure handling; and the authority gate for any external, destructive,
   credential, paid, publication, installation, Git, or irreversible step.
5. Order tasks by dependency, preserve an explicit checkpoint before any
   irreversible boundary, and identify which task produces the first useful
   result. A plan is an execution aid, not permission to execute it.
6. Self-review once: trace every acceptance criterion to a task and check;
   scan for placeholders, unsupported exactness, missing handoffs, inconsistent
   names/interfaces, hidden authority expansion, and tasks that cannot be
   independently verified. Repair the plan or report the blocker.
7. Deliver the plan in the normalized brief or a project-local plan artifact.
   Hand off to `codex-task-execution` only when the user's current request
   authorizes implementation; otherwise present the plan for the user's next
   decision.

## Plan Shape

Use concise Markdown scaled to the task:

```markdown
# <Goal> — execution plan

## Scope and evidence
- Goal / non-goals / authority / completion verifier

## Task 1 — <independently verifiable deliverable>
- Owner and dependencies:
- Verified surfaces:
- Action and expected result:
- Validation and fallback:
- Authority gate:
```

For code work, include test-first or test-after sequencing only when the
project's evidence, technology, and change risk justify it. Never fabricate a
code block, line range, function signature, test command, or passing result to
make a plan look complete.

## Safety and Economy

The plan must reduce coordination loss without requiring extra agents,
worktrees, commits, visual tools, external services, or user approvals. It
does not authorize execution, installation, credentials, destructive mutation,
publication, paid actions, or Git changes. Stop at the smallest plan that
makes the next safe decision or execution handoff clear.

## Verification

Before handoff, verify that every selected acceptance criterion maps to a
task and validation, every dependency has a producer, every consequential
authority boundary is visible, and no unsupported detail is presented as fact.
If the design or evidence is insufficient, return the precise question or
evidence task instead of creating a false-complete plan.
